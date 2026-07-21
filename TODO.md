# TODO — Keel Build Roadmap

Mapped to the MIS 676 course schedule so the code stays in step with the design process, not ahead of or behind it. Check items off as you go; add sub-tasks as they emerge — this file should stay honest about actual state, not aspirational state.

## Session handoff — 2026-07-21 (later evening), read this first

**Status: visually verified, builds clean, not committed yet.** Small
calendar-strip quality-of-life fix.

**What changed:** tapping a day in the horizontal calendar strip
(`CalendarStripView`) now scrolls that day to the center of the strip,
animated. Previously the tapped day just got the selected-highlight
wherever it happened to be sitting (e.g. jammed against the left or
right edge), which felt static. The `ForEach`'s `.onTapGesture` now calls
`proxy.scrollTo(day, anchor: .center)` inside `withAnimation` alongside
setting `selectedDate`, using the same `ScrollViewReader` the view
already had for its initial-appearance centering.

**How it was verified:** the day cells use `.onTapGesture` (not `Button`),
so — same as the EventRow issue noted in an earlier handoff — they aren't
exposed as accessibility-actionable targets and the `tap` automation tool
can't target them directly by elementRef. Worked around it with the
lower-level `touch` tool (`down: true, up: true`) aimed at a day cell's
text sub-element, which *does* register as a real touch at that element's
screen coordinates regardless of its accessibility role. Confirmed both
directions: tapping a day pinned to the strip's left edge (17, in a
17–23 window) re-centered it to a 14–20 window with 17 in the middle
(4th of 7); tapping a day pinned to the right edge (20, in a 14–20
window) re-centered back to 17–23 with 20 in the middle. Selection
highlight and centering both landed correctly each time.

**Worth flagging, not fixed this session:** the day cells still use
`.onTapGesture` rather than `Button`, meaning (like the pre-fix EventRow
issue) they likely aren't reachable via VoiceOver either. Out of scope
for "make it snap to center," but worth a dedicated pass if accessibility
matters for the course deliverable.

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

## Explicitly not doing for MVP (revisit only if time allows)
- [ ] Multi-user accounts / shared household view
- [ ] Calendar sync (Google/Apple/Outlook)
- [ ] Push notifications beyond basic local reminders
- [ ] AI-powered input (photo/email parsing) — interesting stretch goal, but conflict prioritization is the hero feature per your HMW; don't dilute focus
