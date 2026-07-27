import SwiftUI
import CoreImage.CIFilterBuiltins

/// Renders an event as a scannable QR code (see `EventQRCoding`) with a
/// share sheet for sending the image itself — e.g. via Messages — as an
/// alternative to someone scanning it in person.
struct EventQRCodeView: View {
    let event: Event
    let allEvents: [Event]

    @Environment(\.dismiss) private var dismiss
    @State private var includeAvailability = false

    /// The owner's other events on `event`'s day — only ever used when
    /// `includeAvailability` is on, and even then only start/end times are
    /// encoded (see `EventQRCoding`), never titles or details.
    private var busyEventsForDay: [Event] {
        let calendar = Calendar.current
        return allEvents.filter { $0.id != event.id && calendar.isDate($0.startDate, inSameDayAs: event.startDate) }
    }

    private var encodedBusyEvents: [Event] {
        includeAvailability ? busyEventsForDay : []
    }

    private var qrImage: UIImage? {
        Self.generateQRCode(from: EventQRCoding.encode(event, busyEvents: encodedBusyEvents))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text(event.title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color("TextPrimary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    if let qrImage {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 260, height: 260)
                            .padding(16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        Text("Couldn't generate a QR code for this event.")
                            .foregroundStyle(Color("TextSecondary"))
                            .frame(width: 260, height: 260)
                    }

                    Text("Scan this with Keel to add \u{201C}\(event.title)\u{201D} to another calendar.")
                        .font(.footnote)
                        .foregroundStyle(Color("TextSecondary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    if !busyEventsForDay.isEmpty {
                        Toggle(isOn: $includeAvailability) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Include my availability for this day")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color("TextPrimary"))
                                Text("Shares only the times you're busy — never event titles or details.")
                                    .font(.caption)
                                    .foregroundStyle(Color("TextSecondary"))
                            }
                        }
                        .tint(Color("AccentColor"))
                        .padding(16)
                        .background(Color("Surface"))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 20)
                    }

                    VStack(spacing: 12) {
                        if let qrImage, let fileURL = Self.writeToTempFile(qrImage) {
                            ShareLink(
                                item: fileURL,
                                preview: SharePreview(event.title, image: Image(uiImage: qrImage))
                            ) {
                                Text("Share as QR Code")
                                    .font(.body.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .foregroundStyle(.white)
                                    .background(Color("AccentColor"))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }

                        ShareLink(item: EventQRCoding.shareText(for: event, busyEvents: encodedBusyEvents)) {
                            Text("Share as Text")
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .foregroundStyle(Color("AccentColor"))
                                .background(Color("Surface"))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("Background").ignoresSafeArea())
            .navigationTitle("Share Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private static func generateQRCode(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let outputImage = filter.outputImage else { return nil }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// `ShareLink` needs a `Transferable` item; writing the PNG to a temp
    /// file and sharing its `URL` is simpler and more reliable than trying
    /// to make `UIImage` itself conform.
    private static func writeToTempFile(_ image: UIImage) -> URL? {
        guard let data = image.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).png")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
