import Foundation
import SwiftData

enum Flexibility: String, Codable, CaseIterable, Identifiable {
    case fixed
    case somewhatFlexible
    case veryFlexible

    var id: String { rawValue }

    var label: String {
        switch self {
        case .fixed: return "Fixed"
        case .somewhatFlexible: return "Somewhat flexible"
        case .veryFlexible: return "Very flexible"
        }
    }

    /// Lower rank = harder to move. Used to compare two events' flexibility.
    var rank: Int {
        switch self {
        case .fixed: return 0
        case .somewhatFlexible: return 1
        case .veryFlexible: return 2
        }
    }
}

/// Optional, user-assigned grouping for time-tracking/filtering — separate
/// from `Flexibility`, which is about how movable an event is, not what
/// kind of commitment it is. Fixed preset list for now (see TODO.md); a
/// closed set keeps the first pass small and lets filtering/reporting UI
/// assume a fixed set of cases instead of an arbitrary user-managed list.
enum EventCategory: String, Codable, CaseIterable, Identifiable {
    case family
    case exercise
    case recreational

    var id: String { rawValue }

    var label: String {
        switch self {
        case .family: return "Family"
        case .exercise: return "Exercise"
        case .recreational: return "Recreational"
        }
    }
}

@Model
final class Event {
    var id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var location: String?
    var notes: String?
    var flexibility: Flexibility
    var category: EventCategory?
    var createdAt: Date
    var isRescheduled: Bool
    var rescheduleNote: String?
    var unresolvedConflictEventID: UUID?

    init(
        id: UUID = UUID(),
        title: String,
        startDate: Date,
        endDate: Date,
        location: String? = nil,
        notes: String? = nil,
        flexibility: Flexibility = .somewhatFlexible,
        category: EventCategory? = nil,
        createdAt: Date = .now,
        isRescheduled: Bool = false,
        rescheduleNote: String? = nil,
        unresolvedConflictEventID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.notes = notes
        self.flexibility = flexibility
        self.category = category
        self.createdAt = createdAt
        self.isRescheduled = isRescheduled
        self.rescheduleNote = rescheduleNote
        self.unresolvedConflictEventID = unresolvedConflictEventID
    }
}
