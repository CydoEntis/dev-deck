<p align="center"><img src="assets/logo.png" width="300" alt="Dev Deck" /></p>

<p align="center">
  <strong>A three-role agent pipeline: planner, builder, reviewer. Each role runs
  on the model you configure; the reviewer verifies work it did not produce.</strong>
</p>

---

Dev Deck is a set of role definitions, build conventions, and an installer that
wrap third-party agent skills. It pins the workflow skills to maintained
upstream packs (pstack, Matt Pocock's pack, Ponytail, anti-slop, caveman, and
your own roadmap skill) and adds three things you control: three role
definitions, your build conventions, and a cross-stack API contract.

The pipeline has three roles:

- **Planner** — turns a request into a plan and a list of independent tickets.
- **Builder** — implements one ticket at a time, test-first.
- **Reviewer** — checks the diff. It starts a fresh session and only receives
  the diff, the plan entry, and the repo's `AGENTS.md`. It does not see the
  builder's session or self-report, so it verifies the change independently.

## Maintenance model

You maintain the role files and conventions. Everything else is pinned upstream
and refreshed by re-running the installer.

| Maintained by you | Pinned upstream (do not edit) |
|---|---|
| 3 role files (`agents/`), 3 convention files (`conventions/`) | pstack, Matt Pocock, Ponytail, anti-slop, caveman, roadmap |

Your conventions live in `conventions/`. Each project gets a short `AGENTS.md`
that points at them. To update an upstream, change its pin in `upstream.json`
and re-run the installer. To change your conventions, edit the file. Neither
requires rewriting a skill.

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

## The roles

| Role | Model slot | Uses | Produces |
|---|---|---|---|
| **Planner** | strongest | roadmap, Matt planning, pstack learn/plan | plan + tickets under `.plan/` |
| **Builder** | low-cost | Matt implement, pstack build/clean, ponytail | commits on the branch |
| **Reviewer** | strong, different family from the builder | Matt code-review, pstack test, ponytail-review, caveman | PASS / FAIL + findings |

Each role is a small file in `agents/`. The model is not in that file: the
installer fills it in from `dev-deck.config.json`, so no model is hard-coded in
a shipped file. Each host gets its own copy: `~/.claude/agents/<role>.md` for
Claude Code, and `~/.codex/agents/<role>.toml` for Codex.

## Prerequisites

