#!/bin/bash
# package.sh — build the distributable EFI-ready archive.
#
# Usage: ./scripts/package.sh [path-to-AppleALC.kext]
#
# Output:
#   dist/Dell-G3-3579-Audio-<version>/        EFI/, OpenCore/, MANIFEST.json, SHA256SUMS, README.md
#   dist/Dell-G3-3579-Audio-<version>.zip
#
# No complete EFI is shipped and no EFI is modified.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

KEXT="${1:-build/DerivedData/Build/Products/Release/AppleALC.kext}"
[ -d "$KEXT" ] || { echo "FAIL: kext not found at $KEXT (run ./scripts/build.sh)" >&2; exit 1; }

KVER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$KEXT/Contents/Info.plist")"
VERSION="${VERSION:-${KVER}-dell100.1}"
NAME="Dell-G3-3579-Audio-${VERSION}"
OUT="dist/${NAME}"

rm -rf "$OUT"
mkdir -p "$OUT/EFI/OC/Kexts" "$OUT/OpenCore"
ditto "$KEXT" "$OUT/EFI/OC/Kexts/AppleALC.kext"

python3 - "$OUT" "$VERSION" <<'PY'
import json, os, plistlib, subprocess, sys, datetime, hashlib
out, version = sys.argv[1], sys.argv[2]
kext = os.path.join(out, 'EFI/OC/Kexts/AppleALC.kext')
info = plistlib.load(open(os.path.join(kext, 'Contents/Info.plist'), 'rb'))
bid = info['CFBundleIdentifier']
bver = info['CFBundleVersion']
exe = info.get('CFBundleExecutable', 'AppleALC')

kernel_add = [{
    'Arch': 'Any',
    'BundlePath': 'AppleALC.kext',
    'Comment': 'AppleALC ' + bver,
    'Enabled': True,
    'ExecutablePath': 'Contents/MacOS/' + exe,
    'MaxKernel': '',
    'MinKernel': '',
    'PlistPath': 'Contents/Info.plist',
}]
with open(os.path.join(out, 'OpenCore/Kernel-Add.plist'), 'wb') as f:
    plistlib.dump(kernel_add, f, fmt=plistlib.FMT_XML)

device_props = {
    'PciRoot(0x0)/Pci(0x1f,0x3)': {'layout-id': bytes([100, 0, 0, 0])},
}
with open(os.path.join(out, 'OpenCore/DeviceProperties-Add.plist'), 'wb') as f:
    plistlib.dump(device_props, f, fmt=plistlib.FMT_XML)

def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()

commit = subprocess.run(['git', 'rev-parse', 'HEAD'], capture_output=True, text=True).stdout.strip()
try:
    xcode = subprocess.run(['xcodebuild', '-version'], capture_output=True, text=True).stdout.splitlines()[0]
except Exception:
    xcode = 'unknown'

manifest = {
    'name': 'Dell-G3-3579-Audio',
    'version': version,
    'generated': datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds'),
    'source_commit': commit,
    'toolchain': xcode,
    'kext': {
        'bundle_identifier': bid,
        'bundle_version': bver,
        'executable_sha256': sha256(os.path.join(kext, 'Contents/MacOS', exe)),
        'info_sha256': sha256(os.path.join(kext, 'Contents/Info.plist')),
    },
    'layout_id': 100,
    'hardware': {
        'codec': '10EC:0236',
        'codec_subsystem': '1028:086F',
        'controller': '8086:A348',
    },
}
with open(os.path.join(out, 'MANIFEST.json'), 'w') as f:
    json.dump(manifest, f, indent=2)
    f.write('\n')
PY

cp README.md "$OUT/README.md"
if [ -f docs/INSTALLATION.md ]; then
    cp docs/INSTALLATION.md "$OUT/OpenCore/INSTALL.md"
else
    printf '# Installation\n\nSee the repository documentation.\n' > "$OUT/OpenCore/INSTALL.md"
fi

plutil -lint "$OUT/OpenCore/Kernel-Add.plist" >/dev/null
plutil -lint "$OUT/OpenCore/DeviceProperties-Add.plist" >/dev/null

( cd "$OUT" && find . -type f ! -name 'SHA256SUMS' -exec shasum -a 256 {} + | sort -k2 > SHA256SUMS )

ZIP="dist/${NAME}.zip"
rm -f "$ZIP"
ditto -c -k --keepParent "$OUT" "$ZIP"

echo
echo "== packaged =="
echo "  bundle : $OUT"
echo "  zip    : $ZIP"
echo "  layout : 100 (DeviceProperties fragment included)"
echo "  kext   : $(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$OUT/EFI/OC/Kexts/AppleALC.kext/Contents/Info.plist")"
