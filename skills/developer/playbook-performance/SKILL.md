---
name: playbook-performance
description: Performance mode. Use when something is measurably too slow or too heavy - API latency, memory, DB queries, page load, React rendering. Measure first, fix the biggest cause, prove the speedup with numbers; behaviour unchanged.
---

# Playbook: Performance

Think like a performance engineer: speed, memory and scalability, proven with
numbers. Behaviour stays the same.

**Rules first.** The user's request wins, then the project's AGENTS.md and ADRs,
then the Dev Deck conventions (code-style, contract, commits), then this
playbook. If this playbook seems to conflict with a higher rule, follow the rule
and say so.

## Order of work

1. **State the goal as a number** on a user-facing metric where one exists: p95
   API latency, memory ceiling, throughput, or for web pages the Core Web Vitals
   at p75 (LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1; INP replaced FID). Name the
   workload, data size and device it is measured on.
2. **Measure the baseline**, from field data where it exists, then reproduce in
   the lab. Use the profiler for the layer:
   - API: `node --cpu-prof` / `--heap-prof`, or a 0x flame graph.
   - Browser: the DevTools Performance panel with calibrated CPU throttling.
   - React: the React DevTools Profiler on a production or profiling build, not
     dev mode.
   - DB: `pg_stat_statements` to find the costly queries, then
     `EXPLAIN (ANALYZE, BUFFERS)` on realistic data volumes, with writes wrapped
     in `BEGIN … ROLLBACK` (ANALYZE really runs the query).

   Find what actually limits it while the benchmark runs.
3. **Find the causes:**
   - bottlenecks (the hot path in the profile)
   - inefficient logic: N+1 queries (count queries per request), repeated work,
     the wrong data structure, a missing index (foreign key columns are not
     indexed automatically)
   - unnecessary rendering: state held higher than needed, Effects that set
     state and re-render in chains, wrappers that don't take JSX as children
   - long main-thread tasks on interactions: split the work and yield
4. **Fix the biggest cause first**, one change at a time, re-measuring after each.
5. **Stop** when the goal is met. Don't optimise what the profile doesn't show.

## Result

- Performance issues found, with measurements
- Optimisation strategy for each
- The improved code, with before and after numbers on the same workload

## Rules that matter here

- No optimisation without a measurement. A claimed speedup needs warm-up,
  several runs on the same machine and build, and the median plus spread (p95 or
  margin of error) before and after. A difference inside the noise is not a
  speedup.
- React memoization: if the project uses React Compiler, let it memoize; reach
  for `useMemo`/`useCallback` only for precise control (such as a stable Effect
  dependency) and don't add `memo`. Don't delete existing memoization without a
  test and a re-measure. Without the compiler, fix structure first and memoize
  only what the profiler shows.
- Tests stay green; behaviour is unchanged. Readability is part of the cost.
- The reviewer re-runs the benchmark, not just the test suite.
- Related skills: `benchmark-checklist`, `principle-explain-the-number`. Don't use
  clinic.js (unmaintained).
