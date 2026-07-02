import Foundation
import SwiftData

/// Thin coordinator for the Agenda screen: day-grouping and delete, both of
/// which need a `ModelContext` the View gets from `@Environment`.
@Observable
final class AgendaViewModel {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func delete(_ event: Event) {
        EventStore.delete(event, in: modelContext)
    }

    /// Groups events into day sections (today first in practice, since the
    /// caller queries sorted by `startDate`), matching DESIGN §4.1.
    func groupedByDay(_ events: [Event]) -> [(day: Date, events: [Event])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: events) { calendar.startOfDay(for: $0.startDate) }
        return groups.keys.sorted().map { day in
            (day: day, events: groups[day]!.sorted { $0.startDate < $1.startDate })
        }
    }
}
