# Pipeline and stages

How the developer deck runs a feature from plan to test, and which skills each
stage uses. For installing and configuring, see the [README](../README.md).

## Pipeline flow

```
Task: "add feature X"   (in a repo whose AGENTS.md references Dev Deck)
└─ Main session (Claude Code or Codex; it loads that host's roles and skills)
   └─ pipeline skill  (orchestrates the three roles; not run by hand)
        ├─ PLANNER   — your strongest model
        │     new session · uses: roadmap, wayfinder/to-spec/to-tickets,
        │     pstack figure-it-out/how/why
        │     produces: .plan/plan.md + .plan/tickets.md
        │
        ├─ BUILDER   — a low-cost model
        │     new session per ticket · uses: implement/tdd, pstack
        │     architect/deslop/no-comments, ponytail
        │     produces: commits on the branch
        │
        └─ REVIEWER  — a strong model from a different provider
              new session · receives ONLY the diff + the plan entry + AGENTS.md
              (not the builder's session or self-report)
              uses: code-review, thermo-nuclear-code-quality-review, blast-radius,
              swarm, ponytail-review/audit, caveman
              produces: VERDICT: PASS | FAIL + findings
```

The reviewer's isolation is the key design point. A model that just reported the
change as working is biased toward agreeing with itself. A separate model that
only sees the diff and the spec has to verify the claim from evidence.

## Stage-by-stage breakdown

Both upstream packs describe work in six stages, but they cover different
ranges. **pstack** handles build/test/deploy and intentionally omits planning
and maintenance. **Matt's pack** handles planning and runs through to
maintenance. Dev Deck combines them: it uses Matt's planning skills, pstack's
build/test skills, and adds an isolated reviewer.

The three roles automate **Plan → Test**. **Deploy** and **Maintain** are not
part of the automated loop; you invoke those skills directly when needed.

### Stage 1 — Plan

- **Role:** planner (strongest model).
- **Approach:** start from the unknowns, not the idea. Learn the existing
  code, gather the answers the request is missing, then refine the idea into a
  spec and thin, independent tickets. For large or ambiguous work, resolve the
  major decisions before writing the spec. Research happens here, as the
  planner's first step, before it plans.
- **Skills:** Matt `research → to-questionnaire`, `grill-with-docs → to-spec →
  to-tickets`, `wayfinder → to-spec`; pstack `how → why → teach` (read the
  code), `figure-it-out → show-me-your-work` (large or unattended work);
  `roadmap` records the result in the project plan.
- **Gap it fills:** pstack has no requirements-gathering or intent skill.
  Matt's `to-spec` and `roadmap`'s intent step provide it.

### Stage 2 — Design

- **Role:** planner, completed before any build starts.
- **Approach:** fix the shape of the code before writing it. Sketch the types,
  test the risky part with throwaway code, compare candidate approaches and
  keep the best, and have the design reviewed before it becomes expensive.
  Keep the vocabulary and module boundaries explicit.
- **Skills:** pstack `architect → arena → interrogate`; Matt `handoff →
  prototype`, `domain-modeling → codebase-design`.
- **Output:** types/shape plus a recorded decision (an ADR via `roadmap` when
  the decision is hard to reverse).

### Stage 3 — Build

- **Role:** builder (low-cost model, one ticket at a time).
- **Approach:** test-first. Implement one piece (or a whole spec if it was
  sliced small enough). For a bug, reproduce it before fixing it. Follow the
  language's strict rules, then remove unnecessary code and comments from the
  diff. Ponytail applies YAGNI throughout: before adding code, check whether it
  already exists, is in the standard library, is a native feature, is an
  installed dependency, or can be a single line.
- **Skills:** Matt `implement → tdd`, `implement-spec → tdd`,
  `diagnosing-bugs → tdd`; pstack `tdd → typescript-best-practices`, `deslop →
  no-comments`; `ponytail`.

### Stage 4 — Test

- **Role:** reviewer (isolated — it never saw the builder's session).
- **Approach:** verify the change on the running application, not only in
  unit tests. Identify what the change could break, check performance numbers,
  review the diff from multiple angles, and remove anything that can be
  removed.
- **Skills:** pstack `create-verification-skill → swarm`, `blast-radius →
  benchmark-checklist`, `interrogate → thermo-nuclear-code-quality-review`;
  Matt `code-review`; `ponytail-review` / `ponytail-audit`; `caveman` keeps the
  output concise. (`anti-slop` is an Oxlint code lint, not a writing tool: its
  `install-anti-slop` skill adds the rules to a repo that asks for them.)
- **Gap it fills:** Matt's pack has no separate QA/e2e/browser-testing skill —
  testing happens in Build. pstack's verification and swarm skills cover it.

### Stage 5 — Deploy

- **Role:** you. Not part of the automated loop.
- **Approach:** make the pull request easy to review, write a clear
  description, follow it through to merge, and resolve conflicts as they occur.
- **Skills:** pstack `make-pr-easy-to-review → babysit → fix-merge-conflicts →
  get-pr-comments`; Matt `pr → wizard`.
- **Limitation:** pstack's release step stops at the merge. Neither pack
  includes CI/CD, release, or rollout skills.

### Stage 6 — Maintain

- **Role:** you, using `roadmap` to track the plan.
- **Approach:** triage new issues as they arrive, review completed work, and
  keep the plan accurate against what the code actually does.
- **Skills:** Matt `triage → implement`, `retro → improve-codebase-architecture`;
  `roadmap reconcile` for the plan document.
- **Limitation:** neither pack includes monitoring, logs, metrics, or incident
  skills. Maintenance here covers issues, agent setup, and code structure.

### Utility skills (not tied to a stage)

- **Router:** Matt `ask-matt` and pstack's router — "which skill do I need?"
- **Set up once:** Matt `setup-matt-pocock-skills`; Dev Deck `init` per project.
- **Interview and re-explain:** `grilling`, `grill-me`, `wait-what`.
- **Learn and write:** `teach`, `writing-for-agents`.

**Order:** Plan → Design → Build → Test are automated. Deploy and Maintain are
manual. This is the sequence the `pipeline` skill runs.

The two packs complement each other because of what each one omits:

- **pstack** omits planning and maintenance; its strength is the Test stage —
  verify on the running app, review the diff, check the numbers.
- **Matt's pack** is built for planning — gather missing answers, refine the
  idea into tickets — and is the only one of the two that reaches maintenance
  (triage, retro, architecture).
- **Dev Deck** adds the isolated reviewer, which neither pack provides on its
  own. That step is the difference between "the agent says it works" and "a
  separate model confirmed it."

Deploy and Maintain are manual steps. When the reviewer returns PASS, you take
the branch to a pull request (or merge) yourself. When a project becomes stale,
`roadmap reconcile` and Matt's `triage`/`retro` are the tools to use; they are
installed but do not run automatically.

