import Foundation
import SwiftData

/// Form state for Add/Edit Event. Only title, date, and start time are
/// required (DESIGN §4.2) — everything else stays optional.
@Observable
final class AddEditEventViewModel {
    var title: String = ""
    var date: Date
    var startTime: Date
    var endTime: Date
    var flexibility: Flexibility = .somewhatFlexible
    var location: String = ""
    var notes: String = ""
    var showsMoreDetails = false

    private let editingEvent: Event?

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isEditing: Bool { editingEvent != nil }

    init(editing event: Event? = nil) {
        self.editingEvent = event
        let calendar = Calendar.current
        if let event {
            title = event.title
            date = calendar.startOfDay(for: event.startDate)
            startTime = event.startDate
            endTime = event.endDate
            flexibility = event.flexibility
            location = event.location ?? ""
            notes = event.notes ?? ""
        } else {
            let now = Date()
            date = calendar.startOfDay(for: now)
            startTime = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
            endTime = calendar.date(byAdding: .hour, value: 2, to: now) ?? now
        }
    }

    private func combined(day: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: day)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(from: DateComponents(
            year: dayComponents.year, month: dayComponents.month, day: dayComponents.day,
            hour: timeComponents.hour, minute: timeComponents.minute
        )) ?? day
    }

    /// Applies the form's current values to `editingEvent`, or returns a new
    /// `Event` ready to be inserted, if this is a fresh add.
    func makeOrUpdateEvent(insertingInto context: ModelContext) -> Event {
        let resolvedStart = combined(day: date, time: startTime)
        var resolvedEnd = combined(day: date, time: endTime)
        if resolvedEnd <= resolvedStart {
            resolvedEnd = resolvedStart.addingTimeInterval(60 * 60)
        }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let editingEvent {
            editingEvent.title = trimmedTitle
            editingEvent.startDate = resolvedStart
            editingEvent.endDate = resolvedEnd
            editingEvent.flexibility = flexibility
            editingEvent.location = trimmedLocation.isEmpty ? nil : trimmedLocation
            editingEvent.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
            return editingEvent
        } else {
            let event = Event(
                title: trimmedTitle,
                startDate: resolvedStart,
                endDate: resolvedEnd,
                location: trimmedLocation.isEmpty ? nil : trimmedLocation,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                flexibility: flexibility
            )
            context.insert(event)
            return event
        }
    }
}
