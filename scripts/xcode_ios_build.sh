#!/bin/bash
# Wrapper for Flutter's xcode_backend.sh.
# - "build": prepare env, run backend, strip xattrs on freshly built native assets
# - "embed_and_thin": setup symlink only - do NOT delete native_assets

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=ios_codesign_env.sh
. "${SCRIPT_DIR}/ios_codesign_env.sh"

CMD="${1:-}"

if [ "$CMD" = "build" ]; then
  ios_codesign_prepare_build
fi

/bin/sh "${FLUTTER_ROOT}/packages/flutter_tools/bin/xcode_backend.sh" "$@"

if [ "$CMD" = "build" ]; then
  strip_if_exists "${ROOT}/build/native_assets"
fi
