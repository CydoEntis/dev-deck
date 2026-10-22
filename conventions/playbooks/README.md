# Playbooks

A playbook is a **mode of work**: it says what to think about first, in what
order, and what to hand back. It does not change the rules. Eight modes:

| # | Playbook | Use when | Changes behaviour? |
|---|---|---|---|
| 1 | [New app](new-app.md) | Starting a product from nothing | New code |
| 2 | [Understand and refactor](understand-and-refactor.md) | Joining or cleaning up an unfamiliar codebase | No |
| 3 | [Debug](debug.md) | Something is broken, slow to reproduce, or failing in production | Fixes the bug only |
| 4 | [System design](system-design.md) | A feature or product needs its architecture decided before code | New code |
| 5 | [Performance](performance.md) | Something is measurably too slow or too heavy | No |
| 6 | [Restructure](restructure.md) | Code works but its shape fights every change | No |
| 7 | [Multi-agent build](multi-agent-build.md) | Non-trivial feature work; the default way to ship a ticket | New code |
| 8 | [UI component](ui-component.md) | Building a reusable, production-grade UI component | New code |

## Which rules win

When two instructions disagree, the higher one wins:

1. **The user's explicit request** for this task.
2. **The project's `AGENTS.md`** and its ADRs (stack, decisions, project rules).
3. **Dev Deck conventions:** [`code-style.md`](../code-style.md),
   [`contract.md`](../contract.md), [`commits.md`](../commits.md).
4. **The playbook.**

A playbook never overrides 1 to 3. If a playbook seems to require breaking a
rule, follow the rule and say so in the result.

## Conflicts between the original prompts, and how they resolve

These playbooks started as standalone prompts. Read literally, some of them
contradict the house style. Here is the reconciled reading:

| Prompt said | Conflicts with | Rule |
|---|---|---|
| "Complete code", "complete application" (1, 4) | One ticket per run, small PRs | "Complete" means **each slice ships finished**: no stubs, no TODOs, tests included. Big work is planned whole and built one ticket at a time. |
| "Make it scalable" (1, 4) | KISS, no speculative abstractions | Build for **today's load**. Keep seams where scale would land, and write the scale trigger in the ADR's "Revisit when". Don't build queues, caches, services or sharding before a number demands them. |
| "Caching strategy" (4) | KISS | Decide where a cache *would* go and what invalidates it; implement one only when a measurement shows the need. |
| "Clean architecture: separate layers" (6) | Vertical slice, colocation | Keep **vertical slices**. Inside a slice, separate pure logic from I/O, point dependencies inward, and keep framework and DB code at the edges. No project-wide `controllers/` + `services/` + `repositories/` layers unless the project's AGENTS.md chose that shape. |
| "You are 4 agents" (7) | The developer pipeline | The pipeline *is* that workflow: Architect = planner, Engineer = builder, Reviewer = blind reviewer. The Optimizer runs only when there is a measured performance goal, after review, using playbook 5. |
| "Improve code" in refactor and performance (2, 5, 6) | "Behaviour unchanged" | Pin behaviour with tests **before** changing anything. Refactor and fix in separate commits. Performance work needs a before and after number. |
| "Give the full code in the answer" (all) | Repo work | In a repo, code goes into files and commits; the reply summarises what changed and how it was verified. Full code in the reply only when there is no repo. |

## Where reusable API responses and errors live

Every API in the deck answers in one shape, defined in
[`contract.md`](../contract.md): the `{ ok, data, meta }` envelope, the 8 error
codes, the error subclasses, one top-level error handler, and the `/api/v1`
prefix. The contract is the spec; each project implements it **once**, in the
first scaffold ticket:

- **Server:** a cross-cutting `http/` module (for example `apps/api/src/http/`):
  envelope helpers, `ERROR_CODES` and `HTTP_STATUS` constants, the base error
  plus 8 subclasses, request-id middleware and the top-level handler. Route code
  throws `NotFoundError` and friends; it never builds error JSON by hand.
- **Shared:** the envelope's Zod schema, the error-code union and the DTO
  schemas, in the shared package (for example `packages/shared/src/http/`), so
  the server and every client use the same types.
- **Client:** one API client module that adds the prefix and auth, validates the
  envelope, returns `data`, throws a typed error carrying `error.code`, and
  creates `NETWORK_ERROR` when the request never reached the server.

## Linking from a project

Each project's `AGENTS.md` adds one line under House style:

```md
- **Playbooks:** pick the matching mode from Dev Deck
  `conventions/playbooks/README.md` (local copy under
  `~/.claude/plugins/marketplaces/dev-deck/conventions/playbooks/`).
```

`CLAUDE.md` stays a single line, `@AGENTS.md`, so Claude Code and Codex read
the same rules.

## Every playbook ends the same way

A result is done only when the house style's definition of done holds: it type
checks, tests pass (including new ones), it ran on the real app, it follows the
house style and the project's AGENTS.md, and an independent reviewer confirmed
it. Say plainly which of these were not met, and why.
