# Plan doc

The single source of truth for **what is in, what is out, what order it happens
in, and what must stay true while it happens.** Keep it short enough to reread in
one sitting. A plan nobody rereads stops being true without anyone noticing.

**It is the hub.** Every planning record in the repo is reachable from it in one
link: each ADR, intent, spec, the glossary, and every open ticket for this project.
Anyone, person or agent, who reads only this file knows where everything lives and
what they must not break.

It links to tickets, ADRs and feature docs; it never repeats their bodies. A copied
body is a second source of truth, and it drifts. If the repo already keeps part of
this elsewhere (a declines list in the agent instructions, a decision log), link
that file instead of copying it.

````markdown
# Plan: <project>

Source of truth for scope, order, decisions and rules. Tickets hold the detail.
Read this before starting work. If work conflicts with it, stop and say so.
Last reconciled: <YYYY-MM-DD> at `<short sha>` on `<base branch>`.
Verify: `<the repo's verify command>`

## Now

Active phase: **<n> — <outcome>**
Next unblocked: <ticket ref> — <title>

## Phases

### 1 — <outcome, one sentence> · complete <YYYY-MM-DD> at `<sha>`

<ticket ref>, <ticket ref>, <ticket ref>

### 2 — <outcome, one sentence> · active

Exit when:
- every ticket below is closed and its change is on `<base branch>`;
- `<verify command>` passes on `<base branch>`;
- <this phase's own outcome check: a named test, command or manual step>.

1. <ticket ref> — <title>
2. [<feature>](docs/features/<slug>/intent.md): <ticket ref>, <ticket ref> · after 1
3. <ticket ref> — <title> · after 1 · can run alongside 2

### 3 — <outcome, one sentence>

Work: [<feature>](docs/features/<slug>/intent.md), <one-line item>
Open decisions:
- <decision that must be settled before this phase gets tickets>

## In scope

- <capability> — <shipped | active | planned> — <evidence or ticket ref>

## Out

- <thing> — declined <YYYY-MM-DD>: <reason>. Bringing it back needs a new decision.

## Later

- <thing> — deferred <YYYY-MM-DD>: <reason>. Comes back when <condition>.

## Decisions

- [ADR-<nnnn>](<path>) — <decision as a sentence>. Rules out: <what it forbids, in a few words>

Superseded ADRs are not listed here; they link forward to what replaced them.

## Rules

- <what must stay true, as a sentence> — <where it holds: path, test or command> — <why: ADR, intent, or reason>
- <rule the code doesn't keep yet> — <where it will hold> — <why> · not yet: <ticket ref>

## Records

Glossary: [<file>](<path>)
Feature docs: `docs/features/`. Each live intent is linked from In scope or a phase.

## Rework

- <YYYY-MM-DD> <ticket ref> → <follow-up ref>: <cause> <→ where the lesson went, once it has gone somewhere>
````

## Rules for keeping it

- **Items come before tickets.** When a phase is first written, its items are
  listed by name. Ticket references are added once the tickets are filed.
- **Only the active phase lists tickets.** Future phases carry an outcome and their
  open decisions. Complete phases shrink to a line of ticket refs.
- **Order lines say "after", not "blocked by".** A line starting "blocked by" can
  be read as a real blocker by tools that parse text. The tracker holds the real
  blockers.
- **Out and Later are not the same.** Out records a *no* so it does not quietly
  return. Later records a *not yet* and what would change that.
- **The hub links everything, and copies nothing.** A new ADR gets a Decisions
  line, a new intent or spec is linked from its In-scope line or phase, and a new
  open ticket for this project appears in a phase. A record nothing here links is
  drift waiting to happen.
- **The hub changes in the same step as the record.** Writing or changing an ADR,
  intent, spec, glossary entry or ticket includes its line here, in the same
  approved change. The work isn't done until the hub says so.
- **A Decisions line says what it rules out.** That half is what an agent mid-ticket
  needs: "Rules out: a sync server" catches the conflict without opening the ADR.
- **Rules are only what must stay true and can be checked.** Each names where it
  holds (a path, a test, a command) and why (an ADR, an intent, or a one-line
  reason). Style preferences and wishes aren't rules. A rule with nothing to check
  it against belongs in an ADR's Consequences, not here.
- **A rule the code doesn't keep yet says so.** `not yet: <ticket>` names the work
  that makes it true. Until then `check` treats it as planned, not as broken.
  Reconcile drops the marker once that ticket's change is on the base branch and
  the rule holds.
- **Hand edits are allowed, and are checked.** Anyone can edit this file. Edits made
  outside a reconcile don't move the stamp, and `/roadmap check` checks every edit
  since the stamp the next time it runs.
- **Every In-scope line points at something**: a file, a test, a ticket. A line
  with nothing behind it is a wish, and belongs under Later.
- **The stamp moves only after a full check against the code**: the baseline that
  created the plan, or a reconcile. Editing the plan without that check does not
  earn a new stamp.
- **The Rework log is how the plan learns.** Reconcile adds a line for each ticket
  that needed a follow-up fix. A cause that appears twice becomes a proposed line in
  the repo's agent instructions or the ticket checklist, and the log says where it
  went.
- **Other planning files point here.** A feature list, phase list or README section
  that describes scope either links to this file or is kept in agreement with it
  on every reconcile. Which of those it is was the user's call.
