# TODO — Keel Build Roadmap

Mapped to the MIS 676 course schedule so the code stays in step with the design process, not ahead of or behind it. Check items off as you go; add sub-tasks as they emerge — this file should stay honest about actual state, not aspirational state.

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

## Explicitly not doing for MVP (revisit only if time allows)
- [ ] Multi-user accounts / shared household view
- [ ] Calendar sync (Google/Apple/Outlook)
- [ ] Push notifications beyond basic local reminders
- [ ] AI-powered input (photo/email parsing) — interesting stretch goal, but conflict prioritization is the hero feature per your HMW; don't dilute focus
