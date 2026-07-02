import XCTest
@testable import Keel

final class ConflictEngineTests: XCTestCase {
    private func event(
        _ title: String,
        start: String,
        end: String,
        flexibility: Flexibility = .somewhatFlexible,
        createdAt: Date = .now
    ) -> Event {
        let formatter = ISO8601DateFormatter()
        return Event(
            title: title,
            startDate: formatter.date(from: start)!,
            endDate: formatter.date(from: end)!,
            flexibility: flexibility,
            createdAt: createdAt
        )
    }

    // MARK: - detectConflict (via conflictKind)

    func testHardOverlapDetected() {
        let a = event("Recital", start: "2026-08-01T17:00:00Z", end: "2026-08-01T18:00:00Z")
        let b = event("Grocery run", start: "2026-08-01T17:30:00Z", end: "2026-08-01T18:30:00Z")
        XCTAssertEqual(ConflictEngine.conflictKind(between: a, and: b), .hard)
    }

    func testSoftConflictWithinBufferDetected() {
        let a = event("Meeting", start: "2026-08-01T17:00:00Z", end: "2026-08-01T18:00:00Z")
        let b = event("Pickup", start: "2026-08-01T18:15:00Z", end: "2026-08-01T18:45:00Z")
        XCTAssertEqual(ConflictEngine.conflictKind(between: a, and: b), .soft)
    }

    func testNoConflictOutsideBuffer() {
        let a = event("Meeting", start: "2026-08-01T17:00:00Z", end: "2026-08-01T18:00:00Z")
        let b = event("Dinner", start: "2026-08-01T20:00:00Z", end: "2026-08-01T21:00:00Z")
        XCTAssertNil(ConflictEngine.conflictKind(between: a, and: b))
    }

    func testNWayConflictPicksEarliestStart() {
        let new = event("New event", start: "2026-08-01T17:00:00Z", end: "2026-08-01T19:00:00Z")
        let later = event("Later overlap", start: "2026-08-01T18:00:00Z", end: "2026-08-01T18:30:00Z")
        let earlier = event("Earlier overlap", start: "2026-08-01T17:15:00Z", end: "2026-08-01T17:45:00Z")
        let unrelated = event("No overlap", start: "2026-08-02T09:00:00Z", end: "2026-08-02T10:00:00Z")

        let picked = ConflictEngine.firstConflict(for: new, among: [later, earlier, unrelated])
        XCTAssertEqual(picked?.title, "Earlier overlap")
    }

    // MARK: - recommend

    func testFixedBeatsFlexible() {
        let recital = event("Recital", start: "2026-08-01T17:00:00Z", end: "2026-08-01T18:00:00Z", flexibility: .fixed)
        let errand = event("Grocery run", start: "2026-08-01T17:30:00Z", end: "2026-08-01T18:30:00Z", flexibility: .veryFlexible)

        let recommendation = ConflictEngine.recommend(a: recital, b: errand)
        guard case .decided(let keep, let move, let reasoning) = recommendation else {
            return XCTFail("Expected a decided recommendation")
        }
        XCTAssertEqual(keep, recital.id)
        XCTAssertEqual(move, errand.id)
        XCTAssertFalse(reasoning.isEmpty)
    }

    func testAdvanceNoticeTiebreak() {
        let earlyBird = event(
            "Booked long ago", start: "2026-08-01T17:00:00Z", end: "2026-08-01T18:00:00Z",
            flexibility: .somewhatFlexible, createdAt: Date(timeIntervalSince1970: 0)
        )
        let lastMinute = event(
            "Just added", start: "2026-08-01T17:30:00Z", end: "2026-08-01T18:30:00Z",
            flexibility: .somewhatFlexible, createdAt: Date(timeIntervalSince1970: 1_000_000)
        )

        let recommendation = ConflictEngine.recommend(a: earlyBird, b: lastMinute)
        guard case .decided(let keep, let move, _) = recommendation else {
            return XCTFail("Expected a decided recommendation")
        }
        XCTAssertEqual(keep, earlyBird.id)
        XCTAssertEqual(move, lastMinute.id)
    }

    func testTrueTieReturnsTooClose() {
        let sameMoment = Date(timeIntervalSince1970: 500_000)
        let a = event("Option A", start: "2026-08-01T17:00:00Z", end: "2026-08-01T18:00:00Z",
                       flexibility: .somewhatFlexible, createdAt: sameMoment)
        let b = event("Option B", start: "2026-08-01T17:30:00Z", end: "2026-08-01T18:30:00Z",
                       flexibility: .somewhatFlexible, createdAt: sameMoment)

        let recommendation = ConflictEngine.recommend(a: a, b: b)
        guard case .tooClose(let reasoning) = recommendation else {
            return XCTFail("Expected a tooClose recommendation")
        }
        XCTAssertEqual(reasoning, ["Both of these look equally flexible — your call."])
    }
}
