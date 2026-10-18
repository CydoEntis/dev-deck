# Ticket

A ticket is written for an executor that has **none of the planning conversation**:
a person next month, or an agent that is told not to guess. Every gap you leave
becomes a question it cannot ask, or a guess it should not make.

**The test:** could someone with none of the conversation finish it from the ticket
and the files it names? If not, it isn't ready.

This page is the default shape. The repo's own ticket template, required fields and
conventions win wherever they differ (see "Tickets" in `SKILL.md`).

## The checklist

A ticket that fails any line isn't ready to show, let alone file.

| | |
|---|---|
| **The title reads as the commit** | It follows the repo's commit convention. Read `AGENTS.md` / `CLAUDE.md` and `git log --oneline` on the base branch. Under Conventional Commits: `feat(search): filter results by tag`, not `Search: add tag filtering`. Under that convention the prefix follows the type: bug → `fix`; feature or change → `feat`; task → whichever fits, such as `refactor`, `chore`, `docs`, `test` or `build`. |
| **A label for its type** | Use the label the repo uses for this type, and the one an executor maps to its instructions if it does (a `bug` or `refactor` agent, say). A label the tracker doesn't have yet is a tracker change: ask before creating it. |
| **One repo** | Work that spans two repos is two tickets, one blocked by the other. |
| **Small** | It passes every line of "The size check" below. |
| **Pass/fail acceptance criteria** | Each one clearly passes or fails, and says how it is checked: the verify command, a named test, a screenshot check, or a stated manual step. "Filtering works well" fails this line. "`pnpm test` passes with a new test for filtering by two tags" passes it. Use numbers where the target is a number: "p95 under 200 ms on the 10k-note fixture." |
| **Bugs start with a failing test** | See "Bugs" below. |
| **Changes name what they override** | A change links the ADR, Out line or design section that made the old behaviour deliberate, and says it is superseded. |
| **Tasks prove nothing changed** | See "Tasks" below. |
| **What users see has a check** | See "UI" below. |
| **Work for a person is marked** | A ticket only a person can do says so, and stays out of any executor's filter. |
| **Non-goals** | The adjacent things a reasonable executor might also do, and must not. |
| **A `## Context` section** | What you learned reading the code, as pointers. See below. |
| **Traces to its source** | A feature ticket links its intent (and spec), and names the requirements it covers. |
| **No open questions** | Anything unsettled is a stated assumption, or it goes back to the user. Never a gap. |
| **Blockers in tracker form** | See "Blockers" below. |
| **Impact only where it applies** | Migrations, new permissions, new dependencies, data leaving the device, docs the repo requires updating: one line each, and only the ones that are true. Never a list of `N/A`. |
| **The repo's own required fields** | If the repo's planning contract or agent instructions require more (a focused test command, affected docs), include it. |

### The size check

A ticket is small enough when **all** of these hold. If any fails, split it.

- **One thing.** One behaviour, one fix, or one refactor step. If the title needs
  "and" to join two different changes, it is two tickets. The same mechanical
  change made in several places (one rename, one replaced helper) is still one
  thing.
- **It ships alone.** Merging it by itself leaves the verify command green and the
  product working. If one acceptance criterion could ship without the others (the
  model without the UI, rendering without keyboard support), it gets its own
  ticket. The places a single mechanical change touches don't each need their own.
- **A short list.** About five acceptance criteria at most, not counting the verify
  line, and about five files to change at most (tests aside).
- **A quick review.** A reviewer can read the whole diff in one sitting, a few
  hundred lines at most.
- **A short run.** An agent can finish it in one session, well inside any time limit
  the executor has.

**Split along the work's own seams**, not by guessing hours:

- data before the code that uses it;
- the core behaviour before its UI;
- the happy path before the edge cases, when the edge cases stand alone;
- the new path before removing the old one.

Each piece gets its own ticket, with `Blocked by` between them.

### Bugs

A bug ticket requires the fix to be proven by a test that failed first:

1. Write a test that reproduces the bug.
2. Run it, and confirm it fails for the reason the bug describes.
3. Fix the bug **without editing that test**.

The ticket names where the test goes, and states the reproduction precisely enough to
write it: the input, the steps, what happens, and what should happen.

### Tasks

A refactor, dependency, docs, tooling or test ticket proves that users see no
difference:

- the verify command passes;
- existing tests pass **unedited**, except for moves or renames the ticket names;
- for anything on screen, the visual check says "unchanged."

The ticket says what gets better, and how that is measured when it can be ("the
build drops from 90 s to under 60 s").

### Blockers

Record blockers the way this repo's tickets already do (see "Tickets" in
`SKILL.md`).

- **The tracker has blocking relations**: use the relation.
- **Blockers go in the body**: write `Blocked by <ref>` at the start of its own
  line.

Anything that reads blockers from the body reads them line by line. The body has to
keep real line breaks, and no other line may *start* with "blocked by" or "depends
on".

### UI

A ticket that changes what a user sees names a check for it:

- **Screens**: which screen or state to capture, at what size, and what it must
  match (a section of `DESIGN.md`, a mock, or the existing screen it must not
  change).
- **Command-line output**: the exact output expected, captured by a test.

If the executor can't take screenshots, the check is a manual step, and the ticket
says so.

## The body

````markdown
## Goal

<One sentence: what is true once this merges.>

Intent: [<title>](<path>) · Spec: [<title>](<path>) · Covers: R1, R3

## Acceptance criteria

- [ ] <observable behaviour> — checked by <test / command / screenshot / manual step>
- [ ] <error, empty or recovery behaviour, only where this change has one>
- [ ] `<verify command>` passes

## Reproduction

<bugs only: input, steps, actual, expected>

- [ ] New test `<path>` › `<name>` fails before the fix and passes after it, unedited

## Visual check

<UI only: screen and state, size, and what it must match>

## Non-goals

- <adjacent change that must not happen here>

## Context

- Change: `<path>` — `<symbol>` is where <the thing> happens
- Copy the pattern in: `<path>` — `<symbol>` already does <the same shape>
- Test: add to `<path>`
- Watch out: `<symbol>` in `<path>` already does <X>; use it rather than writing a second one
- After <ticket ref> lands: `<path>` will have `<symbol>`; call it rather than <the old way>

## Assumptions

- <only if there are any>

## Impact

- Migration: <only if there is one>
- Permissions: <only if they change>
- New dependency: <only if one is added, and why>
- Docs: <only if the repo requires a doc update for this change>

Blocked by <ref>
````

Leave out any section that doesn't apply: the Intent line for work without an intent,
**Reproduction** for anything but a bug, **Visual check** for anything that isn't UI,
and **Assumptions** and **Impact** when they would be empty. Leave out the `Blocked by`
line when there is no blocker, or when the tracker holds it as a relation.

## The Context section

Every line comes from something you **read**, not something you expect to be there.

- **Pointers, not copies.** Name the file and the symbol; don't paste the code. Pasted
  code goes stale the moment an earlier ticket changes it, and the executor reads the
  real file anyway.
- **Only what this ticket needs.** A fact every ticket needs (layout, naming, test
  style) belongs in the repo's `AGENTS.md` / `CLAUDE.md`. If it's missing there, say
  so in the handoff rather than copying it into every ticket.
- **Say what an earlier ticket will change.** When a ticket is blocked, the code it
  starts from isn't the code you read. Name what the blocker adds or moves.
- **Never start a Context line with "blocked by" or "depends on"** (see "Blockers").
