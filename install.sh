#!/usr/bin/env bash
set -euo pipefail
ARC_STEEL_SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$ARC_STEEL_SOURCE_DIR/tools/install.py" "$@"
