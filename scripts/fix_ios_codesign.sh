#!/bin/bash
# One-time / post-flutter-clean fix for iOS Archive code signing on Desktop.
# Usage: bash scripts/fix_ios_codesign.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Preparing iOS build environment (Desktop-safe)"
echo "    Project: $ROOT"

# shellcheck source=ios_codesign_env.sh
. "$ROOT/scripts/ios_codesign_env.sh"
ios_codesign_prepare_build

echo "==> Done."
echo "    build/ -> ~/Library/Caches/SleepableFlutter/build"
echo "    You can now Archive from Xcode or run: flutter build ipa --release"
echo ""
echo "    Run this script again after: flutter clean"
