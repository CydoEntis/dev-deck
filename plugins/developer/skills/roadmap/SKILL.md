---
name: roadmap
description: Plans software work at any size and keeps the plan true. The bug, feature, change and task commands (or add, to have the type worked out) plan one piece of work — overlap check, questions until nothing is open, an intent and spec where needed, placement in the plan, and small tickets an unattended agent can finish. init (once per project) audits the repo, settles keep / merge / decline / defer, records costly decisions as ADRs, and writes one plan doc with ordered phases, of which only the active one gets tickets. reconcile checks the plan against code, history and tracker. check is a fast read-only look at whether current work breaks the plan. Triggers on "/roadmap", "$roadmap", "/roadmap bug", "/roadmap feature", "/roadmap change", "/roadmap task", "/roadmap check", "does this break the plan", "plan this feature", "I want to build X", "make tickets for", "break this down", "grill me", "interview me", "plan the project", "what's left for MVP", "what phase are we in", "the plan is stale".
---

# Roadmap

Planning answers three questions: **what is in, what is out, and what order it
happens in.** This skill answers them, for anything from one bug to a whole
project. It keeps the answer true against the code, and turns only the next step
into tickets.

Claude Code calls it with `/roadmap`; Codex calls the same skill with `$roadmap`.

## Why this exists

One repository removed a feature's controls from its app. The next day its feature
list still marked the feature `done`, a new ticket asked an agent to "finish" it,
and an older ticket said it must never come back. Each document was right the day
it was written. **Plans rot because nothing re-reads them against the code, and
work gets sliced several ways because starting it costs nothing.** So: every piece
of work goes through one plan, every claim carries evidence, and a reconcile pass
treats the plan as a claim to be checked.

## Modes

**The rule: no plan yet → `init`. Want something built → name its type, or `add`
if you're not sure. Is the plan still true → `reconcile`. About to start or ship
some work → `check`.**

```
/roadmap bug <thing>       something broke
/roadmap feature <thing>   something new
/roadmap change <thing>    works as designed, want it different
/roadmap task <thing>      no user-visible change (refactor, deps, docs)
/roadmap add <thing>       not sure which: the type gets worked out

/roadmap init              once per project: create the plan
/roadmap reconcile         is the plan still true? did a phase finish?
/roadmap check [target]    quick: does this work break the plan?
```

Any size works with the first five. A single broken behaviour is usually a few
small tickets; a large new capability usually becomes a new phase.

| | |
|---|---|
| **`init`** | Creates the project's plan: a baseline, keep / merge / decline / defer, phases with exit conditions, and tickets for the first phase. **Runs once per project.** Once a plan exists, new work of any size goes through `add`, never through `init` again. → read `init.md` |
| **`bug`, `feature`, `change`, `task`, `add` + `<thing>`** | Plan one piece of work into the project: overlap check, type and size, an intent (and a spec when design is involved), placement, tickets. All five run the same method. The first four name the type; `add` has it worked out. Work bigger than a phase becomes one or more new phases in the plan (in a repo with no plan, it starts `init`). → read `add.md` |
| **`reconcile`** | Checks the plan against the code, history and tracker, resolves every mismatch, reviews rework, and, when a phase has finished, opens the next one. → read `reconcile.md` |
| **`check` + `[target]`** | A read-only look, in seconds, at whether one ticket, branch or described change breaks the plan: a decision, a rule, the Out list, the phase order. Writes nothing; names the command that fixes each conflict. Safe for an unattended agent to run before a ticket. → read `check.md` |

**Read the matching file in this skill's directory and follow it.** This page holds
the rules every mode shares; the method is in the file. Below, **`add` stands for
all five work commands**.

When no command was named, apply the rule: the message describes something to
build, change or fix → `add`; otherwise, the repo has a plan (see "The planning
set") → `reconcile`; otherwise → `init`. Say which you picked in one line.

**There is never a second plan for one project.** `init` in a repo that already has
a plan switches to `reconcile`, even when that plan is vague or badly out of date.

## What this skill owns

**Owns:** scope (in / out / later), phase order and exit conditions, intents and
specs, ADRs, the rules the code must keep, the glossary, tickets for the active
phase, and the plan section of the repo's agent instructions (offered, never
required).

