# TODO — Keel Build Roadmap

Mapped to the MIS 676 course schedule so the code stays in step with the design process, not ahead of or behind it. Check items off as you go; add sub-tasks as they emerge — this file should stay honest about actual state, not aspirational state.

## Session handoff — 2026-07-21 (evening), read this first

**Status: visually verified, builds clean, not committed yet.** Follow-up
to the "what's coming" preview added earlier today (already committed):
the cards in that preview now show the event's date (not just time), and
a pencil icon to edit inline.

**What changed:**
- `EventRow` gained two new params: `showsDate` (prepends e.g. "Tue, Jul
  21 · " before the time range — off by default, since the same-day
  agenda list already implies the date via the selected day) and `onEdit`
  (shows a trailing pencil `Button` when set).
- `AgendaView`'s upcoming-events cards now pass `showsDate: true` and
  `onEdit: { editingEvent = event }`, wired to a new
  `@State private var editingEvent: Event?` + `.sheet(item:)` that opens
  `AddEditEventView` directly — no detour through the detail screen.
- The card itself is a real `Button` (not `.onTapGesture`) wrapping
  `EventRow`, with the pencil as a nested `Button` inside it. Nested
  buttons are flaky inside `List` rows, but this card lives in a plain
  `ScrollView`/`VStack`, where hit-testing correctly disambiguates: tapping
  the pencil's bounds triggers only the pencil, tapping elsewhere on the
  card triggers navigation to detail. Confirmed both work independently
  via UI automation (tapping the card body → detail screen; tapping the
  pencil → "Edit Event" sheet, pre-filled, separately from tapping the
  card).
- Earlier draft used `.onTapGesture` on a plain (non-Button) container for
  the card body — reverted after discovering it isn't exposed as an
  accessibility-actionable element (UI automation couldn't target it, and
  neither would VoiceOver). Real `Button`s avoid that.

**Next steps for whoever picks this up:**
1. `git status` will show `EventRow.swift` and `AgendaView.swift`
   modified — review the diff, then commit and push.
2. The same-day agenda list (below the calendar strip, for a day that
   *does* have events) doesn't have the pencil/inline-edit — only the
   "what's coming" preview does, per what was asked for. Worth asking
   whether that inconsistency should be resolved (add it everywhere, or
   leave the same-day list as swipe-to-delete + tap-to-detail-then-edit).

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

## Explicitly not doing for MVP (revisit only if time allows)
- [ ] Multi-user accounts / shared household view
- [ ] Calendar sync (Google/Apple/Outlook)
- [ ] Push notifications beyond basic local reminders
- [ ] AI-powered input (photo/email parsing) — interesting stretch goal, but conflict prioritization is the hero feature per your HMW; don't dilute focus
