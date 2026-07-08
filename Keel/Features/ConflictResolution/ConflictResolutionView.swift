import SwiftUI
import SwiftData

/// Pushed (never `.sheet()`) per DESIGN §3/§8 — this decision deserves a full
/// screen, not a dismissible overlay. Three stages: choosing which event
/// wins (decided KEEP/MOVE hierarchy, or too-close-to-call §6.4 equal
/// weight), picking the moved event's new time (ranked suggestions + manual
/// override), and a brief confirmation before returning to Agenda — nothing
/// is saved, and the screen never dismisses, until the user picks a time.
struct ConflictResolutionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ConflictResolutionViewModel
    var onResolved: (() -> Void)?

    init(eventA: Event, eventB: Event, onResolved: (() -> Void)? = nil) {
        _viewModel = State(initialValue: ConflictResolutionViewModel(eventA: eventA, eventB: eventB))
        self.onResolved = onResolved
    }

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            content
        }
        .navigationTitle("Conflict")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.stage {
        case .choosing:
            if viewModel.isStillConflicted {
                choosingStage
            } else {
                staleState
            }
        case .pickingTime(let keep, let move, let suggestions):
            pickingTimeStage(keep: keep, move: move, suggestions: suggestions)
        case .confirmed(let move, let newStart):
            confirmedStage(move: move, newStart: newStart)
        }
    }

    // MARK: - Choosing

    private var choosingStage: some View {
        ScrollView {
            VStack(spacing: 20) {
                reasoningCard
                eventCard(viewModel.eventA, isKeepSide: viewModel.defaultKeep === viewModel.eventA)
                eventCard(viewModel.eventB, isKeepSide: viewModel.defaultKeep === viewModel.eventB)
                choosingActions
            }
            .padding(20)
        }
    }

    private var staleState: some View {
        VStack(spacing: 16) {
            Text("This conflict has been resolved.")
                .font(.body)
                .foregroundStyle(Color("TextPrimary"))
            Button("Back to Agenda") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(Color("AccentColor"))
        }
    }

    private var reasoningCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundStyle(Color("TextSecondary"))
                Text(viewModel.recommendation.reasoning.first ?? "")
                    .font(.body)
                    .foregroundStyle(Color("TextPrimary"))
            }
            if viewModel.showsDetail, viewModel.recommendation.reasoning.count > 1 {
                ForEach(viewModel.recommendation.reasoning.dropFirst(), id: \.self) { line in
                    Text(line)
                        .font(.footnote)
                        .foregroundStyle(Color("TextSecondary"))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color("Surface"))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color("Border")))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func eventCard(_ event: Event, isKeepSide: Bool) -> some View {
        let showsTags = viewModel.isDecided
        return VStack(alignment: .leading, spacing: 8) {
            if showsTags {
                Text(isKeepSide ? "KEEP" : "MOVE")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isKeepSide ? Color("AccentColor") : Color("ConflictColor"))
            }
            Text(event.title)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color("TextPrimary"))
            Text(event.startDate, style: .time)
                .font(.footnote.monospacedDigit())
                .foregroundStyle(Color("TextSecondary"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(showsTags && !isKeepSide ? Color("ConflictTint") : Color("Surface"))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(showsTags && isKeepSide ? Color("AccentColor") : Color("Border"), lineWidth: showsTags && isKeepSide ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var choosingActions: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.beginRescheduling(keep: viewModel.defaultKeep, move: viewModel.defaultMove, in: modelContext)
            } label: {
                Text("Keep \(viewModel.defaultKeep.title), move \(viewModel.defaultMove.title)")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(.white)
                    .background(Color("AccentColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Button {
                viewModel.beginRescheduling(keep: viewModel.defaultMove, move: viewModel.defaultKeep, in: modelContext)
            } label: {
                Text("Keep \(viewModel.defaultMove.title) instead")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(Color("AccentColor"))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color("AccentColor"), lineWidth: 1.5))
            }

            Button {
                onResolved?()
                dismiss()
            } label: {
                Text("Keep both, decide later")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color("TextSecondary"))
            }

            if viewModel.recommendation.reasoning.count > 1 {
                Button {
                    viewModel.showsDetail.toggle()
                } label: {
                    Text(viewModel.showsDetail ? "Hide detail" : "See more detail")
                        .font(.footnote)
                        .foregroundStyle(Color("TextSecondary"))
                }
            }
        }
    }

    // MARK: - Picking time

    private func pickingTimeStage(keep: Event, move: Event, suggestions: [RescheduleSuggestion]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("New time for \(move.title)")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color("TextPrimary"))
                    Text("Keeping \(keep.title) where it is.")
                        .font(.footnote)
                        .foregroundStyle(Color("TextSecondary"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !suggestions.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(suggestions) { suggestion in
                            suggestionCard(suggestion)
                        }
                    }
                }

                manualOverrideSection(move: move)

                VStack(spacing: 12) {
                    Button {
                        viewModel.confirmPickedTime(keep: keep, move: move)
                    } label: {
                        Text("Confirm")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .foregroundStyle(.white)
                            .background(viewModel.canConfirmPickedTime ? Color("AccentColor") : Color("AccentColor").opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(!viewModel.canConfirmPickedTime)

                    Button("Back") {
                        viewModel.backToChoosing()
                    }
                    .font(.footnote)
                    .foregroundStyle(Color("TextSecondary"))
                }
            }
            .padding(20)
        }
    }

    private func suggestionCard(_ suggestion: RescheduleSuggestion) -> some View {
        let isSelected = !viewModel.isUsingManualTime && viewModel.selectedSuggestion == suggestion
        return Button {
            viewModel.isUsingManualTime = false
            viewModel.selectedSuggestion = suggestion
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.start, format: .dateTime.weekday(.wide).month().day().hour().minute())
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : Color("TextPrimary"))
                Text(suggestion.reason)
                    .font(.footnote)
                    .foregroundStyle(isSelected ? .white.opacity(0.85) : Color("TextSecondary"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(isSelected ? Color("AccentColor") : Color("Surface"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func manualOverrideSection(move: Event) -> some View {
        DisclosureGroup(
            "Pick a different time",
            isExpanded: Binding(
                get: { viewModel.isUsingManualTime },
                set: { newValue in
                    viewModel.isUsingManualTime = newValue
                    if newValue {
                        viewModel.revalidateManualTime(move: move, in: modelContext)
                    }
                }
            )
        ) {
            VStack(alignment: .leading, spacing: 12) {
                DatePicker("Date", selection: $viewModel.manualDate, displayedComponents: .date)
                DatePicker("Start", selection: $viewModel.manualStartTime, displayedComponents: .hourAndMinute)
                DatePicker("End", selection: $viewModel.manualEndTime, displayedComponents: .hourAndMinute)

                if let conflict = viewModel.manualConflict {
                    Text("This still overlaps with \(conflict.title).")
                        .font(.footnote)
                        .foregroundStyle(Color("ConflictColor"))
                }
            }
            .padding(.top, 8)
            .onChange(of: viewModel.manualDate) { _, _ in viewModel.revalidateManualTime(move: move, in: modelContext) }
            .onChange(of: viewModel.manualStartTime) { _, _ in viewModel.revalidateManualTime(move: move, in: modelContext) }
            .onChange(of: viewModel.manualEndTime) { _, _ in viewModel.revalidateManualTime(move: move, in: modelContext) }
        }
        .tint(Color("TextPrimary"))
        .padding(16)
        .background(Color("Surface"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Confirmed

    private func confirmedStage(move: Event, newStart: Date) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(Color("SuccessColor"))
            Text("\(move.title) moved")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color("TextPrimary"))
            Text(newStart, format: .dateTime.weekday(.wide).month().day().hour().minute())
                .font(.body)
                .foregroundStyle(Color("TextSecondary"))
            Button("Back to Agenda") {
                onResolved?()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("AccentColor"))
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(20)
    }
}
