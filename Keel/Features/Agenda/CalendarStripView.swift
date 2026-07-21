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
        VStack(alignment: .leading, spacing: 8) {
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
            .padding(.horizontal, 20)
            .padding(.top, 8)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(days, id: \.self) { day in
                            dayCell(day)
                                .id(day)
                                .onTapGesture {
                                    selectedDate = day
                                    withAnimation {
                                        proxy.scrollTo(day, anchor: .center)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
                .frame(height: 80)
                // A plain .onAppear scrollTo can undershoot against a
                // LazyHStack this large before it's finished its first
                // layout pass; deferring one runloop tick via .task gives
                // it time to measure nearby cells first, which is enough
                // for scrollTo to land correctly. Re-fires whenever
                // windowCenter changes (id below forces recreation), so
                // jumping via the month picker re-centers too.
                .task {
                    try? await Task.sleep(nanoseconds: 50_000_000)
                    proxy.scrollTo(windowCenter, anchor: .center)
                }
            }
            // Keying on windowCenter forces the whole strip to recreate
            // only when jumping via the month picker — not on every
            // in-strip tap, which would otherwise snap the scroll
            // position back to center each time and defeat manual
            // scrolling.
            .id(windowCenter)
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
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { jump(to: pickerDate) }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
            .presentationBackground(Color("Surface"))
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
