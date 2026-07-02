---
name: conflict-prioritization
description: Use this skill whenever writing, modifying, or reasoning about conflict detection, event overlap logic, or prioritization/ranking of colliding commitments in Keel. Covers how two or more events are compared, what signals drive "which one wins," and how that reasoning should surface in the UI. Trigger this for any code touching event scheduling, collision detection, ranking, or priority scoring — not for generic CRUD on events (adding/editing/deleting a single event with no conflict).
---

# Conflict Prioritization

This skill defines Keel's core domain logic: how the app decides two commitments collide, and which one should win. Keep this file as the single source of truth so the reasoning doesn't drift or get reinvented differently in different features. Update it as user research refines the model — don't let code and this doc disagree.

## Step 1: Detecting a conflict

A conflict exists when two events overlap in time, accounting for:
- **Travel/buffer time**, not just the literal start/end timestamps (a 5pm meeting across town and a 5:30pm pickup can still be a conflict)
- **Soft conflicts**: back-to-back events with no buffer at all, even if they don't technically overlap — worth surfacing as a lower-severity warning, not a hard block

Don't treat "same time slot" as the only conflict condition. Ask before assuming buffer defaults — this should come from research (Homework #3–6 interviews), not an arbitrary constant.

## Step 2: Prioritization signals

When two events collide, rank them using signals like the following (this list is a **starting hypothesis** — replace/refine once your team's synthesis phase produces real insight statements):

| Signal | Example | Why it matters |
|---|---|---|
| Flexibility | Flight departure vs. casual coffee | Some things literally cannot move |
| Dependents | Kid's recital vs. solo errand | Other people are counting on it |
| Sunk cost | Paid deposit, non-refundable booking | Real cost to dropping it |
| Recurrence | One-off vs. weekly standing commitment | A missed one-off may be higher stakes than skipping one instance of a recurring thing |
| Advance notice | Booked 3 months ago vs. added yesterday | Commitment age can signal importance |

**Do not hardcode a single weighted formula and call it done.** The MVP should make the reasoning *visible and explainable* to the user — show which signals tipped the recommendation — rather than silently picking a winner. A black-box "Keel picked for you" undermines the whole "control from chaos" goal; the user needs to trust *why*, not just *what*.

## Step 3: Surfacing the decision

- Never auto-resolve a conflict without the user's confirmation for MVP. Recommend, don't decide.
- Always show the "why" alongside the recommendation — one line is enough (e.g., "Recital has no buffer to reschedule; errand can move to any day this week").
- If confidence is low (signals are ambiguous or evenly matched), say so rather than forcing a false-confident pick.

## When implementing

- Keep conflict-detection and prioritization logic in a dedicated, testable module (e.g. `ConflictEngine`) — not scattered inline in views or scattered across event CRUD code.
- Write this so new signals can be added without restructuring the engine (it will change as research findings come in).
- Any UI that surfaces a conflict should pull its copy/reasoning from the same engine output — don't let two screens explain a conflict differently.
