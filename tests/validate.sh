#!/usr/bin/env bash
# Validate the roundtable plugin structure. Extra args are passed through,
# e.g. `tests/validate.sh --project-dir /path/to/project/.roundtable`.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$here/validate.py" "$@"
