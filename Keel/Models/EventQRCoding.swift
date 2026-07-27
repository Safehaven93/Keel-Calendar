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
    /// The sharer's busy time-blocks for `startDate`'s day, if they opted in
    /// to sharing availability. Times only — never titles, locations, or
    /// notes, since a recipient should be able to see *when* the owner is
    /// busy without seeing *what* they're doing.
    var busyBlocks: [DateInterval] = []
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

    /// - Parameter busyEvents: the sharer's other events on `event`'s day,
    ///   included only when they've opted in to sharing availability (an
    ///   explicit checkbox at share time — never on by default). Only each
    ///   event's start/end time is encoded, never its title, location, or
    ///   notes, so a recipient learns *when* the sharer is busy but not
    ///   *what* they're doing.
    static func encode(_ event: Event, busyEvents: [Event] = []) -> String {
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
        for busyEvent in busyEvents {
            lines.append("X-KEEL-BUSY:\(dateFormatter.string(from: busyEvent.startDate))-\(dateFormatter.string(from: busyEvent.endDate))")
        }
        lines.append("END:VEVENT")
        return lines.joined(separator: "\n")
    }

    /// A human-readable summary with the same encoded block from
    /// `encode(_:)` underneath — readable for anyone the text is shared
    /// with, but a Keel recipient can still paste the whole message into
    /// the scan screen's "paste a code" fallback and get it imported
    /// directly, same as if they'd scanned the QR code.
    static func shareText(for event: Event, busyEvents: [Event] = []) -> String {
        let dateLine = event.startDate.formatted(.dateTime.weekday(.wide).month().day())
        let timeLine = "\(event.startDate.formatted(.dateTime.hour().minute()))–\(event.endDate.formatted(.dateTime.hour().minute()))"
        var lines = [event.title, "\(dateLine) · \(timeLine)"]
        if let location = event.location, !location.isEmpty {
            lines.append(location)
        }
        lines.append("")
        lines.append("Paste this into Keel's \u{201C}Scan Event QR\u{201D} screen to add it directly:")
        lines.append(encode(event, busyEvents: busyEvents))
        return lines.joined(separator: "\n")
    }

    static func decode(_ text: String) -> ScannedEventDraft? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("BEGIN:VEVENT"), trimmed.contains("END:VEVENT") else { return nil }

        var fields: [String: String] = [:]
        var busyBlocks: [DateInterval] = []
        for rawLine in trimmed.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard let colonIndex = line.firstIndex(of: ":") else { continue }
            let key = String(line[line.startIndex..<colonIndex])
            let value = String(line[line.index(after: colonIndex)...])
            if key == "X-KEEL-BUSY" {
                let parts = value.components(separatedBy: "-")
                if parts.count == 2,
                   let busyStart = dateFormatter.date(from: parts[0]),
                   let busyEnd = dateFormatter.date(from: parts[1]),
                   busyEnd > busyStart {
                    busyBlocks.append(DateInterval(start: busyStart, end: busyEnd))
                }
                continue
            }
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
            category: category,
            busyBlocks: busyBlocks
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
