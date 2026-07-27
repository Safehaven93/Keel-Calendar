import SwiftUI

/// Shown after scanning/pasting a shared event that included the owner's
/// availability. Lays the owner's busy blocks (times only — see
/// `EventQRCoding`) next to the recipient's own events for that day, and
/// lets the recipient propose a time in one of the open windows. Nothing is
/// saved here — proposing a time just carries the adjusted draft into the
/// normal Add/Edit review form, same as any other scanned event.
struct AvailabilityCompareView: View {
    let draft: ScannedEventDraft
    let allEvents: [Event]
    let defaultDate: Date

    @Environment(\.dismiss) private var dismiss
    @State private var proposedDraft: ScannedEventDraft?
    @State private var isShowingForm = false

    private let dayStartHour = 7
    private let dayEndHour = 22

    private var day: Date { Calendar.current.startOfDay(for: draft.startDate) }

    private var myEventsToday: [Event] {
        allEvents
            .filter { Calendar.current.isDate($0.startDate, inSameDayAs: day) }
            .sorted { $0.startDate < $1.startDate }
    }

    private var myBusyIntervals: [DateInterval] {
        myEventsToday.map { DateInterval(start: $0.startDate, end: $0.endDate) }
    }

    private var theirBusyBlocks: [DateInterval] {
        draft.busyBlocks.sorted { $0.start < $1.start }
    }

    private var dayRange: DateInterval {
        let calendar = Calendar.current
        let start = calendar.date(bySettingHour: dayStartHour, minute: 0, second: 0, of: day) ?? day
        let end = calendar.date(bySettingHour: dayEndHour, minute: 0, second: 0, of: day) ?? day
        return DateInterval(start: start, end: end)
    }

    /// Gaps of at least 30 minutes, within `dayRange`, where neither person
    /// has a busy block.
    private var freeWindows: [DateInterval] {
        let combinedBusy = (theirBusyBlocks + myBusyIntervals).sorted { $0.start < $1.start }
        var windows: [DateInterval] = []
        var cursor = dayRange.start
        for busy in combinedBusy {
            let clippedStart = max(busy.start, dayRange.start)
            let clippedEnd = min(busy.end, dayRange.end)
            guard clippedEnd > clippedStart, clippedEnd > cursor else { continue }
            if clippedStart > cursor {
                windows.append(DateInterval(start: cursor, end: clippedStart))
            }
            cursor = max(cursor, clippedEnd)
        }
        if cursor < dayRange.end {
            windows.append(DateInterval(start: cursor, end: dayRange.end))
        }
        return windows.filter { $0.duration >= 30 * 60 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("\u{201C}\(draft.title)\u{201D} was shared with their availability for \(day.formatted(.dateTime.weekday(.wide).month().day())).")
                        .font(.body)
                        .foregroundStyle(Color("TextPrimary"))

                    scheduleCard(
                        title: "Their busy times",
                        rows: theirBusyBlocks.map { timeRangeLabel($0) },
                        emptyLabel: "Free all day"
                    )

                    scheduleCard(
                        title: "Your busy times",
                        rows: myEventsToday.map { "\(timeRangeLabel(DateInterval(start: $0.startDate, end: $0.endDate))) · \($0.title)" },
                        emptyLabel: "Free all day"
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Open windows for both of you")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("TextSecondary"))

                        if freeWindows.isEmpty {
                            Text("No shared open windows between \(dayStartHour):00 and \(dayEndHour):00.")
                                .font(.body)
                                .foregroundStyle(Color("TextSecondary"))
                        } else {
                            ForEach(Array(freeWindows.enumerated()), id: \.offset) { _, window in
                                Button {
                                    propose(in: window)
                                } label: {
                                    Text("Propose \(timeRangeLabel(window))")
                                        .font(.body.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .foregroundStyle(.white)
                                        .background(Color("AccentColor"))
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                            }
                        }
                    }

                    Button {
                        useOriginalTime()
                    } label: {
                        Text("Use their original proposed time (\(timeRangeLabel(DateInterval(start: draft.startDate, end: draft.endDate))))")
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(Color("AccentColor"))
                            .background(Color("Surface"))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(20)
            }
            .background(Color("Background").ignoresSafeArea())
            .navigationTitle("Find a Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $isShowingForm, onDismiss: { dismiss() }) {
                if let proposedDraft {
                    AddEditEventView(allEvents: allEvents, defaultDate: defaultDate, prefill: proposedDraft)
                }
            }
        }
    }

    private func scheduleCard(title: String, rows: [String], emptyLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("TextSecondary"))
            if rows.isEmpty {
                Text(emptyLabel)
                    .font(.body)
                    .foregroundStyle(Color("TextPrimary"))
            } else {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    Text(row)
                        .font(.body)
                        .foregroundStyle(Color("TextPrimary"))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color("Surface"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func timeRangeLabel(_ interval: DateInterval) -> String {
        "\(interval.start.formatted(.dateTime.hour().minute()))\u{2013}\(interval.end.formatted(.dateTime.hour().minute()))"
    }

    private func propose(in window: DateInterval) {
        let originalDuration = draft.endDate.timeIntervalSince(draft.startDate)
        let duration = min(originalDuration, window.duration)
        let start = window.start
        let end = start.addingTimeInterval(duration)
        proposedDraft = ScannedEventDraft(
            title: draft.title,
            startDate: start,
            endDate: end,
            location: draft.location,
            notes: draft.notes,
            flexibility: draft.flexibility,
            category: draft.category
        )
        isShowingForm = true
    }

    private func useOriginalTime() {
        proposedDraft = ScannedEventDraft(
            title: draft.title,
            startDate: draft.startDate,
            endDate: draft.endDate,
            location: draft.location,
            notes: draft.notes,
            flexibility: draft.flexibility,
            category: draft.category
        )
        isShowingForm = true
    }
}
