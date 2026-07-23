#!/bin/bash
# Keeps iOS builds working when the project lives on Desktop, Downloads, or iCloud.
# - Strips com.apple.provenance from native-asset packages in pub-cache
# - Redirects Flutter build/ output to ~/Library/Caches (outside Desktop)
#
# Used automatically from: Xcode build phases, pod install, fix_ios_codesign.sh

set -uo pipefail

export COPYFILE_DISABLE=1
export COPYFILE_UNPACK=0
export TMPDIR="${TMPDIR:-/tmp}"

if [ -n "${SRCROOT:-}" ]; then
  ROOT="$(cd "${SRCROOT}/.." && pwd)"
else
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
fi

PUB_CACHE="${PUB_CACHE:-${HOME}/.pub-cache/hosted/pub.dev}"
CACHE_BUILD_DIR="${HOME}/Library/Caches/SleepableFlutter/build"

strip_if_exists() {
  if [ -e "$1" ]; then
    /usr/bin/xattr -cr "$1" 2>/dev/null || true
  fi
}

log() {
  if [ "${IOS_CODESIGN_QUIET:-0}" != "1" ]; then
    echo "==> $*"
  fi
}

# Symlink build/ to cache. Safe to call on every Xcode phase.
ios_codesign_setup() {
  log "iOS build env: ${ROOT}"

  for pkg in objective_c rive_common; do
    for dir in "${PUB_CACHE}/${pkg}"-*; do
      if [ -d "$dir" ]; then
        strip_if_exists "$dir"
      fi
    done
  done

  strip_if_exists "${ROOT}/.dart_tool"

  mkdir -p "${CACHE_BUILD_DIR}"
  strip_if_exists "${CACHE_BUILD_DIR}"

  if [ -L "${ROOT}/build" ]; then
    log "build/ already symlinked to cache"
  elif [ -d "${ROOT}/build" ]; then
    log "Moving build/ off Desktop -> ${CACHE_BUILD_DIR}"
    if [ "$(ls -A "${ROOT}/build" 2>/dev/null | wc -l | tr -d ' ')" != "0" ]; then
      /bin/cp -R "${ROOT}/build/." "${CACHE_BUILD_DIR}/" 2>/dev/null || true
      strip_if_exists "${CACHE_BUILD_DIR}"
    fi
    rm -rf "${ROOT}/build"
    ln -s "${CACHE_BUILD_DIR}" "${ROOT}/build"
  elif [ ! -e "${ROOT}/build" ]; then
    log "Linking build/ -> ${CACHE_BUILD_DIR}"
    ln -s "${CACHE_BUILD_DIR}" "${ROOT}/build"
  fi
}

# Only run BEFORE flutter build (not before embed_and_thin).
# Do NOT delete native_assets/ios here — Xcode embed runs later in the same
# archive and needs objective_c.framework. Full clean is build_ipa.sh only.
ios_codesign_prepare_build() {
  ios_codesign_setup

  NATIVE_ASSETS_IOS="${CACHE_BUILD_DIR}/native_assets/ios"
  if [ ! -d "${NATIVE_ASSETS_IOS}" ]; then
    return 0
  fi

  strip_if_exists "${NATIVE_ASSETS_IOS}"
}

# Default: setup only (never delete native_assets - embed phase needs them).
ios_codesign_setup
