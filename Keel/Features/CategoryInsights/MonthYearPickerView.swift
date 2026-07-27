import SwiftUI

/// Lightweight month + year picker, distinct from `MonthCalendarPicker`
/// (which picks a specific day) — Category Insights only ever needs
/// month granularity. Uses two wheel pickers rather than a day grid, and
/// keeps an explicit Done button since wheel-scrolling is a continuous
/// gesture without a natural "this tap is the selection" moment the way
/// a day-grid tap has.
struct MonthYearPickerView: View {
    @Binding var selectedMonth: Date

    @Environment(\.dismiss) private var dismiss
    @State private var monthIndex: Int
    @State private var year: Int

    private let calendar = Calendar.current
    private let monthSymbols = Calendar.current.monthSymbols
    private let yearRange: [Int]

    init(selectedMonth: Binding<Date>) {
        _selectedMonth = selectedMonth
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: selectedMonth.wrappedValue)
        _monthIndex = State(initialValue: (components.month ?? 1) - 1)
        let currentYear = calendar.component(.year, from: .now)
        _year = State(initialValue: components.year ?? currentYear)
        yearRange = Array((currentYear - 5)...(currentYear + 5))
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                Picker("Month", selection: $monthIndex) {
                    ForEach(Array(monthSymbols.enumerated()), id: \.offset) { index, symbol in
                        Text(symbol).tag(index)
                    }
                }
                .pickerStyle(.wheel)

                Picker("Year", selection: $year) {
                    ForEach(yearRange, id: \.self) { candidateYear in
                        Text(String(candidateYear)).tag(candidateYear)
                    }
                }
                .pickerStyle(.wheel)
            }
            .navigationTitle("Jump to Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        var components = DateComponents()
                        components.year = year
                        components.month = monthIndex + 1
                        components.day = 1
                        if let date = calendar.date(from: components) {
                            selectedMonth = calendar.startOfDay(for: date)
                        }
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(280)])
        .presentationBackground(Color("Surface"))
    }
}
