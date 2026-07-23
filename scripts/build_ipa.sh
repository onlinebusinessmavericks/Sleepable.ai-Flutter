#!/bin/bash
# One-command release IPA for App Store (Desktop/Downloads-safe).
# Fixes: missing objective_c native assets + simulator slice in Transporter upload.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CACHE_BUILD_DIR="${HOME}/Library/Caches/SleepableFlutter/build"

validate_device_binary() {
  local binary="$1"
  local label="$2"

  if [ ! -f "$binary" ]; then
    return 0
  fi

  local build_info
  build_info="$(xcrun vtool -show-build "$binary" 2>/dev/null || true)"

  if echo "$build_info" | grep -qi "simulator"; then
    echo ""
    echo "ERROR: ${label} is a Simulator build — App Store upload will fail."
    echo "       Re-run: bash scripts/build_ipa.sh"
    echo ""
    xcrun vtool -show-build "$binary" || true
    exit 1
  fi
}

validate_ipa_frameworks() {
  local ipa="$1"
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  unzip -q "$ipa" -d "$tmp_dir"
  while IFS= read -r -d '' binary; do
    validate_device_binary "$binary" "$(basename "$(dirname "$(dirname "$binary")")")"
  done < <(find "$tmp_dir" -path "*/Frameworks/objective_c.framework/objective_c" -print0)

  rm -rf "$tmp_dir"
}

echo "==> Step 1/5: Prepare iOS build environment"
"$ROOT/scripts/fix_ios_codesign.sh"

echo "==> Step 2/5: Clean caches (prevents stale / simulator native assets)"
unset FLUTTER_ROOT
flutter clean
rm -rf "${CACHE_BUILD_DIR}/native_assets"
rm -rf "${ROOT}/.dart_tool/flutter_build"
rm -rf "${ROOT}/build/native_assets"

flutter pub get

echo "==> Step 3/5: CocoaPods"
cd ios
pod install --repo-update
cd ..

"$ROOT/scripts/fix_ios_codesign.sh"

echo "==> Step 4/5: Prebuild iOS release (generates objective_c.framework)"
flutter build ios --release --no-codesign

if [ ! -f "${ROOT}/build/native_assets/ios/objective_c.framework/objective_c" ]; then
  echo "ERROR: objective_c.framework was not created."
  echo "       Run: bash scripts/diagnose_ios_codesign.sh"
  exit 1
fi

echo "==> Step 5/5: Package IPA"
flutter build ipa --release

IPA_PATH="$(ls -1 "${ROOT}"/build/ios/ipa/*.ipa 2>/dev/null | head -1)"
if [ -z "${IPA_PATH}" ]; then
  echo "ERROR: IPA not found under build/ios/ipa/"
  exit 1
fi

echo "==> Validating IPA before Transporter upload"
validate_ipa_frameworks "${IPA_PATH}"

echo ""
echo "SUCCESS — upload this file with Transporter:"
ls -lh "${IPA_PATH}"
