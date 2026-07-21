import SwiftUI

/// One Agenda card: time + title, with a terracotta left-edge accent and
/// inline "Conflicts with X" label when the event is in an unresolved
/// conflict (DESIGN.md §4.1 / §5.4) — never an icon-only badge.
struct EventRow: View {
    let event: Event
    let conflictPartnerTitle: String?
    /// Prepends the event's date to the time line — off by default since
    /// same-day agenda lists already imply the date via the selected day;
    /// the "what's coming" preview on an empty day spans multiple days, so
    /// it needs the date spelled out.
    var showsDate: Bool = false
    /// When set, shows a trailing pencil button that calls this instead of
    /// requiring a trip through the event detail screen to edit.
    var onEdit: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(conflictPartnerTitle != nil ? Color("ConflictColor") : Color.clear)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 4) {
                timeLine
                Text(event.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color("TextPrimary"))
                if let conflictPartnerTitle {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                        Text("Conflicts with \(conflictPartnerTitle)")
                    }
                    .font(.footnote)
                    .foregroundStyle(Color("ConflictColor"))
                }
            }
            .padding(.leading, 13)
            Spacer(minLength: 0)

            if let onEdit {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundStyle(Color("TextSecondary"))
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color("Surface"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var timeLine: some View {
        let time = Text(event.startDate...event.endDate)
        Group {
            if showsDate {
                Text(event.startDate, format: .dateTime.weekday(.abbreviated).month().day()) + Text(" · ") + time
            } else {
                time
            }
        }
        .font(.footnote.monospacedDigit())
        .foregroundStyle(Color("TextSecondary"))
    }
}
