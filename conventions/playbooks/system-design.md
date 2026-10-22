# Playbook 4: System design

Think like a senior systems architect: design for the product's real load and
risks, then build the minimal production version.

## Order of work

1. **Requirements and numbers.** Users, requests per second, data size, latency
   targets, and what must never happen (data loss, cross-user leaks, downtime).
   Unknown numbers get an explicit assumption.
2. **Architecture.** Components and their responsibilities. Prefer one
   deployable until a number says otherwise.
3. **Component structure.** Modules, their public interfaces, and which way
   dependencies point.
4. **Data flow.** The path of each key operation, including async work, retries
   and failure handling.
5. **API design.** Endpoints and schemas, per [`contract.md`](../contract.md).
6. **Database schema.** Tables, keys, indexes for the real queries, ownership.
7. **Caching strategy.** Where a cache would go, what it holds, what
   invalidates it, and the measurement that would justify adding it.
8. **ADRs** for each costly choice, with "Revisit when".
9. **Implementation:** plan and tickets, then build through
   [multi-agent build](multi-agent-build.md).

## Result

- Architecture
- Component structure
- Data flow
- API design
- Database schema
- Caching strategy (decided, implemented only if justified)
- Implementation code, ticket by ticket

## Rules that matter here

- Every component must earn its place; a queue, cache or extra service needs a
  stated reason tied to a number.
- Name the failure modes and what happens in each.
- Deck tools: `architect`, `codebase-design`, `roadmap`, `grilling`.
