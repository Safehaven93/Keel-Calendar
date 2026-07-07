import XCTest
@testable import Keel

final class RescheduleSuggesterTests: XCTestCase {
    private func event(
        _ title: String,
        start: String,
        end: String,
        flexibility: Flexibility = .somewhatFlexible
    ) -> Event {
        let formatter = ISO8601DateFormatter()
        return Event(
            title: title,
            startDate: formatter.date(from: start)!,
            endDate: formatter.date(from: end)!,
            flexibility: flexibility
        )
    }

    func testPrefersCloserTimeOverFartherDay() {
        // Original 18:30-19:30 is blocked by a fixed "Class" on day 0, whose
        // wide buffer only leaves 17:00-18:00 free that same day. Every
        // other day in the (somewhat-flexible, 4-day) window carries an
        // identical filler fixed event, so every day is equally "clear" —
        // isolating pure time-proximity from day-clearness. The closer
        // same-day slot should win despite being 90 minutes off, because
        // staying on the requested day outweighs a perfectly-timed slot on
        // an equally-busy later day.
        let move = event("Dinner with mom", start: "2026-07-07T18:30:00Z", end: "2026-07-07T19:30:00Z", flexibility: .somewhatFlexible)
        let keep = event("Class", start: "2026-07-07T18:30:00Z", end: "2026-07-07T20:30:00Z", flexibility: .fixed)
        let fillers = (1...4).map { dayOffset in
            event(
                "Unrelated \(dayOffset)",
                start: "2026-07-\(String(format: "%02d", 7 + dayOffset))T09:00:00Z",
                end: "2026-07-\(String(format: "%02d", 7 + dayOffset))T10:00:00Z",
                flexibility: .fixed
            )
        }

        let suggestions = RescheduleSuggester.suggestions(for: move, avoiding: [keep] + fillers)

        XCTAssertEqual(suggestions.first?.start, ISO8601DateFormatter().date(from: "2026-07-07T17:00:00Z"))
    }

    func testPrefersClearerDayOnProximityTie() {
        // Original slot is blocked on day 0 (same "Class" shape as above).
        // Day 1 offers the exact original time but has a fixed event
        // elsewhere that day; day 2 also offers the exact original time and
        // is otherwise empty. The emptier day should rank first despite
        // being one day further out.
        let move = event("Dinner with mom", start: "2026-07-07T18:30:00Z", end: "2026-07-07T19:30:00Z", flexibility: .veryFlexible)
        let blocker = event("Class", start: "2026-07-07T18:30:00Z", end: "2026-07-07T20:30:00Z", flexibility: .fixed)
        let busyDayOne = event("Something else", start: "2026-07-08T09:00:00Z", end: "2026-07-08T10:00:00Z", flexibility: .fixed)

        let suggestions = RescheduleSuggester.suggestions(for: move, avoiding: [blocker, busyDayOne])

        XCTAssertEqual(suggestions.first?.start, ISO8601DateFormatter().date(from: "2026-07-09T18:30:00Z"))
    }

    func testNeverCollidesWithKeptEvent() {
        // Regression: the old heuristic excluded both conflict-pair events
        // from the collision check, so a suggested slot could still land
        // on top of the event chosen to keep. Construct a case where the
        // naive "same time tomorrow" slot collides with the kept event,
        // and confirm the suggester routes around it.
        let move = event("Dinner with mom", start: "2026-07-07T18:30:00Z", end: "2026-07-07T19:30:00Z", flexibility: .veryFlexible)
        let keep = event("Recurring Class", start: "2026-07-08T18:30:00Z", end: "2026-07-08T20:30:00Z", flexibility: .fixed)

        let suggestions = RescheduleSuggester.suggestions(for: move, avoiding: [keep])

        for suggestion in suggestions {
            XCTAssertNil(ConflictEngine.conflictKind(aStart: suggestion.start, aEnd: suggestion.end, bStart: keep.startDate, bEnd: keep.endDate))
        }
    }

    func testRespectsMaxCount() {
        let move = event("Dinner with mom", start: "2026-07-07T18:30:00Z", end: "2026-07-07T19:30:00Z", flexibility: .veryFlexible)

        let suggestions = RescheduleSuggester.suggestions(for: move, avoiding: [], maxCount: 2)

        XCTAssertLessThanOrEqual(suggestions.count, 2)
    }

    func testNeverReturnsEmptyEvenWhenNearbyTimesAreAllBusy() {
        // Block every ±3h slot around the original time for six straight
        // days (the very-flexible window is 7 days); only the seventh day
        // is left open, and only at a time far from the original — this
        // should still surface a suggestion rather than an empty list.
        let move = event("Dinner with mom", start: "2026-07-07T18:30:00Z", end: "2026-07-07T19:30:00Z", flexibility: .veryFlexible)
        let calendar = Calendar.current
        var blockers: [Event] = []
        for dayOffset in 0...5 {
            let day = calendar.date(byAdding: .day, value: dayOffset, to: move.startDate)!
            let blockStart = calendar.date(byAdding: .hour, value: -3, to: day)!
            let blockEnd = calendar.date(byAdding: .hour, value: 3, to: day)!
            blockers.append(event(
                "Blocker",
                start: ISO8601DateFormatter().string(from: blockStart),
                end: ISO8601DateFormatter().string(from: blockEnd)
            ))
        }

        let suggestions = RescheduleSuggester.suggestions(for: move, avoiding: blockers)

        XCTAssertFalse(suggestions.isEmpty)
    }
}
