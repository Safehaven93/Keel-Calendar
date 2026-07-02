import Foundation
import SwiftData

@Observable
final class ConflictResolutionViewModel {
    let eventA: Event
    let eventB: Event
    let recommendation: Recommendation
    var showsDetail = false

    init(eventA: Event, eventB: Event) {
        self.eventA = eventA
        self.eventB = eventB
        self.recommendation = ConflictEngine.recommend(a: eventA, b: eventB)
    }

    /// DESIGN §6.3: if this pair no longer references each other (resolved
    /// elsewhere, or one side deleted), this is a stale/no-longer-applicable
    /// state, not an error.
    var isStillConflicted: Bool {
        eventA.unresolvedConflictEventID == eventB.id && eventB.unresolvedConflictEventID == eventA.id
    }

    var isDecided: Bool { recommendation.isDecided }

    /// Default keep candidate for the primary action — the engine's pick
    /// when decided, else `eventA` for the equal-weight §6.4 case (the UI
    /// renders both cards with equal weight regardless).
    var defaultKeep: Event {
        if case .decided(let keep, _, _) = recommendation {
            return keep == eventA.id ? eventA : eventB
        }
        return eventA
    }

    var defaultMove: Event {
        defaultKeep === eventA ? eventB : eventA
    }

    func resolve(keep: Event, move: Event, in context: ModelContext) {
        let suggestion = suggestedReschedule(for: move, in: context)
        EventStore.resolve(keep: keep, move: move, newStart: suggestion.start, newEnd: suggestion.end)
    }

    /// Simple next-available-slot heuristic: try the same time on each of the
    /// following days, within a window implied by the moved event's
    /// flexibility, until one doesn't collide with anything else on the
    /// calendar. Falls back to +1 day if the whole window is booked.
    private func suggestedReschedule(for event: Event, in context: ModelContext) -> (start: Date, end: Date) {
        let duration = event.endDate.timeIntervalSince(event.startDate)
        let calendar = Calendar.current
        let windowDays: Int
        switch event.flexibility {
        case .fixed: windowDays = 1
        case .somewhatFlexible: windowDays = 4
        case .veryFlexible: windowDays = 7
        }

        let others = (try? context.fetch(FetchDescriptor<Event>()))?
            .filter { $0.id != event.id && $0.id != eventA.id && $0.id != eventB.id } ?? []

        for offset in 1...windowDays {
            guard let candidateStart = calendar.date(byAdding: .day, value: offset, to: event.startDate) else { continue }
            let candidateEnd = candidateStart.addingTimeInterval(duration)
            let collides = others.contains {
                ConflictEngine.conflictKind(aStart: candidateStart, aEnd: candidateEnd, bStart: $0.startDate, bEnd: $0.endDate) != nil
            }
            if !collides {
                return (candidateStart, candidateEnd)
            }
        }
        let fallbackStart = calendar.date(byAdding: .day, value: 1, to: event.startDate) ?? event.startDate
        return (fallbackStart, fallbackStart.addingTimeInterval(duration))
    }
}
