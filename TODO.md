# TODO — Keel Build Roadmap

Mapped to the MIS 676 course schedule so the code stays in step with the design process, not ahead of or behind it. Check items off as you go; add sub-tasks as they emerge — this file should stay honest about actual state, not aspirational state.

## Session handoff — 2026-07-26 (later evening), read this first

**Status: visually verified, builds clean, not committed yet.**
Sub-piece 2 of "Event categories + time-spent tracking": filtering the
calendar by category. Sub-piece 1 (the category field itself) is already
committed/pushed. Sub-piece 3 (monthly time-spent breakdown) is still
NOT started.

**What changed:**
- `AgendaView` gained `@State private var categoryFilter: EventCategory?`
  (`nil` = show everything) and a `Menu`-based filter control
  (`categoryFilterMenu`) next to the "Agenda" header — a capsule showing
  "All Categories" or the active category's name, matching the existing
  chip/capsule visual language.
- New `filteredEvents` computed property (`events`, or `events` filtered
  to `categoryFilter` when set) now feeds the day list, the "what's
  coming" preview, and — deliberately — the month-picker's busyness
  shading and conflict-day badges too, so picking e.g. "Exercise" shades
  the whole month by where exercise events actually land, not just the
  currently-selected day's list. This was an explicit decision flagged in
  the brainstormed plan below ("pick one deliberately, don't leave it
  ambiguous") — chose "filter reflects everywhere" over "day list only."
- Conflict-partner lookups (`conflictTitle`, `handleTap`) deliberately
  keep reading the unfiltered `events` — a conflict is a real
  relationship between two events regardless of which category is being
  viewed, so filtering that out would break the conflict-resolution flow
  rather than just hiding rows.

**Verified via UI automation:** built two test events on the same day —
"Soccer practice" (Exercise) and "Baseball practice" (Family, after
correcting a mid-session mis-tap that briefly put Exercise on the wrong
event — worth noting only because it validated the filter logic itself
was correct even while the *test data* was momentarily wrong). Opened
the filter menu, confirmed all four options render with a checkmark on
the active one. Selected "Exercise" — day list narrowed to just Soccer
practice. Selected "Family" — narrowed to just Baseball practice.
Selected "All Categories" — both reappeared. Filter capsule's label and
tint update correctly in each case.

**Next steps for whoever picks this up:**
1. `git status` will show `AgendaView.swift` modified — review the diff,
   then commit and push.
2. Sub-piece 3 (monthly time-spent breakdown) is the only piece left —
   see the full "Event categories + time-spent tracking" entry below for
   the brainstormed UI options (text list, bar chart, stat tiles,
   month-over-month comparison, passive summary).

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
- [ ] **QR code event sharing.** Generate a QR code for an event (via
  `CIFilter`'s built-in `CIQRCodeGenerator`, no third-party dependency)
  encoding the event as a standard iCalendar `VEVENT` text block — reusing
  an existing format rather than inventing one. Another Keel user scans it
  with an in-app camera scanner (AVFoundation) to import the event
  locally. No server needed since the QR carries the full event data
  itself. Constraint: only works between two people who both have Keel
  installed (no web fallback for non-users) — but that's consistent with
  Keel's existing "manually ingest other people's commitments" design;
  this would just make that manual step faster.
- [ ] **Shared-event time suggestions.** Propose an event with someone
  else (e.g. "Saturday" with your girlfriend) and have Keel suggest a
  time that avoids both people's fixed commitments — e.g. you're booked
  11am–1pm, she's booked 7–9pm, Keel suggests 3–5pm. Meaningfully bigger
  lift than the two ideas above: since there's no backend, both
  schedules can only meet via a **two-step peer-to-peer exchange**, not
  a single share:
  1. You share a draft event for a date, with a payload of just your
     busy time-blocks that day (not full event details — how much to
     expose is a privacy decision worth making deliberately).
  2. Her Keel receives it, combines it with her own local events for
     that day, and computes free windows avoiding both people's fixed
     commitments — this should reuse/extend the existing conflict
     engine (`ConflictEngine`/`SKILL.md` prioritization) generalized
     from one schedule to two, rather than new logic from scratch.
  3. She picks a slot and shares it back to confirm — a second
     round-trip, since nothing syncs automatically without a server.

  This is conceptually adjacent to "multi-user accounts" (excluded
  below) but meaningfully different — per-event peer-to-peer sharing,
  not persistent account/calendar syncing — so it doesn't actually
  cross that line. It's also a strong thematic fit: it's "conflict
  detection + prioritization" extended from one person to two, which is
  Keel's hero differentiator per `CLAUDE.md`. Worth prototyping only if
  the core single-user conflict engine is rock solid first.
- [ ] **Event categories + time-spent tracking.** Likely picked up
  tonight. **Research-grounded, not scope creep** — unlike the other
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
