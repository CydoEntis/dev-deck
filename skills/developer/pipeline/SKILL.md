---
name: pipeline
description: Run the Dev Deck pipeline for a piece of work — planner produces a plan and tickets, builder implements ticket by ticket, reviewer verifies blind. Use when the user says "run the pipeline", "build this feature", "ship this", or hands over a task that needs planning before code. Not for quick one-line fixes.
---

# Pipeline

Drive one piece of work through the three roles: **planner → builder →
reviewer**. You are the conductor: you pass artifacts between roles, you do
not do their work yourself.

## Preconditions

1. The repo has an `AGENTS.md` (or `CLAUDE.md`) with stack rules. If it does
   not, stop and tell the user to run the `init` skill first.
2. Roles are available as subagents (`planner`, `builder`, `reviewer`) if the
   host supports them, otherwise as instruction files under the dev-deck
   `agents/` directory.

## Flow

### 1. Plan

- If a plan for this work already exists in `.plan/` and the user did not ask
  to replan: use it. Point out stale tickets (referenced files that no longer
  exist, acceptance criteria that look superseded) and ask whether to
  re-plan.
- Otherwise: run the **planner** role with the user's request. It must return
  a plan doc and tickets under `.plan/`.
- Show the user the plan + ticket list and get approval before building. If
  the user changes the plan, send it back to the planner, not to the builder.

### 2. Build (one ticket at a time, in ticket order)

For each approved ticket:
- Run the **builder** role with exactly: the ticket text, the file path of
  the plan doc, and the instruction to follow the repo's AGENTS.md.
- Wait for its definition-of-done report. If the build failed or is
  incomplete, re-run the builder with the failure output, max 2 attempts.
- Only start the next ticket after the current one is committed.

### 3. Review (blind)

- Run the **reviewer** role. Pass it ONLY: the diff (or commit range), the
  plan entries for the tickets just built, and the repo's AGENTS.md path.
  Never pass the builder's session transcript or self-report.
- On PASS: mark the tickets done in `.plan/` (or hand off to `roadmap`
  reconcile if the project uses it) and report to the user.
- On FAIL: run the builder again with the reviewer's findings as the new
  ticket, then review again. **Max 2 review–fix loops.** After that, stop and
  hand the user the open findings — the loop is not converging and a human
  decision is needed.

### 4. Report

End with a short report: tickets built, review verdicts, anything left open,
what the user should do next (commit/PR/merge decisions are the user's).

## Rules

- Conductor does not write application code or reviews itself — it only
  dispatches roles and moves artifacts.
- Every role run starts fresh (new subagent session, or a new instruction
  pass). If a role stalls or loops, stop and report; do not retry more than
  the caps above.
- If the host cannot spawn subagents, fall back to sequential instruction
  passes: read the role file from the dev-deck `agents/` directory and
  execute its instructions in this session, then clear it from context before
  the next role (re-read only what the next role is allowed to see).
