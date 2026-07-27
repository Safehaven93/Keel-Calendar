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
    @State private var editingEvent: Event?
    @State private var selectedDate = Calendar.current.startOfDay(for: .now)
    @State private var categoryFilter: EventCategory?
    @State private var isShowingInsights = false
    @State private var isShowingScanner = false

    private var viewModel: AgendaViewModel { AgendaViewModel(modelContext: modelContext) }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                Color("Background").ignoresSafeArea()

                VStack(spacing: 0) {
                    CalendarStripView(selectedDate: $selectedDate, conflictDays: conflictDays, eventCountByDay: eventCountByDay)

                    HStack {
                        Text("Agenda")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color("TextPrimary"))
                        Spacer()
                        Button {
                            isShowingInsights = true
                        } label: {
                            Image(systemName: "chart.bar.fill")
                                .foregroundStyle(Color("TextSecondary"))
                                .padding(8)
                                .background(Color("Surface"))
                                .clipShape(Circle())
                        }
                        Button {
                            isShowingScanner = true
                        } label: {
                            Image(systemName: "qrcode.viewfinder")
                                .foregroundStyle(Color("TextSecondary"))
                                .padding(8)
                                .background(Color("Surface"))
                                .clipShape(Circle())
                        }
                        categoryFilterMenu
                    }
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
            .sheet(item: $editingEvent) { event in
                AddEditEventView(allEvents: events, editing: event)
            }
            .sheet(isPresented: $isShowingInsights) {
                CategoryInsightsView(events: events, initialMonth: selectedDate)
            }
            .sheet(isPresented: $isShowingScanner) {
                ScanEventQRView(allEvents: events, defaultDate: selectedDate)
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
            let dayEvents = viewModel.events(on: selectedDate, from: filteredEvents)
            if dayEvents.isEmpty {
                emptyDayContent
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(dayEvents) { event in
                            Button {
                                handleTap(on: event)
                            } label: {
                                EventRow(
                                    event: event,
                                    conflictPartnerTitle: conflictTitle(for: event),
                                    onEdit: { editingEvent = event }
                                )
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
        let upcoming = viewModel.upcomingPriorityEvents(after: selectedDate, from: filteredEvents)
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
                        EventRow(
                            event: event,
                            conflictPartnerTitle: conflictTitle(for: event),
                            showsDate: true,
                            onEdit: { editingEvent = event }
                        )
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
    /// exclamation-mark decoration. Reflects the active category filter, so
    /// the badge only marks conflicts among events actually being shown.
    private var conflictDays: Set<CalendarDay> {
        Set(filteredEvents.filter { $0.unresolvedConflictEventID != nil }.map { CalendarDay($0.startDate) })
    }

    /// Event counts per day, for the month picker's busyness shading.
    /// Reflects the active category filter, so picking e.g. "Exercise"
    /// shades the month by exercise days specifically — that's the whole
    /// point of the filter, letting a user spot where a category clusters.
    private var eventCountByDay: [CalendarDay: Int] {
        Dictionary(filteredEvents.map { (CalendarDay($0.startDate), 1) }, uniquingKeysWith: +)
    }

    /// All events when no filter is active, otherwise only events matching
    /// `categoryFilter`. Drives the day list, the "what's coming" preview,
    /// and the month-picker shading/conflict badges — everywhere the
    /// filter should visibly narrow what's shown. Conflict-partner lookups
    /// (`conflictTitle`, `handleTap`) deliberately keep using the
    /// unfiltered `events`, since a conflict is a real relationship
    /// between two events regardless of which category is being viewed.
    private var filteredEvents: [Event] {
        guard let categoryFilter else { return events }
        return events.filter { $0.category == categoryFilter }
    }

    private var categoryFilterMenu: some View {
        Menu {
            Button {
                categoryFilter = nil
            } label: {
                if categoryFilter == nil {
                    Label("All Categories", systemImage: "checkmark")
                } else {
                    Text("All Categories")
                }
            }
            ForEach(EventCategory.allCases) { category in
                Button {
                    categoryFilter = category
                } label: {
                    if categoryFilter == category {
                        Label(category.label, systemImage: "checkmark")
                    } else {
                        Text(category.label)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(categoryFilter?.label ?? "All Categories")
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(categoryFilter == nil ? Color("TextSecondary") : Color("AccentColor"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color("Surface"))
            .clipShape(Capsule())
        }
    }
}

#Preview {
    AgendaView()
        .modelContainer(for: Event.self, inMemory: true)
}
