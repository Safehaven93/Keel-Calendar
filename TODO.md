# TODO — Keel Build Roadmap

Mapped to the MIS 676 course schedule so the code stays in step with the design process, not ahead of or behind it. Check items off as you go; add sub-tasks as they emerge — this file should stay honest about actual state, not aspirational state.

## Session handoff — 2026-07-27 (latest), read this first

**Status: visually verified end-to-end, builds clean, not committed yet.**
Built the "shared-event availability" feature — the scoped-down version of
the "shared-event time suggestions" brainstorm entry below (still present
in the ideas list, now largely superseded by this). Lets a recipient see
the event owner's availability for that day, not just the one event, and
propose a different time back — reusing the QR/text sharing infrastructure
end to end rather than adding a new channel.

**What changed:**
- `EventQRCoding.swift`: `ScannedEventDraft` gained `busyBlocks:
  [DateInterval]` (defaults to `[]`). `encode(_:busyEvents:)` and
  `shareText(for:busyEvents:)` gained an optional `busyEvents: [Event]`
  parameter — when non-empty, each event's start/end time is encoded as
  a repeated `X-KEEL-BUSY:START-END` line. Deliberately **times only** —
  per explicit user direction, the recipient should see *when* the owner
  is busy, never *what* they're doing, so no titles/locations/notes ever
  go into these lines. `decode(_:)` parses `X-KEEL-BUSY` lines back into
  `busyBlocks`.
- `EventQRCodeView.swift`: gained an opt-in, **off-by-default** "Include
  my availability for this day" toggle — only shown at all when the
  owner has other events that day (nothing to share otherwise). When on,
  both "Share as QR Code" and "Share as Text" (now consolidated into this
  one sheet, replacing the two separate buttons that used to live
  directly on `EventDetailView`) encode the day's other events as busy
  blocks via the `busyEvents:` parameter.
- `EventDetailView.swift`: the two separate share buttons collapsed into
  one "Share Event" button opening `EventQRCodeView` (now passed
  `allEvents:` so it can compute the day's busy blocks).
- `AvailabilityCompareView.swift` (new, in `Features/QRSharing/`): shown
  on the recipient's side, after a scan/paste decode, only when
  `busyBlocks` is non-empty. Lists the owner's busy times and the
  recipient's own events for that day side by side (list-based, not a
  graphical timeline — simpler to build/verify and matches the rest of
  the app's card style), computes open windows (≥30 min gaps, within a
  7am–10pm display range) where neither has something, and lets the
  recipient tap "Propose <window>" to carry an adjusted
  `ScannedEventDraft` (same title/location/notes/flexibility/category,
  new start/end clamped to the window) into the existing prefill
  `AddEditEventView` — or "Use their original proposed time" to skip
  straight to the original scanned time. Nothing is saved until that
  form is submitted, same review-before-save pattern as plain QR import.
- `ScanEventQRView.swift`: `handle(_:)` now branches on whether the
  decoded draft has busy blocks — empty routes straight to the existing
  prefill sheet (unchanged behavior for a plain shared event), non-empty
  routes through the new `AvailabilityCompareView` first. Both paths
  still cascade-dismiss back to Agenda the same way.
- `Keel.xcodeproj/project.pbxproj`: added the four required entries for
  `AvailabilityCompareView.swift` (this project has no file-system-
  synchronized groups, so every new file needs manual `PBXBuildFile` +
  `PBXFileReference` + group + Sources-phase entries). First attempt
  picked UUIDs that collided with `EventQRCoding.swift`'s existing ones
  (damaged-project build error) — fixed by generating genuinely random
  24-hex-char IDs and confirming uniqueness via `grep -c` before
  rebuilding.

**Verified via UI automation, full round trip:**
1. Set up test data: two same-day events, resolved a real conflict
   between them via the existing conflict engine (validates this feature
   composes with, not around, the conflict system).
2. Opened "Extra workout"'s Share Event sheet — confirmed the
   availability toggle is hidden when there's only one event that day,
   then appears once a second event exists. Confirmed it defaults off.
3. Toggled it on, shared as text. The QR image visibly grew denser (more
   encoded lines) confirming the busy block made it into the payload —
   same "share sheet contents aren't in the accessibility tree" tooling
   limitation as prior sessions, so verified by screenshot rather than
   reading the clipboard, but the downstream decode step (next) proves
   the content was correct regardless.
