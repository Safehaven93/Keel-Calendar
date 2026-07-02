import Foundation

/// Detects overlap/collision between commitments and recommends which one
/// should win, with explainable reasoning. Kept separate from views and CRUD
/// per CLAUDE.md/SKILL.md so this logic doesn't get reinvented per screen.
enum ConflictEngine {
    /// Gap under this is still flagged as a soft conflict even without literal
    /// overlap. Placeholder default (SKILL.md: don't assume a buffer without
    /// research) — revisit once interviews confirm real travel/buffer norms.
    static let softConflictBuffer: TimeInterval = 30 * 60

    static let signals: [ConflictSignal] = [
        ConflictSignals.flexibility,
        ConflictSignals.advanceNotice,
    ]

    static func conflictKind(between a: Event, and b: Event) -> ConflictKind? {
        conflictKind(aStart: a.startDate, aEnd: a.endDate, bStart: b.startDate, bEnd: b.endDate)
    }

    /// Date-range form of `conflictKind`, usable without constructing `Event`
    /// instances — e.g. when probing candidate reschedule slots.
    static func conflictKind(aStart: Date, aEnd: Date, bStart: Date, bEnd: Date) -> ConflictKind? {
        if aStart < bEnd && bStart < aEnd {
            return .hard
        }
        let gap = aStart < bStart
            ? bStart.timeIntervalSince(aEnd)
            : aStart.timeIntervalSince(bEnd)
        if gap >= 0 && gap < softConflictBuffer {
            return .soft
        }
        return nil
    }

    /// First conflicting event in `existing` for `new`, ordered by earliest
    /// `startDate`. MVP only surfaces one pair at a time even when `new`
    /// overlaps several existing events — the rest are a known limitation
    /// (see build plan) rather than silently dropped or improvised mid-flow.
    static func firstConflict(for new: Event, among existing: [Event]) -> Event? {
        existing
            .filter { $0.id != new.id && conflictKind(between: new, and: $0) != nil }
            .sorted { $0.startDate < $1.startDate }
            .first
    }

    static func recommend(a: Event, b: Event) -> Recommendation {
        var reasoning: [String] = []
        var winnerID: UUID?

        for signal in signals {
            switch signal.evaluate(a, b) {
            case .favors(let eventID, let reason):
                reasoning.append(reason)
                if winnerID == nil { winnerID = eventID }
            case .neutral:
                continue
            }
        }

        guard let winnerID, !reasoning.isEmpty else {
            return .tooClose(reasoning: ["Both of these look equally flexible — your call."])
        }
        let loserID = winnerID == a.id ? b.id : a.id
        return .decided(keep: winnerID, move: loserID, reasoning: reasoning)
    }
}
