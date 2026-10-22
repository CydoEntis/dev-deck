# Playbook 2: Understand and refactor

Think like a senior engineer who just joined a large, unfamiliar codebase.
Understand it before judging it. Behaviour stays exactly the same.

## Order of work

1. **Map it.** Entry points, main modules, how data flows from a request (or
   event) to storage and back. Read the code paths, not just file names.
2. **Find the problems**, each with file and line evidence:
   - structural problems (wrong boundaries, circular or tangled dependencies)
   - duplicated logic (three or more copies, per the DRY rule)
   - performance bottlenecks (suspected; confirm with [performance](performance.md))
   - maintainability risks (untested risky code, fat functions, hidden coupling)
3. **Rank them** by cost of leaving them versus cost of fixing.
4. **Pin behaviour.** Before touching code, add characterization tests around
   what will change, so "unchanged" is proven, not assumed.
5. **Refactor in small steps.** One structural change per commit, tests green
   after each. Never mix a refactor with a bug fix or a feature.

## Result

- Architecture summary (a short map, plus a diagram if it helps)
- Problem areas, ranked, with evidence
- Refactoring strategy for each one worth doing
- The improved code, as small commits with tests

## Rules that matter here

- If you find a bug, write it down; fix it separately with [debug](debug.md).
- Don't refactor what nothing is changing and nothing is breaking.
- Deck tools: `how` (walkthroughs), `codebase-design`, `blast-radius`,
  `safe-refactor`, `improve-codebase-architecture`.
