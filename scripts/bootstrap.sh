#!/bin/bash
# bootstrap.sh — verify the host toolchain and prepare build inputs.
#
# It does not install software and does not need root. Build dependencies are
# fetched by scripts/fetch-deps.sh at pinned commits when they are missing.
#
# Usage: ./scripts/bootstrap.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ok()   { printf '  ok    %s\n' "$*"; }
fail() { printf '  FAIL  %s\n' "$*" >&2; exit 1; }

echo "== host =="
[ "$(uname -s)" = "Darwin" ] || fail "macOS is required to build a kext"

DEV_DIR="$(xcode-select -p 2>/dev/null || true)"
[ -n "$DEV_DIR" ] || fail "no developer directory; install Xcode"
case "$DEV_DIR" in
    *CommandLineTools*) fail "xcode-select points at Command Line Tools; run: sudo xcode-select -s /Applications/Xcode.app" ;;
esac
ok "developer dir: $DEV_DIR"

command -v xcodebuild >/dev/null || fail "xcodebuild not found"
ok "$(xcodebuild -version | awk 'NR==1')"

command -v clang >/dev/null || fail "clang not found"
ok "clang: $(clang --version | awk 'NR==1')"

SDK="$(xcrun --sdk macosx --show-sdk-version 2>/dev/null || true)"
[ -n "$SDK" ] || fail "macOS SDK not found"
ok "macOS SDK $SDK"

echo "== build dependencies =="
if [ ! -f Lilu.kext/Contents/Resources/Headers/plugin_start.hpp ] \
   || [ ! -f MacKernelSDK/Library/universal/libkmod.a ]; then
    command -v git >/dev/null || fail "git is required to fetch build dependencies"
    echo "  missing; fetching pinned dependencies (network required once)"
    "$ROOT/scripts/fetch-deps.sh"
else
    ok "Lilu headers/library present"
    ok "MacKernelSDK present"
fi

[ -f Lilu.kext/Contents/Resources/Headers/plugin_start.hpp ] || fail "Lilu headers incomplete; rerun scripts/fetch-deps.sh"
[ -f Lilu.kext/Contents/Resources/Library/plugin_start.cpp ] || fail "Lilu library incomplete; rerun scripts/fetch-deps.sh"
[ -f MacKernelSDK/Library/universal/libkmod.a ]              || fail "MacKernelSDK incomplete; rerun scripts/fetch-deps.sh"

echo "== source layout =="
[ -f Resources/ALC236/layout100.xml ]    || fail "layout100.xml missing"
[ -f Resources/ALC236/Platforms100.xml ] || fail "Platforms100.xml missing"
[ -f Resources/PinConfigs.kext/Contents/Info.plist ] || fail "PinConfigs missing"
ok "layout 100 resources present"

echo
echo "bootstrap complete. Next: ./scripts/build.sh"
