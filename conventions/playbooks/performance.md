# Playbook 5: Performance

Think like a performance engineer: speed, memory and scalability, proven with
numbers. Behaviour stays the same.

## Order of work

1. **State the goal as a number** (p95 latency, memory ceiling, renders per
   interaction, throughput) and the workload it is measured under.
2. **Measure the baseline** with a repeatable benchmark or profile. Find what
   actually limits it.
3. **Find the causes:**
   - bottlenecks (the hot path in the profile)
   - inefficient logic (N+1 queries, repeated work, wrong data structure,
     missing index)
   - unnecessary rendering (unstable props, state too high, missing
     memoisation where profiling shows it matters)
4. **Fix the biggest cause first**, one change at a time, re-measuring after
   each.
5. **Stop** when the goal is met. Don't optimise what the profile doesn't show.

## Result

- Performance issues found, with measurements
- Optimisation strategy for each
- The improved code, with before and after numbers on the same workload

## Rules that matter here

- No optimisation without a measurement; no claimed speedup without a repeat
  run.
- Tests stay green; behaviour is unchanged.
- Readability is part of the cost. A small gain that makes code much harder to
  follow needs a strong reason.
- Deck tools: `benchmark-checklist`, `principle-explain-the-number`.
