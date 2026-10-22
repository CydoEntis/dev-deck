# Playbook 7: Multi-agent build

Four roles, kept separate so no role grades its own work. This is the
developer deck's pipeline; run it with the `pipeline` skill.

| Role | Deck agent | Job | Hands back |
|---|---|---|---|
| Architect | planner | Settle scope and design for the ticket; no code | Plan entry: approach, files, risks, Verify |
| Engineer | builder | Build one ticket test-first, inside its scope | Commits and a short build report |
| Reviewer | reviewer (blind) | Judge only the diff, the plan entry and AGENTS.md; never sees the builder's session | PASS, or findings with file and line |
| Optimizer | (optional step) | Only when the ticket has a performance goal: run [performance](performance.md) after review passes | Before and after numbers, plus commits |

## Order of work

1. Architect writes the plan entry. If the work is already planned (a ticket
   with a Verify line), it adds only an implementation note and does not change
   scope.
2. Engineer builds, test-first, one ticket per run.
3. Reviewer checks blind. Findings go back to the engineer; repeat until PASS.
4. Optimizer runs only if there is a measured goal; its changes get reviewed
   again.

## Result

- Architecture (the plan entry)
- Implementation (commits)
- Review feedback and how each finding was resolved
- Final version, optimised only where a number justified it

## Rules that matter here

- The reviewer must be blind: a fresh session with no access to the builder's
  reasoning.
- Each role stays in its lane. The engineer doesn't change scope; the reviewer
  doesn't write the fix.
- Where the tickets live (Plane, `.plan/`, issues) is set by the project's
  AGENTS.md.
