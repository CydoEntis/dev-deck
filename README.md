<p align="center"><img src="assets/logo.png" width="120" alt="Dev Deck" /></p>
<h1 align="center">Dev Deck</h1>

<p align="center">
  <strong>A personal agent pipeline — three roles, three models, one house style.
  Install once, use it in every repo.</strong>
</p>

---

Dev Deck is a thin **glue layer** on top of the skills you'd maintain yourself.
It pins the heavy lifting to well-kept upstream skill packs (pstack, Matt
Pocock's pack, Ponytail, antislop, caveman) and adds three things that are
yours: **three role definitions**, **your house conventions**, and **an
installer that wires it all into your hosts**.

The result: a planner that thinks hard, a builder that stays cheap, and a
reviewer that sees the work **blind** — so it can't be talked into rubber-
stamping what it didn't do.

## Why it's convenient

You stop maintaining a pile of workflow skills. Instead you maintain ~200
lines of *your own* taste:

| You own (small, yours) | Upstream pins you never edit |
|---|---|
| 3 role cards (`agents/`) | pstack, Matt Pocock, Ponytail, antislop, caveman |
| 3 convention files (`conventions/`) | roadmap, professor |

Your **conventions** travel with you via `conventions/`, not via a stack-pack
library. Every project just gets a thin `AGENTS.md` pointing at them. Update
an upstream? Bump a pin, re-run install. Change your taste? Edit the
convention file. Neither one ever means re-writing a skill.

## How a feature flows

```
User: "add feature X"   (in a repo whose AGENTS.md points at Dev Deck)
└─ Main session (any model; host auto-loads the roles + skills)
   └─ pipeline skill  (the conductor — you are not doing this by hand)
        ├─► PLANNER   — your strongest model
        │      fresh context · pulls: roadmap, wayfinder/to-spec/to-tickets,
        │      pstack figure-it-out/how/why
        │      emits: .plan/plan.md + .plan/tickets.md
        │
        ├─► BUILDER   — a cheap workhorse model
        │      fresh context per ticket · pulls: implement/tdd, pstack
        │      architect/deslop/no-comments, ponytail (always on)
        │      emits: commits on the branch
        │
        └─► REVIEWER  — a different-model-family strong model, BLIND
               fresh context · sees ONLY the diff + the plan entry + AGENTS.md
               (never the builder's session or self-report)
               pulls: code-review, thermo-nuclear review, blast-radius, swarm,
               ponytail-review/audit, caveman/antislop
               emits: VERDICT: PASS | FAIL + findings
```

The reviewer being blind is the whole point. A builder who just told you it
works will keep telling you it works. A fresh model that only sees the diff
and the spec has no loyalty to the work — it checks it.

## How we think, stage by stage

Both upstream packs describe work as six stages — but they disagree on the
ends. **pstack** is a *build/test/deploy machine*: it deliberately skips
planning ("the rule: answer the question, don't pre-plan") and ships no
maintenance skills. **Matt's pack** is built for *planning* and is the only
one of the two that runs all the way to maintenance. Dev Deck fuses them:
Matt's planning depth, pstack's test rigor, and a **blind reviewer** that
neither pack provides on its own.

Our three roles cover **Plan → Test**. **Deploy** and **Maintain** are escape
hatches — they live in the deck but only run when you invoke them.

### Stage 1 · Plan — *"what are we actually building, and do we know enough?"*

- **Owns it:** planner (your strongest model).
- **How we think:** don't start from the idea — start from the unknowns.
  Learn the code first, get the answers you lack, then grill the idea into a
  spec and thin, independent tickets. If the job is big and foggy, chart the
  big decisions before committing to a spec.
- **Skills pulled:** Matt `research → to-questionnaire`, `grill-with-docs →
  to-spec → to-tickets`, `wayfinder → to-spec`; pstack `how → why → teach`
  (learn the code first), `figure-it-out → show-me-your-work` (big or
  unattended jobs); `roadmap` places the result in the project's living plan.
- **Gap we cover:** pstack has no requirements-gathering or intent skill.
  Matt's `to-spec` and `roadmap`'s intent step fill that hole.

### Stage 2 · Design — *"what shape will the code take?"*

- **Owns it:** planner, settled before any build starts.
- **How we think:** settle the shape before writing anything. Sketch the
  types, try the risky part in throwaway code, let rival approaches compete
  and keep the best, and have models attack the design so it's robust before
  it's expensive. Keep the vocabulary and module boundaries explicit.
- **Skills pulled:** pstack `architect → arena → interrogate`; Matt `handoff →
  prototype`, `domain-modeling → codebase-design`.
- **Output:** types/shape + a recorded decision (an ADR via `roadmap` when it's
  expensive to reverse).

### Stage 3 · Build — *"the smallest change the evidence justifies"*

- **Owns it:** builder (cheap model, one ticket at a time).
- **How we think:** test-first. Build one piece (or the whole spec, if it was
  sliced thin enough); for a hard bug, reproduce before fixing. Follow the
  language's strict rules, then strip the AI junk from the diff. The YAGNI
  ladder stays on the whole time: does this need to exist at all?
- **Skills pulled:** Matt `implement → tdd`, `implement-spec → tdd`,
  `diagnosing-bugs → tdd`; pstack `tdd → typescript-best-practices`, `deslop →
  no-comments`; `ponytail` (always on).

### Stage 4 · Test — *"'it compiles' is not evidence"*

- **Owns it:** reviewer (a different model family, **blind** — it never saw the
  builder's session).
- **How we think:** prove it on the real app, not in a unit-test vacuum. Find
  what the change could break, sanity-check the numbers, attack the diff from
  several angles, and cut anything that can be cut.
- **Skills pulled:** pstack `create-verification-skill → swarm`, `blast-radius
  → benchmark-checklist`, `interrogate → thermo-nuclear-code-quality-review`;
  Matt `code-review`; `ponytail-review` / `ponytail-audit`; `caveman` +
  `antislop` keep the output decluttered.
- **Gap we cover:** Matt's pack has no separate QA/e2e/browser-testing skill —
  tests live in Build. pstack's verification + swarm is our safety net for
  that.

### Stage 5 · Deploy — *"get it merged, then stop"*

- **Owns it:** you. Deliberately not in the automated loop.
- **How we think:** make the PR easy to review, write a clear description,
  babysit it to merge, resolve conflicts as they come.
- **Skills pulled:** pstack `make-pr-easy-to-review → babysit →
  fix-merge-conflicts → get-pr-comments`; Matt `pr → wizard`.
- **Gap we accept:** pstack's release step stops at the merge; neither pack
  ships CI/CD, release, or rollout skills. That's yours to run.

### Stage 6 · Maintain — *"keep the plan true and the code healthy"*

- **Owns it:** you, with `roadmap` as the bookkeeper.
- **How we think:** sort new issues as they arrive, look back and tidy up, and
  keep the plan honest against what the code actually does.
- **Skills pulled:** Matt `triage → implement`, `retro →
  improve-codebase-architecture`; `roadmap reconcile` for the plan doc.
- **Gap we accept:** no monitoring, logs, metrics, or incident skills in
  either pack — maintenance here means issues, agent setup, and code shape,
  not observability.

### Anytime (utility skills, not stage-bound)

- **Router:** Matt `ask-matt` and pstack's router — "which skill do I want?"
- **Set up once:** Matt `setup-mattpocock-skills`; Dev Deck `init` per project.
- **Interview & re-explain:** `grilling`, `grill-me`, `wait-what`.
- **Learn & write:** `teach`, `writing-for-agents`.

**Best-practice order:** Plan → Design → Build → Test automated; Deploy and
Maintain by hand. That's exactly the pipeline the `pipeline` skill drives.

The shape of the two packs, and why they fit together:

- **pstack** is a *build/test/deploy machine*. It deliberately has no planning
  skill ("the rule: answer the question, don't pre-plan") and nothing for
  maintenance. Its superpower is the Test stage — prove it on the real app,
  attack the diff, vet the number.
- **Matt's pack** is built for *planning* — answer the questions you lack,
  sharpen the idea into tickets — and it's the only one of the two that runs
  all the way to maintenance (triage, retro, architecture).
- **Dev Deck stitches them**: Matt's planning depth, pstack's build/test
  rigor, and a **blind reviewer** in between that neither pack provides on its
  own. That blind step is the difference between "the agent thinks it works"
  and "a second brain that wasn't there confirmed it."

Deploy and Maintain are **escape hatches, not a loop**. When the reviewer says
PASS you take the branch to a PR (or merge) yourself; when a project gets
stale, `roadmap reconcile` and Matt's `triage`/`retro` are the tools you reach
for — they live in the deck, but they don't run without you.

## The roles

| Role | Model slot | Pulls | Emits |
|---|---|---|---|
| **Planner** | strongest ({{PLANNER}}) | roadmap, Matt planning, pstack learn/plan | plan + tickets under `.plan/` |
| **Builder** | cheap ({{BUILDER}}) | Matt implement, pstack build/clean, ponytail | commits on the branch |
| **Reviewer** | other-family strong ({{REVIEWER}}), blind | Matt code-review, pstack test/attack, ponytail-review, caveman/antislop | PASS / FAIL + findings |

Each role is a small markdown file. The `model:` frontmatter is a placeholder
the installer fills from your config — so no model is ever hard-coded in a
shipped file.

## Quickstart

**Install (Windows):**
```powershell
git clone <this repo> C:\dev\dev-deck
cd C:\dev\dev-deck
copy dev-deck.config.json.example dev-deck.config.json
# edit dev-deck.config.json → set your model slots + hosts
.\install\install.ps1
```

**Install (macOS / Linux / OMarchy):**
```bash
git clone <this repo> ~/dev-deck
cd ~/dev-deck
cp dev-deck.config.json.example dev-deck.config.json
# edit dev-deck.config.json
./install/install.sh
```

The installer pulls the pinned upstreams, copies their skills into your host's
global skill dir, writes the three role cards (models substituted), writes the
`pipeline` + `init` skills, and registers Context Mode MCP. It's idempotent —
run it again any time.

**Set up a project:** in any repo, ask for the **init** skill. It reads your
manifests, drafts a thin `AGENTS.md` (your stack + house-style pointer + commit
format + pipeline note), and writes it *without clobbering* anything that's
already there.

**Run the pipeline:** in a deck-ready repo, ask for the **pipeline** skill on a
feature. It deals planner → builder → reviewer and hands you the verdict.

## Updating

- **Refresh an upstream:** bump its pin in `upstream.json`, re-run install.
- **Verify:** run `install\doctor.ps1` (or `install.sh` sibling) — it checks
  pins are current, no skill-name collisions, roles are in place, MCP is
  reachable.

## Swapping hosts or machines

Edit `dev-deck.config.json` (model slots + `hosts` list) and re-run install.
The roles and conventions are host-agnostic markdown; the installer just maps
them onto whatever host you've enabled. Same on a brand-new Linux box — clone,
fill config, run `install.sh`.

Supported hosts: **OpenCode, Claude Code, Codex, Pi, DeepSeek harness.** Hosts
with native subagents (OpenCode, Claude Code) run the three roles as true
subagents; the rest run them as instruction files with sequential handoffs.

## Building your own

- **Add a convention:** drop a file in `conventions/`. Reference it from
  `agents/reviewer.md` and `conventions/code-style.md` so it gets enforced.
- **Add an upstream pin:** add a row to `upstream.json` (name, url, ref,
  skillsPath). Re-run install.
- **Change a role's behavior:** edit `agents/<role>.md` (it's git-tracked).
- **New host:** add a mapping row in `install.ps1` / `install.sh`.

## FAQ

- **Why does the reviewer see nothing?** Because a builder who said "it
  works" will keep saying it. The reviewer is a fresh, different-family model
  handed only the diff, the plan entry, and the repo's rules. It has to prove
  the claim itself.
- **Why do models live in `dev-deck.config.json` and not the agents?** So no
  model is baked into a shipped file. Anyone can point a role at whatever model
  they have — or leave it blank to inherit the host's default.
- **What happens when the reviewer fails?** Builder gets the findings as a new
  ticket, then re-review. Capped at **2 loops** — after that it stops and hands
  you the open findings, because the loop isn't converging and a human decision
  is needed.
- **Why no per-stack convention packs?** Each repo's `AGENTS.md` owns its own
  stack rules. A global pack library is just a maintenance treadmill — the
  global file is your taste; the local file is the project's reality.
- **Do I get a `config.json` in every repo?** No. Projects get only their
  `AGENTS.md`. Model overrides live in the one `dev-deck.config.json`, or in an
  optional per-project `.dev-deck.json` if you want one repo on a stronger
  model.

## License

MIT.

<sub>Salvaged in part from a private work playbook — the cross-stack contract
(`conventions/contract.md`) and the blind-verify pattern (`agents/reviewer.md`).
Aevox-specific content has been anonymized.</sub>