- **Windows** with PowerShell 5.1 or newer (`install\install.ps1`), or
  **macOS / Linux** with Python 3.8 or newer (`install/install.sh`). See
  [Platforms](#platforms).
- **git**, on PATH.
- **Node.js**, on PATH. Context Mode runs through `npx`.
- **Claude Code CLI** (`claude`) and/or **Codex CLI** (`codex`), on PATH, for the
  hosts you enable. The installer registers Context Mode through these CLIs and
  reports an issue if one is missing.

## Quickstart

**1. Clone the repo**

```powershell
git clone https://github.com/CydoEntis/dev-deck C:\dev\dev-deck
cd C:\dev\dev-deck
```

**2. Create your config: choose your packs and models** (see [Configuration](#configuration))

```powershell
copy dev-deck.config.json.example dev-deck.config.json
notepad dev-deck.config.json
```

**3. Run the installer**

```powershell
.\install\install.ps1
```

It pulls the pinned upstreams for your enabled packs into `cache/`, copies their
skills into `~/.claude/skills`, and, when the `dev-deck` pack is enabled, writes
the three role files for each host you enabled and registers Context Mode with
Claude Code and Codex. It exits 0 on success and 1 if anything failed, with the
reason printed. It is idempotent: run it again to refresh.

**4. Verify**

```powershell
.\install\doctor.ps1
```

The doctor checks that the config exists, no role file still has an unfilled
`{{...}}` model placeholder, every installed skill has a `SKILL.md`, the
required `roadmap` skill is installed, and Context Mode is registered in each
enabled host. It exits 0 only when all of those pass.

**Set up a project:** in any repo, invoke the **init** skill. It reads your
manifests, drafts a short `AGENTS.md` (your stack, a pointer to the house
style, the commit format, and a pipeline note), and writes it without
overwriting anything that is already there.

**Run the pipeline:** in a configured repo, invoke the **pipeline** skill on a
feature. It runs planner → builder → reviewer and returns the verdict. Run it
from the host you want: a Claude Code session uses the `claude` model slots, and
a Codex session uses the `codex` slots.

## Configuration

`dev-deck.config.json` is git-ignored and lives in the repo root. Start from
`dev-deck.config.json.example`. It has three keys:

```json
{
  "packs": ["dev-deck"],
  "hosts": ["claude", "codex"],
  "models": {
    "claude": { "planner": "<model>", "builder": "<model>", "reviewer": "<model>" },
    "codex":  { "planner": "<model>", "builder": "<model>", "reviewer": "<model>" }
  }
}
```

- **`packs`** — which packs to install. `"dev-deck"` is the planner, builder and
  reviewer roles, the `pipeline` and `init` skills, and the pinned workflow
  skills. `"designer"` is for app design work and has no skills yet, so it
  installs nothing for now. Use `["dev-deck"]`, `["designer"]`, or
  `["dev-deck", "designer"]`. Each pin in `upstream.json` lists the packs that
  install it.
- **`hosts`** — which hosts to install for: `"claude"`, `"codex"`, or both.
  Only hosts listed here get role files or MCP registration.
- **`models.<host>.<role>`** — the model each role uses on that host. Use the
  exact model ID that host accepts. Claude Code also accepts the aliases
  `opus`, `sonnet`, and `haiku`. Leave a value empty (`""`) to inherit that
  host's default model.

Example for a Claude Code user: set the planner and reviewer to your strongest
Claude model and the builder to a cheaper one. Use model IDs your host accepts;
the installer does not check them.

**Keep the reviewer in a different model family from the builder.** That is the
point of the isolated reviewer. If `builder` and `reviewer` are both Claude
models, the reviewer is only a second opinion from the same family. Setting
`reviewer` to a Codex model on the `codex` host is the cross-family option.

After editing the config, run `.\install\install.ps1` again, then check the role
file, for example `Select-String "^model:" $HOME\.claude\agents\planner.md`.

## Updating

- **Refresh an upstream:** change its pin in `upstream.json`, then re-run
  `.\install\install.ps1`.
- **Change a model:** edit `dev-deck.config.json`, then re-run the installer.
- **Verify:** run `.\install\doctor.ps1`.

## Platforms

- **Windows (PowerShell):** supported. `install\install.ps1` and
  `install\doctor.ps1` are the tested path.
- **macOS and Linux:** `install/install.sh` and `install/doctor.sh` run
  `install/install.py` and `install/doctor.py`, which do the same work as the
  PowerShell scripts. The Python logic is tested on Windows with Python 3.14
  and through the shell wrapper under Git Bash. It has **not yet been run on
  macOS or Linux**, so treat it as untested there until someone runs it. Run
  `./install/install.sh`, then `./install/doctor.sh`.

## Hosts

Supported hosts: **Claude Code and Codex.** Both get the three roles as native
subagents: Claude Code from `~/.claude/agents` as markdown, Codex from
`~/.codex/agents` as TOML. Both also get Context Mode registered as an MCP
server.

Pi, OpenCode and DeepSeek are not supported. Pi has no subagents, so the three
roles cannot run as separate agents there.

## Contributing

- **Add a convention:** add a file in `conventions/`. Reference it from
  `agents/reviewer.md` and `conventions/code-style.md` so it is enforced.
- **Add an upstream pin:** add a row to `upstream.json` (name, url, ref,
  skillsPath). Re-run the installer. Set `"required": true` to make the doctor
  fail when the skill is missing.
- **Change a role's behavior:** edit `agents/<role>.md`.
- **Add a host:** add a writer for it in `install/install.ps1` and
  `install/install.py`, and a check in `install/doctor.ps1` and `install/doctor.py`.
- **Add a pack:** make a folder `skills/<pack>/` with one folder per skill, and
  list the pack name in the `packs` of each pin that belongs to it.

## FAQ

- **Why does the reviewer see nothing from the builder?** A model that
  reported the change as working is biased toward agreeing with itself. The
  reviewer is a fresh model handed only the diff, the plan entry, and the
  repo's rules. It must verify the claim from evidence.
- **Why are models in `dev-deck.config.json` and not in the role files?** So
  no model is hard-coded in a shipped file. Anyone can point a role at any
  available model, or leave it blank to inherit the host's default.
- **What happens when the reviewer fails?** The builder receives the findings
  as a new ticket, then the review runs again. This is capped at 2 loops —
  after that, the pipeline stops and returns the open findings, because the
  loop is not converging and a human decision is needed.
- **Why are there no per-stack convention packs?** Each repo's `AGENTS.md`
  owns its own stack rules. A global pack library is a maintenance burden; the
  global file holds your taste, and the local file holds the project's actual
  setup.
- **Does each repo get a config file?** No. Projects get only their
  `AGENTS.md`. All model settings live in the one `dev-deck.config.json`.

## License

MIT.
