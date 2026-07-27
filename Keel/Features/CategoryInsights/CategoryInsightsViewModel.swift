import Foundation

/// One category's tally for a given month — includes an "uncategorized"
/// row (nil category) so the breakdown accounts for every event, not just
/// the ones a user remembered to tag. `durationDelta` is nil when the
/// category had zero events last month (a "new" category this month, not
/// a meaningful comparison); otherwise it's this month's total minus last
/// month's, so a negative value means less time than last month.
struct CategoryBreakdownRow: Identifiable {
    let id: String
    let label: String
    let count: Int
    let totalDuration: TimeInterval
    let durationDelta: TimeInterval?
}

/// Groups a month's events by category, tallying both count and total time
/// per category — the interview insight behind this feature was about
/// time specifically ("am I overloading one category"), but a raw count
/// is cheap to show alongside it and useful on its own. Also compares
/// each category's total against the prior month, which more directly
/// serves that insight than a single-month snapshot alone.
@Observable
final class CategoryInsightsViewModel {
    var displayedMonth: Date

    init(displayedMonth: Date = .now) {
        self.displayedMonth = Calendar.current.startOfDay(for: displayedMonth)
    }

    func rows(from events: [Event]) -> [CategoryBreakdownRow] {
        let current = tally(events, for: displayedMonth)
        let previous = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth)
            .map { tally(events, for: $0) } ?? [:]

        return current.map { category, stats in
            let durationDelta = previous[category].map { stats.duration - $0.duration }
            return CategoryBreakdownRow(
                id: category?.rawValue ?? "uncategorized",
                label: category?.label ?? "Uncategorized",
                count: stats.count,
                totalDuration: stats.duration,
                durationDelta: durationDelta
            )
        }
        .sorted { $0.totalDuration > $1.totalDuration }
    }

    func changeMonth(by offset: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: offset, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private struct CategoryTally {
        let count: Int
        let duration: TimeInterval
    }

    private func tally(_ events: [Event], for month: Date) -> [EventCategory?: CategoryTally] {
        let calendar = Calendar.current
        let monthEvents = events.filter { calendar.isDate($0.startDate, equalTo: month, toGranularity: .month) }
        let grouped = Dictionary(grouping: monthEvents, by: { $0.category })
        return grouped.mapValues { events in
            CategoryTally(
                count: events.count,
                duration: events.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            )
        }
    }

    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        return formatter
    }()

    static func formattedDuration(_ interval: TimeInterval) -> String {
        durationFormatter.string(from: interval) ?? "0m"
    }
}
