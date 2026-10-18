# Roadmap: check

A quick look, done while working: **does this work break anything the plan says?**
It is meant to take seconds, so run it before starting a ticket, before opening a
pull request, or whenever a change feels like it might cross a decision.

**Read `SKILL.md` first.** Its rules on evidence and staying on the path apply. This
mode is **read-only**: it writes no file, changes no ticket, and asks nothing until
the end. It works the same in Claude Code, in Codex (Plan mode included), and when
an unattended agent runs it before starting a ticket.

`check` is not `reconcile`. It reads the plan doc and only what the target touches.
It does not run the verify command, sweep the tracker, review rework, or move the
stamp. When it finds something only a full pass can settle, it says to run
`reconcile`.

```
1  Target   what is being checked
2  Load     the plan doc, and only the records the target touches
3  Check    the target against the plan
4  Report   Clear, or the conflicts with their evidence
```

---

## 1 — Target

Whatever the user named after `check`:

- **A ticket** (`#41`, `APP-41`): its title, body and acceptance criteria.
- **A branch, or nothing**: the current branch's changes against the base branch
  (`git diff origin/<base>...HEAD`), plus any uncommitted changes, plus the ticket
  the branch or its commits name, if any.
- **A description** ("I'm about to add offline mode"): that description.
- **`plan`**: only the plan doc's own edits (see below).

**Plan doc edits are always part of the target.** If the plan doc changed since its
stamp (`git diff <stamp> -- <plan doc>`, plus uncommitted changes to it), those
edits are checked too, whatever else was named. Hand edits are allowed; this is
where they get checked. With no stamp, there is no baseline to diff against: say so,
and suggest `/roadmap reconcile`.

Settle the base branch as `SKILL.md` describes, from the plan doc's stamp first.
Say what the target is in one line.

## 2 — Load

Read **the plan doc** in full. Then read only the records the target touches:

- the ADRs on its **Decisions** list whose subject the target touches;
- the **Rules** lines whose files or area the target touches;
- the intent and spec of the work the target belongs to, if any;
- the glossary, if the target names a term it defines;
- for plan doc edits: what each edited line names (the rule's path or test, the
  ADR, the ticket, the linked file), and nothing else.

Rules lines marked `not yet: <ticket>` are planned, not broken: the target only
conflicts with one if it works against it.

**No plan doc** → check against whichever files in the planning set hold scope and
order (see "The planning set" in `SKILL.md`), and say the check is weaker for it.
**No plan at all** → say so in one line, suggest `/roadmap init`, and stop.

## 3 — Check

Look for these, and only these:

| Finding | What it looks like |
|---|---|
| **Breaks a decision** | The target does what an active ADR ruled out, or undoes what it chose. |
| **Breaks a rule** | The target changes code so that a line under **Rules** no longer holds. |
| **Builds something Out** | The target builds or brings back something under **Out**. |
| **Not in the plan** | The target adds scope that no phase, In-scope line or ticket mentions. |
| **Wrong phase** | The target's ticket belongs to a phase that is not active. |
| **Not on the hub** | The target's ticket, intent, spec or ADR is not linked from the plan doc. |
| **Feature drift** | The target goes past, or falls short of, its intent's outcome or the spec's requirements. |
| **Edit doesn't hold** | A plan doc edit since the stamp claims something the evidence contradicts: a Rules line the code breaks (and isn't marked `not yet`), an Out item that an open ticket or In-scope line still builds, a Decisions line with no ADR behind it or one that disagrees with another, a ticket marked done whose change isn't on the base branch, or a link to a file that doesn't exist. |
| **Plan is stale** | The stamp is missing, or the files the target touches changed on the base branch since the stamp, in ways the plan doesn't mention. |

Every finding carries evidence: the plan doc's line, the ADR section, and the
target's `path:line` or ticket text that crosses it. **No evidence, no finding.**

These aren't findings: code quality, style, test gaps, naming, or anything else the
plan never claimed. `check` asks whether the work fits the plan, not whether the
code is good.

## 4 — Report

**Nothing found** → one line: `Clear: <target> fits the plan (stamp <sha>, <date>).`
If the stamp is old, add how many commits the base branch is past it.

**Something found** → one table, worst first (most likely to make someone build
the wrong thing):

| # | Finding | The plan says | The work does | Evidence | Next |
|---|---|---|---|---|---|
| 1 | Breaks a decision | ADR-0004: notes are stored locally only | adds a sync client | `docs/adr/0004-local-only.md` § Decision; `src/sync/client.ts:1` | stop: `/roadmap change` to revisit ADR-0004, or drop the sync client |
| 2 | Not on the hub | — (silent) | ticket #52 | plan doc's active phase lists #48–#51 only | `/roadmap reconcile` |

**Next** names exactly one route for each finding:

- the work is wrong → change the work (say what to drop or keep);
- the plan should change → `/roadmap change`, or `/roadmap add` for new scope;
- the plan's record is out of date → `/roadmap reconcile`;
- a plan doc edit doesn't hold → undo or correct the edit, or `/roadmap reconcile`
  if the code is what should change.

Then ask which way to go for each finding that needs a decision (see "How to ask"
in `SKILL.md`). Never pick for the user, and never fix anything here: the fix is
another command's job.

**Run by an unattended agent**, there is no one to ask. Report the table and stop
the ticket. Never resolve a conflict by picking a side.

No handoff: the report is the output.
