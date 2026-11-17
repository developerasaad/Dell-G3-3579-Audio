#!/bin/bash
# fetch-deps.sh — fetch pinned build dependencies and materialise them.
#
# Downloads (git) and verifies by commit hash:
#   Lilu         0249c3a918c68a43891350f35fded615b1575776  (BSD-3-Clause)
#   MacKernelSDK 3f750085caa17ec3a7880f11c11bf4f48cd6a164  (APSL-2.0)
#
# The resulting directories are build inputs, not redistributed content:
#   Lilu.kext/Contents/Resources/{Headers,Library}
#   MacKernelSDK/{Headers,Library,LICENSE.txt}
#
# Requires network access on first run. Both directories are git-ignored.
# Called automatically by scripts/bootstrap.sh when the inputs are missing.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

LILU_URL="https://github.com/acidanthera/Lilu.git"
LILU_COMMIT="0249c3a918c68a43891350f35fded615b1575776"
MKS_URL="https://github.com/acidanthera/MacKernelSDK.git"
MKS_COMMIT="3f750085caa17ec3a7880f11c11bf4f48cd6a164"
DEPS="$ROOT/.tmp/deps"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

fetch() {
    local name="$1" url="$2" commit="$3" dest="$4"
    if [ -d "$dest/.git" ] && [ "$(git -C "$dest" rev-parse HEAD 2>/dev/null)" = "$commit" ]; then
        printf '  cached  %s @ %s\n' "$name" "${commit:0:12}"
        return 0
    fi
    rm -rf "$dest"
    mkdir -p "$dest"
    git -C "$dest" init -q
    git -C "$dest" remote add origin "$url"
    git -C "$dest" fetch -q --depth 1 origin "$commit"
    git -C "$dest" checkout -q FETCH_HEAD
    [ "$(git -C "$dest" rev-parse HEAD)" = "$commit" ] \
        || fail "$name commit mismatch (expected $commit)"
    printf '  fetched %s @ %s\n' "$name" "${commit:0:12}"
}

mkdir -p "$DEPS"
fetch "Lilu" "$LILU_URL" "$LILU_COMMIT" "$DEPS/lilu"
fetch "MacKernelSDK" "$MKS_URL" "$MKS_COMMIT" "$DEPS/mackernelsdk"

[ -f "$DEPS/lilu/Lilu/Headers/plugin_start.hpp" ] || fail "Lilu source layout unexpected"
[ -f "$DEPS/lilu/Lilu/Library/plugin_start.cpp" ] || fail "Lilu source layout unexpected"
[ -f "$DEPS/mackernelsdk/Library/universal/libkmod.a" ] || fail "MacKernelSDK source layout unexpected"

echo "== materialising build inputs =="
rm -rf Lilu.kext MacKernelSDK

mkdir -p Lilu.kext/Contents/Resources
# -L resolves the upstream relative symlinks (hde64.h, hde32.h, capstone) in place.
cp -RL "$DEPS/lilu/Lilu/Headers" Lilu.kext/Contents/Resources/Headers
cp -RL "$DEPS/lilu/Lilu/Library" Lilu.kext/Contents/Resources/Library
cp "$DEPS/lilu/Lilu/Headers/plugin_start.hpp" Lilu.kext/Contents/Resources/Library/plugin_start.hpp
cp "$DEPS/lilu/LICENSE.txt" Lilu.kext/Contents/Resources/LICENSE.txt

mkdir -p MacKernelSDK
cp -R "$DEPS/mackernelsdk/Headers" MacKernelSDK/Headers
cp -R "$DEPS/mackernelsdk/Library" MacKernelSDK/Library
cp "$DEPS/mackernelsdk/LICENSE.txt" MacKernelSDK/LICENSE.txt

[ -f Lilu.kext/Contents/Resources/Headers/plugin_start.hpp ] || fail "Lilu headers incomplete"
[ -f Lilu.kext/Contents/Resources/Library/plugin_start.cpp ] || fail "Lilu library incomplete"
[ -f MacKernelSDK/Library/universal/libkmod.a ] || fail "MacKernelSDK incomplete"

echo "  ok      Lilu headers/library"
echo "  ok      MacKernelSDK headers/library"
echo "dependencies ready. Next: ./scripts/build.sh"
