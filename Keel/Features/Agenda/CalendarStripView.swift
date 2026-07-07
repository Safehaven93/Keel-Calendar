import SwiftUI

/// Month label + horizontal, scrollable day strip — today centered on first
/// appearance, scroll left for past days, right for future days. Selecting
/// a day filters the Agenda list below to that single day. Tapping the
/// month label opens a traditional calendar grid for jumping to any day,
/// month, or year.
struct CalendarStripView: View {
    @Binding var selectedDate: Date
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
            // Keying on windowCenter forces the ScrollView to recreate
            // (and therefore re-run its initial-appearance centering) only
            // when jumping via the month picker — not on every in-strip
            // tap, which would otherwise snap the scroll position back to
            // center each time and defeat manual scrolling.
            .id(windowCenter)
            .defaultScrollAnchor(.center)
        }
        .sheet(isPresented: $isShowingMonthPicker) {
            NavigationStack {
                DatePicker("Select a date", selection: $pickerDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
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
