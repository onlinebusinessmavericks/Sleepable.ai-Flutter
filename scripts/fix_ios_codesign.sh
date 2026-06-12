#!/bin/bash
# Fixes: "resource fork, Finder information, or similar detritus not allowed"
# during iOS code signing. Common when the project lives on iCloud Desktop,
# was copied via zip/airdrop, or synced from another machine.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PUB_CACHE="${PUB_CACHE:-$HOME/.pub-cache/hosted/pub.dev}"

echo "==> Stripping extended attributes for iOS code signing"
echo "    Project: $ROOT"

# Never strip the whole Pods tree from a script (slow + can break permissions).
# Only strip build output and known native-asset packages in pub-cache.
if [ -d "$ROOT/build" ]; then
  /usr/bin/xattr -cr "$ROOT/build" 2>/dev/null || true
fi

for pkg in objective_c rive_common; do
  for dir in "$PUB_CACHE"/${pkg}-*; do
    if [ -d "$dir" ]; then
      echo "    pub-cache: $(basename "$dir")"
      /usr/bin/xattr -cr "$dir" 2>/dev/null || true
    fi
  done
done

# Strip Flutter/Dart tool caches that may contain prebuilt native assets.
if [ -d "$ROOT/.dart_tool" ]; then
  /usr/bin/xattr -cr "$ROOT/.dart_tool" 2>/dev/null || true
fi

echo "==> Done. You can now run: flutter build ipa --release"
