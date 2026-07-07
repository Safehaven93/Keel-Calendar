import SwiftUI

/// One Agenda card: time + title, with a terracotta left-edge accent and
/// inline "Conflicts with X" label when the event is in an unresolved
/// conflict (DESIGN.md §4.1 / §5.4) — never an icon-only badge.
struct EventRow: View {
    let event: Event
    let conflictPartnerTitle: String?

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(conflictPartnerTitle != nil ? Color("ConflictColor") : Color.clear)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.startDate...event.endDate)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(Color("TextSecondary"))
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
        }
        .padding(16)
        .background(Color("Surface"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
