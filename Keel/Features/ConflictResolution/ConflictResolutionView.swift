import SwiftUI
import SwiftData

/// Pushed (never `.sheet()`) per DESIGN §3/§8 — this decision deserves a full
/// screen, not a dismissible overlay. Handles three states: decided
/// (KEEP/MOVE hierarchy), too-close-to-call (§6.4, equal weight), and stale
/// (§6.3, conflict already resolved elsewhere).
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

            if !viewModel.isStillConflicted {
                staleState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        reasoningCard
                        eventCard(viewModel.eventA, isKeepSide: viewModel.defaultKeep === viewModel.eventA)
                        eventCard(viewModel.eventB, isKeepSide: viewModel.defaultKeep === viewModel.eventB)
                        actions
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Conflict")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var staleState: some View {
        VStack(spacing: 16) {
            Text("This conflict has been resolved.")
                .font(.body)
                .foregroundStyle(Color("TextPrimary"))
            Button("Back to Agenda") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
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
                    .foregroundStyle(isKeepSide ? Color.accentColor : Color("ConflictColor"))
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
                .stroke(showsTags && isKeepSide ? Color.accentColor : Color("Border"), lineWidth: showsTags && isKeepSide ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.resolve(keep: viewModel.defaultKeep, move: viewModel.defaultMove, in: modelContext)
                onResolved?()
                dismiss()
            } label: {
                Text("Keep \(viewModel.defaultKeep.title), move \(viewModel.defaultMove.title)")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(.white)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Button {
                viewModel.resolve(keep: viewModel.defaultMove, move: viewModel.defaultKeep, in: modelContext)
                onResolved?()
                dismiss()
            } label: {
                Text("Keep \(viewModel.defaultMove.title) instead")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(Color.accentColor)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.accentColor, lineWidth: 1.5))
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
}
