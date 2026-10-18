# ADR

An architecture decision record captures **why** a decision that is expensive to
reverse was made, so the next person does not reopen it by accident or keep it
out of habit.

Offer one only when the decision is **hard to reverse**, **surprising without
context**, and **the result of a real trade-off**: all three (see "ADRs" in
`SKILL.md`). Naming, formatting, and anything a single pull request could undo
don't qualify.

Use the repo's existing folder, numbering and format if it has them. Otherwise
`docs/adr/NNNN-<slug>.md`, numbered from the highest existing one.

````markdown
# ADR-<NNNN>: <the decision, as a sentence>

Status: proposed | accepted | superseded by [ADR-<NNNN>](<path>) | superseded in part by [ADR-<NNNN>](<path>) (§ <section>)
Date: <YYYY-MM-DD>
Supersedes: [ADR-<NNNN>](<path>) (§ <section>, when only part)   ← only when it does

## Context

What forced a decision now. The facts, with evidence: files, commits, measurements,
tickets. What happens if nothing is decided.

## Decision

What was chosen, in plain terms. What is now true that was not before.

## Alternatives considered

- **<option>**: what it would have cost, and why it lost.
- **<option>**: what it would have cost, and why it lost.

## Consequences

- What gets easier.
- What gets harder, or is now ruled out.
- What has to change: migrations, removed code, docs, permissions.
````

## Rules

- **Proposed until the user accepts it.** You draft ADRs; the user makes them
  accepted.
- **Never edit an accepted ADR's decision.** Supersede it: write a new one, and mark
  the old one `superseded by` with a link forward. Fixing a typo or a broken link is
  fine.
- **Supersede only what changed.** When a new decision replaces one section of an
  old ADR, mark the old one `superseded in part`, name the section, and the rest of
  it stays active.
- **Existing ADRs keep their own wording.** A status this page does not define
  ("accepted for planning; implementation deferred") is read as written. If it
  matters to the plan whether that ADR is active, ask.
- **The active set never disagrees with itself.** If two active decisions conflict,
  that is a reconcile finding, and one of them gets superseded.
