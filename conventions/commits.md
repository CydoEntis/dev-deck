# Commit Conventions

## Format

```
<type>(<scope>): <summary>

<body — optional>

<footer — optional>
```

## Types

| Type | When |
|---|---|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `refactor` | Code change that neither adds a feature nor fixes a bug |
| `docs` | Documentation only |
| `test` | Adding or fixing tests |
| `chore` | Build, CI, tooling, dependency updates |
| `perf` | Performance improvement |
| `style` | Formatting, whitespace, semicolons (no logic change) |

## Rules

- **Scope** is the feature or module affected: `feat(auth)`, `fix(parser)`.
  Omit scope if the change is cross-cutting.
- **Summary** is imperative, present tense: "add", "fix", "remove" — not
  "added", "fixes", "removing". Max 72 chars.
- **One commit per logical change.** If you made three changes, make three
  commits. Don't bundle.
- **No ticket/issue IDs in the commit body.** The PR links them.
- **No "wip", "tmp", "asdf" commits.** If it's not ready, don't commit it.
- **Rebase, don't merge** for feature branches (unless the project uses
  merge commits explicitly).
- **Never `git add -A`.** Stage specific files.

## Examples

```
feat(auth): add refresh-token rotation

fix(parser): handle empty CSV header row

refactor: extract validate_body into shared middleware

docs: update API reference for /v2 endpoints

test: add integration tests for payment webhook

chore(deps): bump zod from 3.23 to 4.1
```
