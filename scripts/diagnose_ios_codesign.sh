#!/bin/bash
# Quick diagnostic for iOS CodeSign / Archive failures. Run on Megh's Mac and share output.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "========== Sleepable iOS CodeSign Diagnostic =========="
echo "Project: $ROOT"
echo "User:    $(whoami)"
echo ""

echo "--- 1. build/ symlink (MUST point to Library/Caches) ---"
if [ -L "build" ]; then
  echo "OK: build -> $(readlink build)"
elif [ -d "build" ]; then
  echo "PROBLEM: build/ is a real folder on Desktop (run: bash scripts/fix_ios_codesign.sh)"
else
  echo "PROBLEM: build/ missing (run: bash scripts/fix_ios_codesign.sh)"
fi
echo ""

echo "--- 2. objective_c.framework xattrs (should be empty) ---"
FRAMEWORK="build/native_assets/ios/objective_c.framework/objective_c"
if [ -f "$FRAMEWORK" ]; then
  XATTR_OUT=$(xattr -l "$FRAMEWORK" 2>&1 || true)
  if [ -z "$XATTR_OUT" ]; then
    echo "OK: no extended attributes"
  else
    echo "PROBLEM:"
    echo "$XATTR_OUT"
  fi
else
  echo "Not built yet (normal before first build)"
fi
echo ""

echo "--- 3. pub-cache objective_c ---"
ls -d "${HOME}/.pub-cache/hosted/pub.dev/objective_c-"* 2>/dev/null || echo "Not found"
echo ""

echo "--- 4. Signing certificates on this Mac ---"
security find-identity -v -p codesigning 2>/dev/null | head -10 || echo "Could not list identities"
echo ""

echo "--- 5. Xcode project team (must match a cert on this Mac) ---"
grep "DEVELOPMENT_TEAM" ios/Runner.xcodeproj/project.pbxproj | head -1
echo ""

echo "--- 6. Required scripts present ---"
for f in scripts/ios_codesign_env.sh scripts/xcode_ios_build.sh scripts/fix_ios_codesign.sh; do
  if [ -f "$f" ]; then echo "OK: $f"; else echo "MISSING: $f (pull latest git)"; fi
done
echo ""

echo "--- 7. Xcode build phase uses wrapper ---"
if grep -q "xcode_ios_build.sh" ios/Runner.xcodeproj/project.pbxproj; then
  echo "OK: project.pbxproj uses xcode_ios_build.sh"
else
  echo "PROBLEM: old Xcode project (pull latest git)"
fi
echo ""
echo "========== End diagnostic =========="
