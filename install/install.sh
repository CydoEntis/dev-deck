#!/usr/bin/env bash
# Dev Deck installer (Linux/macOS). Same behaviour as install.ps1:
# pull pinned upstream skills, install skills + role agents, register MCP.
# Idempotent. Personal skills win on name conflicts.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="${HOME}"
SKILL_TARGET="${HOME_DIR}/.claude/skills"
ISSUES=()

jget() { python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(eval(sys.argv[2]))" "$1" "$2" 2>/dev/null; }

CONFIG="${ROOT}/dev-deck.config.json"
if [[ ! -f "$CONFIG" ]]; then
  cp "${ROOT}/dev-deck.config.json.example" "$CONFIG"
  echo "Created $CONFIG from the example. Edit it (model slots, hosts), then re-run." >&2
  exit 1
fi

PLANNER="$(jget "$CONFIG" "d['planner']")"
BUILDER="$(jget "$CONFIG" "d['builder']")"
REVIEWER="$(jget "$CONFIG" "d['reviewer']")"
HOSTS="$(jget "$CONFIG" "','.join(d['hosts'])")"

mkdir -p "$SKILL_TARGET" "${ROOT}/cache"

# --- fetch upstreams -------------------------------------------------------
python3 - "$ROOT" <<'PY'
import json, subprocess, sys, os, shutil, tempfile
root = sys.argv[1]
pins = json.load(open(os.path.join(root, "upstream.json")))["pins"]
found = {}  # skill-name -> (source-name, dir)
for pin in pins:
    name, url, ref, sp, local = pin["name"], pin.get("url", ""), pin.get("ref", ""), pin.get("skillsPath", "skills"), pin.get("localPath", "")
    if not url and not local:
        print(f"skip    {name} (no url or localPath yet)")
        continue
    if url:
        dest = os.path.join(root, "cache", name)
        if not os.path.isdir(os.path.join(dest, ".git")):
            args = ["git", "clone", "--depth", "1"]
            if ref and ref not in ("main", "master"):
                args += ["--branch", ref]
            args += [url, dest]
            subprocess.run(args, check=True, stdout=subprocess.DEVNULL)
            print(f"fetched {name} ({url})")
        else:
            if ref and ref not in ("main", "master"):
                subprocess.run(["git", "-C", dest, "fetch", "--depth", "1", "origin", ref], check=True, stdout=subprocess.DEVNULL)
                subprocess.run(["git", "-C", dest, "reset", "--hard", f"origin/{ref}"], check=True, stdout=subprocess.DEVNULL)
            else:
                subprocess.run(["git", "-C", dest, "pull", "--ff-only"], check=True, stdout=subprocess.DEVNULL)
            print(f"updated {name}")
        src = dest
    else:
        src = local
        if not os.path.isdir(src):
            print(f"FAILED  local path missing: {name} -> {local}", file=sys.stderr)
            sys.exit(1)
        print(f"using local {name} ({src})")
    base = os.path.join(src, sp)
    if not os.path.isdir(base):
        print(f"FAILED  skillsPath not found in {name}: {base}", file=sys.stderr)
        sys.exit(1)
    for dirpath, dirnames, filenames in os.walk(base):
        rel = os.path.relpath(dirpath, base)
        if rel.count(os.sep) > 2:
            dirnames[:] = []
            continue
        if "SKILL.md" in filenames:
            found[os.path.basename(dirpath)] = (name, dirpath)
json.dump(found, open(os.path.join(root, "cache", ".found.json"), "w"))
print(f"discovered {len(found)} upstream skills")
PY

# --- install skills ---------------------------------------------------------
FOUND="${ROOT}/cache/.found.json"
count=0
# personal skills from the repo
for d in "${ROOT}"/skills/*/; do
  name="$(basename "$d")"
  rm -rf "${SKILL_TARGET}/${name}"
  cp -R "$d" "${SKILL_TARGET}/${name}"
  count=$((count+1))
done
# upstream skills
while read -r name; do
  [[ -z "$name" ]] && continue
  srcdir="$(python3 -c "import json; d=json.load(open('$FOUND')); print(d['$name'][1])")"
  if [[ -L "${SKILL_TARGET}/${name}" ]]; then
    rm -f "${SKILL_TARGET}/${name}"
  elif [[ -d "${SKILL_TARGET}/${name}" ]]; then
    echo "conflict '${name}' exists and is not tracked by us - skipped (personal wins)" >&2
    ISSUES+=("skill conflict skipped: $name")
    continue
  fi
  cp -R "$srcdir" "${SKILL_TARGET}/${name}"
  count=$((count+1))
done < <(python3 -c "import json; [print(k) for k in sorted(json.load(open('$FOUND')))]")
echo "installed ${count} skill copies"

# --- role agent files --------------------------------------------------------
for host in ${HOSTS//,/ }; do
  case "$host" in
    opencode) agent_dir="${HOME_DIR}/.config/opencode/agent" ;;
    claude)   agent_dir="${HOME_DIR}/.claude/agents" ;;
    *)        echo "note    host '$host': roles stay as instruction files in the repo"; continue ;;
  esac
  mkdir -p "$agent_dir"
  for tpl in "${ROOT}"/agents/*.md; do
    role="$(basename "$tpl" .md)"
    case "$role" in
      planner)  model="$PLANNER" ;;
      builder)  model="$BUILDER" ;;
      reviewer) model="$REVIEWER" ;;
      *)        model="" ;;
    esac
    if [[ "$host" == "claude" ]]; then
      [[ -z "$model" ]] && model="inherit"
      sed "s/{{[A-Z_]*}}/${model}/g" "$tpl" > "${agent_dir}/${role}.md"
    else
      if [[ -z "$model" ]]; then
        sed -E '/^model:[[:space:]]*\{\{[A-Z_]+\}\}/d' "$tpl" > "${agent_dir}/${role}.md"
      else
        sed "s/{{[A-Z_]*}}/${model}/g" "$tpl" > "${agent_dir}/${role}.md"
      fi
    fi
  done
  echo "agents  wrote role files -> ${agent_dir}"
done

# --- MCP registration (opencode) --------------------------------------------
if [[ ",${HOSTS}," == *",opencode,"* ]]; then
  OCFG="${HOME_DIR}/.config/opencode/opencode.json"
  if [[ -f "$OCFG" ]]; then
    cp "$OCFG" "${OCFG}.bak-$(date +%Y%m%d-%H%M%S)"
    python3 - "$OCFG" "${ROOT}/mcp/context-mode.json" <<'PY'
import json, sys
ocfg, mcffile = sys.argv[1], sys.argv[2]
oc = json.load(open(ocfg))
mcp = json.load(open(mcffile))
oc.setdefault("mcp", {})
for k, v in mcp.get("servers", {}).items():
    oc["mcp"][k] = v
    if "REPLACE-WITH" in " ".join(map(str, v.get("command", []))):
        print(f"ISSUE  MCP '{k}' still has a placeholder command - edit mcp/context-mode.json", file=sys.stderr)
json.dump(oc, open(ocfg, "w"), indent=2)
print("mcp     merged", len(mcp.get("servers", {})), "server(s)")
PY
  else
    ISSUES+=("opencode config not found at $OCFG - MCP not registered")
  fi
fi

# --- manifest ----------------------------------------------------------------
python3 - "$ROOT" "$FOUND" "$HOSTS" <<'PY'
import json, sys, os, datetime
root, foundfile, hosts = sys.argv[1], sys.argv[2], sys.argv[3]
found = json.load(open(foundfile)) if os.path.exists(foundfile) else {}
manifest = {
    "installedAt": datetime.datetime.now().isoformat(),
    "skills": {k: v[0] for k, v in found.items()} |
              {os.path.basename(p): "dev-deck" for p in [os.path.join(root, "skills", d) for d in os.listdir(os.path.join(root, "skills"))]},
    "hosts": hosts.split(","),
}
json.dump(manifest, open(os.path.join(root, "installed.json"), "w"), indent=2)
PY

if [[ ${#ISSUES[@]} -gt 0 ]]; then
  echo "Issues (${#ISSUES[@]}):" >&2
  printf ' - %s\n' "${ISSUES[@]}" >&2
  exit 1
fi
echo "Done. Run install/doctor.sh to verify."
