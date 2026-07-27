import SwiftUI

/// Per-month category breakdown (count + total time), reachable from the
/// Agenda screen. Text-list presentation deliberately, per TODO.md's
/// brainstormed options — cheapest to build and the right starting point
/// before investing in a chart.
struct CategoryInsightsView: View {
    let events: [Event]

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CategoryInsightsViewModel
    @State private var isShowingMonthYearPicker = false

    init(events: [Event], initialMonth: Date) {
        self.events = events
        _viewModel = State(initialValue: CategoryInsightsViewModel(displayedMonth: initialMonth))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        monthHeader

                        let rows = viewModel.rows(from: events)
                        if rows.isEmpty {
                            Text("No events this month.")
                                .font(.body)
                                .foregroundStyle(Color("TextSecondary"))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 60)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(rows) { row in
                                    breakdownCard(row)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Category Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $isShowingMonthYearPicker) {
                MonthYearPickerView(selectedMonth: Binding(
                    get: { viewModel.displayedMonth },
                    set: { viewModel.displayedMonth = $0 }
                ))
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                viewModel.changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
            }
            Spacer()
            Button {
                isShowingMonthYearPicker = true
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.displayedMonth, format: .dateTime.month(.wide).year())
                        .font(.headline)
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
                }
            }
            Spacer()
            Button {
                viewModel.changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
            }
        }
        .foregroundStyle(Color("TextPrimary"))
    }

    private func breakdownCard(_ row: CategoryBreakdownRow) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(row.label)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color("TextPrimary"))
                Text("\(row.count) event\(row.count == 1 ? "" : "s")")
                    .font(.footnote)
                    .foregroundStyle(Color("TextSecondary"))
                deltaLabel(row)
            }
            Spacer()
            Text(CategoryInsightsViewModel.formattedDuration(row.totalDuration))
                .font(.body.weight(.semibold))
                .foregroundStyle(Color("AccentColor"))
        }
        .padding(16)
        .background(Color("Surface"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    /// "New this month" when there's no prior-month data to compare
    /// against; otherwise a signed duration delta vs. last month.
    @ViewBuilder
    private func deltaLabel(_ row: CategoryBreakdownRow) -> some View {
        Group {
            if let delta = row.durationDelta {
                if delta == 0 {
                    Text("No change vs last month")
                        .foregroundStyle(Color("TextSecondary"))
                } else {
                    let isUp = delta > 0
                    Label(
                        "\(isUp ? "+" : "−")\(CategoryInsightsViewModel.formattedDuration(abs(delta))) vs last month",
                        systemImage: isUp ? "arrow.up.right" : "arrow.down.right"
                    )
                    .foregroundStyle(isUp ? Color("AccentColor") : Color("TextSecondary"))
                }
            } else {
                Text("New this month")
                    .foregroundStyle(Color("AccentColor"))
            }
        }
        .font(.caption)
    }
}
