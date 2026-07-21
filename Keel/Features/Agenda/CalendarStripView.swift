import SwiftUI

/// Month label + horizontal, scrollable day strip — today centered on first
/// appearance, scroll left for past days, right for future days. Selecting
/// a day filters the Agenda list below to that single day. Tapping the
/// month label opens a traditional calendar grid for jumping to any day,
/// month, or year.
struct CalendarStripView: View {
    @Binding var selectedDate: Date
    let conflictDays: Set<CalendarDay>
    let eventCountByDay: [CalendarDay: Int]
    @State private var windowCenter = Calendar.current.startOfDay(for: .now)
    @State private var isShowingMonthPicker = false
    @State private var pickerDate = Date.now
    private let today = Calendar.current.startOfDay(for: .now)

    private var days: [Date] { AgendaViewModel.dayRange(around: windowCenter, days: 180) }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button {
                        pickerDate = selectedDate
                        isShowingMonthPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedDate, format: .dateTime.month(.wide).year())
                                .font(.subheadline.weight(.semibold))
                            Image(systemName: "chevron.down")
                                .font(.caption2.weight(.semibold))
                        }
                        .foregroundStyle(Color("TextPrimary"))
                    }

                    Spacer()

                    if !Calendar.current.isDate(selectedDate, inSameDayAs: today) {
                        Button("Today") {
                            select(today, proxy: proxy)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("AccentColor"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color("AccentTint"))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(days, id: \.self) { day in
                            dayCell(day)
                                .id(day)
                                .onTapGesture {
                                    select(day, proxy: proxy)
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
                .frame(height: 80)
                // A plain .onAppear scrollTo can undershoot against a
                // LazyHStack this large before it's finished its first
                // layout pass; deferring one runloop tick gives it time to
                // measure nearby cells first, which is enough for scrollTo
                // to land correctly. task(id:) re-runs whenever windowCenter
                // changes (only from a month-picker jump landing outside
                // the current ±180-day window) without tearing down and
                // recreating the whole strip/proxy, which `select` below
                // relies on staying alive for its own direct scrollTo.
                .task(id: windowCenter) {
                    try? await Task.sleep(nanoseconds: 50_000_000)
                    proxy.scrollTo(windowCenter, anchor: .center)
                }
            }
        }
        .sheet(isPresented: $isShowingMonthPicker) {
            NavigationStack {
                MonthCalendarPicker(selectedDate: $pickerDate, conflictDays: conflictDays, eventCountByDay: eventCountByDay)
                    .padding()
                    .navigationTitle("Select a date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { isShowingMonthPicker = false }
                        }
                    }
                    // Tapping a day picks it and closes the sheet in one
                    // step — no separate "Done" confirmation needed. Only
                    // fires on an actual day tap inside the grid: the
                    // pickerDate = selectedDate assignment that seeds this
                    // sheet happens before it's presented, and browsing
                    // months with the chevrons only changes the picker's
                    // displayed month, not pickerDate.
                    .onChange(of: pickerDate) { _, newValue in
                        jump(to: newValue)
                    }
            }
            .presentationDetents([.medium, .large])
            .presentationBackground(Color("Surface"))
        }
    }

    /// Selects `day` and scrolls it to center immediately. Used by both
    /// in-strip taps and the "Today" button — relies on `day` already
    /// being inside the currently rendered ±180-day window, which holds
    /// for everything except a month-picker jump that lands far outside
    /// it (that path goes through `jump(to:)` instead, which re-centers
    /// the window itself before scrolling).
    private func select(_ day: Date, proxy: ScrollViewProxy) {
        selectedDate = day
        withAnimation {
            proxy.scrollTo(day, anchor: .center)
        }
    }

    private func jump(to date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        selectedDate = day
        windowCenter = day
        isShowingMonthPicker = false
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
