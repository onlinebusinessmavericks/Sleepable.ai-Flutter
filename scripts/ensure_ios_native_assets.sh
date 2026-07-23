#!/bin/bash
# Ensures build/native_assets/ios/objective_c.framework exists before Xcode embed.
# Called from xcode_ios_build.sh during embed_and_thin.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=ios_codesign_env.sh
. "${SCRIPT_DIR}/ios_codesign_env.sh"

ios_codesign_setup

NATIVE_IOS="${ROOT}/build/native_assets/ios"
FRAMEWORK="${NATIVE_IOS}/objective_c.framework/objective_c"

if [ -f "$FRAMEWORK" ]; then
  exit 0
fi

log "objective_c.framework missing — prebuilding iOS release native assets"

cd "$ROOT"
unset FLUTTER_ROOT
flutter build ios --release --no-codesign

if [ ! -f "$FRAMEWORK" ]; then
  echo "ERROR: objective_c.framework still missing after flutter build ios."
  echo "       Run: bash scripts/build_ipa.sh"
  exit 1
fi

strip_if_exists "${ROOT}/build/native_assets"
