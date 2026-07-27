import Foundation

/// A parsed-but-not-yet-saved event, produced by decoding a scanned QR
/// code. Deliberately not an `Event` — nothing from a scan should touch
/// SwiftData until the user reviews and saves it via the normal Add/Edit
/// form, same as any other new event.
struct ScannedEventDraft {
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let notes: String?
    let flexibility: Flexibility
    let category: EventCategory?
}

/// Encodes/decodes an event as a standard iCalendar `VEVENT` block — reusing
/// an existing interchange format rather than inventing a bespoke one, so
/// the QR text is at least meaningful to other calendar apps that scan it,
/// even though only Keel will understand the `X-KEEL-*` extension fields
/// (flexibility/category aren't standard iCalendar concepts).
enum EventQRCoding {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        return formatter
    }()

    static func encode(_ event: Event) -> String {
        var lines = [
            "BEGIN:VEVENT",
            "UID:\(event.id.uuidString)",
            "SUMMARY:\(escape(event.title))",
            "DTSTART:\(dateFormatter.string(from: event.startDate))",
            "DTEND:\(dateFormatter.string(from: event.endDate))",
        ]
        if let location = event.location, !location.isEmpty {
            lines.append("LOCATION:\(escape(location))")
        }
        if let notes = event.notes, !notes.isEmpty {
            lines.append("DESCRIPTION:\(escape(notes))")
        }
        lines.append("X-KEEL-FLEXIBILITY:\(event.flexibility.rawValue)")
        if let category = event.category {
            lines.append("X-KEEL-CATEGORY:\(category.rawValue)")
        }
        lines.append("END:VEVENT")
        return lines.joined(separator: "\n")
    }

    static func decode(_ text: String) -> ScannedEventDraft? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("BEGIN:VEVENT"), trimmed.contains("END:VEVENT") else { return nil }

        var fields: [String: String] = [:]
        for rawLine in trimmed.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard let colonIndex = line.firstIndex(of: ":") else { continue }
            let key = String(line[line.startIndex..<colonIndex])
            let value = String(line[line.index(after: colonIndex)...])
            fields[key] = unescape(value)
        }

        guard let title = fields["SUMMARY"], !title.isEmpty,
              let startText = fields["DTSTART"], let startDate = dateFormatter.date(from: startText) else {
            return nil
        }
        let endDate = fields["DTEND"].flatMap(dateFormatter.date(from:)) ?? startDate.addingTimeInterval(60 * 60)

        let flexibility = fields["X-KEEL-FLEXIBILITY"].flatMap(Flexibility.init(rawValue:)) ?? .somewhatFlexible
        let category = fields["X-KEEL-CATEGORY"].flatMap(EventCategory.init(rawValue:))

        return ScannedEventDraft(
            title: title,
            startDate: startDate,
            endDate: endDate,
            location: fields["LOCATION"],
            notes: fields["DESCRIPTION"],
            flexibility: flexibility,
            category: category
        )
    }

    private static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    private static func unescape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\;", with: ";")
            .replacingOccurrences(of: "\\,", with: ",")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }
}
