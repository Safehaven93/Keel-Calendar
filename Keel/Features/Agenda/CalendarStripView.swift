import SwiftUI

/// Horizontal, scrollable day strip — today centered on first appearance,
/// scroll left for past days, right for future days. Selecting a day
/// filters the Agenda list below to that single day.
struct CalendarStripView: View {
    @Binding var selectedDate: Date
    private let days = AgendaViewModel.dayRange(around: .now, days: 180)
    private let today = Calendar.current.startOfDay(for: .now)

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(days, id: \.self) { day in
                    dayCell(day)
                        .onTapGesture { selectedDate = day }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        // `days` is symmetric around today, so centering the initial scroll
        // offset on the content's midpoint lands exactly on today — more
        // reliable than a ScrollViewReader.scrollTo, which can undershoot
        // against a LazyHStack this large before it's finished laying out.
        .defaultScrollAnchor(.center)
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDate)
        let isToday = Calendar.current.isDate(day, inSameDayAs: today)

        return VStack(spacing: 4) {
            Text(day, format: .dateTime.weekday(.abbreviated))
                .font(.caption2.weight(.medium))
                .foregroundStyle(isSelected ? .white : Color("TextSecondary"))
            Text(day, format: .dateTime.day())
                .font(.body.weight(.semibold))
                .foregroundStyle(isSelected ? .white : Color("TextPrimary"))
            Circle()
                .fill(isToday && !isSelected ? Color("AccentColor") : Color.clear)
                .frame(width: 4, height: 4)
        }
        .frame(width: 48, height: 64)
        .background(isSelected ? Color("AccentColor") : Color("Surface"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
