import SwiftUI
import SwiftData

/// Hero card tinted by flexibility, details below, no decision-support
/// content (that lives only in Conflict Resolution) — DESIGN §4.4.
struct EventDetailView: View {
    let event: Event

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Event.startDate) private var allEvents: [Event]
    @State private var isEditing = false
    @State private var isShowingQRCode = false

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    heroCard

                    if event.location != nil || event.notes != nil || event.rescheduleNote != nil {
                        detailsCard
                    }

                    Button {
                        isShowingQRCode = true
                    } label: {
                        Label("Share Event", systemImage: "square.and.arrow.up")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("AccentColor"))

                    HStack(spacing: 12) {
                        Button("Edit") { isEditing = true }
                            .buttonStyle(.bordered)
                            .tint(Color("AccentColor"))
                            .frame(maxWidth: .infinity)

                        Button("Delete") {
                            EventStore.delete(event, in: modelContext)
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .tint(Color("ConflictColor"))
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Event")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isEditing) {
            AddEditEventView(allEvents: allEvents, editing: event)
        }
        .sheet(isPresented: $isShowingQRCode) {
            EventQRCodeView(event: event, allEvents: allEvents)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(event.flexibility.label.uppercased())
                if let category = event.category {
                    Text("·")
                    Text(category.label.uppercased())
                }
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(Color("AccentColor"))
            Text(event.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color("TextPrimary"))
            Text(event.startDate, format: .dateTime.weekday(.wide).month().day().hour().minute())
                .font(.body)
                .foregroundStyle(Color("AccentColor"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(event.flexibility == .fixed ? Color("AccentTint") : Color("Surface"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let location = event.location {
                Label(location, systemImage: "mappin.and.ellipse")
            }
            if let notes = event.notes {
                Label(notes, systemImage: "note.text")
            }
            if event.isRescheduled, let note = event.rescheduleNote {
                Label(note, systemImage: "arrow.triangle.branch")
                    .foregroundStyle(Color("TextSecondary"))
            }
        }
        .font(.body)
        .foregroundStyle(Color("TextPrimary"))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color("Surface"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
