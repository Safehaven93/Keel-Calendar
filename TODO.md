# TODO — Keel Build Roadmap

Mapped to the MIS 676 course schedule so the code stays in step with the design process, not ahead of or behind it. Check items off as you go; add sub-tasks as they emerge — this file should stay honest about actual state, not aspirational state.

## Session handoff — 2026-07-21 (later same day), read this first

**Status: visually verified, builds clean, not committed yet.** Added an
"upcoming events" fallback to the empty-day agenda state.

**What changed:** when the selected day has no events, the Agenda no
longer just says "Nothing on the books." It now shows "Nothing today!
But take a look at what's coming" and, below that, the soonest upcoming
events — but only from the highest-priority `Flexibility` tier that has
any: `fixed` first, then `somewhatFlexible`, then `veryFlexible`
(`AgendaViewModel.upcomingPriorityEvents(after:from:limit:)`). So a
far-off fixed commitment outranks a sooner flexible one; flexible events
only surface once there's nothing more fixed on the horizon. Capped at 5
events, no explicit day-window cutoff.

Verified interactively via UI automation:
- fixed event 2 days out correctly showed, and correctly suppressed a
  *sooner* (1 day out) somewhat-flexible event — confirms tier priority
  beats chronological order
- deleting the fixed event immediately surfaced the somewhat-flexible
  one that had been suppressed — confirms the tier-fallback works, not
  just tier-1-or-nothing

Also confirmed: with no upcoming events of any tier, the headline shows
alone with no list below it — reads cleanly, no leftover empty spacing.

**Next steps for whoever picks this up:**
1. `git status` will show `AgendaView.swift` and `AgendaViewModel.swift`
   modified — review the diff, then commit and push.
2. Not yet tested: the `veryFlexible` fallback tier specifically (only
   fixed → somewhatFlexible was exercised this session).
3. No explicit "near future" day cutoff was implemented — it always shows
   the soonest events of the best available tier, however far out. Revisit
   if that reads as too permissive once there's real usage data.

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
