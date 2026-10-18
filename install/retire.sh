#!/usr/bin/env bash
# Dev Deck one-time cleanup (Linux/macOS). Mirrors retire.ps1.
#   1. Retires old personal workflow skills Dev Deck replaces.
#      - Symlinks/junctions are removed (source preserved).
#      - Real directories are moved to dev-deck/retired/ (reversible).
#   2. Disables Aevox Playbook plugins in ~/.claude/settings.json without
#      touching any C:/Work source.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SkillRoots=("${HOME}/.claude/skills" "${HOME}/.agents/skills")
RetiredDir="${ROOT}/retired"
mkdir -p "$RetiredDir"

Retire=(research grilling grill-me interview project-planning teach hbr tug starter)

echo "Dev Deck retire"
for s in "${SkillRoots[@]}"; do
  [[ -d "$s" ]] || continue
  for name in "${Retire[@]}"; do
    p="${s}/${name}"
    [[ -e "$p" || -L "$p" ]] || continue
    if [[ -L "$p" ]]; then
      target="$(readlink "$p")"
      rm "$p"
      echo "  link removed: ${p}  (source kept: ${target})"
    else
      mv "$p" "${RetiredDir}/${name}"
      echo "  moved to retired: ${p} -> retired/${name}"
    fi
  done
done

Settings="${HOME}/.claude/settings.json"
if [[ -f "$Settings" ]]; then
  cp "$Settings" "${Settings}.bak-devdeck-$(date +%Y%m%d-%H%M%S)"
  python3 - "$Settings" <<'PY'
import json, sys
path = sys.argv[1]
obj = json.load(open(path))
changed = 0
plugins = obj.get("enabledPlugins", {})
for key in plugins:
    if key.endswith("@aevox-playbook") or key.startswith("aevox-"):
        plugins[key] = False
        changed += 1
if changed:
    obj["enabledPlugins"] = plugins
    json.dump(obj, open(path, "w"), indent=2)
    print(f"Disabled {changed} Aevox plugin(s) in {path}")
else:
    print("No Aevox plugins found to disable in", path)
PY
else
  echo "No $Settings found (skipped plugin disable)"
fi

echo ""
echo "Note: work source (C:/Work/Aevox-Playbook equivalent) was NOT touched."
echo "Done. Run install/doctor.sh to verify."
