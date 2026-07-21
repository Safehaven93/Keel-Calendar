import SwiftUI

/// Plain year/month/day key, independent of any single `Date`'s time
/// component or calendar/timeZone metadata, so day membership checks
/// (e.g. "does this day have a conflict") compare cleanly.
struct CalendarDay: Hashable {
    let year: Int
    let month: Int
    let day: Int

    init(_ date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        year = components.year ?? 0
        month = components.month ?? 0
        day = components.day ?? 0
    }
}

/// Custom SwiftUI month-grid date picker (DESIGN §4.1). Neither SwiftUI's
/// `DatePicker(.graphical)` nor UIKit's `UICalendarView` let a marker sit
/// tight against a specific day number — both reserve a separate decoration
/// slot below the row, which reads as ambiguous between two rows once a
/// week wraps. Drawing the grid ourselves puts the conflict badge directly
/// over the day cell's own corner instead.
struct MonthCalendarPicker: View {
    @Binding var selectedDate: Date
    let conflictDays: Set<CalendarDay>
    let eventCountByDay: [CalendarDay: Int]

    @State private var displayedMonth: Date

    private let calendar = Calendar.current
    private let today = Calendar.current.startOfDay(for: .now)

    /// Event counts at/above this map to full-strength fill — a handful of
    /// commitments already reads as "busy" for this app's target user, so
    /// the ramp shouldn't need a packed day to reach its darkest shade.
    private static let busyCountCap = 4.0

    init(selectedDate: Binding<Date>, conflictDays: Set<CalendarDay>, eventCountByDay: [CalendarDay: Int]) {
        _selectedDate = selectedDate
        self.conflictDays = conflictDays
        self.eventCountByDay = eventCountByDay
        _displayedMonth = State(initialValue: Calendar.current.startOfDay(for: selectedDate.wrappedValue))
    }

    var body: some View {
        VStack(spacing: 16) {
            header
            weekdayHeader
            grid
        }
        .padding(.horizontal, 4)
    }

    private var header: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
            }
            Spacer()
            Text(displayedMonth, format: .dateTime.month(.wide).year())
                .font(.headline)
            Spacer()
            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
            }
        }
        .foregroundStyle(Color("TextPrimary"))
    }

    private var weekdayHeader: some View {
        let symbols = calendar.veryShortWeekdaySymbols
        let firstIndex = calendar.firstWeekday - 1
        let rotated = Array(symbols[firstIndex...]) + Array(symbols[..<firstIndex])
        return HStack(spacing: 0) {
            ForEach(Array(rotated.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color("TextSecondary"))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var grid: some View {
        VStack(spacing: 8) {
            ForEach(Array(weeksInDisplayedMonth().enumerated()), id: \.offset) { _, week in
                HStack(spacing: 0) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                        if let day {
                            dayCell(day)
                        } else {
                            Color.clear.frame(maxWidth: .infinity, minHeight: 40)
                        }
                    }
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let isToday = calendar.isDate(day, inSameDayAs: today)
        let hasConflict = conflictDays.contains(CalendarDay(day, calendar: calendar))
        let busyness = busynessFillOpacity(for: day)
        let usesLightText = busyness > 0.5

        return Button {
            selectedDate = day
        } label: {
            ZStack(alignment: .topTrailing) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.body.weight(isToday ? .bold : .regular))
                    .foregroundStyle(usesLightText ? .white : Color("TextPrimary"))
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(Color("AccentColor").opacity(busyness))
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color("AccentColor"), lineWidth: isSelected ? 2 : 0)
                    )

                if hasConflict {
                    Circle()
                        .fill(Color("ConflictColor"))
                        .frame(width: 7, height: 7)
                        .offset(x: -6, y: 4)
                }
            }
        }
        .buttonStyle(.plain)
    }

    /// Maps a day's event count onto the accent color's own opacity range,
    /// rather than introducing a new hue — DESIGN.md keeps this app to a
    /// single accent color, and reusing it here (a subtle tint at low
    /// counts up to a solid, deeper fill at high counts) extends that one
    /// voice instead of competing with it.
    private func busynessFillOpacity(for day: Date) -> Double {
        let count = eventCountByDay[CalendarDay(day, calendar: calendar)] ?? 0
        guard count > 0 else { return 0 }
        let fraction = min(Double(count), Self.busyCountCap) / Self.busyCountCap
        return 0.15 + fraction * 0.65
    }

    private func changeMonth(by offset: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    /// Every day in `displayedMonth`'s weeks, padded with `nil` for the
    /// leading/trailing days that belong to adjacent months, grouped 7-per-week.
    private func weeksInDisplayedMonth() -> [[Date?]] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        var days: [Date?] = []
        var current = firstWeek.start
        while current < monthInterval.end {
            days.append(calendar.isDate(current, equalTo: displayedMonth, toGranularity: .month) ? current : nil)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? monthInterval.end
        }
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<min($0 + 7, days.count)]) }
    }
}
