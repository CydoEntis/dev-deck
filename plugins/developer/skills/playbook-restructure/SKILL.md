---
name: playbook-restructure
description: Restructure (clean architecture) mode. Use when code works but its shape fights every change - separate concerns, raise modularity, cut coupling inside vertical slices, behaviour unchanged.
---

# Playbook: Restructure

Think like a senior engineer giving working code a clean structure: separate
concerns, raise modularity, cut coupling. Behaviour stays the same.

**Rules first.** The user's request wins, then the project's AGENTS.md and ADRs,
then the Dev Deck conventions (code-style, contract, commits), then this
playbook. If this playbook seems to conflict with a higher rule, follow the rule
and say so.

"Clean architecture" here means clean **inside vertical slices**, not
project-wide horizontal layers. The rule that matters from clean and hexagonal
architecture is that dependencies point inward and the framework, database and
network stay at the edges; the layer folders are optional.

## Order of work

1. **Pin behaviour** with tests around everything that will move.
2. **Find the tangles:**
   - business logic mixed with I/O (HTTP, DB, filesystem, framework)
   - modules that reach into each other's internals; import cycles
   - one feature spread across many folders
   - files that change together in commits but live in different folders
     (`git log --name-only`)
3. **Design the target shape:**
   - one folder per feature, holding its route, logic, types and tests
   - pure logic separate from the edges. The edge loads data, calls pure logic,
     then writes what the logic returned. If logic must trigger I/O mid-flow,
     the edge passes a function in; a function type is the port, so no interface
     or class is needed.
   - minimise coupling between slices and maximise it inside one. A slice never
     imports another slice's internals, only its public entry.
   - each module hides more than it exposes; merge pass-through modules that
     only forward calls
   - shared code only where two features really use it
4. **Move in small steps.** One feature at a time, the app working and tests
   green after each commit. Before deleting the old path, check nothing else
   imports it.

## Result

- New folder structure
- Architecture description (what lives where, which way dependencies point)
- Refactored code, as small behaviour-preserving commits

## Rules that matter here

- Inside a slice, start simple and refactor toward a pattern only when a smell
  shows. No new layers, base classes or single-implementation interfaces unless
  a test or a second consumer needs them.
- Lock the shape in once it settles: add a dependency check (for example
  dependency-cruiser: no cycles, no cross-slice internals) to `verify`.
- If the project's AGENTS.md chose a different shape, follow it.
- Done means the house definition of done, including an independent review.
- Related skills: `codebase-design`, `safe-refactor`, `blast-radius`.