4. On the "recipient" side: seeded the simulator pasteboard via `xcrun
   simctl pbcopy` with a hand-built VEVENT payload (mirroring exactly
   what `encode` would produce) representing a third-party "Coffee
   catch-up" event with two owner busy blocks (1:30–3:00 PM and
   10:00–11:30 PM). Pasted and imported via the existing paste fallback.
5. `AvailabilityCompareView` correctly showed both busy lists ("Their
   busy times": 1:30–3:00 PM, 10:00 PM–11:30 PM; "Your busy times":
   the two real events with their titles) and computed exactly the
   expected two open windows (7:00 AM–1:30 PM and 3:00 PM–10:00 PM).
6. Tapped "Propose 7:00 AM–1:30 PM" — landed in the prefill form with
   title "Coffee catch-up", correct date, and start time 7:00 AM. Saved
   it successfully with no conflict (the math checked out).
7. Cleaned up all test events afterward so the simulator's data matches
   what it had before this session.

**Not verified / known gaps (consistent with prior QR/text handoffs):**
byte-exact share-sheet clipboard content (see above), live-camera scan on
a physical device, and a foreign (non-Keel) QR/text code that happens to
contain busy blocks in some other format (decode's nil-guard is
code-reviewed, not device-tested).

**Next steps for whoever picks this up:**
1. `git status` will show `EventQRCoding.swift`, `EventQRCodeView.swift`,
   `EventDetailView.swift`, `ScanEventQRView.swift`,
   `AvailabilityCompareView.swift` (new), and `project.pbxproj` modified
   — review the diff, then commit and push.
2. The "Shared-event time suggestions" idea further down this file can
   probably be marked done/superseded by this, or narrowed to just the
   remaining gap: this feature shows availability and lets the recipient
   propose a time, but doesn't yet let the *owner* see or respond to a
   proposal that comes back (the round trip currently ends at "recipient
   saves an event on their own calendar" — there's no signal back to the
   original owner that a time was picked, since there's still no backend
   or push notifications).

## Session handoff — 2026-07-27 (yet still even later), read this first

**Status: visually verified, builds clean, not committed yet.**
Follow-up to QR sharing (already committed/pushed): added a "Share as
Text" option next to "Share as QR Code" on the event detail screen.

**What changed:**
- `EventQRCoding.shareText(for:)` (new): a human-readable summary (title,
  date, time, location if present) with the same encoded `VEVENT` block
  from `encode(_:)` appended underneath. Anyone can read the summary;
  a Keel recipient can also paste the whole shared message into the scan
  screen's "paste a code" fallback and get the event imported directly
  — same mechanism the QR code uses, just delivered as text instead of
  an image.
- `EventDetailView` gained a `ShareLink(item: EventQRCoding.shareText(for: event))`
  button styled to match "Share as QR Code" (bordered instead of
  prominent, so QR reads as the primary option and text as the
  alternative) rather than opening a sheet first — `ShareLink` presents
  the system share sheet directly since there's no intermediate image to
  preview.

