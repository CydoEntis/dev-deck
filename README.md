<p align="center"><img src="assets/logo.png" width="300" alt="Dev Deck" /></p>

<h1 align="center">Dev Deck</h1>

<p align="center">
  Installable agent setups for <strong>building software</strong> and <strong>designing apps</strong>.
  Pick a deck, run the installer, and your AI coding tools get the skills and roles.
</p>

---

## Contents

- [What it is](#what-it-is)
- [Decks](#decks)
- [Quick start](#quick-start)
- [Configuration](#configuration)
- [Verify and update](#verify-and-update)
- [Requirements and platforms](#requirements-and-platforms)
- [How it works](#how-it-works)
- [Customize](#customize)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)

## What it is

Dev Deck is a platform for installing curated agent skills. It is a repository
with three parts:

- **Upstream skill packs**, pinned to specific repositories and refreshed by the
  installer (pstack, Matt Pocock's pack, ponytail, anti-slop, caveman, roadmap,
  Impeccable, Intent, and Emil Kowalski's skills).
- **Role definitions and conventions** you control: a planner, builder and
  reviewer, plus your coding conventions.
- **An installer and health check** for Windows (PowerShell) and macOS/Linux
  (Python), which writes everything into the folders your tools read.

The developer pipeline's key idea is a **blind reviewer**: the reviewer starts a
fresh session and sees only the diff, the plan entry and the repo's `AGENTS.md`.
It never sees the builder's session or its claims, so it checks the change
independently.

## Decks

A **deck** is a set of skills you install from Dev Deck. Install one or both.

| | **developer** | **designer** |
|---|---|---|
| For | Building software: planning, coding, reviewing | Designing app UI and UX: screens, flows, copy, motion |
| Roles (planner, builder, reviewer) | Yes | No |
| Context Mode MCP server | Yes | No |
| Works in | Claude Code and Codex | Claude Code |
| Project setup | `init` skill (optional `AGENTS.md`) | `/impeccable init` (writes `PRODUCT.md`) |

**Choose:**
- Building a feature or fixing a bug: `developer`.
- Working on a screen's look, layout, copy or motion: `designer`.
- Both: a design task can use `designer` skills, and a build task can use the
  `developer` pipeline.

**What `developer` installs**
- Roles: `planner`, `builder`, `reviewer`, for Claude Code and Codex.
- Skills: `pipeline`, `init`, plus the pinned workflow skills from pstack, Matt
  Pocock's pack, ponytail, anti-slop, caveman and roadmap. roadmap is required.

**What `designer` installs**
- **Impeccable** (`pbakaus/impeccable`, Apache-2.0): the `/impeccable` skill with
  24 commands. Start each project with `/impeccable init`. Common commands:
  `critique`, `audit`, `polish`, `shape`, `animate`, `bolder`, `quieter`.
- **Intent** (`ghaida/intent`, CC0), picked: `/evaluate`, `/wireframe`,
  `/articulate`, `/include`, `/fortify`. Some picks point at skills that are not
  installed (`/journey`, `/organize`), so those cross-references do not resolve.
- **Emil Kowalski's skills** (`emilkowalski/skills`, MIT), picked:
  `emil-design-eng`, `animate`, `animation-performance`, `review-animations`,
  `break-ui`, `mobile-native`, `apple-design`, `animation-vocabulary`.

The picks are the `include` lists on the `intent` and `emil` pins in
`upstream.json`. Edit them and re-run the installer to change what installs.

## Quick start

Requirements are listed in [Requirements and platforms](#requirements-and-platforms).

**1. Clone the repository**

```powershell
git clone https://github.com/CydoEntle/dev-deck C:\dev\dev-deck
cd C:\dev\dev-deck
```

**2. Create your config** and choose your decks and models (see
[Configuration](#configuration)).

```powershell
copy dev-deck.config.json.example dev-deck.config.json
notepad dev-deck.config.json
```

**3. Run the installer**

```powershell
.\install\install.ps1
```

**4. Verify**

```powershell
.\install\doctor.ps1
```

The doctor exits 0 when every check passes.

**Next steps**

- In a project, run the **init** skill (developer) or **`/impeccable init`**
  (designer) to set it up.
- In a configured repo, invoke the **pipeline** skill to run planner, builder
  and reviewer on a feature.

## Configuration

`dev-deck.config.json` is git-ignored and lives in the repository root. Start from
`dev-deck.config.json.example`.

```json
{
  "decks": ["developer", "designer"],
  "hosts": ["claude", "codex"],
  "models": {
    "claude": { "planner": "<model>", "builder": "<model>", "reviewer": "<model>" },
    "codex":  { "planner": "<model>", "builder": "<model>", "reviewer": "<model>" }
  }
}
```

| Key | Meaning |
|---|---|
| `decks` | Which decks to install: `"developer"`, `"designer"`, or both. |
| `hosts` | Which tools get role files: `"claude"`, `"codex"`, or both. Only used by the `developer` deck. |
| `models.<host>.<role>` | The model each role uses on that host. Use IDs the host accepts. Claude Code also accepts `opus`, `sonnet` and `haiku`. An empty string inherits the host's default. |

**Keep the reviewer in a different model family from the builder.** The point of
the reviewer is an independent check. If `builder` and `reviewer` are the same
family, the review is a second opinion from the same model family. Using a Codex
model for the reviewer on the `codex` host gives a cross-family check.

After editing the config, re-run the installer. The installer does not validate
model IDs, so check them with your host.

## Verify and update

- **Verify:** `.\install\doctor.ps1` checks the config, that no role file still has
  an unfilled `{{...}}` placeholder, that every installed skill has a `SKILL.md`,
  that the required `roadmap` skill is installed, and that Context Mode is
  registered in each enabled host.
- **Update:** re-run `.\install\install.ps1`. It is idempotent. It pulls the latest
  upstreams and refreshes what it installed.
- **Change a deck or skill:** change `decks` in the config, or the `include` or
  `exclude` lists on a pin in `upstream.json`, then re-run the installer. Skills
  it installed earlier that are no longer selected are removed.
- **Remove a deck's roles or MCP registrations:** the installer does not remove
  these. Delete `~/.claude/agents/{planner,builder,reviewer}.md` and the
  `context-mode` entries by hand.

## Requirements and platforms

**Windows** (tested):
- PowerShell 5.1 or newer.
- git and Node.js on PATH. Context Mode runs through `npx`.
- The `claude` and/or `codex` CLI on PATH, for the hosts you enable.
- Installer: `install\install.ps1`. Health check: `install\doctor.ps1`.

**macOS and Linux** (not yet verified on those systems):
- Python 3.8 or newer, plus git and Node.js on PATH.
- The same CLIs as Windows.
- Run `./install/install.sh`, then `./install/doctor.sh`. These run the Python
  implementation in `install/install.py` and `install/doctor.py`. The Python logic
  has been tested on Windows and through a shell wrapper under Git Bash. It has
  not been run on macOS or Linux yet.

**Hosts:** Claude Code and Codex. Pi, OpenCode and DeepSeek are not supported. Pi
has no subagents, so the three roles cannot run separately there.

## How it works

The developer deck runs a feature through three roles: planner, builder and
reviewer. The planner turns a request into tickets. The builder implements one
ticket at a time, test-first. The reviewer checks each change blind. If the
reviewer fails a change, the builder gets the findings and tries again, up to two
loops. After that the pipeline stops and reports the open findings for a person to
decide.

Each role is a small file in `agents/`. The model is not in that file: the
installer fills it in from your config, so no model is hard-coded in a shipped
file. Each host gets its own copy: `~/.claude/agents/<role>.md` for Claude Code,
and `~/.codex/agents/<role>.toml` for Codex.

For the full flow and the skills each stage uses, see
[docs/pipeline.md](docs/pipeline.md).

## Customize

- **Change a role's behavior:** edit `agents/<role>.md`.
- **Add a convention:** add a file in `conventions/` and reference it from
  `agents/reviewer.md` and `conventions/code-style.md`, so it is enforced.
- **Add an upstream pin:** add an entry to `upstream.json` with `name`, `url`,
  `ref`, `skillsPath` and `decks`. Add `include` or `exclude` to choose skills
  from it, and `"required": true` to make the doctor fail when it is missing.
- **Add a deck:** create `skills/<deck>/` with one folder per skill, and list the
  deck name in the `decks` of each pin that belongs to it. A deck can also be only
  upstream pins, with no folder.
- **Add a host:** add a writer in `install/install.ps1` and `install/install.py`,
  and a check in `install/doctor.ps1` and `install/doctor.py`.

## FAQ

**Why does the reviewer see nothing from the builder?**
A model that reported its change as working tends to agree with itself. The
reviewer starts fresh with only the diff, the plan entry and the repo's rules, so
it has to verify the claim from the evidence.

**Why are models in the config and not in the role files?**
So no model is hard-coded in a shipped file. You can point any role at any model
you have, or leave it empty to inherit the host's default.

**What happens when the reviewer fails a change?**
The builder receives the findings and the review runs again. This is capped at two
loops. After that the pipeline stops and returns the open findings, because the
loop is not converging and a person needs to decide.

**Does each project get a config file?**
No. A project gets only its `AGENTS.md`, from the `init` skill. All model settings
live in the one `dev-deck.config.json`.

**Why are there no per-stack convention packs?**
Each repository's `AGENTS.md` owns its stack rules. A global library of stack packs
would be hard to maintain. The global conventions hold your preferences, and the
project file holds what is true for that project.

**Can I use only the designer deck without installing anything for development?**
Yes. Set `"decks": ["designer"]`. No roles and no MCP registrations are written.

## Contributing

Issues and pull requests are welcome. Before opening a pull request:

1. Run both installer and doctor on Windows, and confirm the doctor passes.
2. Keep the PowerShell and Python implementations in step. A change to
   `install.ps1` usually needs the matching change in `install.py`.
3. Use Conventional Commits, for example `feat(install): ...` or `docs(readme): ...`.

## License

MIT. See [LICENSE](LICENSE).

The upstream skill packs keep their own licenses: Apache-2.0 for Impeccable,
CC0 for Intent, and MIT for Emil Kowalski's skills. Each pinned repository's
license applies to the code it provides.
