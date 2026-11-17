# Third-party notices

This repository contains modified upstream source. Third-party build
dependencies are downloaded at build time and are not redistributed here.
Nothing is presented as original work beyond the layout 100 resources and the
build/packaging scripts.

Release archives contain only the built `AppleALC.kext`, the OpenCore
fragments and documentation — no upstream sources, headers or SDK files.

## AppleALC

- Upstream: https://github.com/acidanthera/AppleALC
- Base revision: `ff01db21749271916d44605503499ceaa61d94b2` (1.9.9)
- Licence: BSD-3-Clause (`LICENSE`, `LICENSE.txt`)
- Retained: the C++ patching engine (`AppleALC/`), `ResourceConverter`, the
  Xcode project, `alc-verb`, and the shared resource tables
  (`Controllers.plist`, `Kexts.plist`, `Vendors.plist`). Copyright headers are
  unchanged.
- Modified: codec resources reduced to ALC236, layout 100 added, PinConfigs
  reduced to one entry. No C++ logic was changed.

## Layout 69 attribution

Layout 100 is derived from upstream ALC236 layout 69, whose upstream comment is
"ALC236 for Dell ICL for Lorys89 by Vorshim". The topology is reused with
permission of the project licence; the Dell G3 3579 registration and the
single-layout packaging are this repository's changes.

## Lilu (build dependency)

- Upstream: https://github.com/acidanthera/Lilu
- Commit: `0249c3a918c68a43891350f35fded615b1575776`
- Licence: BSD-3-Clause (upstream `LICENSE.txt`)
- Not redistributed: `scripts/fetch-deps.sh` downloads the pinned commit into
  `.tmp/deps/lilu/` and copies the development headers and `plugin_start.cpp`
  into git-ignored build paths (`Lilu.kext/Contents/Resources/`, including
  `LICENSE.txt`). The Lilu runtime kext is not included; users must install Lilu
  separately.
- Local change: `plugin_start.hpp` copied into `Library/` for the Xcode project,
  and relative header symlinks resolved by `cp -RL`.

## MacKernelSDK (build dependency)

- Upstream: https://github.com/acidanthera/MacKernelSDK
- Commit: `3f750085caa17ec3a7880f11c11bf4f48cd6a164`
- Licence: Apple Public Source License 2.0 (upstream `LICENSE.txt`)
- Not redistributed: fetched by `scripts/fetch-deps.sh` into `.tmp/deps/` and
  copied unmodified (`Headers/`, `Library/`) into the git-ignored `MacKernelSDK/`.

## Linux kernel (reference only)

The Linux `snd-hda-codec-realtek` driver was studied as behavioural evidence for
ALC236 headset handling. It is GPL-2.0. **No Linux source code is included in or
copied into this repository.**

## Apple

AppleHDA, Core Audio, Xcode and the macOS SDK are Apple products and are not
redistributed here. This project only supplies configuration resources that
AppleHDA consumes at runtime.
