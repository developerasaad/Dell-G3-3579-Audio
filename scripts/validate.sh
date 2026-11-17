#!/bin/bash
# validate.sh — static checks for the specialised ALC236/layout-100 build.
#
# Usage: ./scripts/validate.sh [path-to-AppleALC.kext]
#
# With no argument it validates build/DerivedData/Build/Products/Release/AppleALC.kext.
# Exits non-zero on the first failed category and prints a summary.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

KEXT="${1:-build/DerivedData/Build/Products/Release/AppleALC.kext}"
FAILS=0
pass() { printf '  PASS  %s\n' "$*"; }
fail() { printf '  FAIL  %s\n' "$*"; FAILS=$((FAILS+1)); }

echo "== resource tree =="
TOP="$(ls -p Resources | grep -v / | grep -v '\.md5$' | sort | tr '\n' ' ')"
[ "$TOP" = "Controllers.plist Kexts.plist Vendors.plist " ] \
    && pass "top-level tables only" || fail "unexpected top-level resources: $TOP"

DIRS="$(ls -d Resources/*/ | sort | tr '\n' ' ')"
[ "$DIRS" = "Resources/ALC236/ Resources/PinConfigs.kext/ " ] \
    && pass "only ALC236 + PinConfigs" || fail "unexpected codec directories: $DIRS"

EXTRA="$(ls Resources/ALC236 | grep -v -E '^(Info\.plist|layout100\.xml|Platforms100\.xml)(\.md5|\.zlib|\.zlib\.md5)?$' || true)"
[ -z "$EXTRA" ] && pass "ALC236 holds layout 100 only" || fail "extra ALC236 resources: $EXTRA"

echo "== plist content =="
/usr/libexec/PlistBuddy -c 'Print :Files:Layouts'   Resources/ALC236/Info.plist >/dev/null 2>&1 \
    && pass "ALC236 Info.plist parses" || fail "ALC236 Info.plist unreadable"
plutil -lint Resources/PinConfigs.kext/Contents/Info.plist >/dev/null \
    && pass "PinConfigs lint" || fail "PinConfigs lint failed"

python3 - "$KEXT" <<'PY'
import plistlib, sys
fails = 0
def check(cond, msg):
    global fails
    print(('  PASS  ' if cond else '  FAIL  ') + msg)
    if not cond: fails += 1

info = plistlib.load(open('Resources/ALC236/Info.plist','rb'))
layouts   = [e.get('Id') for e in info['Files']['Layouts']]
platforms = [e.get('Id') for e in info['Files']['Platforms']]
check(layouts == [100],   f"layout registration is exactly [100]: {layouts}")
check(platforms == [100], f"platform registration is exactly [100]: {platforms}")

lay = open('Resources/ALC236/layout100.xml').read()
pla = open('Resources/ALC236/Platforms100.xml').read()
check('<key>LayoutID</key>' in lay and '<integer>100</integer>' in lay, "layout100.xml declares LayoutID 100")
check(lay.count('<integer>100</integer>') >= 2, "layout100.xml PathMapID is 100")
check('<key>PathMapID</key>' in pla and '<integer>100</integer>' in pla, "Platforms100.xml declares PathMapID 100")

pc = plistlib.load(open('Resources/PinConfigs.kext/Contents/Info.plist','rb'))
entries = [e for p in pc['IOKitPersonalities'].values() for e in (p.get('HDAConfigDefault') or [])]
check(len(entries) == 1, f"PinConfigs has exactly 1 entry: {len(entries)}")
check(entries and entries[0].get('CodecID') == 283902518, "entry targets codec 283902518 (ALC236)")
check(entries and entries[0].get('LayoutID') == 100, "entry targets layout 100")

kext = sys.argv[1]
try:
    ki = plistlib.load(open(kext + '/Contents/Info.plist','rb'))
except Exception as e:
    check(False, f"built kext Info.plist readable: {e}")
    sys.exit(1)

check(ki.get('CFBundleIdentifier') == 'as.vit9696.AppleALC', f"bundle id {ki.get('CFBundleIdentifier')}")
check('as.vit9696.Lilu' in (ki.get('OSBundleLibraries') or {}), "Lilu dependency declared")
check(bool(ki.get('CFBundleVersion')), f"version {ki.get('CFBundleVersion')}")
pers = ki.get('IOKitPersonalities', {}).get('as.vit9696.AppleALC', {})
arr = pers.get('HDAConfigDefault') or []
check(len(arr) == 1, f"kext ships exactly 1 HDAConfigDefault entry: {len(arr)}")
check(arr and arr[0].get('CodecID') == 283902518 and arr[0].get('LayoutID') == 100,
      "kext entry is ALC236 / layout 100")
check(not any(e.get('CodecID') != 283902518 for e in arr), "no other codecs in the kext")

exec_name = ki.get('CFBundleExecutable', '')
import os
check(os.path.isfile(f"{kext}/Contents/MacOS/{exec_name}"), f"executable Contents/MacOS/{exec_name} exists")
sys.exit(1 if fails else 0)
PY
[ $? -eq 0 ] && pass "plist/metadata checks" || fail "plist/metadata checks"

echo "== build artifact =="
if [ -d "$KEXT" ]; then
    pass "kext present: $KEXT"
    file "$KEXT/Contents/MacOS/AppleALC" | grep -q 'Mach-O' \
        && pass "kext binary is Mach-O" || fail "kext binary is not Mach-O"
    if [ -f build/build.log ]; then
        grep -q 'Release' build/build.log && pass "build log is Release" || fail "build log is not Release"
        grep -q 'BUILD SUCCEEDED' build/build.log && pass "build log reports success" || fail "build log missing BUILD SUCCEEDED"
    else
        fail "build/build.log missing (run ./scripts/build.sh)"
    fi
else
    fail "kext not found; run ./scripts/build.sh"
fi

echo
if [ "$FAILS" -eq 0 ]; then
    echo "validation passed"
    exit 0
fi
echo "validation failed: $FAILS problem(s)"
exit 1
