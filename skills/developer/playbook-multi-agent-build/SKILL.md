---
name: playbook-multi-agent-build
description: Multi-agent build mode. Use for non-trivial feature work or a planned ticket - Architect (planner), Engineer (builder), blind Reviewer, and an Optimizer only when there is a measured performance goal. Explains roles, hand-offs, stop rules and cost.
---

# Playbook: Multi-agent build

Four roles, kept separate so no role grades its own work. This is the developer
deck's pipeline; run it with the `pipeline` skill.

**Rules first.** The user's request wins, then the project's AGENTS.md and ADRs,
then the Dev Deck conventions (code-style, contract, commits), then this
playbook. If this playbook seems to conflict with a higher rule, follow the rule
and say so.

| Role | Deck agent | Job | Hands back |
|---|---|---|---|
| Architect | planner | Settle scope and design for the ticket; no code | Plan entry: goal, files, out of scope, risks, Verify |
| Engineer | builder | Build one ticket test-first, inside its scope | Commits and a short build report |
| Reviewer | reviewer (blind) | Judge the diff, the plan entry and AGENTS.md; never sees the builder's session | PASS, or findings with file, line and evidence |
| Optimizer | optional step | Only when the ticket has a measured performance goal: run `playbook-performance` after review passes | Before and after numbers, plus commits |

## Order of work

1. **Architect** writes the plan entry. If the work is already planned (a ticket
   with a Verify line), it adds only an implementation note and does not change
   scope. The plan entry is the only context the builder and reviewer share, so
   it must stand alone: goal, files, out of scope, Verify.
2. **Engineer** builds, test-first, one ticket per run.
3. **Reviewer** checks blind against the Verify line. It runs `verify`, exercises
   the changed path on the running app, and reports evidence (commands and
   output), not opinions. Findings go back to the engineer. Stop after 3 review
   rounds without PASS and hand the open findings to the user.
4. **Optimizer** runs only if there is a measured goal; its changes are reviewed
   again.

## Result

- Architecture (the plan entry)
- Implementation (commits)
- Review feedback and how each finding was resolved
- Final version, optimised only where a number justified it

## Rules that matter here

- The reviewer is blind: a fresh session with no access to the builder's
  reasoning. Prompt it to be skeptical and assume the change is wrong until the
  evidence shows otherwise. Use a different model than the builder where
  possible; same-model review reduces bias but doesn't remove it.
- The reviewer flags only what breaks correctness, the Verify line, security, or
  AGENTS.md. Style preferences are notes, not findings.
- Each role stays in its lane: the engineer doesn't change scope; the reviewer
  doesn't write the fix.
- Never build two tickets in parallel if one changes what the other touches.
  Parallel builders go in separate worktrees.
- The full pipeline costs many times a single session. For a change you can
  describe in one sentence, skip the planner unless the project's AGENTS.md
  requires it; the blind review still runs.
- Where tickets live (Plane, `.plan/`, issues) is set by the project's AGENTS.md.
