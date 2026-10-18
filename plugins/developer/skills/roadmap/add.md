# Roadmap: planning one piece of work

`/roadmap bug`, `feature`, `change`, `task` and `add` all run this file. You plan one
piece of work and fit it into the project's plan. You end at "the tickets exist."
The first four commands name the type; `add` leaves it to step 1.

**Read `SKILL.md` first.** Its shared rules and its repo facts apply to every step
below.

```
0  Overlap  already planned, ticketed, or ruled out?         facts: yours
1  Sort     type (bug, feature, change, task) and size       your call, confirmed
2  Intent   question it until nothing is open → intent.md    when step 1 says so
3  Spec     requirements and design → spec.md                only when design needs its own doc
4  Place    where it sits in the plan                        decisions: theirs
5  Ticket   confirm filing, draft, show, file, prove
```

---

## 0 — Overlap

**Settle the repo facts first** (see `SKILL.md`), since the overlap search needs to
know where tickets live. Then, **before the first question, go and look.** Search for
this surface in:

- the planning set (see `SKILL.md`), the plan doc's **Decisions** ("Rules out")
  and **Rules** lines first;
- open tickets, in the place "Where tickets live" pointed to. If you can't search
  there from this session, say so;
- open pull requests and recent branches.

Then say what you found, first thing. **Report every case that applies**, in one
round:

- **It is under Out.** It was declined, with a date and a reason. Show that. Taking
  it back is the user's decision, and becomes a change to the plan.
- **It is under Later.** Promoting it now is a decision; ask.
- **It crosses a decision or a rule.** An active ADR rules it out, or it would break
  a line under Rules. Show which. Going ahead means superseding the ADR or changing
  the rule, which makes it a change, and that is the first question.
- **A live intent covers it.** Don't start a second one. Ask whether to extend or
  supersede it.
- **Open tickets cover part of it.** Say how many there are and how long they have
  sat. Ask whether this is new work or the rest of that work. Usually it is the rest.
- **It already works, or mostly.** Show the evidence, and ask what is actually
  missing.
- **Nothing covers it.** Say so in one line and go on.

Don't skip this because the user sounds sure. That is how one surface ends up with
several overlapping efforts, none of them finished.

## 1 — Sort

Read the code the work touches and what it depends on, and nothing more. Then settle
the work's **type** and **size** from evidence.

**For a bug, get the reproduction first.** If the request doesn't say exactly what
happens, ask for the steps in plain text (see "How to ask" in `SKILL.md`) before
classifying it. You can't tell a bug from a change without knowing what the user
actually saw.

- **The command named the type**: start from it, and check it against the table
  below. If the evidence disagrees, say so and ask whether to plan it as the type the
  evidence shows. Never switch types silently.
- **`add`**: decide the type from the table, not from how the request was worded.

State both with the evidence, then confirm them with a question. For example (made
up): *"`DESIGN.md:40` promises X, and `src/y.ts:88` does Z. Plan this as a bug,
several tickets?"*, with the main alternative type and size as the other options.
The user can also say "just ticket it" or "grill me" at any point.

**A request that mixes types** ("fix X and add Y") is split into separate items. Say
how you split it, then take each item through this step on its own.

### Type

| Type | How to tell | What follows |
|---|---|---|
| **Bug** | It behaves differently from something promised: a doc, a spec, a test, an ADR, a recorded decision, or how it worked before (`git log -S`, an older release). **If nothing promised the expected behaviour, it isn't a bug**; it's a feature or a change. Say so. | Show where actual and expected part ways in the code. If the code, tests and history can't confirm it, say so, and carry the user's steps as an assumption. |
| **Feature** | Nothing like it exists yet; step 0 confirmed that. | An intent, and a spec if step 3 calls for one. |
| **Change** | It exists and works as designed, and the user wants it to behave differently. | Find what made it work this way: an ADR, the Out list, a design doc, a test that pins it, the commit that built it. If something did, the change overrides that decision, and that is the first question. |
| **Task** | Users see no difference: a refactor, dependency, docs, tooling or test work. | Its tickets prove behaviour is unchanged (see `references/ticket.md`). If the work would change what users see, it isn't a task; say so. |

### Size