**Verified via UI automation, with one small gap:** confirmed both
buttons render correctly side by side. Tapped "Share as Text" — the
system share sheet opened with a text-content preview correctly titled
"Extra workout" (the event's title), with Copy/Save to Files/Reminders
options, confirming it's sharing real content tied to the event and not
empty/broken. **Could not verify the exact shared text byte-for-byte**:
same tooling limitation as the wheel-picker and live-camera gaps in
earlier handoffs — the accessibility-snapshot tool doesn't surface the
native share sheet's contents at all here (unlike the wheel-picker case,
it didn't crash, it just returns the screen underneath), so there was no
element ref to tap "Copy" and read the clipboard back. Confidence is
still high: `shareText` is a straightforward string built from two
already-verified pieces — `encode(_:)` (thoroughly round-trip tested via
the QR/paste-decode flow) and the same date-formatting pattern already
used elsewhere in `EventDetailView`'s hero card.

**Next steps for whoever picks this up:**
1. `git status` will show `EventQRCoding.swift` and `EventDetailView.swift`
   modified — review the diff, then commit and push.
2. Optional, low-priority: if you want the byte-exact verification, the
   quickest path is probably `xcrun simctl pbpaste` after manually
   tapping Copy in the simulator (interactively, not via automation),
   or just eyeball it on a real device alongside the other manual checks
   already queued (live camera scan, foreign-QR-code handling).

## Session handoff — 2026-07-27 (still even later), read this first

**Status: committed.** Built the
QR code event sharing feature from the brainstormed ideas list — first
build, not an iteration on existing work.

**What changed:**
- `EventQRCoding.swift` (new, in `Models/`): encodes an `Event` as a
  standard iCalendar `VEVENT` text block (`SUMMARY`/`DTSTART`/`DTEND`/
  `LOCATION`/`DESCRIPTION`, plus `X-KEEL-FLEXIBILITY`/`X-KEEL-CATEGORY`
  extension fields since those aren't standard iCalendar concepts), and
  decodes it back into a `ScannedEventDraft` — a plain struct, not an
  `Event`, so nothing from a scan touches SwiftData until the user
  reviews and saves it through the normal form.
- `EventQRCodeView.swift` (new, in `Features/QRSharing/`): renders the
  encoded text as a QR image via `CIFilter.qrCodeGenerator()`, with a
  `ShareLink` for sending the image (written to a temp PNG file first,
  since `ShareLink` needs a `Transferable` item and a file `URL` is more
  reliable than trying to make `UIImage` conform). Reachable via a new
  "Share as QR Code" button on `EventDetailView`.
- `QRScannerView.swift` (new): a `UIViewControllerRepresentable` wrapping
  `AVFoundation` (`AVCaptureSession` + `AVCaptureMetadataOutput`) for
  live QR detection — SwiftUI has no native camera/scanning view.
- `ScanEventQRView.swift` (new): hosts the camera view plus a manual
  "paste a code" fallback text field. On a successful decode (from
  either path), opens `AddEditEventView` pre-filled via a new `prefill:
  ScannedEventDraft?` parameter threaded through
  `AddEditEventViewModel.init` — still an *add*, not an edit
  (`editingEvent` stays nil), so it goes through the same save/conflict
  path as any manually-created event. Reachable via a new
  "qrcode.viewfinder" button in `AgendaView`'s header.
- Added `INFOPLIST_KEY_NSCameraUsageDescription` to both build
  configurations (`Info.plist` is auto-generated from build settings in
  this project, no physical plist file to edit).
- Four new files added to `Keel.xcodeproj/project.pbxproj` by hand
  again (same reminder as prior handoffs — this project doesn't
  auto-include new files).

**Why the paste fallback isn't just a nice-to-have:** the iOS Simulator
has no real camera to point at a printed QR code, so it's the only path
that let this get verified at all via automation — same shape of
limitation as the wheel-picker gap from an earlier handoff, but this
time worked around instead of left as a manual-check note.

**Verified via UI automation, thoroughly:**
- Generated a QR code for a real event ("Extra workout") — confirmed a
  valid-looking QR image renders (correct finder-pattern structure) and
  the Share button/sheet appear.
- Confirmed the scan screen loads without crashing even with no camera
  present (`AVCaptureDevice.default(for: .video)` returns nil in
  Simulator, so `configureSession()` just no-ops — black preview area,
  no crash).
- Exercised the full decode path: typing text with embedded newlines
  isn't supported by the automation tool's typing (`ACTION_FAILED` /
  "unsupported by AXe typing"), and a Return keypress didn't insert a
  newline into the field either — worked around by setting the
  simulator's pasteboard via `xcrun simctl pbcopy <udid>` from the shell
  and using the field's native long-press → Paste menu instead. Pasted a
  full `VEVENT` block (title, start/end time spanning 2–4pm, location,
  `veryFlexible`, `recreational`), tapped Import — confirmed every field
  landed correctly in the pre-filled Add Event form: title, date, start
  time, end time, flexibility card, category chip, and location all
  matched the source data exactly.
- Saved the scanned/pre-filled event — it correctly triggered a real
  conflict against an existing event at an overlapping time, proving the
  QR-imported event flows through the same conflict engine as any
  manually-entered one rather than bypassing it. Resolved via "Keep
  both," confirmed it landed back on Agenda normally.
- **Not verified**: an actual live-camera scan of a physically-rendered
  QR code — impossible to automate without real hardware. The camera
  path (`AVCaptureMetadataOutput` → `metadataOutput(_:didOutput:from:)`
  → `onCode`) is standard, well-established AVFoundation usage; whoever
  picks this up should do one real-device check (two phones, or one
  phone scanning the QR shown on a Mac screen) to confirm the live path
  end to end — the decode/prefill/save logic downstream of "a string
  arrived" is already fully verified above.

**Next steps for whoever picks this up:**
1. `git status` will show new files under `Keel/Models/EventQRCoding.swift`
   and `Keel/Features/QRSharing/`, plus `EventDetailView.swift`,
   `AddEditEventView.swift`, `AddEditEventViewModel.swift`,
   `AgendaView.swift`, and `Keel.xcodeproj/project.pbxproj` modified —
   review the diff, then commit and push.
2. Do the real-device camera check described above when convenient.
3. Not handled: what happens if someone scans a *non*-Keel QR code (e.g.
   a random URL). Currently `EventQRCoding.decode` returns nil for
   anything without `BEGIN:VEVENT`/`END:VEVENT`, which correctly shows
   the "Not a Keel Event Code" alert rather than crashing — this was
   verified indirectly (decode's guard clause is straightforward) but
   not tested with an actual foreign QR code scan.

## Session handoff — 2026-07-21 (still later evening), read this first

**Status: visually verified, builds clean, not committed yet.** Added a
"Today" button to the calendar strip, top-right, aligned with the
"July 2026" month label — only visible when the selected day isn't
today; tapping it jumps back and re-centers.

**What changed, and a real bug it surfaced:** the naive first pass
reused the existing `jump(to:)` (the function the month-picker "Done"
button calls), which re-centers by setting `windowCenter` and relying on
a `.id(windowCenter)`-triggered view recreation + `.task` to re-run
`proxy.scrollTo`. That works for the month picker because it's jumping to
an arbitrary, usually-different month. But the Today button often taps
back to a `windowCenter` that's *already* `today` (nothing changed it —
per-day taps only move `selectedDate`, not `windowCenter`) — so the id
never changes, the task never re-fires, and the strip silently failed to
scroll even though the correct day got selected/highlighted. Caught this
by screenshotting after tapping "Today" and seeing today's cell
correctly highlighted but pinned to the strip's edge instead of centered
— the same "static" complaint that prompted the per-tap centering fix
earlier this session, just via a different code path.

**Fix:** restructured `CalendarStripView` so `ScrollViewReader` wraps the
whole view (header included), not just the day strip — giving the header
buttons direct access to the scroll `proxy`. Extracted a `select(_:proxy:)`
helper that both per-day taps and the "Today" button now call: it sets
`selectedDate` and does an immediate `proxy.scrollTo(day, anchor: .center)`
in `withAnimation`, no longer routed through `windowCenter`/`jump(to:)` at
all. Separately, swapped the old `.task { } .id(windowCenter)`
destroy-and-recreate trick for `.task(id: windowCenter) { }`, which
re-runs the re-center task when `windowCenter` changes (still needed for
month-picker jumps, which *can* land outside the current ±180-day
window) without tearing down and rebuilding the `ScrollViewReader` — so
the same long-lived `proxy` stays valid for `select` to use directly.

**Verified via UI automation** (same `touch` down/up workaround as the
prior centering fix, since day cells and now the "Today" button use
non-`Button` or otherwise-untargetable-by-`tap` accessibility roles in
some cases): tapped day 17 away from today (20) → "Today" button
appeared top-right → tapped it → strip re-centered on 20 (17–23 window,
20 in the middle) and the button disappeared. Also re-verified the
month-picker jump path still works post-refactor: jumped to Jul 5 via
the month grid → strip correctly centered on a 2–8 window with 5 in the
middle.

**Next steps for whoever picks this up:**
1. `git status` will show `CalendarStripView.swift` modified — review the
   diff, then commit and push.

## Phase 0 — Before writing app code
- [ ] Finish 3 user conversations about scheduling pain points (Homework #3, due before Session 3)
- [ ] Confirm project plan with team (Homework #3/4)
- [ ] Run `DESIGN_PROMPT.md` through Claude Design → produce `DESIGN.md`
- [ ] Review `DESIGN.md` + `SKILL.md` together — make sure the prioritization signals in the skill file match what research actually surfaced, not just the starting hypothesis

## Phase 1 — Data synthesis (Session 5–6, parallel to app scaffolding)
- [ ] Finish data synthesis / insight statements (Homework #5)
- [ ] Revisit `SKILL.md` prioritization table — replace hypothesis signals with real ones from synthesis
- [ ] Update persona in `CLAUDE.md` if research shifts who the primary user actually is

## Phase 2 — Xcode project scaffolding
- [x] New SwiftUI + SwiftData project, iOS 17+ target
- [x] Set up MVVM folder structure (`Features/`, `Models/`, `ConflictEngine/`)
- [x] Basic `Event` SwiftData model (title, start, end, location, flexibility flag, notes)
- [x] Manual event entry flow (add/edit/delete) — no conflict logic yet, just CRUD

## Phase 3 — Conflict engine (core differentiator — prioritize this over polish)
- [x] Overlap detection (literal time overlap)
- [x] Buffer/travel-time soft-conflict detection
- [x] Prioritization scoring using signals from `SKILL.md`
- [x] Explainability: surface *why* one event is recommended over another
- [x] Unit tests for the conflict engine — this is the piece most worth getting right

## Phase 4 — Conflict UI
- [x] Conflict alert / inline warning when a new event collides with an existing one
- [x] Resolution screen: show both events, the recommendation, and the reasoning
- [x] User can override the recommendation (never auto-resolve silently)
- [x] "Keep both, decide later" escape hatch — user can leave a conflict unresolved and later clear/re-trigger it just by editing either event's time (fixed a bug where editing from Event Detail never re-checked conflicts)
- [x] Conflict indicator (small badge) on the month picker for any day with an unresolved conflict — required swapping the native `DatePicker(.graphical)` for a custom SwiftUI month grid, since neither it nor `UICalendarView` can place a marker tight against a specific day number

## Phase 5 — MVP polish (Session 7–8, Implementation)
- [x] Home/agenda view — what does the user see day-to-day
- [ ] Empty states, onboarding (minimal — this is a prototype, not a launch)
- [ ] Visual pass using `DESIGN.md` direction
- [ ] Bug pass / demo-readiness check

## Phase 6 — Pitch prep
- [ ] Storyboard for 3–5 min pitch video (per syllabus final project requirements)
- [ ] Persona + empathy map slides
- [ ] Live demo script — pick 1–2 conflict scenarios that showcase the differentiator clearly
- [ ] Reflection notes: what you learned, what you'd do differently

## Ideas discussed, feasibility-checked, not started (2026-07-21 evening)
Brainstormed with Claude; not built, just captured so the reasoning doesn't
have to be redone. None of these block MVP — pick up only if time allows.

- [ ] **Event reminder notifications.** User picks an offset (e.g. 5 min /
  1 hour / 1 day / 1 week before) when creating/editing an event; Keel
  fires a local notification at that time. This is *local* notifications
  (`UNUserNotificationCenter`, scheduled on-device), not true push — no
  backend/APNs needed, which fits Keel's no-backend architecture. Already
  implicitly in scope per the line below ("push notifications *beyond*
  basic local reminders" is what's excluded, not local reminders
  themselves). Rough shape: add a reminder-offset field to `Event`, a
  picker in `AddEditEventView` next to the existing Flexibility picker,
  and a scheduler that creates/cancels a `UNNotificationRequest` (keyed to
  the event's `id`) on save/edit/delete.
- [x] **QR code event sharing.** Built 2026-07-27 — see the session
  handoff above for the full implementation and verification details.
  Generates a QR code for an event (`CIFilter`'s built-in
  `CIQRCodeGenerator`, no third-party dependency) encoding the event as
  a standard iCalendar `VEVENT` text block. Another Keel user scans it
  with an in-app camera scanner (AVFoundation) to import the event
  locally, reviewed through the normal Add Event form before saving. No
  server needed since the QR carries the full event data itself.
  Live-camera scanning itself couldn't be automate-tested (no simulator
  camera) — flagged for a real-device check — but the decode → prefill →
  save path, including conflict detection against existing events, is
  fully verified via the paste fallback.
- [x] **Shared-event time suggestions — step 1 of 2 done.** Built
  2026-07-27 (see "latest" session handoff above) as "shared-event
  availability": an opt-in, off-by-default checkbox shares the owner's
  busy time-blocks (times only, never titles/details — a deliberate
  privacy choice) alongside the event; the recipient's Keel shows both
  schedules side by side, computes free windows, and lets them propose a
  time, landing in the normal review-before-save form. This covers steps
  1–2 of the two-step exchange originally sketched below (share
  busy-blocks → compute free windows against the recipient's own
  events). **Still open:** step 3 — there's no signal back to the
  original owner when the recipient picks a time; the round trip
  currently ends at "recipient saves an event on their own calendar."
  Closing that gap needs either a second manual share-back (recipient
  re-shares their chosen slot as a new QR/text, owner imports it the
  same way) or, longer-term, a real sync layer — no backend exists yet,
  so it'd stay peer-to-peer for now.

  Original framing, kept for context: propose an event with someone else
  (e.g. "Saturday" with your girlfriend) and have Keel suggest a time
  that avoids both people's fixed commitments — e.g. you're booked
  11am–1pm, she's booked 7–9pm, Keel suggests 3–5pm. This is
  conceptually adjacent to "multi-user accounts" (excluded below) but
  meaningfully different — per-event peer-to-peer sharing, not
  persistent account/calendar syncing — so it doesn't actually cross
  that line. It's also a strong thematic fit: it's "conflict detection +
  prioritization" extended from one person to two, which is Keel's hero
  differentiator per `CLAUDE.md`.
- [x] **Event categories + time-spent tracking.** Built 2026-07-26/27
  across three commits (category field, calendar filter, monthly
  breakdown screen) — see session handoffs above for verification
  details. **Research-grounded, not scope creep** — unlike the other
  ideas in this list, this one came directly out of a user interview: an
  end user wants a visual of where his time is actually going, to catch
  himself accidentally overloading one category without realizing it —
  which directly feeds Keel's core loop, since noticing "I'm spending
  way too much on X" is exactly the signal that should make him reprioritize
  and move things in other categories. Worth reflecting this in
  `SKILL.md` / the persona notes once built, since it's a real synthesis
  insight, not a nice-to-have.

  Three sub-pieces, increasing difficulty:
  1. **Category field.** Add an optional `Category` to `Event`, same
     shape as the existing `Flexibility` enum. Decision needed before
     starting: fixed presets (Family/Exercise/Recreational — small,
     closed list, easy) vs. user-defined custom categories (open-ended,
     but needs its own `Category` model + a create/manage-categories
     flow — meaningfully bigger). Default to presets for a first pass
     unless there's a specific reason to need custom ones. Picker in
     `AddEditEventView`'s "More details" section, mirroring the
     flexibility cards.
  2. **Filter the calendar by category.** A filter control (menu or
     segmented picker, probably near the "Agenda" header) that narrows
     the day list to one category at a time. Need to decide whether the
     month-picker busyness shading reflects the active filter or always
     shows everything unfiltered — pick one deliberately, don't leave it
     ambiguous.
  3. **Monthly time-spent-per-category.** The one flagged as uncertain —
     but the math is the easy part: sum `endDate - startDate` per
     category for events in the selected month, all local, no backend
     needed. The real question is where/how it surfaces in the UI.
     Brainstormed options, roughly cheapest-to-priciest to build:
     - **Text breakdown list** — "Family: 6h 30m", "Exercise: 3h",
       sorted descending, on a new small screen. Cheapest to build,
       least visual — probably the right starting point to validate the
       feature before investing in a chart.
     - **Horizontal bar per category** — proportion of tracked time as a
       simple `Rectangle`-width bar, reusing the same
       `Color("AccentColor").opacity(...)` visual language already
       established by the month-picker busyness shading, so it reads as
       the same design system rather than a bolted-on chart.
     - **Stat tiles/cards** — one card per category with its total,
       loosely similar to the flexibility cards' visual weight.
     - **Month-over-month comparison** — this month vs. last month per
       category, surfacing the delta ("Exercise dropped from 8h → 2h").
       Directly serves the interviewed user's actual goal (noticing an
       unintentional skew) better than a single-month snapshot alone,
       so it's worth treating as the real target, not text-list as a
       placeholder for something fancier.
     - **Passive monthly summary** — instead of (or in addition to) a
       dedicated screen the user has to remember to open, surface a
       short summary automatically at the start of a new month (e.g. a
       banner/insight card on the Agenda screen: "Last month: 60% of
       your tracked time went to Work"). Highest payoff for the actual
       insight (catches the user passively, doesn't require them to dig
       for it) but the biggest lift — needs a "has this been shown yet
       this month" state and a good dismiss/re-surface rule.
     - Ruled out for now: a full donut/pie chart or per-day stacked
       timeline — visually richer but meaningfully more SwiftUI work for
       an MVP prototype, and the text-list/bar options above answer the
       user's actual stated need ("am I overloading one category")
       without it.

## Explicitly not doing for MVP (revisit only if time allows)
- [ ] Multi-user accounts / shared household view
- [ ] Calendar sync (Google/Apple/Outlook)
- [ ] Push notifications beyond basic local reminders
- [ ] AI-powered input (photo/email parsing) — interesting stretch goal, but conflict prioritization is the hero feature per your HMW; don't dilute focus
