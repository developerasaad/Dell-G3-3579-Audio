# Hardware

All identifiers below refer to different hardware layers. A controller PCI ID is
not a codec ID, and a codec ID does not determine a board's pin wiring.

## Identifiers

| Layer | Value | How it was obtained |
|---|---|---|
| Computer | Dell G3 3579, Intel Coffee Lake | Physical machine |
| HDA controller | `8086:A348` | PCI configuration / IORegistry |
| Codec | Realtek ALC236, `10EC:0236` | `IOHDACodecVendorID` = `283902518` |
| Codec revision | `0x100002` | `IOHDACodecRevisionID` = `1048578` |
| Codec subsystem | `1028:086F` | Linux/BIOS evidence; **not exposed by macOS** |
| Layout | `100` | This project |

macOS publishes the codec vendor/device and revision. It does not expose the
codec subsystem, so `1028:086F` cannot be read back at runtime on macOS.

## Pin topology used by layout 100

| Pin | Role | Pin default config | Signal path |
|---|---|---|---|
| `0x12` | Internal microphone | `0x90a60120` | `0x12 → ADC 0x24` (via converter `0x07`) |
| `0x14` | Internal speakers | `0x90170140` | `0x14 → DAC 0x02` |
| `0x19` | Combo jack input | `0x00a71040` (Mic In) | `0x19 → ADC 0x23` (via converter `0x08`) |
| `0x21` | Headphones | `0x01211030` | `0x21 → DAC 0x03` |

Pin `0x19` is retasked from Line In (`0x008b…`, upstream layout 15) to Mic In
(`0x00a7…`, layout 100). That change is what makes the headset microphone work.

## Codec observations

Measured with AppleALC's `alc-verb` on the test boot:

- `0x19` widget capabilities `0x0040048b`: input capable, headphone-drive bit,
  VREF capable, **no presence-detect bit**.
- `0x21` widget capabilities `0x0040058d`: presence detect present.
- `0x19` pin control during capture: `0x22` (input enable + VREF ground).
  The wake verb sets `0x24` (input + VREF 80 %).
- COEF `0x45 = 0xd689` at initialisation; wake data re-applies pin control on
  `0x14`, `0x19`, `0x21`.
- ADC connection lists: `0x22 = {0x18,0x19,0x1a,0x1b,0x1d}`,
  `0x23 = {0x18,0x19,0x1a,0x1b,0x1d,0x12}`, `0x24 = {0x12,0x13}`.

Jack presence comes from the headphone pin `0x21`. Automatic input switching
was verified with the macOS Recorder app: removing the headset returns capture
to the internal microphone, and reinserting it returns to the external input.
Pin `0x19` itself has no presence-detect capability.

## Functional verification

Measured on Sonoma 14.8.9 with a CTIA 4-pole headset:

| Test | Result |
|---|---|
| Internal speakers | working |
| Headphones | working, jack detection via `0x21` |
| Internal microphone | RMS -17.7 dBFS, peak +0.7 dBFS |
| Headset microphone, 80 % input | RMS -22.2 dBFS, peak -1.6 dBFS, 0 clipped |
| Headset microphone, 100 % input | clipping (315 clipped samples) |

## Linux reference

The Linux `snd-hda-codec-realtek` driver was used as a behavioural reference
only. It has no quirk for `1028:086F`; the closest Dell fixups retask `0x19` to
`0x01a1913c` ("headset mic, without its own jack detect") and run a dynamic
headset state machine that AppleHDA does not have. No GPL code was copied into
this repository.

## What is not known

- Whether a second physical unit of the same model has identical wiring.
- OMTP headset behaviour (untested; the static coefficient targets CTIA).
- Whether Sequoia 15.8.2 behaves identically; not tested with this build.
