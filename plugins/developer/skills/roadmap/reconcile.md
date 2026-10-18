# Roadmap: reconcile

You check an existing plan against the code, the history and the tracker. You fix
whatever disagrees, and when the active phase is finished, you close it and write
tickets for the next one.

**Read `SKILL.md` first.** Its shared rules, "Repo facts every run needs" and "The
planning set" all apply below.

No plan (no file in the planning set sets order) → switch to `init.md`, and say so.

```
1  Load     the planning set, and what changed since it was last checked
2  Check    every claim in it, and the rework since       facts: yours
3  Decide   the mismatches that need a judgement          decisions: theirs
4  Apply    approved edits, one tracker change at a time, then the stamp
5  Phase    close the active phase if its exit holds, then open the next
```

Run it after a phase's last ticket merges, before planning new work in a repo that
already has a plan, and whenever someone suspects the plan is wrong.

---

## 1 — Load

Settle the repo facts, and run the verify command (see "Repo facts every run
needs" in `SKILL.md`).

Read the **whole planning set**: every file in it, every ADR in the ADR folder, and
every ticket any of them links. For each linked ticket, record its state and whether
its change is on the base branch: find the merged pull request that closes it (the
ticket or the code host shows the link), and check that its merge commit is on the
base (`git merge-base --is-ancestor <commit> origin/<base>`).

Then collect the **open tickets for this project**, from wherever "Where tickets
live" pointed: the project, milestone or label the plan uses. If the tracker has no
such grouping, that means every open ticket for this repo. List any that no file in
the set links. If this session can't reach the tracker, say which checks that
leaves undone.

**What changed, and since when.** The plan doc's stamp says when it was last
reconciled (see [references/plan-doc.md](references/plan-doc.md)).

- **Stamp present.** `git log <stamp>..<base>` and the pull requests merged in that
  range are what to explain. Claims are still checked against the base branch as it
  is now.
- **No stamp, or no plan doc yet.** Nothing has ever been reconciled. Check **every**
  claim against the base branch as it is now. Use history only to explain what you
  find, going back as far as the oldest file in the set.

**Rework.** For each ticket closed since the stamp (or, with no stamp, in the active
phase), look for follow-up fixes: pull requests or `fix` commits that landed after
it merged, touch the same files, and either mention the ticket or fix what it
built. For each, work out the cause from the diff and the ticket:

- **a planning gap**: the ticket missed a fact, a decision, an edge case, or a
  check;
- **an execution slip**: the ticket was right, and the work didn't follow it;
- **outside change**: something else moved underneath it.

**The active phase** is found as "The planning set" in `SKILL.md` describes. If the
plan doesn't mark it, label your pick an **assumption**. Steps 1 and 2 may use it;
mark any finding that depends on it, and confirm it in the first round of step 3.

## 2 — Check

Every statement the planning set makes about the present is a claim. Check each one,
and look for these mismatches in particular:

| Mismatch | What it looks like |
|---|---|
| **Done, still open** | The ticket is open, but its change is on the base branch. |
| **Closed, not done** | The ticket is closed, but its pull request never merged, or its acceptance criteria do not hold on the base branch. |
| **Planned, but removed** | The set calls something in scope or done; a later commit removed it or left it unreachable. |
| **Shipped, but unplanned** | A change landed that no phase or ticket mentions. Scope moved without a decision. |
| **Docs disagree** | Two files in the set, or a file and the code, tell different stories. Includes files that name different sources of truth. |
| **Tickets disagree** | Two open tickets require opposite things, or duplicate each other. |
| **Stale decision** | The code no longer follows an active ADR, or two active decisions conflict. |
| **Contradicts a decision** | An open ticket asks for something an active ADR ruled out or replaced. |
| **Order broken** | A ticket merged before its blocker; a blocker the executor can never see, so the ticket waits forever; tickets for a phase that is not active (unless the repo's contract allows it). |
| **Orphan ticket** | An open ticket for this project that no file in the set links. |
| **Not on the hub** | An ADR, intent, spec or glossary that the plan doc doesn't link; a Decisions line missing what its ADR rules out; a superseded ADR still listed. |
| **Rule broken** | A line under Rules no longer holds on the base branch: the path, test or command it names shows otherwise. A `not yet: <ticket>` rule is broken only once that ticket's change is on the base branch; if it holds by then, drop the marker. |
| **Agents not pointed** | The agent instructions (`AGENTS.md`, `CLAUDE.md`) don't point at the plan doc, point at the wrong file, or the two disagree. Only a finding if the user accepted the section before; otherwise offer it once (see [references/agent-instructions.md](references/agent-instructions.md)). |
| **Feature drift** | An intent or spec changed after its tickets were filed, but the tickets didn't; a spec requirement no ticket covers; an accepted intent whose tickets have all closed but which isn't marked done. |
| **Red base** | The verify command fails on the base branch. |

Present one table, **ranked by how likely each mismatch is to make someone build the
wrong thing** — worst first:

| # | Mismatch | The set says | Reality | Evidence | Proposed fix |
|---|---|---|---|---|---|
| 1 | Planned, but removed | Reminders `done` (`docs/FEATURES.md:12`); #41 "finish reminders" | controls removed; panel unreachable | `a1b2c3d` "remove reminder controls"; `rg ReminderPanel src` finds no import outside its folder | ask: was removal intended? |
| 2 | Orphan ticket | — (silent) | #47 open and approved for the executor | no file in the set mentions #47 | ask: add to phase, or unapprove |
| 3 | Done, still open | #38 open | change is on `main` | PR #44 closes #38; its merge commit is an ancestor of `main` | close #38 |

**These aren't mismatches**: code quality, style, dependency age, test gaps, or
refactor opportunities. The plan never claimed anything about them. A reconcile
checks the plan, not the codebase.

Use `— (silent)` when the set says nothing. A mismatch with no evidence is not a
mismatch yet: get the evidence, or leave it out.

Then present the rework, separately:

| Ticket | Follow-up | Cause | Lesson |
|---|---|---|---|
| #31 | #35 `fix(export): keep empty tags` | planning gap: the empty case was never asked | ticket checklist already covers it; the question was skipped |
| #33 | `9f8e7d6` `fix(search): debounce input` | planning gap: no performance target | **second time** (see Rework log, #22): propose an AGENTS.md line |

**A cause that shows up twice**, in this table or in the plan doc's Rework log,
becomes a proposal: one line for the repo's agent instructions (for execution
slips) or for how tickets are written here (for planning gaps). Once, it is a note.
Twice, it is a pattern.

If nothing disagrees and there is no rework, say so in one line and go to step 4 for
the stamp.

## 3 — Decide

Split the table in two.

- **Mechanical.** One right answer: close a ticket whose change has merged; close a
  ticket that contradicts an active ADR (cite the ADR); fix a broken link; add a
  missing hub link; update a status the evidence settles. These need approval, not a question.
- **Judgement.** The fix depends on what the user wants. Was the rule broken on
  purpose (change the rule) or by mistake (a ticket)? Was the removal intended?
  Does the unplanned change belong in this phase, or come back out? Is the stale ADR
  superseded, or is the code fixed?

Ask the judgement items in rounds (see "How to ask" in `SKILL.md`). **When there is
no plan doc yet, "which file is the source of truth" goes in the first round**, and
any question whose fix depends on that answer waits for the next one. **Confirming an
assumed active phase also goes in the first round**, and findings that depend on it
wait for the answer.

A removal that was intended becomes **decline** in the plan doc, with its date and
reason; if it removes a subsystem with stored data, it also needs an ADR. A removal
that was a regression becomes a ticket in the active phase.

## 4 — Apply

Show the full set of changes, then apply what was approved:

- **Plan doc and ADR edits.** Superseding an ADR means a new ADR, with the old one
  marked superseded (in whole or in part) and linking forward.
- **Tracker changes, one item at a time.** Each is approved on its own. Anything not
  approved goes in the handoff for the user to do.
- **Other files in the set** shrink to a link to the plan doc, or get their wrong
  lines corrected, only as approved.
- **The Rework log** gets a line for each follow-up found, and any approved lesson
  goes where it was approved to go: the agent instructions or the plan doc.

**Then stamp the plan doc**: reconciled today, at the base commit you checked
against. The stamp is a document edit too, so it is shown with the rest. No plan doc
yet (the user has not picked one) → no stamp; say so in the handoff.

## 5 — Phase

Check the active phase's exit condition line by line, against the evidence from
steps 1 and 2.

**It does not hold.** Say exactly which line fails, and name the next unblocked
ticket. Stop.

**It holds.** Then:

1. **Close the phase.** Mark it complete in the plan doc, with the date and the
   commit it was verified at. Mark the phase's finished intents as done.
2. **Re-read the next phase against the code as it is now.** The finished phase
   changed things. Check that the next phase's outcome still makes sense and its open
   decisions are still open. Check later phases only for anything the finished phase
   made obsolete.
3. **Settle its open decisions** in rounds. A decision that stays open moves the
   phase back, or splits it. It never reaches a ticket.
4. **Mark it active**, with its exit condition, once the user confirms.
5. **Write its tickets** as `init.md` step 5 does: each item through `add.md`.

If there is no next phase, say the plan is complete, and ask whether to plan what
comes next (`/roadmap add` for each piece of work) or leave it there.

Finish with the handoff from `SKILL.md`.