**Does not own:** implementation, running tickets, or grading finished work. You end
at "the plan and the tickets exist." **Never write code**, not even a stub or a spike.

## Shared rules

### Facts are your job. Decisions are the user's.

When a question needs a fact (what the code does, whether a thing is wired up, what
shipped last week), go and find it. **Never ask the user something you could look
up.** If the session can run subagents, use them for broad sweeps and keep their
conclusions, not their file dumps; otherwise sweep one area at a time. A running
lookup only holds back the questions that depend on it.

What the product should be belongs to the user: keep, merge, decline, defer, phase
order, anything expensive to reverse. Always bring a recommendation. Never settle
one yourself because the answer seemed obvious.

### Stay on the path

Every run has a **path**:

- **`add`**: the one piece of work the user named.
- **`init`**: the project's goal (what the user asked for, or else the purpose the
  README and agent instructions state) and what already exists.
- **`reconcile`**: what the planning set claims, and what changed since it was last
  checked.
- **`check`**: the one target named, against the plan.

Everything you read, ask, write and propose serves that path, and nothing else. Any
codebase is full of things that could be better. Noticing them is cheap; chasing
them is how a plan sprawls.

**The test:** would this change a ticket for the path's work, the plan, or a
decision the user is making in this run? If not, it's off the path.

- **Read for the path.** Inspect what the work touches and what it depends on. A
  broad sweep in `init` or `reconcile` maps what exists; it doesn't audit code
  quality.
- **Propose only on the path.** No refactors, upgrades, clean-ups, new features or
  "while we're here" ideas that the user didn't bring and the path doesn't need.
- **Never act off the path.** Don't fix, edit, migrate, file, or reconfigure anything
  because you noticed it.
- **Brief every subagent the same way.** A sweep prompt names the path, and says to
  report facts that bear on it and suggest nothing.
- **Serving the request is on the path**, even when it touches something else. If
  the requested action can't be reached because a button is hidden, showing the
  button is one of the options. The same hidden button, raised for its own sake, is
  not.
- **A contradiction in something this work relies on is on the path.** A design
  source the spec has to cite, or a doc a ticket has to update, becomes a spec
  Concern or a question.
