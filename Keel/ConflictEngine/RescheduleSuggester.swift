import Foundation

/// One candidate day/time for a rescheduled event, with a plain-language
/// reason so the recommendation stays explainable (SKILL.md: "show which
/// signals tipped the recommendation").
struct RescheduleSuggestion: Identifiable, Equatable {
    let id = UUID()
    let start: Date
    let end: Date
    let reason: String

    static func == (lhs: RescheduleSuggestion, rhs: RescheduleSuggestion) -> Bool {
        lhs.start == rhs.start && lhs.end == rhs.end
    }
}

/// Suggests where a bumped event could move to, ranked by proximity to its
/// original time and how clear the candidate day otherwise is — not just
/// the first non-colliding slot.
enum RescheduleSuggester {
    private static let timeOffsetsMinutes: [Int] = {
        var offsets = [0]
        for step in stride(from: 30, through: 180, by: 30) {
            offsets.append(step)
            offsets.append(-step)
        }
        return offsets
    }()

    /// - Parameter others: the full calendar **minus only `event` itself**.
    ///   Must include whatever event(s) `event` was conflicting with — a
    ///   candidate slot that still overlaps the kept event is not a valid
    ///   suggestion.
    static func suggestions(for event: Event, avoiding others: [Event], maxCount: Int = 3) -> [RescheduleSuggestion] {
        let calendar = Calendar.current
        let duration = event.endDate.timeIntervalSince(event.startDate)
        let windowDays: Int
        switch event.flexibility {
        case .fixed: windowDays = 1
        case .somewhatFlexible: windowDays = 4
        case .veryFlexible: windowDays = 7
        }

        var candidates: [(start: Date, end: Date, dayOffset: Int, timeOffsetMinutes: Int)] = []

        for dayOffset in 0...windowDays {
            guard let dayBase = calendar.date(byAdding: .day, value: dayOffset, to: event.startDate) else { continue }
            for offset in timeOffsetsMinutes {
                let candidateStart = dayBase.addingTimeInterval(TimeInterval(offset * 60))
                let candidateEnd = candidateStart.addingTimeInterval(duration)
                let collides = others.contains {
                    ConflictEngine.conflictKind(aStart: candidateStart, aEnd: candidateEnd, bStart: $0.startDate, bEnd: $0.endDate) != nil
                }
                if !collides {
                    candidates.append((candidateStart, candidateEnd, dayOffset, offset))
                    break // offsets are ordered by proximity; first free one wins for this day
                }
            }
        }

        // Fallback: nothing found near the original time anywhere in the
        // window — widen to the first available slot per day, same-time
        // only, so there's always at least one suggestion.
        if candidates.isEmpty {
            for dayOffset in 1...windowDays {
                guard let candidateStart = calendar.date(byAdding: .day, value: dayOffset, to: event.startDate) else { continue }
                let candidateEnd = candidateStart.addingTimeInterval(duration)
                let collides = others.contains {
                    ConflictEngine.conflictKind(aStart: candidateStart, aEnd: candidateEnd, bStart: $0.startDate, bEnd: $0.endDate) != nil
                }
                if !collides {
                    candidates.append((candidateStart, candidateEnd, dayOffset, 0))
                    break
                }
            }
        }

        let scored = candidates.map { candidate -> (candidate: (start: Date, end: Date, dayOffset: Int, timeOffsetMinutes: Int), score: Double) in
            let dayEvents = others.filter { calendar.isDate($0.startDate, inSameDayAs: candidate.start) }
            let fixedCount = dayEvents.filter { $0.flexibility == .fixed }.count
            // Weighted so a same-day slot a couple hours off still beats a
            // perfectly-timed slot a day later: staying on the requested
            // day matters more than exact minute alignment, but day
            // clearness (especially avoiding other fixed commitments)
            // matters more still.
            let score = -Double(abs(candidate.timeOffsetMinutes)) / 30.0 * 0.5
                - Double(dayEvents.count) * 1.5
                - Double(fixedCount) * 2.5
                - Double(candidate.dayOffset) * 2.0
            return (candidate, score)
        }
        .sorted { $0.score > $1.score }

        return scored.prefix(maxCount).map { entry in
            let dayEvents = others.filter { calendar.isDate($0.startDate, inSameDayAs: entry.candidate.start) }
            let fixedCount = dayEvents.filter { $0.flexibility == .fixed }.count
            return RescheduleSuggestion(
                start: entry.candidate.start,
                end: entry.candidate.end,
                reason: reasonText(dayOffset: entry.candidate.dayOffset, start: entry.candidate.start, eventCount: dayEvents.count, fixedCount: fixedCount)
            )
        }
    }

    private static func reasonText(dayOffset: Int, start: Date, eventCount: Int, fixedCount: Int) -> String {
        let dayLabel = dayOffset == 0 ? "Later today" : start.formatted(.dateTime.weekday(.wide))
        let timeLabel = start.formatted(.dateTime.hour().minute())
        let clearness: String
        if eventCount == 0 {
            clearness = "your schedule is clear that day"
        } else if fixedCount == 0 {
            clearness = "only flexible commitments that day"
        } else if fixedCount == 1 {
            clearness = "one fixed commitment that day too"
        } else {
            clearness = "\(fixedCount) fixed commitments that day too"
        }
        return "\(dayLabel) at \(timeLabel) — \(clearness)"
    }
}
