import SwiftUI
import SwiftData

enum AgendaRoute: Hashable {
    case detail(Event)
    case conflict(Event, Event)
}

struct AgendaView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Event.startDate) private var events: [Event]
    @State private var path = NavigationPath()
    @State private var isAddingEvent = false

    private var viewModel: AgendaViewModel { AgendaViewModel(modelContext: modelContext) }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                Color("Background").ignoresSafeArea()

                if events.isEmpty {
                    Text("Nothing on the books.")
                        .font(.body)
                        .foregroundStyle(Color("TextSecondary"))
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 28) {
                            ForEach(viewModel.groupedByDay(events), id: \.day) { group in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(group.day, style: .date)
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(Color("TextPrimary"))
                                        .padding(.horizontal, 20)

                                    VStack(spacing: 12) {
                                        ForEach(group.events) { event in
                                            Button {
                                                handleTap(on: event)
                                            } label: {
                                                EventRow(event: event, conflictPartnerTitle: conflictTitle(for: event))
                                            }
                                            .buttonStyle(.plain)
                                            .swipeActions {
                                                Button(role: .destructive) {
                                                    viewModel.delete(event)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 110)
                    }
                }

                Button {
                    isAddingEvent = true
                } label: {
                    Text("+ Add event")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.accentColor))
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Agenda")
            .navigationDestination(for: AgendaRoute.self) { route in
                switch route {
                case .detail(let event):
                    EventDetailView(event: event)
                case .conflict(let a, let b):
                    ConflictResolutionView(eventA: a, eventB: b)
                }
            }
            .sheet(isPresented: $isAddingEvent) {
                AddEditEventView(allEvents: events)
            }
        }
    }

    private func handleTap(on event: Event) {
        if let partnerID = event.unresolvedConflictEventID,
           let partner = events.first(where: { $0.id == partnerID }) {
            path.append(AgendaRoute.conflict(event, partner))
        } else {
            path.append(AgendaRoute.detail(event))
        }
    }

    private func conflictTitle(for event: Event) -> String? {
        guard let partnerID = event.unresolvedConflictEventID else { return nil }
        return events.first(where: { $0.id == partnerID })?.title
    }
}

#Preview {
    AgendaView()
        .modelContainer(for: Event.self, inMemory: true)
}