- **Off-path findings stay out**, with one exception: something that would break the
  planned work (the plan's tickets and the tickets being drafted), or that puts
  users' data or security at risk. Breaking the planned work includes an executor
  that would run tickets out of order, skip them, or wait forever. The exception
  gets one line under **Noticed, not pursued** in the handoff, saying what and
  where, with evidence, and no recommendation.

### Every claim about the present carries its evidence

A statement about how things are now cites where you saw it: `path:line`, a command
and what it printed, a commit, or a ticket. Anything unverified is labelled
**assumption**. A stale plan, a closed ticket, a generated file and a superseded ADR
are evidence of what someone once intended, not current requirements. Findings that
matter to the work but need no decision now (two verify commands that disagree,
say) go under **Open** in the handoff.

### The repo's own planning rules come first

A repo may document its own planning contract: how far ahead it tickets, which label
approves work, how phases gate, how commits are made. Following it is never a
mismatch. Where it clearly differs from a default here (ticketing a whole serial
chain at once, say), follow it without asking. Ask only when the repo's rule is
unclear or its files disagree, and record the answer where the repo keeps its
planning rules.

### How to ask

**Every step is interactive.** Decisions, confirmations and approvals all go to the
user as questions, through the session's question pop-up whenever it has one. Plain
text is the fallback. Which tool each session has, its limits, and the plain-text
format are in [references/asking.md](references/asking.md).

The method comes from Matt Pocock's grilling skills
(https://github.com/mattpocock/skills). The link is credit only; everything you need
is here.

Map the decisions as a tree: each decision branches into the ones that depend on it.
The **frontier** is every open decision whose prerequisites are settled.

- **Default: rounds.** Ask the whole frontier at once, then wait. A question whose
  answer depends on another question in the same round waits for the next round.
- **"One at a time"**: if the user asks for it, ask one frontier question per turn,
  in dependency order, until they say otherwise.
- **Recommend first.** The recommended option comes first, labelled
  "(Recommended)", with its reason. The other options are the real alternatives,
  each with what it costs. Never add filler options.
- **Context above, question in the tool.** Evidence, tables and drafts go in your
  message before the question. The question itself stays short.
- **Answers in the user's own words** (a problem statement, the steps that reproduce
  a bug) are asked in plain text, one at a time, with an example of the kind of
  answer you need. If a doc in the repo already states the answer, quote it, and
  ask the user to confirm it instead.

**Make it concrete.** When a decision is about behaviour, test it with a specific
scenario at its edge ("a user with no tags opens the filter; what do they see?").
**Check the code.** When the user says how something works and the code disagrees,
show them the evidence. **Check the words** (see "Glossary").

Ask only questions whose answer changes what gets built. Stop when nothing left to
ask would change the plan or a ticket.

### Show before you write

Drafting is free. Writing is not. **Show every document change and every ticket
before creating it, and wait for approval.** That covers the plan doc, intents,
specs, ADRs, glossary entries, tickets and tracker changes.

- **New files and new tickets** are approved as a batch: one question with Approve,
  Change something, and Not yet.
- **Changes to existing records** (editing, closing, reopening, relabelling or
  retitling a ticket; creating a label the tracker doesn't have yet) are approved
  one item at a time, never as "clean up the tracker". Use several questions when
  there are more items than one question can hold.
- **Never delete, merge or rename an existing planning document** without explicit
  approval.

**Filing includes its bookkeeping.** Writing the new ticket references into docs you
already showed (the plan, the intent, the spec's Coverage) is part of the approved
change, and needs no second approval. Say in the handoff that you did it.

**Before writing, look again.** Re-read each file you are about to change, and check
`git status`. If a file changed since you read it, someone else is working here: read
it again, fold your change into the new content, and show it again. Write only the
files you showed.

**Writing files is not committing them.** When the run ends, offer the commit if the
repo's rules allow one (right branch, right message format). Make it only if the user
says yes, and stage only the files you wrote, by name.

**Codex Plan mode can't write.** It allows reading and exploring, but no file edits
and no filing. Do the questioning and approvals there, then show the final drafts
and ask the user to leave Plan mode so you can write and file what they approved.

### Every record lands on the hub in the same step

The plan doc is the hub (see [references/plan-doc.md](references/plan-doc.md)): every
ADR, intent, spec, glossary and open ticket for the project is linked from it, and
none is copied into it. **Drift starts in the gap between writing a record and
updating the hub**, so there is no gap:

- Any run that writes or changes one of those records shows the matching hub line
  in the **same** approval, and writes both together. A new ADR comes with its
  Decisions line (including what it rules out); a superseded one comes with its line
  removed. A new intent or spec comes with its link. A filed ticket comes with its
  place in a phase. A closed or reworded ticket comes with any line that named it.
- A decision that leaves something that must stay true, and that a path, test or
  command can show, comes with a **Rules** line.
- **A hub line is a claim, so check it before showing it.** Run a new Rules line's
  check against the base branch. If the code already breaks it, show the evidence
  and let the user pick: mark it `not yet: <ticket>` with the ticket that makes it
  true, or drop it. Never write a rule as holding when it doesn't. Check a new
  Decisions line's "Rules out" against the open tickets and the In-scope lines, and
  show any that it would contradict in the same approval.
- With no plan doc, the same applies to each file in the set that holds scope or
  order.

A run is not finished while a record it touched is missing from the hub. Writing
the hub lines doesn't move the stamp; only a full check against the code does.

### Only the active phase has tickets

Later phases get an outcome and a list of open decisions. A ticket written two
phases early describes code that will be different by the time anyone picks it up,
and it makes starting work look cheaper than it is. (A repo's own contract can say
otherwise; see above.)

### Tickets are always small

Planned work always ends as **small, easy-to-finish tickets**, never one big ticket,
however the work started. A big ticket is where an unattended agent runs out of
time, a reviewer skims, and a failure throws away the most work. Many small tickets
with blockers between them beat a few big ones. The size check is in
[references/ticket.md](references/ticket.md); when in doubt, split.

Grouping belongs in the plan doc and the intent, or in the tracker's own grouping (a
project, milestone, parent issue or module). Never group by merging tickets.

### No open question reaches a ticket

An open question ends one of three ways, and the user picks:

- **Answered**: it becomes scope, a constraint, a requirement, or an ADR.
- **Deferred**: it goes under Later, with what would bring it back.
- **Split**: it becomes its own intent or phase, and the plan records what waits on it.

A ticket may carry a **stated assumption**, never a gap.

## Repo facts every run needs

Settle these first, and state each one with where it came from. (`check` needs only
the base branch.)

**Base branch**, in order of preference: the plan doc's stamp; the config of any tool
that works tickets or runs CI (a `base` field, a workflow's target branch); agent
instructions; `origin/HEAD`.

**Which code to read.** The base branch as it is on the remote. Compare the local
branch with the remote (`git ls-remote`, or after a `git fetch`, which is fine). If
they differ, read the remote version (`git show origin/<base>:<path>`), or say which
one you read and why. Files that exist only locally on purpose (a tool config the
repo ignores or excludes from git) are read from the working tree.

**Verify command**, in order of preference: the plan doc's `Verify:` line; the config
of any tool that works tickets; agent instructions (`AGENTS.md`, `CLAUDE.md`); the CI
workflow; package scripts or `Makefile`. If these disagree, that is a finding for the
handoff.

**Running it** (`init` and `reconcile` only), against the remote base commit:

- The user's checkout is on that commit and clean → run it there.
- Otherwise → `git worktree add --detach <scratch dir> origin/<base>`, run it there,
  and remove the worktree afterwards. **Never switch, stash or reset the user's
  checkout.**
- Dependencies are missing → ask before installing them.
- Cap it: `timeout 600 <command>`. If it needs services you cannot start, or hits the
  cap, report it as **not run** (or **timed out**) and say why. Never guess its result.
- In Codex Plan mode, run it only in the user's checkout, and only when that is on
  the base commit and clean (Plan mode allows builds that write only caches and build
  output). Otherwise report it as **not run** until the user leaves Plan mode.

**CI on the base branch** (every mode): if the repo's CI runs on pushes to the base
branch and this session can read it, check the latest *completed* run there. Say if
it is red. If CI only runs on pull requests, or there is no CI, say "not checked"
and why.

**Where tickets live.** Work this out now (see "Find out how tickets are filed
here"), so the overlap check can search the right place. Confirm it with the user
only when it's time to draft tickets.

## The planning set

**The planning set** is everything in the repo that states scope or order: plan and
roadmap files, feature lists, phase lists, planning contracts, decision logs,
"what this does not do" lists, README sections about scope, feature docs, the
glossary, the ADR folder, and the tickets any of these link to. Find it by reading
the agent instructions and `README`, then checking for `ROADMAP.md`, `PLANNING.md`,
`PLAN.md`, `FEATURES.md`, `BACKLOG.md` and `CONTEXT.md` (at the root and under
`docs/`), plus `docs/features/`.

**A plan** is a file in the set that sets **order**: phases, milestones, or an ordered
list of work. Scope-only files (a declines list, a decision log) are not a plan.
**The repo has a plan** when at least one file sets order.

**The plan doc** is the file that is declared the source of truth for scope and order
(and, once it has them, decisions and rules),
by its own text or by the agent instructions. A file name alone doesn't make one: a
`PLANNING.md` that only describes how to write tickets is a contract, not the plan
doc.

- **A plan doc exists** → it is the plan.
- **The repo has a plan but no plan doc** (order in one file, scope in another, or
  several files claiming to be the source) → treat the whole set as the plan. Each
  file keeps the part it already holds. Choosing one source of truth is
  `reconcile`'s question; `add` mentions it once and moves on. **Propose; never merge
  files yourself.**
- **No plan** → `init` creates the plan doc where the repo already keeps planning
  docs, or else at `docs/PLANNING.md`, and links the scope-only files instead of copying them. `add`
  works without one.

**The active phase** is the phase the plan marks active. If none is marked, it is the
phase holding the work already in progress (open pull requests, started tickets). If
nothing is in progress, it is the phase holding the lowest-ordered open ticket, and
failing that, the first unfinished phase. Unless it is marked, label it an
assumption, and confirm it with the user before anything is written or filed on the
strength of it. If work in progress spans several phases, pick the lowest of them and
say so.

**Tickets live in the tracker; everything else lives in the repo.** The docs link to
tickets and never copy their bodies.

Shape: [references/plan-doc.md](references/plan-doc.md).

## Feature docs

Work that needs questioning gets a folder: `docs/features/<slug>/`, or the repo's
existing convention for this.

- **`intent.md`** says why the work exists and what is true once it's done, in the
  requester's own words (or a repo doc's words the requester confirmed). It is
  required for every piece of work that reaches the intent step. Shape:
  [references/intent.md](references/intent.md).
- **`spec.md`** covers requirements and design, with concerns listed first. It is only
  for work whose decisions the tickets can't hold on their own (see `add.md` step 3).
  Shape: [references/spec.md](references/spec.md). Without a spec, concerns such as
  security go in the intent's Constraints and in each affected ticket's Impact.

There is no separate implementation plan. **The ordered tickets are the plan**, and
they are what an unattended executor reads.

Both docs are `draft` until the user accepts them. Once tickets exist, a change to
either doc is a planning change: update the affected tickets in the same pass, and
say so. There is one live intent per piece of work; replacing one marks the old one
superseded.

## Glossary

`CONTEXT.md` (or the repo's existing glossary) holds the project's words and what
they mean, and nothing else: no implementation details, and no decisions (those go
in ADRs). A README section that defines the domain's terms counts as the glossary.

- If there is one, read it before asking anything, and hold every question and doc
  to its terms.
- **Settle a term only when the confusion would change what gets built, or how a
  ticket reads.** Two names for the same thing in old docs is a doc fix, not a
  question.
- When a term is settled, show the entry, and add it once approved, straight away
  rather than at the end.
- With no glossary, offer to create one the first time a term needs settling. If the
  user declines, record the term in the intent's Constraints instead. Never create an
  empty glossary.

## ADRs

Offer an ADR only when **all three** hold:

1. **Hard to reverse**: changing course later costs real work (a data model, a
   storage or sync strategy, a permission boundary, removing a subsystem).
2. **Surprising without context**: a future reader would ask "why this way?"
3. **A real trade-off**: there were genuine alternatives, and one was picked for
   specific reasons.

Use the repo's ADR folder and numbering; with none, use `docs/adr/NNNN-slug.md`.
**The active set** is every accepted ADR, minus any part a later ADR superseded, and
it never contains two decisions that disagree. Always read the whole ADR folder, not
only the ADRs something links.

Shape and supersession rules: [references/adr.md](references/adr.md).

## Tickets

Every mode ends the same way: confirm how tickets are filed, draft them against
[references/ticket.md](references/ticket.md), show them, get approval, file them,
and prove it.

**This skill assumes no tracker and no way of working.** Every team and every person
files tickets differently. Find out how this one does, confirm it, and follow it.
When you can't tell, hand the tickets over instead of guessing.

### Find out how tickets are filed here

Keep the evidence for each answer.

- **Where they go** (tracker, project or team, labels, assignee, starting state):
  1. what the user said in this conversation;
  2. what the repo shows: agent instructions, contributing and planning docs; issue
     and pull request templates; how commits, branches and pull requests name
     tickets (`#123`, `APP-123`); and the config of any tool that pulls tickets to
     work on, whose filter shows the tracker, the project, and the labels that mean
     "ready".
- **How to reach it**: a skill or command for that tracker, a connector (MCP server)
  for it, or its CLI, in whatever this session has. A tool that happens to be
  connected doesn't decide where tickets go; the repo does.
- **What they look like**: templates in the repo, templates kept in the tracker
  itself, and the shape of recent tickets for this repo.

**Confirm before drafting**, with a question: "File these in <where>, using <how>?"
Offer what you found, any other candidates, and **"Just give me the tickets."**

### Follow what you found

- **The method.** If a skill, command or tool handles filing, use it rather than
  calling the tracker yourself.
- **The shape.** The body template, required fields, labels, assignee, starting
  state, and how blockers are recorded all come from what you found, and they win
  over `references/ticket.md` where they differ. If two of the repo's own templates
  conflict, ask which one applies.
- **What picks them up.** If something pulls tickets to work on, make each ticket
  match its filter, including any label that means "approved for an agent" (the user
  approving the drafts is that approval). Use the blocker form it reads, and name
  only blockers it can see or a person will close; otherwise the ticket waits
  forever. Respect any limit it documents.
- **Work only a person can do** (a check on a real device, an account change) is
  still planned: as a step in a phase's exit condition, or as a ticket marked for a
  person and kept out of any executor's filter.
- **Task folders.** If the executor reads tickets from a folder as its source (not a
  local cache it fills from a tracker), write them there in the format its docs give.
- **Blocker references.** Tickets are filed in order, so a blocker can name a ticket
  filed a moment earlier. Filling in those references doesn't need another approval.

Never assume a tracker's API or fields from memory.

### When you can't file

If nothing tells you how, the user doesn't say, or this session lacks what the method
needs (a connector this tool doesn't have, a missing key), say exactly that. Then hand
over the approved tickets: in order, ready to paste, each with its title, labels and
blockers written out.

**Remembering the answer is the user's call.** If you had to ask how tickets are
filed, offer to note it for next time wherever the user keeps such notes, or nowhere.
Don't create a file for it unasked.

### Prove it

After filing, read each ticket back the same way it was filed, and check that:

- title, labels and blockers are what was approved;
- the body kept its line breaks (a body saved with literal `\n` is one line, and
  anything that reads blockers line by line won't see them);
- whatever pulls tickets would pick it up. Run the read-only query from its config,
  or an equivalent one. **Never run an executor's own command to check**: a "pull"
  that imports tickets writes files and may disturb a live run.

Fix anything that fails before reporting done. Then write each ticket's reference
back: into the plan doc's active phase (or, with no plan doc, into each file that
holds order), and into the intent's **Tickets** line.

## What stays and what goes

**Kept in the repo, on purpose.** These are the plan's record. Tickets link to them,
and `reconcile` checks them later. They are never deleted as cleanup; they change
status instead (`done`, `superseded`).

- the plan doc;
- `docs/features/<slug>/intent.md` and `spec.md`;
- ADRs;
- the glossary.

**Kept in the tracker.** The tickets. Drafts live in the conversation until they are
approved; they are never written to repo files (except where an executor reads a
task folder as its source).

**Temporary, and removed before the handoff.** Anything made only to do the work: a
worktree for running the verify command, a scratch file, a log. Put these outside
the repo, and delete them when you're done.

The handoff lists every file written, so the user can see exactly what changed.

## Handoff

End every run with:

1. **State**: the active phase, and whether its exit condition holds. With no plan,
   say so.
2. **Decided**: each decision made this run, and where it is recorded.
3. **Changed**: files written, and tracker records created or edited. Say whether
   the files are committed.
4. **Next**: the next unblocked ticket, and what blocks the rest.
5. **Open**: anything deferred, split off or not approved; findings that need no
   decision now; and risks to this work you saw but did not resolve.
6. **Noticed, not pursued**: only if something off the path met the exception in
   "Stay on the path". One line each, with no recommendation.

Keep it short. The plan doc is the record; the handoff points at it.
