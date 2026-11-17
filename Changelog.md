# Changelog

## 1.9.9-dell100.1 — 2026-11-17

First specialised release for the Dell G3 3579.

### Added

- Layout 100 for ALC236 (`10EC:0236`): pin `0x19` retasked from Line In to
  Mic In, routed through ADC `0x23`; internal microphone remains on `0x12 → ADC
  0x24`. Registered under a Dell-specific layout/platform pair.
- `Resources/PinConfigs.kext` entry for codec `283902518`, layout 100, with the
  76-byte ConfigData used by layout 69.
- Build tooling: `scripts/bootstrap.sh`, `build.sh`, `validate.sh`,
  `package.sh`, `identify-hardware.sh`.
- Build dependencies fetched at pinned commits by `scripts/fetch-deps.sh`
  (Lilu headers, MacKernelSDK); no third-party sources are committed.
- OpenCore fragments generated at packaging time
  (`Kernel-Add.plist`, `DeviceProperties-Add.plist`).
- Documentation: README, hardware, building, installation, compatibility,
  contributing, security, code of conduct, third-party notices.

### Changed

- Codec resources reduced to ALC236 only (110 directories removed, 49 MB →
  104 KB).
- Layout and platform registration reduced to layout 100.
- `HDAConfigDefault` reduced from 664 entries to one.
- Release binary size 1,905,640 B → 83,000 B. C++ source unchanged.

### Verified

- Sonoma 14.8.9 (23J631), Dell G3 3579: speakers, headphones, internal
  microphone, CTIA headset microphone, volume and mute.
- Automatic input switching in applications (macOS Recorder): unplugging the
  headset returns capture to the internal microphone, reinserting it returns to
  the external input.
- Headset microphone at 80 % input: RMS -22.2 dBFS, peak -1.6 dBFS, no clipping.

### Known limitations

- Transient loss of the output volume property (≤ 0.5 s) during plug/unplug.
- One latched-mute occurrence, cause not established.
- OMTP headsets untested; Sequoia untested with this build.

### Base

- AppleALC 1.9.9, commit `ff01db21749271916d44605503499ceaa61d94b2`.
- Lilu headers `0249c3a918c68a43891350f35fded615b1575776`.
- MacKernelSDK `3f750085caa17ec3a7880f11c11bf4f48cd6a164`.
