import SwiftUI

/// Scans a Keel event QR code and, on success, opens the normal Add/Edit
/// form pre-filled for review — nothing is saved until the user confirms
/// there, same as any other new event. Includes a manual "paste a code"
/// fallback: genuinely useful if the camera can't get a clean read, and
/// it's the only path a simulator (no real camera) can exercise.
struct ScanEventQRView: View {
    let allEvents: [Event]
    let defaultDate: Date

    @Environment(\.dismiss) private var dismiss
    @State private var pastedCode = ""
    @State private var draft: ScannedEventDraft?
    @State private var isShowingPrefillForm = false
    @State private var showsInvalidCodeAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack {
                    QRScannerView { code in
                        handle(code)
                    }
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 220, height: 220)
                }
                .frame(maxWidth: .infinity, minHeight: 320, maxHeight: 360)
                .clipped()

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Or paste a code")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color("TextSecondary"))
                        TextField("Paste scanned event text here", text: $pastedCode, axis: .vertical)
                            .lineLimit(4...8)
                            .padding(12)
                            .background(Color("Surface"))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Button("Import") {
                            handle(pastedCode)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color("AccentColor"))
                        .frame(maxWidth: .infinity)
                        .disabled(pastedCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(20)
                }
            }
            .background(Color("Background").ignoresSafeArea())
            .navigationTitle("Scan Event QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Not a Keel Event Code", isPresented: $showsInvalidCodeAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("That QR code or text doesn't look like a Keel event. Try scanning again.")
            }
            .sheet(isPresented: $isShowingPrefillForm, onDismiss: { dismiss() }) {
                if let draft {
                    AddEditEventView(allEvents: allEvents, defaultDate: defaultDate, prefill: draft)
                }
            }
        }
    }

    private func handle(_ code: String) {
        guard let parsed = EventQRCoding.decode(code) else {
            showsInvalidCodeAlert = true
            return
        }
        draft = parsed
        isShowingPrefillForm = true
    }
}
