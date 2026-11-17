# Compatibility

Three categories only. "Same codec" is not a compatibility statement.

## Verified

Physically tested with this exact build:

| Field | Value |
|---|---|
| Manufacturer / model | Dell G3 3579 |
| Platform | Intel Coffee Lake |
| Controller | `8086:A348` |
| Codec | ALC236 `10EC:0236`, revision `0x100002` |
| Subsystem | `1028:086F` |
| macOS | Sonoma 14.8.9 (23J631) |
| OpenCore / Lilu | OpenCore (project EFI) / Lilu 1.7.3 |
| Layout | 100 |
| Verified functions | speakers, headphones, internal microphone, CTIA headset microphone, volume/mute, automatic input switching |
| Automatic input switching | verified with the macOS Recorder app: unplugging returns capture to the internal microphone, reinserting returns to the external input |
| Validation | Physical recording and playback, November 2026 |

Measured: headset microphone RMS -22.2 dBFS, peak -1.6 dBFS at 80 % input gain,
no clipped samples. Internal microphone RMS -17.7 dBFS.

Sequoia 15.8.2 has **not** been tested with this build.

## Candidate

Potentially similar, but unverified:

- Other Dell laptops with ALC236 and a combo jack whose microphone sits on pin
  `0x19`, wired like this board.

To move a candidate to verified, the following must be collected on the actual
machine:

1. `IOHDACodecVendorID` and `IOHDACodecRevisionID` (`ioreg`).
2. The subsystem ID if it can be obtained (Linux `codec#0` dump is acceptable).
3. Whether the internal microphone, speakers and headphones work with layout 100.
4. Whether a known CTIA headset microphone records intelligible speech.
5. Observed jack behaviour (does the output follow plug/unplug?).

Without step 3 and 4 the machine stays "unknown", regardless of codec ID.

## Unknown / unsupported

- Any machine where the combo-jack microphone is not on `0x19`, or where the
  playback and capture paths differ from the tables in `docs/HARDWARE.md`.
- Machines where headset detection is wired to a GPIO instead of the codec pins.
- OMTP headsets: the layout uses a static CTIA-oriented coefficient; OMTP was
  not tested.
- Non-ALC236 codecs: the resource set in this repository contains ALC236 only;
  other codecs will find no layout at all.

## Reporting a compatibility result

Open the "Compatibility report" issue form. Include the values above, the test
outcomes, and whether the machine is a candidate you want listed here.

Redact serial numbers, UUIDs, MLB/ROM values, and any other private identifiers
before posting logs.
