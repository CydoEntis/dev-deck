---
name: playbook-new-app
description: New-app mode. Use when starting a product or service from nothing - "build an app", "new project", "MVP from scratch". Designs architecture, data model, API and UI, then builds a walking skeleton and ships ticket by ticket.
---

# Playbook: New app

Think like a senior full-stack engineer starting a real startup MVP: the
smallest version that works in production and doesn't have to be thrown away
when it grows.

**Rules first.** The user's request wins, then the project's AGENTS.md and ADRs,
then the Dev Deck conventions (code-style, contract, commits), then this
playbook. If this playbook seems to conflict with a higher rule, follow the rule
and say so.

## Order of work

1. **Goal and success condition.** One sentence on what the app does, and one
   check that proves it works for a real user.
2. **Architecture.** The fewest moving parts that meet the goal: a modular
   monolith by default. Record each costly choice as an ADR: context, options
   considered, decision, consequences (good and bad), status, and "Revisit
   when". Never edit an accepted ADR; supersede it with a new one that links back.
3. **Threat model.** Who could abuse each entry point, and how, before the
   schema is fixed.
4. **Data model.** Tables, keys, unique constraints, ownership (whose row is it),
   what is shared between users. Unique constraints that span users leak
   existence; scope them per user.
5. **API.** Endpoints with request and response schemas, following the Dev Deck
   API contract from the first endpoint.
6. **UI architecture.** Screens, navigation, where server state lives, and the
   loading, empty and error states.
7. **File structure.** Vertical slices: one folder per feature, tests beside
   source, a shared package only for what crosses HTTP or two apps.
8. **Plan and tickets.** Ordered phases; tickets only for the first phase, each
   one PR in size, each with a Verify line and its blockers.
9. **Build.** The first ticket is a walking skeleton: workspace, `verify`
   command, CI, the contract's `http/` module, and one thin feature running end
   to end (UI → API → DB) on the real deployment target. Then ticket by ticket
   with `playbook-multi-agent-build`.

## Result

- Architecture, with ADRs and the threat model
- File structure
- Database schema
- API endpoints
- UI architecture
- The plan and first-phase tickets
- Code, delivered ticket by ticket, each one finished and tested

## Rules that matter here

- "Scalable" means no rewrite is needed to grow, not built for scale now. Build
  for today's load and write the scale trigger in the ADR's "Revisit when". No
  queues, caches, extra services or sharding before a number demands them.
- "Complete" means each slice ships finished: no stubs, no TODOs, tests included.
- Security from the first ticket: auth on every route; every query scoped to its
  owner (another user's row is `NOT_FOUND`); input and external responses
  validated at the boundary; secrets out of the repo; dependencies pinned with a
  lockfile and scanned in CI; no debug output or stack traces in responses. Use
  OWASP ASVS 5.0 Level 1 as the baseline checklist.
- Modules talk only through each other's public interface, and a module owns its
  tables. Add a lint or test that fails on a cross-module import before there
  are three modules.
- Done means the house definition of done: type checks, tests pass, exercised on
  the running app, follows the house style and AGENTS.md, independently reviewed.
- Related skills: `roadmap` (plan, phases, tickets, ADRs), `architect`,
  `codebase-design`, `init` (AGENTS.md), `pipeline`.
