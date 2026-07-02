# Keel — Design Brief

**Project:** Keel, an iOS scheduling app for the household's de facto calendar owner
**Format:** Design spec for SwiftUI implementation, written for an AI coding assistant
**Status:** MVP scope only

---

## 1. Problem & Impact Goal

The user is the person everyone in their household asks "are we free Saturday?" They can *see* everyone's commitments but don't *control* all of them — commitments originate from independent parties (partner, kids' activities, work, extended family). Existing calendar apps (Cozi, TimeTree, FamilyWall, Apple/Google Calendar) detect double-booking but stop there — they never help the user decide which commitment should win.

**How Might We:** organize schedules so conflict is minimized, and when it does happen, surface the information needed to prioritize effectively.

**Impact goal:** create control from chaos.

**Primary user (MVP — single persona):** A busy parent, mid-30s to 40s, mentally exhausted by being the household's scheduling bottleneck. Not tech-averse, but has zero patience for friction — if adding an event takes more than a few taps, they abandon it. They don't want another calendar to babysit; they want the app to tell them something they didn't already know.

---

## 2. Design Principles

These govern every screen and interaction decision. When in doubt, default to these over convention.

1. **Explain, don't just alert.** A conflict badge or red dot is not information. Every conflict surface must state *why* one commitment should win — the reasoning is the product, not the detection.
2. **Never auto-resolve.** The app recommends; the user decides. Silent rescheduling or auto-dismissal destroys trust in a tool whose entire job is to be trusted with the household's time.
3. **Friction is the enemy.** Every core action (add event, resolve conflict) should be completable in the fewest taps possible. If a screen asks for information the app could infer, infer it.
4. **Calm is a feature.** This is a stress-reduction tool for someone already overwhelmed. No badges-for-badges'-sake, no streaks, no gamified nudges, no more than one accent color fighting for attention on any screen.
5. **One clear next action per screen.** Never present the user with an open-ended list of things they could do. Always surface the single most useful action given context (e.g. "Resolve conflict," not a menu of five options).

---

## 3. Core Flow — Conflict Detection & Resolution

This is the flow the whole app is designed around. Sequence below assumes a new commitment is added that collides with an existing one (the same sequence applies when a synced/incoming commitment creates a collision).

**Step 1 — Add commitment**
User adds an event (title, date, time, optional location) via the fastest possible entry path (see §4, Add/Edit Event). No conflict awareness needed at this step — user isn't interrupted mid-entry.

**Step 2 — Conflict detected on save**
On save, Keel checks for time overlap against existing commitments. If none, event saves silently and user returns to Agenda. If a conflict exists, user is taken directly to the **Conflict Resolution screen** — not a modal alert, not a toast. This is a real screen because the decision deserves real space.

**Step 3 — Conflict surfaced with reasoning**
Screen shows both commitments side by side with a plain-language recommendation, e.g.:
> "Recital has no buffer to reschedule. Grocery run can move to any day this week."

The recommendation is generated from signals the app already has: flexibility (does this commitment have a fixed external time, e.g. a performance/appointment, vs. a self-scheduled task), rescheduling window (how many days it could plausibly move within), and who it involves (a commitment tied to another person, e.g. a kid's recital, outweighs a solo errand — surfaced when known, never assumed to be true 100% of the time — recommendation is a signal, not a verdict).

**Step 4 — User decides**
Three explicit actions, always visible, never buried in a menu:
- **Keep both / reschedule the loser** — user confirms the app's recommendation; Keel proposes a new time for the lower-priority item and lets the user adjust before confirming.
- **Override** — user picks the other commitment to keep instead; app deprioritizes/reschedules the one it had recommended keeping.
- **See more detail** — expands reasoning (why this one, what else is on the loser's day, alternate slots) without leaving the screen.

**Step 5 — Resolution confirmed**
Whichever commitment moved gets an explicit new time, shown to the user before the screen dismisses — never moved silently in the background. Return to Agenda; the moved event is visibly marked as rescheduled (subtle, not celebratory) for one view so the user isn't confused about why a time changed.

---

## 4. Screen Inventory (MVP)

Four screens only. No account/settings screens, no onboarding beyond first-run empty state.

### 4.1 Agenda (Home)
- Default landing screen. Single vertical scroll, grouped by day, today at top.
- **Layout: individual white rounded cards (14–16pt radius) per event, not a dense flat list.** Generous card padding (16pt) and gaps (12pt) between cards — density stays on the roomy end even as the list grows; resist collapsing back into a tight table.
- Each card: time (fixed-width column, tabular figures) + title. A conflicting event's card carries a thin left-edge accent in conflict terracotta (`#B5674A`) plus a one-line inline label under the title ("Conflicts with Grocery run") — never an icon-only badge.
- One primary action: a floating pill button ("+ Add event", solid accent teal, white label, soft shadow), centered at the bottom of the screen, always reachable by thumb.
- If a commitment is currently in unresolved conflict, its card carries the marker above and tapping it goes straight to Conflict Resolution — conflicts are never left to be discovered only via a separate inbox.

### 4.2 Add/Edit Event
- Minimum required fields to save: title, date, start time. Everything else (end time, location, notes) optional.
- **Layout: card-composer style, not a form/table.** Title is a single large freeform input at the top (placeholder "What's happening?"), styled like writing a note rather than filling a field. Date and time sit below as two big equal-width tappable chips, side by side.
- Natural-language-friendly title field is acceptable (e.g. typing "Dentist Tue 3pm" could parse date/time) if feasible — reduces taps for the target user.
- **Flexibility is three large, equal-weight tappable cards** (Fixed / Somewhat flexible / Very flexible), stacked full-width, selected state filled in accent teal — not a small segmented control. This is the single most important input for future conflict reasoning and deserves real visual weight, not a buried toggle.
- Save is a full-width bold button pinned at the bottom, always visible without scrolling for the required fields.

### 4.3 Conflict Resolution
- Triggered automatically on conflicting save (see §3). Never a screen the user navigates to manually from a menu — it only exists in response to a real conflict.
- **Layout: reasoning first, then stacked cards, in that reading order.** A single reasoning card at the top (neutral white/bordered, small clock/info glyph, plain-language sentence) states the recommendation before the user sees the commitments themselves.
- Below it, the two commitments are stacked (not side by side) as full-width cards: the recommended-to-keep commitment gets a stronger accent-teal border and a small "KEEP" tag; the recommended-to-move commitment is visually quieter (muted background, "MOVE" tag in conflict terracotta) — hierarchy communicates the recommendation before the user reads a word.
- Three stacked actions below the cards, in descending visual weight: solid accent-teal primary button ("Keep X, move Y"), an outline secondary button ("Keep Y instead"), and an understated text link ("See more detail") — matching §3 Step 4.
- This screen should never feel like an error state. It's a decision-support screen, not a warning screen — tone and color should reflect "here's useful information," not "something went wrong."

### 4.4 Event Detail
- Tapping any Agenda card lands here. **Layout: hero card at top** — a full-width rounded block tinted with the event's flexibility color (accent tint for fixed, neutral for flexible), containing a small uppercase flexibility tag, the event title, and date/time in accent-colored text. Supporting details (location, notes) sit in a plain white card below.
- If the event was ever part of a resolved conflict, a short, non-intrusive line notes it inline in the details card ("Rescheduled Grocery run to Sunday to keep this clear") — transparency without extra chrome.
- Edit/delete actions as two equal-width buttons at the bottom (delete in conflict-terracotta text, never a saturated red). No additional decision-support content here (that lives in Conflict Resolution only).

---

## 5. Visual Direction

### 5.1 Palette

Cool, low-saturation palette — trustworthy and calm, not clinical. One accent color only, used sparingly, plus a single reserved conflict-severity hue so it doesn't compete with the brand accent.

| Role | Value | Usage |
|---|---|---|
| Background | `#F7F8F9` | Base app background |
| Surface | `#FFFFFF` | Cards, sheets |
| Border/divider | `#E4E7EA` | Hairlines, card edges |
| Text primary | `#1B2126` | Titles, primary copy |
| Text secondary | `#5B6670` | Metadata, timestamps, helper text |
| Accent (brand) | `#2F6F76` (deep teal) | Primary buttons, selected states, the app's single "voice" color |
| Accent tint | `#DCEAEB` | Accent-colored surfaces (e.g. selected day, subtle highlight) |
| Conflict — needs attention | `#B5674A` (muted terracotta) | Conflict markers, recommendation emphasis — warm but desaturated, never alarm-red |
| Conflict tint | `#F4E7E1` | Background for conflict cards/rows — warm, not red |
| Success/confirmed (sparing use) | `#4C7A5E` (muted sage) | Only for "resolved" confirmation state, used once per flow, never as a persistent badge |

Avoid pure black, pure white, and saturated red/green — the palette should read as considered and warm-neutral, not clinical or alarm-driven.

### 5.2 Typography

- **SF Pro (system default)** throughout — no custom display font. This is a utility app; typographic restraint reinforces calm.
- Use Dynamic Type / `Font.TextStyle` semantic sizes (`.largeTitle`, `.title2`, `.body`, `.footnote`) rather than fixed point sizes, for accessibility and native feel.
- Weight does the work of hierarchy, not size variety: `.semibold` for titles/times, `.regular` for body/metadata. Avoid more than 2 weights on any single screen.
- Numerals (times) should use `.monospacedDigit()` so times in a list align vertically — small detail, large calm payoff.

### 5.3 Spacing & Density

- **Confirmed direction: roomy, card-based, generous whitespace** — not a compact list/table. Every screen (Agenda, Add/Edit, Conflict Resolution, Event Detail) is composed of individually-boxed white rounded cards on a soft neutral background, not flush rows or dense grouped lists. This is the opposite of a data-dense productivity dashboard.
- Base spacing unit: 8pt. Card padding 16–20pt. Gaps between cards 12–14pt. Section spacing 24–32pt.
- Corner radius: consistent moderate-to-generous rounding (14–20pt) on cards/sheets/buttons — soft but not bubbly/playful.
- Agenda cards: one time + one title + at most one status marker per card. Resist adding more metadata per card even if available — push detail to the Detail screen.
- Primary actions read as pill-shaped buttons (999px radius) or full-width rounded rectangles — never bare text links for anything the user does often.

### 5.4 Communicating Conflict Severity

Severity is communicated through **hierarchy and language first, color second** — never through count-style badges or red dots alone (those alert without explaining, violating principle #1).

- **Agenda card, unresolved conflict:** a thin left-edge accent in the conflict terracotta (`#B5674A`) on the card, plus a one-line inline label ("Conflicts with Recital") instead of an icon-only badge. No numeric badge count anywhere in the app.
- **Conflict Resolution screen:** a reasoning card at the top states the recommendation in plain language before the commitments are shown. Below it, the recommended-to-keep commitment is a full-strength card with an accent-teal border and a small "KEEP" tag; the recommended-to-move commitment is a visually quieter, muted card with a "MOVE" tag in conflict terracotta — hierarchy communicates the recommendation before the user even reads the reasoning sentence.
- **Event Detail:** the event's flexibility status colors a hero card at the top of the screen (accent tint for fixed commitments, neutral for flexible ones) — flexibility is visible at a glance without a separate label needing to be read.
- **No traffic-light system.** Avoid green/yellow/red severity levels — conflict is binary (exists / doesn't) and the *reasoning*, not a severity score, is what varies. Manufacturing false precision (e.g. "72% conflict") would undermine trust.
- Icons: at most one glyph, a simple line-style "overlap" or "arrows crossing" symbol (SF Symbols `arrow.triangle.branch` or similar), used only as a small inline marker next to the conflict label — never as a large illustrative graphic.

---

## 6. Empty & Error States

### 6.1 Agenda — Empty
- First-run or fully-clear day/week: no illustration-heavy empty state. A single calm line of text ("Nothing on the books.") plus the add-event action, same placement as always. Empty state should look like a *feature* (a clear schedule, which is the goal) not a broken/incomplete screen.

### 6.2 Agenda — Load/Sync Error
- If the app can't load or sync commitments (e.g. calendar permission revoked, network failure for any synced source): show existing cached data if available, with a small non-blocking inline banner at the top ("Some events may be out of date — [Retry]"). Never a full-screen error blocking access to what the user already has cached — losing access to their schedule is the worst-case failure for this app's core promise.

### 6.3 Conflict Resolution — No Longer Applicable
- If a user navigates to a conflict that's already been resolved elsewhere (e.g. the colliding event was deleted) or opens a stale notification: show a brief confirmation state ("This conflict has been resolved.") with a single action back to Agenda — never an error message, since nothing actually went wrong.

### 6.4 Conflict Resolution — Insufficient Information to Recommend
- If Keel can't confidently generate a reasoned recommendation (e.g. both events are equally flexible, no signal to differentiate): don't force a fake-confident recommendation. State it plainly ("Both of these look equally flexible — your call.") and present the two commitments with equal visual weight, still with the same three actions from §3 Step 4. Never fabricate a reason to seem smarter than the app's actual signal.

---

## 7. Explicit Non-Goals (MVP)

Out of scope — do not build, and do not leave UI affordances implying these are coming soon (no grayed-out nav items, no "coming soon" cards):

- **Multi-user / shared views.** No partner accounts, no permissions, no "who added this" attribution UI. MVP is single-user, single-device.
- **Calendar sync (Apple Calendar, Google Calendar, etc.).** MVP works on commitments entered directly in Keel. Import/sync is a post-MVP problem; don't design placeholder sync settings.
- **Kid-facing UI.** No child logins, no simplified kid views. Kids' activities are entered by the parent as regular commitments.
- **Notifications/reminders system.** No push notification design, no reminder scheduling UI, beyond what's structurally required for the conflict flow itself.
- **Settings screen.** No preferences, theming, account management, or configuration screens of any kind for MVP.
- **Recurring events.** Treat every commitment as a single instance for MVP; no recurrence rules UI.
- **Gamification of any kind.** No streaks, no "you resolved 5 conflicts this week," no achievement language — directly conflicts with design principle #4.

---

## 8. Implementation Notes for SwiftUI

- Build with native SwiftUI components (`List`, `NavigationStack`, `Form` for Add/Edit) rather than custom-drawn equivalents — native feel supports the "calm, trustworthy" goal more than a custom design language would.
- Conflict Resolution should be presented as a full screen (`NavigationStack` push), not a `.sheet()` — this is a decision that deserves the same weight as any other primary screen, not a dismissible overlay that invites the user to swipe away without deciding.
- Respect Dynamic Type and support Dark Mode from the start using semantic colors (`Color("Background")`, etc. defined in an asset catalog) rather than hardcoded hex in every view — define the palette in §5.1 as a `ColorSet` once.
- Keep the conflict-reasoning logic (flexibility comparison, rescheduling window, priority signals) in a separate model/service layer, not embedded in the view — this logic will likely evolve fastest post-MVP.
