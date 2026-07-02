# CLAUDE.md — Keel

Project context for Claude Code. Read this before making changes. Keep it updated as decisions change — this is the single source of truth for *why*, not just *what*.

## What this is

**Keel** is an iOS app for the parent/adult who acts as the de facto scheduling hub for their household. It doesn't just show a shared calendar — it detects when commitments collide and helps the user decide, in the moment, which one actually wins.

Built for **MIS 676: Human-Centered Design of AI Artifacts** (Stevens, Summer 2026). Final deliverable: working MVP prototype presented at the on-site hackathon.

## The design challenge (from Team 1's framing doc)

- **Problem:** Organizing schedules, appointments, due dates, and recurring commitments across a household — and when things collide, knowing what actually matters.
- **How Might We:** *How might we organize our lives for more efficient scheduling so that the least amount of conflict is encountered? If conflicts do arise, how might we bring forth information that allows the user to prioritize effectively?*
- **Impact target:** Establish and maintain control of time — create control from chaos.
- **Constraint to design around:** The user's zone of control is limited because multiple independent parties (partner, kids, work, extended family) generate commitments the user didn't create and can't unilaterally move.

## Primary user (MVP scope)

**One persona only for MVP — do not build for the whole household yet.**

The parent/adult who is the *de facto* scheduling hub: the one who gets asked "wait, are we free Saturday?" They see everyone's commitments but don't control all of them. Success = fewer missed things, less time spent untangling collisions, more confidence that nothing important got dropped.

Explicitly **out of scope for MVP**: multi-user accounts, kid-facing views, shared/collaborative editing, partner logins. Single-user app that *ingests* other people's commitments (manually, for now) rather than syncing multiple accounts.

## Core differentiator — this is the thing being tested

**Conflict detection + smart prioritization.** Not just "you're double-booked" (every competitor does this) — but a reasoned answer to "which one should win, and why."

Competitive landscape (researched July 2026): Cozi, TimeTree, FamilyWall, Apple/Google Calendar all do shared-calendar-with-manual-entry. None of them help you *decide* when two things collide. That gap is Keel's reason to exist. If a feature doesn't serve conflict detection or prioritization, it's a nice-to-have, not MVP.

Prioritization should reason about signals like: hard-to-move vs. flexible (a flight vs. a coffee catch-up), who else is depending on it (kid's recital vs. solo errand), cost of dropping it (deposit lost, relationship cost), and recurrence (one-off vs. weekly). Don't hardcode a single scoring formula without user testing — this is exactly what your interviews and synthesis phase should surface. Update this section once you have real insight statements.

## Tech stack

- **SwiftUI** for UI — declarative, matches prior project experience
- **SwiftData** for persistence — local-first, no backend for MVP
- **iOS 17+** target
- No backend / no auth for MVP. If sync becomes a stretch goal, treat it as post-MVP (CloudKit, not custom backend)

## Conventions

- MVVM: Views stay dumb; logic lives in `@Observable` view models
- One feature = one folder (`Features/ConflictDetection/`, `Features/EventInput/`, etc.), not one giant flat file list
- Prefer SwiftData `@Model` types close to how they'll actually be queried — don't over-normalize prematurely
- Explain reasoning before implementing non-trivial changes — I'm learning to code alongside this build, plain-English first, code second
- Commit in small, working increments — each commit should build and run

## Reference files in this repo

- `DESIGN.md` — visual/UX spec (generated via Claude Design, see `DESIGN_PROMPT.md`)
- `SKILL.md` — domain logic for conflict detection & prioritization, so this reasoning stays consistent across the codebase instead of getting reinvented per-feature
- `TODO.md` — build roadmap, mapped to the course schedule

## Course grounding — don't lose sight of this

This is a human-centered design class, not a hackathon-for-its-own-sake. Every feature should trace back to a synthesized insight from your team's interviews (Homework #3–6). If you're building something that isn't grounded in an insight statement or pain point from research, flag it — it may be scope creep.
