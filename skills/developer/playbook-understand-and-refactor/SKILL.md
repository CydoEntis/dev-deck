---
name: playbook-understand-and-refactor
description: Understand-and-refactor mode. Use when joining or cleaning up an unfamiliar codebase - map architecture and data flow, find structural problems, duplication, bottlenecks and risks, then refactor with behaviour unchanged.
---

# Playbook: Understand and refactor

Think like a senior engineer who just joined a large, unfamiliar codebase.
Understand it before judging it. Behaviour stays exactly the same.

**Rules first.** The user's request wins, then the project's AGENTS.md and ADRs,
then the Dev Deck conventions (code-style, contract, commits), then this
playbook. If this playbook seems to conflict with a higher rule, follow the rule
and say so.

## Order of work

1. **Map it.** Entry points, main modules, how data flows from a request (or
   event) to storage and back. Read the code paths, not just file names.
2. **Find the problems**, each with file and line evidence:
   - structural problems (wrong boundaries, import cycles, tangled dependencies)
   - duplicated logic (three or more copies, per the DRY rule)
   - performance bottlenecks (suspected; confirm with `playbook-performance`)
   - maintainability risks (untested risky code, functions doing several jobs,
     hidden coupling)
3. **Rank them.** Start with hotspots: files that change often and are large or
   complex. Find churn with
   `git log --since=12.month --format= --name-only | sort | uniq -c | sort -rn | head -20`,
   then weigh it against size. A complex file nobody touches is low priority.
4. **Pin behaviour.** Before touching code, add characterization tests around
   what will change. They record what the code does today, not what it should
   do. Pin odd behaviour as-is and log it as a possible bug. Snapshot tests are
   fine for wide outputs. If the code can't be tested, break the smallest
   dependency first by passing in a function or value at a seam, and change
   nothing else in that commit.
5. **Refactor in small steps.** One structural change per commit, tests green
   after each. Refactor only code the tests cover. Prefer the editor's automated
   refactorings (rename, move, extract) over hand edits. Never mix a refactor
   with a bug fix or a feature.

## Result

- Architecture summary: a system context view (users, external systems) and a
  container view (apps, API, DB, workers). Go deeper only where it helps.
- Problem areas, ranked, with evidence
- Refactoring strategy for each one worth doing
- The improved code, as small commits with tests

## Rules that matter here

- Refactor to make a coming change easy. With no change coming, write the plan
  down and stop.
- A bug you find gets written down and fixed separately with `playbook-debug`.
- Done means the house definition of done, including an independent review.
- Related skills: `how`, `codebase-design`, `blast-radius`, `safe-refactor`,
  `improve-codebase-architecture`.
