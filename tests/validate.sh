#!/usr/bin/env bash
# Validate the party-mode plugin structure. Extra args are passed through,
# e.g. `tests/validate.sh --party-dir /path/to/project/.party`.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$here/validate.py" "$@"
