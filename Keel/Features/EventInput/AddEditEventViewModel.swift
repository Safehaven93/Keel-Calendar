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
    var category: EventCategory?
    var location: String = ""
    var notes: String = ""
    var showsMoreDetails = false

    private let editingEvent: Event?

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isEditing: Bool { editingEvent != nil }

    /// - Parameter defaultDate: the day to prefill when adding a new event
    ///   (e.g. the day currently selected in Agenda's calendar strip).
    ///   Ignored when editing an existing event, which keeps its own date.
    init(editing event: Event? = nil, defaultDate: Date = .now) {
        self.editingEvent = event
        let calendar = Calendar.current
        if let event {
            title = event.title
            date = calendar.startOfDay(for: event.startDate)
            startTime = event.startDate
            endTime = event.endDate
            flexibility = event.flexibility
            category = event.category
            location = event.location ?? ""
            notes = event.notes ?? ""
        } else {
            let now = Date()
            date = calendar.startOfDay(for: defaultDate)
            let hourFromNow = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
            let roundedStart = Self.roundedUpToNextHalfHour(hourFromNow, calendar: calendar)
            startTime = roundedStart
            endTime = calendar.date(byAdding: .hour, value: 1, to: roundedStart) ?? roundedStart
        }
    }

    /// Rounds up to the next :00 or :30 — a suggested default of 7:17 reads
    /// as arbitrary; 7:30 reads as a real proposed time.
    static func roundedUpToNextHalfHour(_ date: Date, calendar: Calendar = .current) -> Date {
        let minute = calendar.component(.minute, from: date)
        let remainder = minute % 30
        let rounded = remainder == 0 ? date : calendar.date(byAdding: .minute, value: 30 - remainder, to: date) ?? date
        return calendar.date(bySettingHour: calendar.component(.hour, from: rounded), minute: calendar.component(.minute, from: rounded), second: 0, of: rounded) ?? rounded
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
            editingEvent.category = category
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
                flexibility: flexibility,
                category: category
            )
            context.insert(event)
            return event
        }
    }
}
