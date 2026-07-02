import SwiftUI
import SwiftData

/// Card-composer style Add/Edit screen (DESIGN §4.2): freeform title, date
/// + time chips, a full-weight 3-card flexibility picker, optional details,
/// full-width pinned Save. If saving creates a conflict, pushes straight to
/// Conflict Resolution instead of dismissing (DESIGN §3 step 2).
struct AddEditEventView: View {
    let allEvents: [Event]
    private let editingEvent: Event?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddEditEventViewModel
    @State private var conflictPartner: Event?
    @State private var savedEvent: Event?

    init(allEvents: [Event], editing event: Event? = nil) {
        self.allEvents = allEvents
        self.editingEvent = event
        _viewModel = State(initialValue: AddEditEventViewModel(editing: event))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("Background").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        TextField("What's happening?", text: $viewModel.title, axis: .vertical)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color("TextPrimary"))
                            .padding(16)
                            .background(Color("Surface"))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        HStack(spacing: 12) {
                            chip {
                                DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            chip {
                                DatePicker("", selection: $viewModel.startTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Flexibility")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Color("TextSecondary"))
                            ForEach(Flexibility.allCases) { option in
                                flexibilityCard(option)
                            }
                        }

                        DisclosureGroup("More details", isExpanded: $viewModel.showsMoreDetails) {
                            VStack(alignment: .leading, spacing: 12) {
                                chip {
                                    DatePicker("End time", selection: $viewModel.endTime, displayedComponents: .hourAndMinute)
                                }
                                TextField("Location", text: $viewModel.location)
                                    .padding(12)
                                    .background(Color("Surface"))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                TextField("Notes", text: $viewModel.notes, axis: .vertical)
                                    .padding(12)
                                    .background(Color("Surface"))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .padding(.top, 8)
                        }
                        .tint(Color("TextPrimary"))
                    }
                    .padding(20)
                    .padding(.bottom, 90)
                }

                Button(action: save) {
                    Text("Save")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(.white)
                        .background(viewModel.canSave ? Color.accentColor : Color.accentColor.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(!viewModel.canSave)
                .padding(20)
            }
            .navigationTitle(viewModel.isEditing ? "Edit Event" : "Add Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(item: $conflictPartner) { partner in
                if let savedEvent {
                    ConflictResolutionView(eventA: savedEvent, eventB: partner, onResolved: { dismiss() })
                }
            }
        }
    }

    private func save() {
        let event = viewModel.makeOrUpdateEvent(insertingInto: modelContext)
        let partner = EventStore.relinkConflict(for: event, allEvents: allEvents, in: modelContext)
        if let partner {
            savedEvent = event
            conflictPartner = partner
        } else {
            dismiss()
        }
    }

    @ViewBuilder
    private func chip<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color("Surface"))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func flexibilityCard(_ option: Flexibility) -> some View {
        let isSelected = viewModel.flexibility == option
        return Button {
            viewModel.flexibility = option
        } label: {
            Text(option.label)
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .foregroundStyle(isSelected ? .white : Color("TextPrimary"))
                .background(isSelected ? Color.accentColor : Color("Surface"))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
