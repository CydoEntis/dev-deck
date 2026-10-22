#!/usr/bin/env python3
"""Build the plugin packages in plugins/ from the pinned upstreams.

Plugins ship whole, so the skills they need are copied into the repo. This script
fetches each pin for the decks it is building (the same way install/install.py
does), applies each pin's include/exclude picks, and copies the chosen skills into
plugins/<deck>/skills/. It also writes the role agents for the developer plugin with
`model: inherit`, because a plugin cannot read dev-deck.config.json.

Run it again to refresh the copies after changing upstream.json or skills/.
Requires git and Python 3.8 or newer.
"""

import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "install"))
from install import keep_skill  # noqa: E402  (same pick rules as the installer)

import json  # noqa: E402

DECKS = ["developer", "designer"]


def run_git(args):
    return subprocess.run(["git", *args], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode


def fetch(pin):
    """Return the local directory holding a pin's source, cloning or updating it."""
    cache = ROOT / "cache"
    cache.mkdir(exist_ok=True)
    name, url, ref = pin["name"], pin.get("url", ""), pin.get("ref", "")
    if url:
        dest = cache / name
        branch = ["--branch", ref] if ref and ref not in ("main", "master") else []
        if not (dest / ".git").exists():
            if run_git(["clone", "--depth", "1", *branch, url, str(dest)]):
                raise SystemExit(f"clone failed: {name} ({url})")
        else:
            if branch:
                run_git(["-C", str(dest), "fetch", "--depth", "1", "origin", ref])
                run_git(["-C", str(dest), "reset", "--hard", f"origin/{ref}"])
            else:
                run_git(["-C", str(dest), "pull", "--ff-only"])
        return dest
    local = Path(pin["localPath"])
    if not local.exists():
        raise SystemExit(f"local path missing: {name} -> {local}")
    return local


def discover(pin, src):
    """Map skill directory name -> directory, for skills the pin's picks allow."""
    base = src / pin.get("skillsPath", "skills")
    found = {}
    for skill_md in base.rglob("SKILL.md"):
        if len(skill_md.parent.relative_to(base).parts) > 3:
            continue
        if keep_skill(pin, skill_md.parent.name):
            found[skill_md.parent.name] = skill_md.parent
    return found


def build_deck(deck, pins):
    out = ROOT / "plugins" / deck / "skills"
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)

    chosen = {}  # skill name -> (source label, directory)
    for pin in pins:
        if deck not in pin.get("decks", []):
            continue
        src = fetch(pin)
        for name, path in discover(pin, src).items():
            if name in chosen:
                raise SystemExit(f"skill '{name}' is in both {chosen[name][0]} and {pin['name']}")
            chosen[name] = (pin["name"], path)

    # Personal skills for this deck win over upstream names.
    personal = ROOT / "skills" / deck
    if personal.is_dir():
        for d in sorted(p for p in personal.iterdir() if p.is_dir()):
            chosen[d.name] = ("dev-deck", d)

    for name, (_, path) in sorted(chosen.items()):
        shutil.copytree(path, out / name)
    print(f"{deck}: {len(chosen)} skills copied from {len({s for s, _ in chosen.values()})} sources")
    return len(chosen)


def build_agents():
    out = ROOT / "plugins" / "developer" / "agents"
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)
    for tpl in sorted((ROOT / "agents").glob("*.md")):
        raw = tpl.read_text(encoding="utf-8")
        content = re.sub(r"\{\{\w+\}\}", "inherit", raw)
        (out / tpl.name).write_text(content, encoding="utf-8", newline="\n")
    print(f"developer: {len(list((ROOT / 'agents').glob('*.md')))} role agents (model: inherit)")


def build_conventions():
    # Plugin paths can't reach outside the plugin root, so the house style ships inside it.
    out = ROOT / "plugins" / "developer" / "conventions"
    if out.exists():
        shutil.rmtree(out)
    shutil.copytree(ROOT / "conventions", out)
    print(f"developer: conventions copied ({len(list(out.rglob('*.md')))} files)")


def main():
    pins = json.loads((ROOT / "upstream.json").read_text(encoding="utf-8"))["pins"]
    for deck in DECKS:
        build_deck(deck, pins)
    build_agents()
    build_conventions()
    return 0


if __name__ == "__main__":
    sys.exit(main())
