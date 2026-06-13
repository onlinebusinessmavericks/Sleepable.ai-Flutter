#!/bin/bash
# Use this instead of plain "flutter run" when the project is on Desktop.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# shellcheck source=ios_codesign_env.sh
. "$ROOT/scripts/ios_codesign_env.sh"

if [ $# -eq 0 ]; then
  exec flutter run -d "iPhone 17 Pro"
fi

exec flutter run "$@"
