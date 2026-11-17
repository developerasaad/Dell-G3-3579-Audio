# Dell G3 3579 Audio

A specialised [AppleALC](https://github.com/acidanthera/AppleALC) build that adds
native AppleHDA support for the combo-jack headset microphone on the Dell G3
3579 (Realtek ALC236).

upstream AppleALC ships about a hundred codec resource sets. This repository
keeps **one**: layout **100** for codec `10EC:0236`. The C++ patching engine is
upstream code and is unchanged; the specialisation is a resource selection, not
a new audio stack.

## What it changes compared with upstream AppleALC

| | Upstream 1.9.9 | This build |
|---|---|---|
| Codec resources | 110 directories, ~49 MB | ALC236 only, ~104 KB |
| Layouts | dozens | layout 100 only |
| `HDAConfigDefault` entries | 664 | 1 (`283902518` / layout 100) |
| Release kext binary | 1,905,640 B | 83,000 B |
| C++ source | — | unmodified |

Layout 100 maps pin `0x19` (combo jack) as **Mic In** and routes it through ADC
`0x23`, so a CTIA headset microphone is captured. Upstream layout 15 maps the
same pin as Line In, which is why the headset microphone is silent with it.

## Supported hardware

This is a machine-specific build. Verified on:

| Item | Value |
|---|---|
| Computer | Dell G3 3579, Intel Coffee Lake |
| Codec | Realtek ALC236, `10EC:0236`, revision `0x100002` |
| Codec subsystem | `1028:086F` (established from Linux/BIOS; macOS does not expose it) |
| HDA controller | `8086:A348` |
| Layout | 100 |

A matching codec ID is **not** proof that another laptop will work — pin wiring
and jack detection are board-specific. See [COMPATIBILITY.md](COMPATIBILITY.md).

## macOS versions

- **Sonoma 14.8.9 (23J631)** — tested on hardware.
- **Sequoia 15.8.2** — not tested with this build.

## Features

- Internal speakers and headphones with jack detection.
- Internal microphone.
- CTIA 4-pole headset microphone through the combo jack.
- Automatic input switching: unplugging the headset returns capture to the
  internal microphone (verified with the macOS Recorder app).
- Native volume and mute controls through Core Audio.

Measured on the tested unit at 80 % input gain: RMS -22.2 dBFS, peak -1.6 dBFS,
no clipped samples.

## Requirements

- OpenCore with **Lilu** loaded before AppleALC.
- An existing EFI you can edit; this project does not ship a full EFI.

## Build

```bash
git clone <repository-url>
cd Dell-G3-3579-Audio
./scripts/bootstrap.sh
./scripts/build.sh
./scripts/validate.sh
./scripts/package.sh
```

No third-party sources are committed. The first `bootstrap.sh` run downloads
Lilu headers and MacKernelSDK at pinned commits (network needed once, then
cached under `.tmp/deps/`). See [docs/BUILDING.md](docs/BUILDING.md).

## Install

Copy `AppleALC.kext` from the package into `EFI/OC/Kexts`, add the OpenCore
`Kernel -> Add` entry, and set `layout-id` to `100` on the HDA device.

Full instructions, including replacing an existing AppleALC and rollback:
[docs/INSTALLATION.md](docs/INSTALLATION.md).

## Documentation

- [docs/HARDWARE.md](docs/HARDWARE.md) — codec topology and pin paths
- [docs/BUILDING.md](docs/BUILDING.md) — toolchain and build details
- [docs/INSTALLATION.md](docs/INSTALLATION.md) — OpenCore integration
- [COMPATIBILITY.md](COMPATIBILITY.md) — verified, candidate, unknown
- [CHANGELOG.md](CHANGELOG.md)

## Known limitations

- Plugging or unplugging briefly removes the output volume/mute property while
  Core Audio rebuilds the output controls (measured ≤ 0.5 s). It recovers on its
  own.
- One latched-mute state was observed once during development; it cleared by
  writing the mute flag again. The cause is not proven.
- The combo-jack coefficient is static. An OMTP headset is not supported by this
  configuration; OMTP was not tested.
- Volume above ~85 % input gain clips on the tested unit.

## Credits and licence

Derived from [AppleALC](https://github.com/acidanthera/AppleALC) by vit9696 and
contributors, BSD-3-Clause. Layout 100 is derived from upstream layout 69
("ALC236 for Dell ICL for Lorys89 by Vorshim"). Lilu is BSD-3-Clause;
MacKernelSDK is APSL-2.0. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
and [LICENSE](LICENSE).

This project does not redistribute any Apple binary or SDK. It is not an
independent replacement for macOS audio.
