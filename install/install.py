#!/usr/bin/env python3
"""Dev Deck installer for macOS and Linux (install.sh runs this).

Mirrors install.ps1: pulls the pinned upstreams for the enabled packs, copies
their skills into ~/.claude/skills, writes role files for each enabled host,
and registers Context Mode through the claude and codex CLIs. Idempotent.
Personal skills win over upstream skills with the same name.
"""

import datetime
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HOME = Path.home()
ISSUES = []


def load(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def is_link(path):
    # Symlinks, and Windows junctions when running under Windows Python.
    return path.is_symlink() or (hasattr(os.path, "isjunction") and os.path.isjunction(str(path)))


def remove_link(path):
    # Removes the link only; never what it points at.
    if path.is_symlink():
        path.unlink()
    else:
        os.rmdir(path)


def quiet(args):
    # shutil.which finds Windows .cmd shims (npm installs codex as one).
    exe = shutil.which(args[0])
    if exe is None:
        return 127
    return subprocess.run([exe, *args[1:]], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode


def markdown_agent(raw, model, host):
    if model:
        return re.sub(r"\{\{\w+\}\}", model, raw)
    if host == "claude":
        return re.sub(r"\{\{\w+\}\}", "inherit", raw)
    return re.sub(r"(?m)^model:\s*\{\{\w+\}\}\s*\r?\n", "", raw)


def codex_agent(raw, role, model):
    m = re.match(r"\A---\r?\n(.*?)\r?\n---\r?\n(.*)\Z", raw, re.S)
    if not m:
        raise SystemExit(f"role '{role}' has no frontmatter")
    front, body = m.group(1), m.group(2).rstrip()
    if "'''" in body:
        raise SystemExit(f"role '{role}' body contains ''' (breaks the TOML literal string)")
    d = re.search(r"(?m)^description:\s*(.+?)\s*$", front)
    desc = (d.group(1) if d else "").replace("\\", "\\\\").replace('"', '\\"')
    lines = [f'name = "{role}"', f'description = "{desc}"']
    if model:
        lines.append(f'model = "{model}"')
    lines += ["developer_instructions = '''", body, "'''"]
    return "\n".join(lines) + "\n"


def main():
    cfg_path = ROOT / "dev-deck.config.json"
    if not cfg_path.exists():
        shutil.copy(ROOT / "dev-deck.config.json.example", cfg_path)
        print(f"Created {cfg_path} from the example. Edit it (packs, hosts, models), then re-run.",
              file=sys.stderr)
        return 1

    cfg = load(cfg_path)
    hosts = cfg.get("hosts", [])
    packs = cfg.get("packs", [])
    models = cfg.get("models", {})

    def model_for(host, role):
        return (models.get(host) or {}).get(role) or ""

    # --- fetch upstreams -----------------------------------------------------
    cache = ROOT / "cache"
    cache.mkdir(exist_ok=True)
    skill_names = {}  # skill dir name -> (pin name, directory)
    for pin in load(ROOT / "upstream.json")["pins"]:
        name = pin["name"]
        if not set(pin.get("packs", [])) & set(packs):
            print(f"skip    {name} (pack not enabled)")
            continue
        url, ref = pin.get("url", ""), pin.get("ref", "")
        if not url and not pin.get("localPath"):
            print(f"skip    {name} (no url or localPath yet)")
            continue
        if url:
            dest = cache / name
            branch = ["--branch", ref] if ref and ref not in ("main", "master") else []
            if not (dest / ".git").exists():
                if quiet(["git", "clone", "--depth", "1", *branch, url, str(dest)]):
                    ISSUES.append(f"clone failed: {name} ({url})")
                    continue
                print(f"fetched {name} ({url})")
            else:
                if branch:
                    code = quiet(["git", "-C", str(dest), "fetch", "--depth", "1", "origin", ref]) or \
                        quiet(["git", "-C", str(dest), "reset", "--hard", f"origin/{ref}"])
                else:
                    code = quiet(["git", "-C", str(dest), "pull", "--ff-only"])
                if code:
                    ISSUES.append(f"update failed: {name}")
                    continue
                print(f"updated {name}")
            src = dest
        else:
            src = Path(pin["localPath"])
            if not src.exists():
                ISSUES.append(f"local path missing: {name} -> {src}")
                continue
            print(f"using local {name} ({src})")
        base = src / pin.get("skillsPath", "skills")
        if not base.exists():
            ISSUES.append(f"skillsPath not found in {name}: {base}")
            continue
        for skill_md in base.rglob("SKILL.md"):
            if len(skill_md.parent.relative_to(base).parts) > 3:
                continue
            skill_names[skill_md.parent.name] = (name, skill_md.parent)

    # --- install skills ------------------------------------------------------
    manifest_skills = {}
    personal_src = {}
    for pack in packs:
        pack_dir = ROOT / "skills" / pack
        if not pack_dir.is_dir():
            print(f"note    pack '{pack}' has no skills yet")
            continue
        for d in sorted(p for p in pack_dir.iterdir() if p.is_dir()):
            manifest_skills[d.name] = pack
            personal_src[d.name] = d
    for name, (pin_name, _) in skill_names.items():
        if name not in personal_src:
            manifest_skills[name] = pin_name

    target = HOME / ".claude" / "skills"
    target.mkdir(parents=True, exist_ok=True)
    installed = skipped = 0
    for name in manifest_skills:
        src = personal_src[name] if name in personal_src else skill_names[name][1]
        dst = target / name
        marker = dst / ".devdeck"
        if (dst.exists() or is_link(dst)) and not marker.exists():
            if is_link(dst) and name not in personal_src:
                # Link from an earlier manual setup, now owned by a pinned upstream.
                remove_link(dst)
            else:
                print(f"skip    '{name}' already present without dev-deck marker - personal wins")
                skipped += 1
                continue
        elif is_link(dst):
            remove_link(dst)
        elif dst.exists():
            shutil.rmtree(dst)
        shutil.copytree(src, dst)
        marker.write_text(manifest_skills[name], encoding="utf-8")
        installed += 1
    print(f"installed {installed} skill copies, skipped {skipped} personal conflict(s)")

    # --- role agent files ----------------------------------------------------
    templates = sorted((ROOT / "agents").glob("*.md")) if "dev-deck" in packs else []
    agents = {}
    for host in hosts:
        if host == "claude":
            agent_dir = HOME / ".claude" / "agents"
        elif host == "codex":
            agent_dir = HOME / ".codex" / "agents"
        else:
            print(f"note    host '{host}': no subagent format; skills only")
            continue
        if not templates:
            continue
        agent_dir.mkdir(parents=True, exist_ok=True)
        for tpl in templates:
            role, raw, m = tpl.stem, tpl.read_text(encoding="utf-8"), model_for(host, tpl.stem)
            if host == "codex":
                (agent_dir / f"{role}.toml").write_text(codex_agent(raw, role, m), encoding="utf-8", newline="\n")
            else:
                (agent_dir / f"{role}.md").write_text(markdown_agent(raw, m, host), encoding="utf-8", newline="\n")
            agents[f"{host}/{role}"] = str(agent_dir)
        print(f"agents  wrote {len(templates)} {host} role files -> {agent_dir}")

    # --- MCP registration (claude, codex) -------------------------------------
    if "dev-deck" in packs:
        servers = load(ROOT / "mcp" / "context-mode.json")["servers"]
        for host in ("claude", "codex"):
            if host not in hosts:
                continue
            if not shutil.which(host):
                ISSUES.append(f"{host} CLI not found - MCP not registered for {host}")
                continue
            for name, srv in servers.items():
                cmd = srv.get("command", [])
                if "REPLACE-WITH" in " ".join(cmd):
                    continue
                if host == "claude":
                    quiet([host, "mcp", "remove", "--scope", "user", name])
                    code = quiet([host, "mcp", "add", "--scope", "user", name, "--", *cmd])
                else:
                    quiet([host, "mcp", "remove", name])
                    code = quiet([host, "mcp", "add", name, "--", *cmd])
                if code:
                    ISSUES.append(f"mcp add failed in {host}: {name}")
                else:
                    print(f"mcp     {host} registered {name}")

    # --- manifest ------------------------------------------------------------
    manifest = {
        "installedAt": datetime.datetime.now().isoformat(),
        "hosts": hosts,
        "packs": packs,
        "skills": manifest_skills,
        "agents": agents,
    }
    (ROOT / "installed.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    if ISSUES:
        print(f"\nIssues ({len(ISSUES)}):", file=sys.stderr)
        for issue in ISSUES:
            print(f" - {issue}", file=sys.stderr)
        return 1
    print("\nDone. Run install/doctor.sh to verify.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
