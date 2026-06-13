#!/bin/bash
# Wrapper for Flutter's xcode_backend.sh — runs ios_codesign_env in the same shell
# so COPYFILE_DISABLE and the build/ symlink apply before native assets are signed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=ios_codesign_env.sh
. "${SCRIPT_DIR}/ios_codesign_env.sh"

exec /bin/sh "${FLUTTER_ROOT}/packages/flutter_tools/bin/xcode_backend.sh" "$@"
