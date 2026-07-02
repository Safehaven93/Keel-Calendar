import SwiftUI
import SwiftData

/// Hero card tinted by flexibility, details below, no decision-support
/// content (that lives only in Conflict Resolution) — DESIGN §4.4.
struct EventDetailView: View {
    let event: Event

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    heroCard

                    if event.location != nil || event.notes != nil || event.rescheduleNote != nil {
                        detailsCard
                    }

                    HStack(spacing: 12) {
                        Button("Edit") { isEditing = true }
                            .buttonStyle(.bordered)
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
            AddEditEventView(allEvents: [], editing: event)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(event.flexibility.label.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.accentColor)
            Text(event.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color("TextPrimary"))
            Text(event.startDate, format: .dateTime.weekday(.wide).month().day().hour().minute())
                .font(.body)
                .foregroundStyle(Color.accentColor)
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