- **One ticket**: it passes the size check in `references/ticket.md` as it stands.
- **Several tickets**: anything that fails the size check. Most features land here.
- **A phase or more**: more than one phase's worth of work, or it changes what the
  whole product is. With no plan → say so, and switch to `init.md`: work that big
  needs a plan first. With a plan → it becomes one or more new phases: settle it here
  (steps 2–3), and add the phases in step 4. It gets tickets only once one of them is
  the active phase (or the repo's contract says otherwise).

When in doubt between one ticket and more, pick more.

### Where it goes next

- **Feature**: step 2.
- **Change**: step 2, unless nothing decided the current behaviour and nothing is
  open. Then go to step 4.
- **Bug or task with nothing undecided**: step 4, however many tickets it takes. The
  tickets and a one-line note in the plan are enough.
- **Bug or task with an open decision**: step 2.

## 2 — Intent

Start from what the user actually gave you:

- **An outcome** ("people can't find old notes"). Propose two or three shapes first:
  what each costs, what it rules out, and which you recommend. The chosen shape is
  what the questioning covers.
- **A shape** ("add tag filtering"). Question that shape.
- **A shape that already exists** (step 0 found it). The first question is where it
  falls short for the user. The answer becomes the shape.
- **Neither** ("so I know what to build next"). Treat it as an outcome: the goal is
  the one on the path (see "Stay on the path" in `SKILL.md`).

Then question it (see "How to ask" in `SKILL.md`). The frontier usually starts with:

- **Who and when.** Which user, in which situation, hits this.
- **The edges.** Concrete scenarios: empty, huge, offline, no permission, interrupted
  halfway, the same thing twice.
- **What must not change.** Existing behaviour, data, permissions, the public
  contract.
- **Done.** What the user would check to call it finished.
- **Out.** The adjacent things a reasonable builder might add, and must not.

**When the frontier is empty, ask whether you share an understanding.** An empty
frontier is your judgement; shared understanding is the user's. Then draft
`intent.md` from [references/intent.md](references/intent.md) (it says how the
Problem is framed for each type). Show it, get it accepted, and write it.

**Open Questions must be empty before step 5.** Each one gets answered, deferred, or
split off (see `SKILL.md`). Never resolve one by guessing, and never delete one to
get unblocked.

## 3 — Spec

**Only when the tickets can't carry the decisions on their own:**

- a new screen, layout, or set of visible states that needs a design source;
- a data model change or migration;
- an interface that other code or systems consume;
- requirements shared across several tickets that need one place to be checked
  against.

Otherwise, skip it, and say that you skipped it. Concerns (security, privacy,
permissions) still get written down: in the intent's Constraints, and in each
affected ticket's Impact.

1. **Read the repo's standards before writing a word**: design docs and mocks, code
   and API conventions, security or privacy docs, permission docs, and any skill in
   this session that covers the repo's stack. Policy gets applied while the spec is
   written, not discovered in review.
2. **Draft `spec.md`** from [references/spec.md](references/spec.md), concerns first.
3. **Walk the user through the concerns first.** Those needing a decision become a
   round of questions. Anything that meets the ADR test (see `SKILL.md`) is offered
   as an ADR.
4. **Show the spec, get it accepted, and write it.**

## 4 — Place

Where the work goes depends on the planning set (see "The planning set" in
`SKILL.md`). Show the placement, and make the change only on approval. Each branch
below ends by saying whether the work is **cleared for tickets**.

**No plan.** Nothing to place. Say once that `/roadmap init` would give the repo a
plan, and don't mention it again. **Cleared.**

**A plan doc, or a plan spread over several files.** Put the work into each file
that holds scope or order, in the form that file already uses. With no single plan
doc, say once that `/roadmap reconcile` would settle which file is the source of
truth.

- **In scope.** Add or update its line, linking the intent if there is one.
- **Which phase.** If no file sets phases, the work simply joins the ordered list.
  **Cleared.** Otherwise:
  - It serves the active phase's outcome → it joins the active phase (adding to an
    active phase is a scope change; say so). **Cleared.**
  - It belongs to a later phase → it goes on that phase's list. **Not cleared**,
    unless the repo's own planning contract tickets later phases too. If not
    cleared, stop after the handoff.
  - It is urgent but outside the active phase → the user decides: widen the active
    phase, or insert a phase before it. Never slip it in quietly.
- **Declined or deferred along the way** → Out or Later, with the date and the
  reason. If the repo already keeps such a list somewhere, add it there.
- **Records from steps 2 and 3** go on the hub in the same change (see "Every record
  lands on the hub in the same step" in `SKILL.md`): the intent and spec linked, each
  ADR on Decisions with what it rules out, any new Rules line, and any superseded
  ADR's line removed.

## 5 — Ticket

Only for work step 4 cleared.

1. **Confirm how tickets are filed here** (see "Tickets" in `SKILL.md`). The answer
   decides the template, the labels and the blocker form, so it comes before
   drafting.
2. **Read the code where each ticket lands.** A ticket that names real files gets
   finished; one that describes a vague area gets stopped, or guessed at. What you
   learn goes into each ticket's Context.
3. **Split into small tickets.** Every ticket passes the size check in
   `references/ticket.md`. A spec requirement that could ship on its own gets its
   own ticket. Order the tickets by what depends on what, and run in sequence any
   that change the same code. A feature that comes out as a single ticket is
   suspicious: check it against the size check again.
4. **Draft them** against [references/ticket.md](references/ticket.md) and the
   repo's own shape, and give each one the test at the top of that page. **Tickets
   carry only this work.** Nothing you noticed along the way becomes a ticket, a
   Context line or an acceptance criterion.
5. **Show the coverage** for work with a spec. Every requirement maps to at least one
   ticket, and every ticket traces back to a requirement or to the intent.
6. **Show them all, and ask for approval**: title, body, labels, blockers, and where
   each will be filed.
7. **File, prove, and link back**, as "Tickets" in `SKILL.md` describes. The spec's
   Coverage section gets the real ticket references.

Finish with the handoff from `SKILL.md`.
