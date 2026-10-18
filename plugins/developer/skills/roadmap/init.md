# Roadmap: init

You create the plan for a project that doesn't have one: what is in, what is out,
and the phases in order. Then you write tickets for the first phase only (unless the
repo's planning contract says otherwise). This runs
once per project. Everything after it is a work command (`bug`, `feature`,
`change`, `task`, `add`) or `reconcile`.

**Read `SKILL.md` first.** The shared rules there (evidence, how to ask, show before
you write, only the active phase has tickets) apply to every step below.

```
0  Overlap   is this already planned?                    facts: yours
1  Baseline  what exists, what is verified, what clashes facts: yours
2  Decide    scope, keep/merge/decline/defer, ADRs       decisions: theirs
3  Phase     order the work, set each exit condition     draft, then approval
4  Write     plan doc and ADRs                           after approval
5  Ticket    the first phase only                        draft, approval, file
```

Skip a step only when it is already settled. Do not skip one because it is slow.

---

## 0 — Overlap

**Settle the repo facts first** (see "Repo facts every run needs" in `SKILL.md`;
running the verify command can wait for step 1). Then **check whether this is already
planned.** Look for:

- the planning set, and whether any file in it sets order (see "The planning set"
  in `SKILL.md`);
- open tickets, milestones or projects;
- open pull requests and recent branches.

Then say what you found, first thing:

- **The repo already has a plan** (some file sets order). Switch to `reconcile.md`,
  and say so.
- **Files state scope but nothing sets order** (a declines list, a decision log, a
  handoff note). That isn't a plan. Carry on: the plan you write links those files
  and leaves their content where it is.
- **Open tickets exist.** Say how many there are and how long they have sat. They
  become part of the baseline, and the disposition round decides their fate.
- **Nothing exists.** Say so in one line and go on.

Do not skip this because the user sounds sure. Work sliced several ways at once
usually happened because starting a new plan cost nothing.

## 1 — Baseline

With the repo facts settled in step 0, run the verify command (as `SKILL.md`
describes). Then read, in this order: the repo's agent instructions
(`AGENTS.md`, `CLAUDE.md`, and nested ones), `README`, product and design docs,
every ADR, the source tree and tests, `git log` on the base branch, and the
tracker.

For a repo of any size, split the sweep across subagents in parallel, if the
session can run them (otherwise do the same three passes yourself): one maps
capabilities, one hunts contradictions, one reads the docs and the tracker. Brief
each one on the path (see "Stay on the path" in `SKILL.md`): map what exists and
where it disagrees, and suggest nothing. Keep their conclusions and evidence, not
their file dumps.

The baseline describes what **is**. It isn't a code review. Style, dependency age,
test gaps and refactor ideas aren't part of it unless they bear on the goal.

**Run the verify command** as `SKILL.md` describes. A plan whose first phase assumes
a green base when the base is red starts with a lie.

Then present the baseline in three parts.

**Capabilities.** What the product does today, one row per user-facing capability:

| Capability | State | Evidence |
|---|---|---|
| Search | shipped | `src/search/index.ts:12`, covered by `search.test.ts` |
| Reminders | built, not wired | `src/reminders/panel.tsx` exists; `rg ReminderPanel src` finds no import outside tests |
| Sync | planned | ADR-0003, no code |

States: **shipped** (reachable and tested), **partial**, **built, not wired**,
**untried** (built but never run for real), **planned**, **removed**. For a product
made of instructions rather than code (a skill, a runbook), "shipped" means that
people use it and something checks it.

**Contradictions.** Anywhere two things disagree:

- two concepts for one job, under different names or syntax;
- competing UI or state models for one workflow;
- code that exists but nothing reaches;
- roadmap items already shipped, or already removed;
- docs that describe behaviour the code no longer has;
- ADRs that disagree with each other or with the code.

Each one gets its evidence, the same as a capability row. A contradiction that only
lives in the docs (two files wording the same decision differently) doesn't need a
disposition. It becomes a doc fix, shown in step 4.

**Verification.** The command, and whether it passed on the base branch (or why it
was not run).

## 2 — Decide

If the user gave an **outcome** ("get this to a shippable MVP"), or no direction at
all ("plan it out so I know what's next"), start by proposing two or three shapes for
the plan. For each, say what it costs and what it rules out, and recommend one. The
chosen shape is what the rest of this step works through.

Then ask in rounds (see "How to ask" in `SKILL.md`). The first round is nearly always
the **disposition table**: every capability and contradiction that is not
obviously *keep*, with your recommendation. It lists what exists and what the user
asked for. It never lists features you think the product should have.

| Item | Recommend | Why |
|---|---|---|
| Two editors (`LegacyEditor`, `Editor`) | **merge** into `Editor` | only `Editor` is routed (`src/routes.tsx:31`); `LegacyEditor` is reached only from tests |
| Template registry | **decline** | ADR-0007 replaced templates with snippets |
| Push notifications | **defer** | needs a permission decision; nothing in scope depends on it |

- **keep**: coherent and in scope.
- **merge**: overlapping systems. The decision includes *which one survives*.
- **decline**: out on purpose. Recorded with a date and reason, so it does not
  quietly return.
- **defer**: worth doing, not now. Recorded with what would bring it back.

Later rounds settle whatever the dispositions opened up: what the first milestone
must include, how a merge migrates existing data, which decisions need an ADR, what
must stay true while the work happens (the plan doc's **Rules**: only what a path,
test or command can show), and any term whose confusion would change what gets built (see "Glossary" in
`SKILL.md`).

**The step ends when the frontier is empty and the user confirms you share an
understanding.** The empty frontier is your judgement; the shared understanding is
theirs.

## 3 — Phase

Turn the kept and merged work into an ordered chain of phases.

**A phase is an outcome, not a layer.** It ends with something observable: "search
works offline end to end," not "index work." If you cannot say a phase's
outcome in one sentence, it is two phases. Past roughly eight tickets, look for the
seam that splits it.

**Order the phases by what depends on what:**

1. Decisions before the code that depends on them.
2. The shared seam (parser, schema, storage, permission, public contract) before
   the features that use it.
3. The new path working before the old path is removed.
4. Removal before polish.

**Inside a phase, every ticket is a vertical slice.** It leaves the product working
and the verify command green on its own. Never plan "all the backend, then all the
UI."

**Run in order anything that shares a seam.** Tickets may run in parallel only
when they share no files, contracts, migrations, permissions, or open decisions.
Say which ones can.

**Work only a person can do** (proving something on a real machine, say) belongs in
the plan too: as a step in a phase's exit condition, or as a ticket for a person
(see "Follow what you found" in `SKILL.md`).

**Every phase has an exit condition** you could check tomorrow without asking
anyone:

- every ticket in the phase is closed and its change is on the base branch;
- the verify command passes on the base branch;
- the phase's own outcome check holds (name the test, command or manual step);
- the plan doc says so.

Show the chain: each phase's outcome, exit condition, and, for the first phase
only, its items in order. Later phases get their outcome and open decisions, nothing
more. Ask for approval.

## 4 — Write

Once the chain is approved, show the drafts, then write:

- the plan doc, in the shape of [references/plan-doc.md](references/plan-doc.md),
  at the location `SKILL.md` describes, stamped with the base commit the baseline
  was taken at. The first phase lists its items by name; the ticket references are
  written in after filing, in step 5;
- an ADR for each decision from step 2 that meets the ADR test, in the shape of
  [references/adr.md](references/adr.md);
- the glossary entries settled in step 2;
- the doc fixes from step 1, and links from the scope-only files to the plan doc,
  **only as the user approved them**;
- the **plan section of the agent instructions**, offered as
  [references/agent-instructions.md](references/agent-instructions.md) describes.
  It is what makes coding agents in Claude Code and Codex read the plan doc first and
  stop at a conflict. Offer it; if the user declines, the plan still works.

**The plan doc is the hub from the start.** Every ADR written here has a Decisions
line saying what it rules out; every scope-only file, ADR the repo already had, and
the glossary are linked; nothing is copied in.

## 5 — Ticket

For the first phase only, unless the repo's planning contract tickets further ahead.
Take each item through `add.md` steps 1, 2, 3
and 5. Step 0 happened here, and step 4 is done, because the plan already places
every item.

- **Items that `add.md` step 1 sends to step 4** (most bugs and tasks) go straight
  to step 5.
- **Items it sends to an intent** (features, most changes, anything with an open
  decision) get one, plus a spec if `add.md` step 3 calls for it. Most of their
  decisions were settled in step 2 here, so write the intent from those answers,
  and ask only what is still open.

Confirm how tickets are filed once for the whole phase. Show all the phase's tickets
together, in order, and file them only after one approval. Then write their
references into the plan doc.

Finish with the handoff from `SKILL.md`.
