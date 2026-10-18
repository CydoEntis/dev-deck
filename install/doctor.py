#!/usr/bin/env python3
"""Dev Deck health check for macOS and Linux (doctor.sh runs this). Mirrors doctor.ps1."""

import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HOME = Path.home()
FAILS = 0


def check(label, ok):
    global FAILS
    if ok:
        print(f"  ok   {label}")
    else:
        print(f"  FAIL {label}", file=sys.stderr)
        FAILS += 1


def load(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def mcp_listed(host, args, needle=None):
    # Missing CLI or failed launch counts as not registered, never a crash.
    exe = shutil.which(host)
    if exe is None:
        return False
    try:
        out = subprocess.run([exe, *args], capture_output=True, text=True)
    except OSError:
        return False
    if needle is None:
        return out.returncode == 0
    return needle in out.stdout


def main():
    global FAILS
    print("Dev Deck doctor")
    cfg_path = ROOT / "dev-deck.config.json"
    check("config present", cfg_path.exists())
    if not cfg_path.exists():
        print("Run install.sh first (it creates the config from the example).", file=sys.stderr)
        return 1

    cfg = load(cfg_path)
    hosts = cfg.get("hosts", [])
    packs = cfg.get("packs", [])
    dev_deck = "dev-deck" in packs
    roles = {p.stem for p in (ROOT / "agents").glob("*.md")} if dev_deck else set()

    # Role files: no unfilled {{...}} placeholders.
    agent_dirs = {"claude": HOME / ".claude" / "agents", "codex": HOME / ".codex" / "agents"}
    for host in hosts:
        d = agent_dirs.get(host)
        if not dev_deck or d is None or not d.is_dir():
            continue
        bad = [f for f in d.iterdir() if f.is_file() and f.stem in roles
               and re.search(r"\{\{[A-Z_]+\}\}", f.read_text(encoding="utf-8"))]
        check(f"no {{{{...}}}} vars in {d}", not bad)

    # Skill dirs the installer wrote (marked .devdeck) must contain SKILL.md.
    skill_root = HOME / ".claude" / "skills"
    bad = [d for d in skill_root.iterdir() if d.is_dir() and (d / ".devdeck").exists()
           and not (d / "SKILL.md").exists()] if skill_root.is_dir() else []
    check("all skill dirs have SKILL.md", not bad)

    # Pins marked required must be installed, if their pack is enabled.
    for pin in load(ROOT / "upstream.json")["pins"]:
        if pin.get("required") and set(pin.get("packs", [])) & set(packs):
            check(f"required skill '{pin['name']}' installed",
                  (skill_root / pin["name"] / "SKILL.md").exists())

    # Context Mode registered in each enabled host.
    if dev_deck:
        if "claude" in hosts:
            check("context-mode registered in claude", mcp_listed("claude", ["mcp", "get", "context-mode"]))
        if "codex" in hosts:
            check("context-mode registered in codex", mcp_listed("codex", ["mcp", "list"], "context-mode"))

    print()
    if FAILS == 0:
        print("All checks passed.")
        return 0
    print(f"{FAILS} check(s) failed.", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
