import Foundation
import SwiftData

/// Thin coordinator for the Agenda screen: day-filtering and delete, both of
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

    /// Events on a single calendar day, sorted by start time — the Agenda
    /// list is filtered to one day at a time via the calendar strip.
    func events(on day: Date, from events: [Event]) -> [Event] {
        let calendar = Calendar.current
        return events
            .filter { calendar.isDate($0.startDate, inSameDayAs: day) }
            .sorted { $0.startDate < $1.startDate }
    }

    /// A window of `2*days + 1` calendar days centered on `center`, used to
    /// populate the horizontal calendar strip. Pulled out as a pure function
    /// (rather than embedded in the strip view) so the range math is
    /// independently testable.
    static func dayRange(around center: Date, days: Int) -> [Date] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: center)
        return (-days...days).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start)
        }
    }
}
