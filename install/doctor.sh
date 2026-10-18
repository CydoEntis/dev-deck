#!/usr/bin/env bash
# Dev Deck health check (Linux/macOS). Mirrors doctor.ps1.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILS=0

check() {
  local label="$1"
  shift
  if "$@"; then
    echo "  ok   $label"
  else
    echo "  FAIL $label" >&2
    ((FAILS++)) || true
  fi
}

echo "Dev Deck doctor"
CONFIG="${ROOT}/dev-deck.config.json"
check "config present" test -f "$CONFIG"

if [[ ! -f "$CONFIG" ]]; then
  echo "Run install.sh first." >&2
  exit 1
fi

# Role files must have no unsubstituted template vars
for dir in "${HOME}/.config/opencode/agent" "${HOME}/.claude/agents"; do
  [[ -d "$dir" ]] || continue
  bad=0
  for f in "$dir"/*.md; do
    [[ -f "$f" ]] || continue
    if grep -qE '\{\{[A-Z_]+\}\}' "$f"; then
      bad=1
    fi
  done
  check "no {{...}} vars in $dir" test $bad -eq 0
done

# Skill dirs must contain SKILL.md
bad=0
for d in "${HOME}/.claude/skills"/*/; do
  [[ -d "$d" ]] || continue
  if [[ ! -f "${d}SKILL.md" ]]; then
    bad=1
  fi
done
check "all skill dirs have SKILL.md" test $bad -eq 0

echo ""
if [[ $FAILS -eq 0 ]]; then
  echo "All checks passed."
  exit 0
else
  echo "${FAILS} check(s) failed." >&2
  exit 1
fi
