#!/usr/bin/env bash
# Dev Deck health check (macOS/Linux). The logic lives in doctor.py; this runs it.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY="$(command -v python3 || true)"
if [[ -z "$PY" ]]; then
  echo "python3 is required (3.8 or newer)" >&2
  exit 1
fi
exec "$PY" "$DIR/doctor.py" "$@"
