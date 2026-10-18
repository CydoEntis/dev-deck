---
name: init
description: Set up a repository for the Dev Deck pipeline. Detects the stack from manifests, drafts a thin AGENTS.md with that project's rules plus a pointer to the shared house style, and confirms it with the user. Use on a repo that has no AGENTS.md yet, or when the user says "set this repo up for dev deck". Never overwrites existing conventions.
---

# Init

Make a repo "deck-ready": give it a thin `AGENTS.md` that says which stack
rules apply and points at the shared conventions.

## Steps

### 1. Detect the stack

Read, if present: `package.json` (deps + scripts), `tsconfig.json`,
`Cargo.toml`, `go.mod`, `pyproject.toml`, `requirements.txt`, `Gemfile`,
`.csproj`/`.sln`, Dockerfiles, CI config. Produce a list of detected facts:
language, framework, runtime version, test runner, linter, package manager,
API style (REST/GraphQL/tRPC/none), frontend tooling.

### 2. Check what already exists

- If `AGENTS.md` or `CLAUDE.md` already exists, read it. If it already carries
  a "Dev Deck" section, stop: report that the repo is already set up and
  offer to update it instead.
- If the repo has its own architecture docs (e.g. `docs/ARCHITECTURE.md`),
  note them — the AGENTS.md will point at them, not duplicate them.

### 3. Draft the AGENTS.md section

Draft a short section (15–40 lines). Include:

```markdown
## Dev Deck

- **Stack:** <language, framework, runtime> (detected from <manifest>)
- **House style:** the shared conventions apply — vertical slice,
  colocation, small explicit functions, DRY/KISS, WHY-not-WHAT comments.
- **Commits:** `feat(scope): ...` / `fix(scope): ...`, one logical change per
  commit, no `git add -A`.
- **Stack rules:**
  <3–10 bullet lines of the rules that actually matter for THIS stack —
  e.g. "Rust: no unwrap outside tests, Result across module boundaries",
  "React: function components, TanStack Query for server state",
  "FastAPI: Pydantic at every boundary, no raw dict responses">
- **API contract:** <if the repo talks to other stacks, point at
  conventions/contract.md and say which side this repo is>
- **Pipeline:** feature work goes through the pipeline skill
  (planner → builder → reviewer). Quick fixes can be done in-session.
```

The stack bullets are per-project opinion the user owns: start from general
best practice for that stack, mark each one as a suggestion, and let the user
edit, drop, or add lines. Do not invent project-specific architecture
decisions — ask.

### 4. Confirm and write

Show the draft. On approval:
- No existing AGENTS.md → create it with the section (plus a one-line
  pointer to `CLAUDE.md` if the host uses that name).
- Existing AGENTS.md → append the section under the existing content,
  never rewrite existing lines.
- Never commit; suggest the commit message `docs: add dev deck conventions`.

### 5. Report

What was detected, what was written, what was left to the user to fill in,
and the next step: "run the pipeline for your first feature".
