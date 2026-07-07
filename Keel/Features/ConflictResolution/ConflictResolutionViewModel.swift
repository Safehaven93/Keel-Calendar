import Foundation
import SwiftData

@Observable
final class ConflictResolutionViewModel {
    enum Stage {
        case choosing
        case pickingTime(keep: Event, move: Event, suggestions: [RescheduleSuggestion])
        case confirmed(move: Event, newStart: Date)
    }

    let eventA: Event
    let eventB: Event
    let recommendation: Recommendation
    var showsDetail = false
    var stage: Stage = .choosing

    // Picking-time state
    var selectedSuggestion: RescheduleSuggestion?
    var isUsingManualTime = false
    var manualDate = Date.now
    var manualStartTime = Date.now
    var manualEndTime = Date.now
    var manualConflict: Event?

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

    /// Begins the reschedule flow for `move` (keeping `keep`): generates
    /// ranked suggestions rather than resolving immediately, so the user
    /// sees and can adjust the new time before anything is saved (DESIGN
    /// §3 steps 4-5).
    func beginRescheduling(keep: Event, move: Event, in context: ModelContext) {
        let others = allOtherEvents(excluding: move, in: context)
        let suggestions = RescheduleSuggester.suggestions(for: move, avoiding: others)
        selectedSuggestion = suggestions.first
        isUsingManualTime = false
        manualDate = Calendar.current.startOfDay(for: move.startDate)
        manualStartTime = move.startDate
        manualEndTime = move.endDate
        manualConflict = nil
        stage = .pickingTime(keep: keep, move: move, suggestions: suggestions)
    }

    /// Re-validates the manual date/time pickers against the rest of the
    /// calendar — including `keep` — every time they change, so a manual
    /// pick can never silently reintroduce a collision the way the old
    /// auto-pick heuristic could.
    func revalidateManualTime(move: Event, in context: ModelContext) {
        let (start, end) = combinedManualRange()
        let others = allOtherEvents(excluding: move, in: context)
        manualConflict = others.first {
            ConflictEngine.conflictKind(aStart: start, aEnd: end, bStart: $0.startDate, bEnd: $0.endDate) != nil
        }
    }

    var canConfirmPickedTime: Bool {
        isUsingManualTime ? manualConflict == nil : selectedSuggestion != nil
    }

    func confirmPickedTime(keep: Event, move: Event) {
        let start: Date
        let end: Date
        if isUsingManualTime {
            (start, end) = combinedManualRange()
        } else if let selectedSuggestion {
            (start, end) = (selectedSuggestion.start, selectedSuggestion.end)
        } else {
            return
        }
        EventStore.resolve(keep: keep, move: move, newStart: start, newEnd: end)
        stage = .confirmed(move: move, newStart: start)
    }

    func backToChoosing() {
        stage = .choosing
    }

    private func allOtherEvents(excluding event: Event, in context: ModelContext) -> [Event] {
        (try? context.fetch(FetchDescriptor<Event>()))?.filter { $0.id != event.id } ?? []
    }

    private func combinedManualRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: manualDate)
        func combine(_ time: Date) -> Date {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(from: DateComponents(
                year: dayComponents.year, month: dayComponents.month, day: dayComponents.day,
                hour: timeComponents.hour, minute: timeComponents.minute
            )) ?? manualDate
        }
        return (combine(manualStartTime), combine(manualEndTime))
    }
}
