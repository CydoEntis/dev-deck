# Playbooks

A playbook is a **mode of work**: what to think about first, in what order, and
what to hand back. It does not change the rules. The eight playbooks ship as
skills in the developer plugin, so Claude Code and Codex load each one only when
the task calls for it:

| Skill | Use when | Changes behaviour? |
|---|---|---|
| `playbook-new-app` | Starting a product from nothing | New code |
| `playbook-understand-and-refactor` | Joining or cleaning up an unfamiliar codebase | No |
| `playbook-debug` | Something is broken, flaky, or failing in production | Fixes the bug only |
| `playbook-system-design` | Architecture must be decided before code | New code |
| `playbook-performance` | Something is measurably too slow or too heavy | No |
| `playbook-restructure` | Code works but its shape fights every change | No |
| `playbook-multi-agent-build` | Non-trivial feature work; the default way to ship a ticket | New code |
| `playbook-ui-component` | A reusable, production-grade UI component | New code |

Invoke one by name (Claude Code: `/developer:playbook-debug`; Codex:
`$playbook-debug`), or let the agent pick it from the task. Sources live in
`skills/developer/playbook-*/SKILL.md`; `scripts/build_plugins.py` copies them
into the plugin.

## Which rules win

When two instructions disagree, the higher one wins:

1. **The user's explicit request** for this task.
2. **The project's `AGENTS.md`** and its ADRs.
3. **Dev Deck conventions:** [`code-style.md`](../code-style.md),
   [`contract.md`](../contract.md), [`commits.md`](../commits.md).
4. **The playbook.**

If a playbook seems to require breaking a rule, follow the rule and say so.

## Conflicts between the original prompts, and how they resolve

The playbooks started as standalone prompts. Read literally, some contradict the
house style. The reconciled reading, checked against the sources below:

| Prompt said | Conflicts with | Rule |
|---|---|---|
| "Complete code", "complete application" | One ticket per run, small PRs | "Complete" means each slice ships finished: no stubs, no TODOs, tests included. Big work is planned whole and built one ticket at a time. |
| "Make it scalable" | KISS, YAGNI | Build for today's load; write the scale trigger in the ADR's "Revisit when". No queues, caches or services before a number or a hard constraint demands them. (Fowler, *MonolithFirst*, *Yagni*) |
| "Caching strategy" | KISS | Decide where a cache would go, its TTL and what happens when it is down; implement it only when a measurement shows the need. A cache must never be required to stay up. |
| "Clean architecture: separate layers" | Vertical slice, colocation | Keep vertical slices. Inside a slice, keep pure logic apart from I/O and point dependencies inward; start simple and refactor toward a pattern only when a smell shows. No project-wide `controllers/` + `services/` + `repositories/` unless AGENTS.md chose it. (Martin's Dependency Rule; Bogard, *Vertical Slice Architecture*; Bernhardt, *Functional Core, Imperative Shell*) |
| "You are 4 agents" | The developer pipeline | The pipeline is that workflow: Architect = planner, Engineer = builder, Reviewer = blind reviewer. The Optimizer is the evaluator-optimizer pattern and runs only when a measured target exists. (Anthropic, *Building effective agents*) |
| "Improve code" while "behaviour unchanged" | Refactoring | Pin behaviour with characterization tests first; refactor and fix in separate commits; performance work needs before and after numbers. (Feathers; Fowler) |
| "Give the full code in the answer" | Repo work | In a repo, code goes into files and commits; the reply summarises what changed and how it was verified. |

## Where reusable API responses and errors live

Every API in the deck answers in one shape, defined in
[`contract.md`](../contract.md): the `{ ok, data, meta }` envelope, the 8 error
codes, the error subclasses, one top-level handler, and the `/api/v1` prefix.
The contract is the spec; each project implements it **once**, in its first
scaffold ticket:

- **Server:** a cross-cutting `http/` module (for example `apps/api/src/http/`):
  envelope helpers, `ERROR_CODES` and `HTTP_STATUS` constants, the base error
  plus 8 subclasses, request-id middleware, and one `app.onError` plus
  `app.notFound` on the root app (Hono). The handler also maps framework
  `HTTPException`s to the registry. Route code throws `NotFoundError` and
  friends; it never builds error JSON by hand.
- **Shared:** the envelope's Zod schema, the error-code union and the DTO
  schemas in the shared package (for example `packages/shared/src/http/`),
  free of server-only imports.
- **Client:** one API client module that adds the prefix and auth, validates the
  envelope with the shared schema, returns `data`, throws a typed error carrying
  `error.code`, and creates `NETWORK_ERROR` when the request never reached the
  server. `hono/client` may sit underneath it; plain `fetch` is enough.

## How projects pick this up

- **Playbooks:** installing the developer plugin is enough; the skills load on
  demand. A project's AGENTS.md needs only one line: "Task modes are the
  `playbook-*` skills."
- **House style:** agents and skills in the plugin read the conventions from
  `${CLAUDE_PLUGIN_ROOT}/conventions/`. For every session to see them, add to
  `~/.claude/CLAUDE.md` (Claude Code; user-level imports need no approval):

  ```
  @~/.claude/plugins/marketplaces/dev-deck/conventions/code-style.md
  @~/.claude/plugins/marketplaces/dev-deck/conventions/commits.md
  ```

  Codex has no imports: keep a short summary of code-style and commits in
  `~/.codex/AGENTS.md` (it reads up to 32 KiB of AGENTS.md in total).
- **Contract:** only API projects need it. Restate its key rules in that
  project's AGENTS.md (they're short); agents open `contract.md` for the rest.
- `CLAUDE.md` in each project stays a single line, `@AGENTS.md`. Claude Code
  expands it; Codex reads `AGENTS.md` directly.

Plain text paths in AGENTS.md (like "read conventions/code-style.md") are not
loaded by either tool; the agent sees the file only if it decides to open it.
Use skills, `@` imports (Claude Code), or the text itself.

## Every playbook ends the same way

A result is done only when the house definition of done holds: it type checks,
tests pass (including new ones), it ran on the real app, it follows the house
style and the project's AGENTS.md, and an independent reviewer confirmed it. For
debug and performance work the reviewer re-runs the reproduction or benchmark,
not just the tests. Say plainly which of these were not met, and why.
