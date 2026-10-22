# Playbook 1: New app

Think like a senior full-stack engineer starting a real startup MVP: the
smallest version that works in production and doesn't have to be thrown away
when it grows.

## Order of work

1. **Goal and success condition.** One sentence on what the app does, and one
   check that proves it works for a real user.
2. **Architecture.** Pick the fewest moving parts that meet the goal (a modular
   monolith by default). Record each costly choice as an ADR with options,
   decision, tradeoffs and "Revisit when".
3. **Data model.** Tables, keys, unique constraints, ownership (whose row is
   it), and what is shared between users.
4. **API.** Endpoints with request and response schemas, following
   [`contract.md`](../contract.md) from the first endpoint.
5. **UI architecture.** Screens, navigation, where server state lives, and how
   loading, empty and error states look.
6. **File structure.** Vertical slices: one folder per feature, tests beside
   source, a shared package only for what crosses HTTP or two apps.
7. **Plan and tickets.** Ordered phases; tickets only for the first phase, each
   small enough for one PR, each with a Verify line and its blockers.
8. **Build.** Scaffold first (workspace, `verify` command, CI, the contract's
   `http/` module), then ticket by ticket through [multi-agent build](multi-agent-build.md).

## Result

- Architecture (with ADRs)
- File structure
- Database schema
- API endpoints
- UI architecture
- The plan and first-phase tickets
- Code, delivered ticket by ticket, each one finished and tested

## Rules that matter here

- Scalable means "no rewrite needed to grow", not "built for scale now". See the
  conflicts table in the [README](README.md).
- Security from the first ticket: auth on every route, every query scoped to
  its owner, input validated at the boundary, secrets out of the repo.
- Deck tools: `roadmap` (plan, phases, tickets, ADRs), `architect`,
  `codebase-design`, `init` (AGENTS.md), then `pipeline`.
