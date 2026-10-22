---
name: playbook-debug
description: Debug mode. Use when something is broken, flaky, hard to reproduce, or failing in production - stop the bleeding, reproduce, find the root cause, fix it at the origin with a regression test.
---

# Playbook: Debug

Think like a senior debugging engineer working a production incident: evidence
first, root cause before fix, and a fix that holds.

**Rules first.** The user's request wins, then the project's AGENTS.md and ADRs,
then the Dev Deck conventions (code-style, contract, commits), then this
playbook. If this playbook seems to conflict with a higher rule, follow the rule
and say so.

## Order of work

0. **In production, stop the bleeding first.** Roll back, turn off the flag, or
   shed load. Keep the logs and evidence. A mitigation is not a fix; root-cause
   work starts after.
1. **Understand what the code is supposed to do**, in one or two sentences.
2. **Reproduce.** Get the failure on demand as a failing test, and watch it
   fail. Shrink the input and steps to the smallest case that still fails. If it
   won't reproduce, gather evidence first: logs, metrics and traces for the
   request (follow its request id), plus inputs and timing.
3. **Narrow it down.** Ask what changed last (deploys, config, dependencies,
   data, load). If it used to work, run `git bisect run <test-script>` (exit 125
   skips commits that won't build). Otherwise form hypotheses, rank them by
   evidence, favour common causes over exotic ones, and test the cheapest one
   that splits the space. Write down each hypothesis, prediction and result,
   including the ones that failed. Correlation is not cause.
4. **Find the root cause:** the first place the system went wrong, not where the
   symptom showed up.
5. **Fix it at the root.** A guard is a fix only when the state it handles is
   legitimate.
6. **Check edge cases** around the fix (empty, huge, concurrent, retried,
   malformed, permission boundaries) and add tests for the ones that matter.
7. **Prove it.** The regression test fails without the fix and passes with it,
   and catches the class of bug, not just the one input. The full suite passes.

## Result

- What the code does
- What the problem is (symptom and trigger)
- Why it fails (root cause, with evidence)
- Edge cases considered
- The fix, production-ready, with the regression test
- For a production incident: a blameless postmortem (impact, timeline,
  contributing causes, follow-up actions)

## Rules that matter here

- No fix without a reproduction or a stated reason there can't be one.
  Mitigations (rollback, flag off) don't need one.
- One bug, one fix, one commit. Other problems you spot get written down, not
  fixed in the same change.
- Temporary debug logging goes through the project's logger and comes out before
  merge.
- The reviewer re-runs the reproduction, not just the test suite.
- Related skills: `diagnosing-bugs`, `investigate-first`, `tdd`.
