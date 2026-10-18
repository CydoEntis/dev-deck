<p align="center"><img src="assets/logo.png" width="300" alt="Dev Deck" /></p>

<h1 align="center">Dev Deck</h1>

<p align="center">
  Installable skill decks for <strong>building software</strong> and <strong>designing apps</strong>.
  Install a deck as a plugin with two commands, for Claude Code or Codex, on Windows, macOS or Linux.
</p>

---

## Contents

- [What it is](#what-it-is)
- [Decks](#decks)
- [Install](#install)
- [Update](#update)
- [What you get, by tool](#what-you-get-by-tool)
- [Advanced: the installer script](#advanced-the-installer-script)
- [Requirements](#requirements)
- [How it works](#how-it-works)
- [Customize](#customize)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)

## What it is

Dev Deck is a set of agent skills, grouped into two installable **decks**:

- **developer** for building software: a planner, builder and reviewer that
  work through a feature, plus planning, coding and review skills.
- **designer** for designing app UI and UX: critique, accessibility, copy,
  wireframes and motion skills.

The skills come from upstream projects (pstack, Matt Pocock's pack, ponytail,
anti-slop, caveman, roadmap, Impeccable, Intent and Emil Kowalski's skills) and
are packaged here so a single install works. Each upstream license is kept. See
[License](#license).

The developer deck's key idea is a **blind reviewer**. The reviewer starts a
fresh session and sees only the diff, the plan entry and the repo's `AGENTS.md`.
It never sees the builder's session or its claims, so it checks the change
independently.

## Decks

| | **developer** | **designer** |
|---|---|---|
| Use it for | Building software: planning, coding, reviewing | Designing app UI and UX: screens, flows, copy, motion |
| Planner, builder, reviewer roles | Yes (Claude Code; Codex with the script) | No |
| Skills | 131 in total, including pipeline and init | Impeccable, 5 Intent skills, 8 Emil Kowalski skills |
| Works in | Claude Code and Codex | Claude Code and Codex |

**Choose**

- Building a feature or fixing a bug: install `developer`.
- Working on a screen's look, layout, copy or motion: install `designer`.
- Both: install both. A design task can use the designer skills, and a build
  task can use the developer pipeline.

**What `developer` contains**

- `pipeline` (runs planner, builder and reviewer on a feature) and `init` (sets
  up a project's `AGENTS.md`).
- Workflow skills from pstack, Matt Pocock's pack, ponytail, anti-slop, caveman
  and roadmap.
- Context Mode, an MCP server that keeps tool output out of the chat context.

**What `designer` contains**

- **Impeccable** (Apache-2.0): the `/impeccable` skill with 24 commands. Start each
  project with `/impeccable init`, which writes `PRODUCT.md`. Common commands:
  `critique`, `audit`, `polish`, `shape`, `animate`, `bolder`, `quieter`.
- **Intent** (CC0), five skills: `evaluate` (heuristic review ranked by severity),
  `wireframe`, `articulate` (UI copy), `include` (accessibility), and `fortify`
  (empty, loading and error states). Some point at skills that are not installed
  (`/journey`, `/organize`), so those cross-references do not resolve.
- **Emil Kowalski's skills** (MIT), eight skills: `emil-design-eng`, `animate`,
  `animation-performance`, `review-animations`, `break-ui` (stress-test with
  worst-case data), `mobile-native`, `apple-design`, and `animation-vocabulary`.

## Install

You need the CLI for the tool you use: `claude` for Claude Code, or `codex` for
Codex. Run these in a terminal, not inside a chat. The commands are the same on
Windows, macOS and Linux.

**Claude Code**

```bash
claude plugin marketplace add CydoEntis/dev-deck
claude plugin install developer@dev-deck    # building software
claude plugin install designer@dev-deck     # designing apps
```

**Codex**

```bash
codex plugin marketplace add CydoEntis/dev-deck
codex plugin add developer@dev-deck         # building software
codex plugin add designer@dev-deck          # designing apps
```

Install one deck, the other, or both. Each deck is a separate plugin.

**Then, in a project**

- Developer: run the `init` skill to write an `AGENTS.md` for the project.
- Designer: run `/impeccable init` to write `PRODUCT.md`.

## Update

**Claude Code**

```bash
claude plugin marketplace update dev-deck
claude plugin update developer@dev-deck
claude plugin update designer@dev-deck
```

**Codex**

```bash
codex plugin marketplace upgrade
```

Then remove and add a plugin again if you need the new version (`codex plugin
remove` and `codex plugin add`).

Each plugin has a version number in its manifest. Dev Deck bumps it when a
deck's contents change.

## What you get, by tool

| | Claude Code (plugin) | Codex (plugin) | Installer script |
|---|---|---|---|
| developer skills | Yes | Yes | Yes |
| designer skills | Yes | Yes | Yes |
| Planner, builder, reviewer roles | Yes, set to `inherit` (the model you pick in the session) | No | Yes, Claude and Codex, with the models you set in the config |
| Context Mode server | Yes | Yes | Yes |

The plugin install cannot set a different model for each role. Roles use the
model your session already runs. If you need a model per role, or planner and
reviewer roles in Codex, use the [installer script](#advanced-the-installer-script).

Pick one way to install. Using the plugins and the script together gives you
two copies of each skill.

## Advanced: the installer script

The script installs the same skills into `~/.claude/skills`, writes the roles for
Claude Code and Codex with the models you set, and registers Context Mode through
each tool's MCP command. It is the way to get per-role models and Codex roles.

**Windows**

```powershell
git clone https://github.com/CydoEntis/dev-deck C:\dev\dev-deck
cd C:\dev\dev-deck
copy dev-deck.config.json.example dev-deck.config.json
notepad dev-deck.config.json      # set decks, hosts and models
.\install\install.ps1
.\install\doctor.ps1              # verify; exits 0 when every check passes
```

**macOS and Linux** (Python 3.8 or newer)

```bash
git clone https://github.com/CydoEntis/dev-deck ~/dev-deck
cd ~/dev-deck
cp dev-deck.config.json.example dev-deck.config.json
# edit dev-deck.config.json
./install/install.sh
./install/doctor.sh
```

**The config** is `dev-deck.config.json`, git-ignored, in the repo root:

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

- `decks`: which decks to install. `"developer"`, `"designer"`, or both.
- `hosts`: which tools get role files. Only the `developer` deck has roles.
- `models.<host>.<role>`: the model for each role. Use IDs the host accepts. Claude
  Code also accepts `opus`, `sonnet` and `haiku`. An empty string inherits the
  host's default.

Keep the reviewer in a different model family from the builder. If they are the
same family, the review is a second opinion from the same family. A Codex model
for the reviewer, on the `codex` host, gives a cross-family check.

The installer does not check model IDs. Confirm them with your tool.

The doctor checks the config, that no role file still has an unfilled `{{...}}`
placeholder, that every installed skill has a `SKILL.md`, that the required
`roadmap` skill is installed, and that Context Mode is registered.

## Requirements

- **Claude Code** (`claude`) and/or **Codex** (`codex`) on PATH.
- **Node.js** on PATH. Context Mode runs through `npx`.
- **git** for the installer script.
- **Windows:** PowerShell 5.1 or newer, for `install.ps1`.
- **macOS and Linux:** Python 3.8 or newer, for `install.sh`.

The plugin commands do not depend on the operating system. The installer
script on macOS and Linux has been tested only through Git Bash on Windows, and
has not been run on macOS or Linux yet.

## How it works

The developer deck runs a feature through three roles. The planner turns a request
into tickets. The builder implements one ticket at a time, test-first. The reviewer
checks each change blind. If the reviewer fails a change, the builder gets the
findings and tries again, up to two loops. After that the pipeline stops and
reports the open findings for a person to decide.

For the full flow, and the skills each stage uses, see
[docs/pipeline.md](docs/pipeline.md).

## Customize

- **Change a role's behavior:** edit `agents/<role>.md`, then rebuild the plugins.
- **Change which skills a deck has:** edit the pins in `upstream.json`. Add an
  `include` list to install only named skills, or an `exclude` list to drop some.
- **Add a skill you wrote:** put it in `skills/<deck>/<name>/`, then rebuild.
- **Rebuild after any change:** run `python scripts/build_plugins.py` from the repo
  root, then commit the `plugins/` folder. The script fetches each upstream and
  copies the picked skills into the plugins, and it sets the role models to
  `inherit`.

## FAQ

**Why are skills copied into the repo instead of linked?**
A plugin installs whole, from its own folder. Copying lets a deck contain only the
skills picked from each upstream, and lets it install in one step.

**Why do the plugins set models to `inherit`?**
A plugin cannot read your local config. `inherit` means each role runs on the
model your session already uses. Use the installer script if you need a model per
role.

**Why are there no roles for Codex in the plugin?**
Codex's plugin format does not document agent files, so I have not confirmed
roles work there. The installer script still writes Codex roles.

**Why does the reviewer see nothing from the builder?**
A model that reported its change as working tends to agree with itself. The
reviewer starts fresh with only the diff, the plan entry and the repo's rules, so
it has to verify the claim from evidence.

**What happens when the reviewer fails a change?**
The builder receives the findings, and the review runs again. This is capped at
two loops. After that the pipeline stops and returns the open findings.

**Why are there no per-stack convention packs?**
Each repository's `AGENTS.md` owns its stack rules. A global library of stack
packs would be hard to maintain.

## Contributing

Issues and pull requests are welcome. Before you open a pull request:

1. Rebuild the plugins with `python scripts/build_plugins.py` and commit the result.
2. Run `claude plugin validate .` and confirm it passes.
3. If you change the installer, keep `install.ps1` and `install.py` in step, and
   check `doctor.ps1` and `doctor.py` too.
4. Use Conventional Commits, for example `feat(install): ...` or `docs(readme): ...`.

## License

MIT for the Dev Deck code and the developer and designer decks as assembled here.
See [LICENSE](LICENSE).

The skills keep their upstream licenses: MIT for pstack, Matt Pocock's pack,
ponytail, anti-slop, and Emil Kowalski's skills; Apache-2.0 for Impeccable and
caveman (caveman also ships an MIT license; see its `LICENSING.md`); CC0 for
Intent. roadmap is the author's own repository. Each upstream's license applies
to the skills it provides.
