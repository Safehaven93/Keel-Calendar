import Foundation
import SwiftData

/// Centralizes Event persistence + conflict-lifecycle bookkeeping so it isn't
/// duplicated across Agenda/EventDetail/AddEdit/ConflictResolution view
/// models — every mutation that can affect `unresolvedConflictEventID` goes
/// through here.
enum EventStore {
    /// Deletes `event`. If it was one half of an unresolved conflict, clears
    /// the partner's reference so it doesn't point at a deleted UUID.
    static func delete(_ event: Event, in context: ModelContext) {
        clearConflictReference(for: event.unresolvedConflictEventID, in: context)
        context.delete(event)
    }

    /// Re-checks `event` against the rest of the calendar and links/clears
    /// `unresolvedConflictEventID` on both sides to match. Returns the
    /// conflicting partner, if any, so callers can route to Conflict
    /// Resolution.
    @discardableResult
    static func relinkConflict(for event: Event, allEvents: [Event], in context: ModelContext) -> Event? {
        let previousPartnerID = event.unresolvedConflictEventID
        let others = allEvents.filter { $0.id != event.id }
        let conflict = ConflictEngine.firstConflict(for: event, among: others)

        if let previousPartnerID, conflict?.id != previousPartnerID {
            clearConflictReference(for: previousPartnerID, in: context)
        }

        if let conflict {
            event.unresolvedConflictEventID = conflict.id
            conflict.unresolvedConflictEventID = event.id
        } else {
            event.unresolvedConflictEventID = nil
        }
        return conflict
    }

    /// Applies the outcome of the Conflict Resolution screen: the moved
    /// event gets its new time + a visible reschedule note, and the
    /// conflict marker clears on both sides.
    static func resolve(keep: Event, move: Event, newStart: Date, newEnd: Date) {
        move.startDate = newStart
        move.endDate = newEnd
        move.isRescheduled = true
        move.rescheduleNote = "Rescheduled to keep \(keep.title) clear"
        keep.unresolvedConflictEventID = nil
        move.unresolvedConflictEventID = nil
    }

    private static func clearConflictReference(for eventID: UUID?, in context: ModelContext) {
        guard let eventID else { return }
        let descriptor = FetchDescriptor<Event>(predicate: #Predicate { $0.id == eventID })
        if let partner = try? context.fetch(descriptor).first {
            partner.unresolvedConflictEventID = nil
        }
    }
}
