# TODO — Keel Build Roadmap

Mapped to the MIS 676 course schedule so the code stays in step with the design process, not ahead of or behind it. Check items off as you go; add sub-tasks as they emerge — this file should stay honest about actual state, not aspirational state.

## Session handoff — 2026-07-21, read this first

**Status: visually verified, builds clean, still not committed.** UI
automation (`tap`/`snapshot_ui`/`screenshot`) came back after an MCP
reconnect + fresh Claude Code session, so the month-picker "busyness"
shading from the prior handoff got tested for real: added events across
days with 1, 2, 3, and 5 (capped to 4) counts and opened the month picker.

Confirmed:
- shading is a continuous ramp, not a threshold jump — each additional
  event visibly deepens the `Color("AccentColor")` fill, from a pale tint
  at 1 event up to the darkest shade at the 4+ cap
  (`MonthCalendarPicker.busynessFillOpacity(for:)`)
- text legibly switches to white above the 50% fill-opacity threshold
- the selected-day ring (`Circle().stroke(...)`) reads clearly against
  both light and dark fills

**Bug found + fixed this session:** the month-picker sheet had no
explicit `.presentationBackground`, so it inherited SwiftUI's default
translucent system material — the Agenda view's "+ Add event" button was
bleeding through as a soft blue smear behind days near the bottom of the
grid. Fixed by adding `.presentationBackground(Color("Surface"))` in
`CalendarStripView.swift` (the `.sheet` that presents
`MonthCalendarPicker`). Rebuilt and re-verified — sheet background is now
solid, bleed-through gone.

**Next steps for whoever picks this up:**
1. `git status` will show `MonthCalendarPicker.swift`, `CalendarStripView.swift`,
   `AgendaView.swift` modified (busyness shading) — review the diff, then
   commit and push. Nothing from this feature is committed yet.
2. Any leftover manually-added test events (titled "Test event 1", "Event A/B",
   "Event C1-3", "Event D1-5" on 2026-07-25 through 07-28) were added purely to
   exercise the shading gradient and should be deleted before/as part of that
   commit if any remain.

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
