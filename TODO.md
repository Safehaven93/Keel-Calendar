# TODO — Keel Build Roadmap

Mapped to the MIS 676 course schedule so the code stays in step with the design process, not ahead of or behind it. Check items off as you go; add sub-tasks as they emerge — this file should stay honest about actual state, not aspirational state.

## Session handoff — 2026-07-20/21, read this first

**In progress, not yet committed:** month-picker "busyness" shading. The idea:
in `MonthCalendarPicker.swift`, each day cell's fill now uses
`Color("AccentColor").opacity(...)`, scaled by how many events land on that
day (`AgendaView.eventCountByDay`, capped at 4+ events = darkest shade via
`MonthCalendarPicker.busyCountCap`). Selection changed from a solid fill to
a stroked ring (`Circle().stroke(...)`) so it doesn't visually collide with
the busyness fill. Files touched: `MonthCalendarPicker.swift`,
`CalendarStripView.swift`, `AgendaView.swift`.

**Status: implemented and builds clean, but NOT visually verified yet.**
`git status` will show these three files modified and uncommitted — do not
assume they're done until someone has actually looked at the calendar with
a mix of light/busy days and confirmed:
- shading is visibly distinguishable between e.g. 1 event vs 4+ events
- text stays legible at the darkest shade (currently switches to white
  text above 50% fill opacity — may need tuning)
- the selected-day ring reads clearly against both light and dark fills

**Why this is unverified:** UI automation (tap/swipe) wasn't available in
XcodeBuildMCP this session — only build/run/screenshot. A
`.xcodebuildmcp/config.yaml` enabling `ui-automation` was created at
`~/.xcodebuildmcp/config.yaml` but needed an MCP reconnect to take effect,
which didn't work reliably from the VS Code extension's `/mcp` command.
Plan was to restart Claude Code entirely to pick up the new tools, then
verify this feature interactively (add events across several days, open
the month picker, tap through, screenshot).

**Next steps for whoever picks this up:**
1. Confirm UI automation tools (`tap`, `swipe`, etc.) are now available.
2. Add events on a few different days with varying counts, open the month
   picker, and visually confirm the shading/legibility/ring points above.
3. Tune `MonthCalendarPicker.busyCountCap` / the `0.15...0.65` opacity
   range in `busynessFillOpacity(for:)` if the contrast is too subtle or
   too aggressive.
4. Commit and push once confirmed — nothing from this feature has been
   committed yet.

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
