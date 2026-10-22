---
name: playbook-system-design
description: System-design mode. Use when a product or feature needs its architecture decided before code - components, data flow, API, schema, caching, failure handling - then the minimal production version is built.
---

# Playbook: System design

Think like a senior systems architect: design for the product's real load and
risks, then build the minimal production version.

**Rules first.** The user's request wins, then the project's AGENTS.md and ADRs,
then the Dev Deck conventions (code-style, contract, commits), then this
playbook. If this playbook seems to conflict with a higher rule, follow the rule
and say so.

## Order of work

1. **Requirements and numbers.** Users, requests per second, data size, latency
   targets, and what must never happen (data loss, cross-user leaks, downtime).
   Unknown numbers get an explicit assumption. Write latency targets as
   percentiles (p95/p99), not averages, set from what users need, not from what
   the system does today.
2. **Architecture.** Components and their responsibilities. Prefer one
   deployable until a number or a hard constraint (different runtime, security
   isolation) says otherwise.
3. **Component structure.** Modules, their public interfaces, and which way
   dependencies point.
4. **Data flow.** The path of each key operation, including async work and
   failure handling. Every outbound call gets a timeout. Retries use capped
   exponential backoff with jitter, happen at one layer only, and only for
   idempotent operations.
5. **Threat model.** Who could abuse each entry point and how, before the schema
   is fixed.
6. **API design.** Endpoints and schemas, per the Dev Deck API contract.
7. **Database schema.** Tables, keys, indexes for the real queries (foreign keys
   are not indexed automatically), ownership.
8. **Caching strategy.** Where a cache would go, what it holds, its TTL (from how
   stale the data may be), what invalidates it, what happens when it is empty or
   down, and the measurement that would justify adding it. A cache must never be
   required for the system to stay up.
9. **ADRs** for each costly choice: context, options, decision, consequences,
   status, "Revisit when".
10. **Implementation:** plan and tickets, then build with
    `playbook-multi-agent-build`.

## Result

- Architecture
- Component structure
- Data flow, with failure handling
- API design
- Database schema
- Caching strategy (decided; implemented only if a measurement justifies it)
- Implementation code, ticket by ticket

## Rules that matter here

- Every component earns its place: a queue, cache or extra service needs a stated
  reason tied to a number or a hard constraint.
- Name the failure modes (dependency slow or down, retry storm, duplicate
  delivery, partial write, cross-user leak) and what happens in each.
- Done means the house definition of done, including an independent review.
- Related skills: `architect`, `codebase-design`, `roadmap`, `grilling`.
