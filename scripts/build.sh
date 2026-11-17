#!/bin/bash
# build.sh — clean Release build of AppleALC into build/DerivedData.
#
# Usage: ./scripts/build.sh
#
# Requires ./scripts/bootstrap.sh to have been run once (it creates the
# Lilu.kext/Contents/Resources and MacKernelSDK links the project expects).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

[ -e Lilu.kext/Contents/Resources/Headers ] || fail "build paths missing; run ./scripts/bootstrap.sh"
[ -e MacKernelSDK/Headers ]                 || fail "build paths missing; run ./scripts/bootstrap.sh"

mkdir -p build
LOG="build/build.log"

echo "== clean Release build =="
set -o pipefail
if ! xcodebuild \
        -project AppleALC.xcodeproj \
        -scheme AppleALC \
        -configuration Release \
        -derivedDataPath build/DerivedData \
        clean build 2>&1 | tee "$LOG"
then
    fail "xcodebuild failed; see $LOG"
fi

KEXT="build/DerivedData/Build/Products/Release/AppleALC.kext"
[ -d "$KEXT" ]                          || fail "kext not produced: $KEXT"
[ -f "$KEXT/Contents/MacOS/AppleALC" ]  || fail "kext executable missing"
[ -f "$KEXT/Contents/Info.plist" ]      || fail "kext Info.plist missing"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$KEXT/Contents/Info.plist")"
SHA="$(shasum -a 256 "$KEXT/Contents/MacOS/AppleALC" | awk '{print $1}')"

echo
echo "== built =="
echo "  kext    : $KEXT"
echo "  version : $VERSION"
echo "  sha256  : $SHA"
echo "  log     : $LOG"
