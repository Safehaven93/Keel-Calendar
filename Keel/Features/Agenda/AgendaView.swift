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
    @State private var selectedDate = Calendar.current.startOfDay(for: .now)

    private var viewModel: AgendaViewModel { AgendaViewModel(modelContext: modelContext) }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                Color("Background").ignoresSafeArea()

                VStack(spacing: 0) {
                    CalendarStripView(selectedDate: $selectedDate, conflictDays: conflictDays, eventCountByDay: eventCountByDay)

                    Text("Agenda")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color("TextPrimary"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    contentArea
                }

                Button {
                    isAddingEvent = true
                } label: {
                    Text("+ Add event")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color("AccentColor")))
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                }
                .padding(.bottom, 24)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AgendaRoute.self) { route in
                switch route {
                case .detail(let event):
                    EventDetailView(event: event)
                case .conflict(let a, let b):
                    ConflictResolutionView(eventA: a, eventB: b)
                }
            }
            .sheet(isPresented: $isAddingEvent) {
                AddEditEventView(allEvents: events, defaultDate: selectedDate)
            }
        }
    }

    @ViewBuilder
    private var contentArea: some View {
        if events.isEmpty {
            Text("Welcome! Let's get started! Click the \"+ Add event\" button to add your first event!")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color("TextSecondary"))
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            let dayEvents = viewModel.events(on: selectedDate, from: events)
            if dayEvents.isEmpty {
                emptyDayContent
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(dayEvents) { event in
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
                    .padding(.top, 8)
                    .padding(.bottom, 110)
                }
            }
        }
    }

    /// Filler for an empty day: the headline plus, if any exist, the
    /// soonest upcoming events from the highest-priority flexibility tier
    /// that has some (fixed, then somewhat flexible, then very flexible).
    @ViewBuilder
    private var emptyDayContent: some View {
        let upcoming = viewModel.upcomingPriorityEvents(after: selectedDate, from: events)
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Nothing today! But take a look at what's coming")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color("TextSecondary"))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 24)
                    .padding(.bottom, upcoming.isEmpty ? 0 : 12)

                ForEach(upcoming) { event in
                    Button {
                        handleTap(on: event)
                    } label: {
                        EventRow(event: event, conflictPartnerTitle: conflictTitle(for: event))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 110)
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

    /// Days containing an unresolved conflict, for the month picker's
    /// exclamation-mark decoration.
    private var conflictDays: Set<CalendarDay> {
        Set(events.filter { $0.unresolvedConflictEventID != nil }.map { CalendarDay($0.startDate) })
    }

    /// Event counts per day, for the month picker's busyness shading.
    private var eventCountByDay: [CalendarDay: Int] {
        Dictionary(events.map { (CalendarDay($0.startDate), 1) }, uniquingKeysWith: +)
    }
}

#Preview {
    AgendaView()
        .modelContainer(for: Event.self, inMemory: true)
}
