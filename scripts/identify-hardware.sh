#!/bin/bash
# identify-hardware.sh — read-only audio hardware report.
#
# Usage: ./scripts/identify-hardware.sh
#
# Collects what macOS exposes. Values that macOS does not expose are marked as
# such instead of being guessed. This script never modifies the system and does
# not decide compatibility.

set -u

hex() { printf '0x%X' "$1"; }

echo "== system =="
sw_vers 2>/dev/null || true
MODEL="$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Model Identifier/{print $2}')"
echo "Model Identifier : ${MODEL:-unknown}"

echo
echo "== HDA controller (PCI) =="
ioreg -rn HDEF -l 2>/dev/null | awk '
    /"model"|"IOName"|"device-id"|"vendor-id"|"layout-id"|"alc-layout-id"/ { gsub(/^ +/,""); print "  " $0 }
' | head -20

echo
echo "== codec (driver-published) =="
CODEC="$(ioreg -l 2>/dev/null | awk -F'= ' '/IOHDACodecVendorID/{gsub(/[^0-9]/,"",$2); print $2; exit}')"
REV="$(ioreg -l 2>/dev/null | awk -F'= ' '/IOHDACodecRevisionID/{gsub(/[^0-9]/,"",$2); print $2; exit}')"
if [ -n "${CODEC:-}" ]; then
    VEND="$(hex $((CODEC >> 16)))"
    DEV="$(hex $((CODEC & 0xFFFF)))"
    echo "  vendor/device   : ${VEND}:${DEV} (decimal $CODEC)"
else
    echo "  vendor/device   : not exposed"
fi
[ -n "${REV:-}" ] && echo "  revision        : $(hex "$REV")" || echo "  revision        : not exposed"

cat <<'NOTE'
  codec subsystem : not exposed by macOS. For this project it was established
                    from the Linux driver/BIOS as 1028:086F on the tested unit.
NOTE

echo
echo "== active layout =="
ioreg -rn HDEF -l 2>/dev/null | awk '
    /"layout-id"|"alc-layout-id"/ { gsub(/^ +/,""); print "  " $0 }
'
echo "  expected for this build: alc-layout-id = 100 (0x64)"

echo
echo "== audio endpoints =="
system_profiler SPAudioDataType 2>/dev/null | sed -n '1,40p'

echo
echo "A matching codec ID does not prove that a machine is supported; pin wiring"
echo "and jack detection are board-specific. See COMPATIBILITY.md."
