# Building

## Host requirements

- macOS 14 or later on Intel or Apple silicon (the kext targets `x86_64`).
- **Full Xcode**, not Command Line Tools. The verified toolchain is
  **Xcode 16.2 (16C5032a)** with the **macOS 15.2 SDK**.
- `xcode-select` must point at the Xcode application:

```bash
sudo xcode-select -s /Applications/Xcode.app
xcodebuild -version
```

Command Line Tools alone cannot build the project — the AppleALC target needs
`MacKernelSDK` and the kernel headers shipped with Xcode.

## Dependencies

No third-party sources are committed. `scripts/fetch-deps.sh` downloads them at
pinned commits and verifies the checked-out `HEAD` before use:

| Dependency | Upstream | Commit | Licence |
|---|---|---|---|
| Lilu headers/library | `acidanthera/Lilu` | `0249c3a918c68a43891350f35fded615b1575776` | BSD-3-Clause |
| MacKernelSDK | `acidanthera/MacKernelSDK` | `3f750085caa17ec3a7880f11c11bf4f48cd6a164` | APSL-2.0 |

`scripts/bootstrap.sh` calls the fetcher when the inputs are missing, so network
access is required once per clone. The checkouts are cached in `.tmp/deps/` and
materialised into the paths the Xcode project expects:

```text
.tmp/deps/lilu          -> Lilu.kext/Contents/Resources/{Headers,Library}
.tmp/deps/mackernelsdk  -> MacKernelSDK/{Headers,Library}
```

All of these paths are git-ignored. To force a fresh download, delete
`.tmp/deps/` and rerun `./scripts/bootstrap.sh`. The pins are authoritative: a
`commit mismatch` abort means upstream history changed, not that the pin should
be relaxed.

## Build

```bash
./scripts/bootstrap.sh   # host check + dependency fetch
./scripts/build.sh       # clean Release build into build/DerivedData
./scripts/validate.sh    # static checks on resources and the built kext
./scripts/package.sh     # dist/Dell-G3-3579-Audio-<version>/ + .zip
```

Outputs:

- `build/DerivedData/Build/Products/Release/AppleALC.kext`
- `build/build.log`
- `dist/Dell-G3-3579-Audio-<version>.zip`

The packaging version defaults to `<CFBundleVersion>-dell100.1`. Override it
with `VERSION=... ./scripts/package.sh` when preparing a release.

## Reproducing a release

1. Check out the release commit.
2. Use Xcode 16.2 or a newer Xcode with the macOS 15.2 SDK.
3. Run the four scripts above.
4. Compare `dist/.../MANIFEST.json` (`kext.executable_sha256`) with the published
   manifest. The release build on the verified toolchain produced
   `b54c7c26d8c330aa059aa59bf9bf207353d14026b26d69090d6c5f024c0a86e8`;
   a different Xcode or SDK may legitimately produce a different hash, which is
   why the manifest records the toolchain.

## What the build does

- `ResourceConverter` packs `Resources/ALC236/*.xml` to `.zlib` and generates
  `AppleALC/kern_resources.cpp`.
- The generated file is git-ignored; it is rebuilt whenever a resource `.md5`
  changes.
- `Merge Pinconfigs` copies `Resources/PinConfigs.kext` into the kext
  `Info.plist` as `HDAConfigDefault`.

## Common problems

| Symptom | Cause and fix |
|---|---|
| `xcodebuild: error: tool 'xcodebuild' requires Xcode` | `xcode-select` points at Command Line Tools; run the `xcode-select -s` command above |
| `'Headers/hde64.h' file not found` | the fetched Lilu inputs are missing or incomplete; rerun `./scripts/bootstrap.sh` |
| `Build input file cannot be found: .../Lilu.kext/Contents/Resources/...` | same as above |
| `fetch-deps.sh` fails on `git fetch`, or aborts with `commit mismatch` | no network access, or the pinned commit is unreachable upstream. Restore access; do not substitute a different revision |
| Stale resources after editing XML | delete `AppleALC/kern_resources.cpp` and `Resources/*.md5`, then rebuild |
| `scripts/build.sh` exits with 141 | a `| head` in a `pipefail` pipeline; report it rather than editing around it |

## Validation coverage

`validate.sh` checks: only ALC236 resources exist; only layout/platform 100 are
registered; the pin-config entry is exactly one for codec `283902518`; the built
kext declares `as.vit9696.Lilu`; its bundle id and version are unchanged; the
executable exists; the build log is a successful Release build.

It cannot check audible behaviour. Speaker, headphone and microphone tests are
hardware tests and are listed in `COMPATIBILITY.md`.
