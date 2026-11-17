# Installation in an existing OpenCore EFI

This project does not ship a complete EFI. You add one kext and two config
entries to the EFI you already boot.

## 1. Back up your EFI

Copy the whole `EFI` folder somewhere safe. All changes below are reversible by
copying it back.

## 2. Install the kext

Copy `EFI/OC/Kexts/AppleALC.kext` from the release package to:

```text
EFI/OC/Kexts/AppleALC.kext
```

If your EFI already has `AppleALC.kext`, **replace the bundle** — do not keep
two copies. There must never be two enabled AppleALC entries. The bundle
identifier stays `as.vit9696.AppleALC`, so OpenCore needs no path changes.

Lilu is required and must load before AppleALC. Keep your existing Lilu entry
above it.

## 3. Kernel -> Add

Add one entry (the package contains this as `OpenCore/Kernel-Add.plist`):

| Key | Value |
|---|---|
| `Arch` | `Any` |
| `BundlePath` | `AppleALC.kext` |
| `Comment` | `AppleALC 1.9.9` |
| `Enabled` | `true` |
| `ExecutablePath` | `Contents/MacOS/AppleALC` |
| `MaxKernel` | *(empty)* |
| `MinKernel` | *(empty)* |
| `PlistPath` | `Contents/Info.plist` |

`MinKernel`/`MaxKernel` are empty because the kext is built for the supported
macOS range as a whole. If you prefer to restrict it, use OpenCore's kernel
version strings; do not guess values from another repository.

## 4. DeviceProperties -> Add

Layout 100 is selected on the HDA device:

```text
PciRoot(0x0)/Pci(0x1f,0x3)
  layout-id = <64000000>
```

`64 00 00 00` is little-endian 100. The package contains this as
`OpenCore/DeviceProperties-Add.plist`. If the device already has a `layout-id`,
overwrite it rather than adding a second key.

## 5. Boot arguments

Do not set `alcid=15` or any other `alcid` value: AppleALC gives `alcid` the
highest priority and it would override the layout. If you prefer boot-args over
DeviceProperties, the equivalent is `alcid=100`, and then `layout-id` must not
contradict it.

## 6. Verify after reboot

```bash
ioreg -rn HDEF -l | grep -E 'layout-id|alc-layout-id'
```

Expect `alc-layout-id = <64000000>` (100).

```bash
system_profiler SPAudioDataType
```

Expect Built-in Output, Built-in Microphone and Built-in Input (External
Microphone). Then record a few seconds with the headset plugged in; set the
input volume around 80 % — higher values clip.

## 7. Rollback

Replace `EFI/OC/Kexts/AppleALC.kext` with the previous bundle and restore the
previous `layout-id` (for stock layout 15, `<0f000000>`), or copy your backed-up
EFI back.

## ocvalidate note

`ocvalidate` is version-sensitive. Validate a **complete copy** of your
`config.plist` with the `ocvalidate` binary that matches your OpenCore release.
The fragments in this package are valid property lists, but they are fragments,
not a full configuration.
