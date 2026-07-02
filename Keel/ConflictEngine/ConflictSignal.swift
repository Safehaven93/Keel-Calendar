import Foundation

/// One contributing factor in deciding which of two colliding events should
/// win. New signals (dependents, sunk cost, recurrence — see SKILL.md) can be
/// appended to `ConflictEngine.signals` once real UI captures them, without
/// restructuring anything else.
struct ConflictSignal {
    let evaluate: (Event, Event) -> Outcome

    enum Outcome {
        case favors(eventID: UUID, reason: String)
        case neutral
    }
}

enum ConflictSignals {
    /// Harder-to-move commitments win. This is the primary signal for MVP —
    /// it needs no UI beyond the flexibility picker already in Add/Edit Event.
    static let flexibility = ConflictSignal { a, b in
        guard a.flexibility.rank != b.flexibility.rank else { return .neutral }
        let (winner, loser) = a.flexibility.rank < b.flexibility.rank ? (a, b) : (b, a)
        let reason = "\(winner.title) (\(winner.flexibility.label.lowercased())) is harder to move than "
            + "\(loser.title), which \(loser.flexibility.reschedulePhrase)."
        return .favors(eventID: winner.id, reason: reason)
    }

    /// Tiebreaker when flexibility is equal: the commitment booked further in
    /// advance is treated as more established. Placeholder heuristic pending
    /// real research signals from SKILL.md's table.
    static let advanceNotice = ConflictSignal { a, b in
        guard a.flexibility.rank == b.flexibility.rank else { return .neutral }
        guard a.createdAt != b.createdAt else { return .neutral }
        let (winner, loser) = a.createdAt < b.createdAt ? (a, b) : (b, a)
        let reason = "\(winner.title) was on the calendar first, ahead of \(loser.title)."
        return .favors(eventID: winner.id, reason: reason)
    }
}

private extension Flexibility {
    var reschedulePhrase: String {
        switch self {
        case .fixed: return "has very little room to move either"
        case .somewhatFlexible: return "can move within the next few days"
        case .veryFlexible: return "can move to any day this week"
        }
    }
}
