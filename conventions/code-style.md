# House Style — Code Conventions

These rules apply to every project in the deck. They are language-agnostic
principles, not stack-specific idioms. Per-project stack rules live in that
project's own `AGENTS.md`.

## Architecture

- **Vertical slice.** A feature lives in one place. Route, handler, logic,
  types, and tests sit together. No horizontal `controllers/` + `services/` +
  `models/` layer soup unless the project explicitly chose that shape and says
  so in its AGENTS.md.
- **Colocation.** A file lives next to the thing it serves. Tests beside
  source. Config beside the thing it configures. If two files are always
  changed together, they belong in the same place.
- **Small interfaces, deep modules.** Keep the public surface of any module
  tiny. Hide complexity behind a clean API. A module should be easy to use
  and hard to misuse.
- **New code is feature-specific by default.** It only earns a place in
  shared/common code once a second, distinct consumer needs it. No
  speculative abstractions.

## Functions

- **Small and explicit.** A function does one thing and its name says what.
  If you need a comment to explain what it does, it does too many things.
- **No fat functions.** A function past ~40 lines, or with more than ~3
  meaningful parameters, is a smell — split it. Prefer returning values over
  mutating shared state.
- **DRY.** Copy-paste a piece of logic twice and you may repeat it. A third
  time means extract it. Don't preemptively DRY code that hasn't proven it's
  duplicated.
- **KISS.** Prefer the simplest thing that works. Reach for the standard
  library and existing dependencies before writing new code.

## Comments

- **WHY, not WHAT.** Code shows what it does. A comment earns its place only
  when it records a non-obvious constraint, a subtle invariant, a workaround,
  or a decision's rationale.
- No narrative narration ("increment the counter", "return the result").
- No commented-out code. Delete it; git remembers.
- No ticket/issue IDs in comments — those belong in the commit message.
- Mark deliberate shortcuts with a `shortcut:` comment so they can be found
  and revisited.

## Errors

- **Fail explicitly.** Never swallow an error silently. Handle it or
  propagate it.
- **Expected** failures (validation, not-found, conflict) use structured,
  typed results. **Unexpected** failures propagate to a single top-level
  handler.
- No bare `catch` / bare `except`. Catch the specific error you can handle.

## Testing

- **"It compiles" is not done.** Prove the change on the running system:
  run the test suite and, where feasible, exercise the real path.
- Test what the user sees and does, not internal state or implementation
  details.
- One test = one behavior. Name the test after the behavior.
- Tests are cheap insurance for risky logic: branching, loops, parsers,
  money, security. Skip ceremony for trivial glue.

## Git & commits

See `conventions/commits.md`. In short: one logical change per commit,
`feat/fix/...` Conventional Commit subjects, `git add <paths>` never `-A`.

## What counts as "done"

A change is done when all of these hold:

1. It type-checks / compiles.
2. Its tests pass, including the new ones.
3. It was exercised on the running app (not just unit-tested in isolation).
4. It follows this house style and the project's own AGENTS.md.
5. An independent review (a different model or a human) has confirmed it.
