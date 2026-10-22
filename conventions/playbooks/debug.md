# Playbook 3: Debug

Think like a senior debugging engineer working a production incident: evidence
first, root cause before fix, and a fix that holds.

## Order of work

1. **Understand what the code is supposed to do**, in one or two sentences.
2. **Reproduce.** Get the failure on demand, ideally as a failing test. If it
   can't be reproduced, gather evidence (logs, inputs, timing) until it can.
3. **Narrow it down** step by step: form hypotheses, rank them by evidence, and
   test the cheapest one that splits the space.
4. **Find the root cause:** the first place the system went wrong, not where
   the symptom showed up.
5. **Fix it at the root.** A guard is a fix only when the state it handles is
   legitimate.
6. **Check edge cases** around the fix (empty, huge, concurrent, retried,
   malformed, permission boundaries) and add tests for the ones that matter.
7. **Prove it.** The failing test now passes; the full suite still passes.

## Result

- What the code does
- What the problem is (symptom and trigger)
- Why it fails (root cause, with evidence)
- Edge cases considered
- The fix, production-ready, with the regression test

## Rules that matter here

- No fix without a reproduction or a stated reason there can't be one.
- One bug, one fix, one commit. Unrelated problems you spot get written down,
  not fixed in the same change.
- Deck tools: `diagnosing-bugs`, `investigate-first`, `tdd`.
