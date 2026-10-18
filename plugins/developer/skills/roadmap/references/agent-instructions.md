# Agent instructions

Coding agents read the repo's agent instructions before they start, and nothing
else is guaranteed. A short section there is what makes them read the plan doc and
stop at a conflict instead of quietly picking a side.

**Never required.** `init` and `reconcile` offer it; the user can decline, and the
plan still works without it.

## The section

````markdown
## Plan

[`<plan doc path>`](<plan doc path>) is the source of truth for scope, order,
decisions and rules. Read it before starting work. If a ticket or change conflicts
with it (an active decision, a rule, or something under Out), stop and report the
conflict. Don't pick a side, and don't edit the plan to make the work fit.
With the roadmap skill installed, `/roadmap check` (Claude Code) or `$roadmap check`
(Codex) runs this check.
````

The first sentences work for an agent that doesn't have the skill. The last one is
for agents that do.

## Where it goes

Claude Code reads `CLAUDE.md`; Codex reads `AGENTS.md`. The section has to reach
whichever tools the repo is worked with, and exist once.

| The repo has | Put it |
|---|---|
| `AGENTS.md` only | in `AGENTS.md`. If the repo is also worked with Claude Code, offer a `CLAUDE.md` holding just `@AGENTS.md`. |
| `CLAUDE.md` only | in `CLAUDE.md`. If the repo is also worked with Codex, offer to move the instructions to `AGENTS.md` and leave `@AGENTS.md` in `CLAUDE.md`. |
| both, `CLAUDE.md` imports `AGENTS.md` | in `AGENTS.md`. |
| both, separate | in each. Say they are separate, and that the two copies must be kept in agreement. |
| neither | in a new `AGENTS.md`, plus a `CLAUDE.md` holding `@AGENTS.md`, if the user approves creating them. |

Nested instruction files (a `packages/api/AGENTS.md`) don't need it; the root one
is read first.

If the repo already has a section pointing at a plan (another file, or old wording),
show the change to it rather than adding a second one.
