#!/bin/bash
# One-command release build for App Store upload (run on Megh's Mac).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

"$ROOT/scripts/fix_ios_codesign.sh"

unset FLUTTER_ROOT
flutter clean
flutter pub get

cd ios
pod install --repo-update
cd ..

"$ROOT/scripts/fix_ios_codesign.sh"
flutter build ipa --release

echo ""
echo "IPA ready:"
ls -lh build/ios/ipa/*.ipa 2>/dev/null || ls -lh build/ios/ipa/
