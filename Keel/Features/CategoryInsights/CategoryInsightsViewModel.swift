import Foundation

/// One category's tally for a given month — includes an "uncategorized"
/// row (nil category) so the breakdown accounts for every event, not just
/// the ones a user remembered to tag.
struct CategoryBreakdownRow: Identifiable {
    let id: String
    let label: String
    let count: Int
    let totalDuration: TimeInterval
}

/// Groups a month's events by category, tallying both count and total time
/// per category — the interview insight behind this feature was about
/// time specifically ("am I overloading one category"), but a raw count
/// is cheap to show alongside it and useful on its own.
@Observable
final class CategoryInsightsViewModel {
    var displayedMonth: Date

    init(displayedMonth: Date = .now) {
        self.displayedMonth = Calendar.current.startOfDay(for: displayedMonth)
    }

    func rows(from events: [Event]) -> [CategoryBreakdownRow] {
        let calendar = Calendar.current
        let monthEvents = events.filter {
            calendar.isDate($0.startDate, equalTo: displayedMonth, toGranularity: .month)
        }
        let grouped = Dictionary(grouping: monthEvents, by: { $0.category })

        return grouped.map { category, events in
            let totalDuration = events.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            return CategoryBreakdownRow(
                id: category?.rawValue ?? "uncategorized",
                label: category?.label ?? "Uncategorized",
                count: events.count,
                totalDuration: totalDuration
            )
        }
        .sorted { $0.totalDuration > $1.totalDuration }
    }

    func changeMonth(by offset: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: offset, to: displayedMonth) {
            displayedMonth = newMonth
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
