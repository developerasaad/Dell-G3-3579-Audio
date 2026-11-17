# Contributing

## Before you open an issue

- Read `docs/HARDWARE.md` and `COMPATIBILITY.md`. A matching codec ID alone does
  not make a machine a candidate.
- Reproduce with the current build, not a modified kext.
- Collect `./scripts/identify-hardware.sh` output and the exact macOS build.

## Bug reports

Use the "Bug report" form. Include:

- What you expected and what happened.
- macOS version and build, OpenCore version, Lilu version.
- Layout actually in use (`ioreg -rn HDEF -l`).
- Whether speakers, headphones, internal mic and headset mic work.
- Reproduction steps (plug order matters).

Redact serial numbers, UUIDs, MLB/ROM and any personal data.

## Compatibility reports

Use the "Compatibility report" form. It asks for the controller ID, codec ID,
subsystem ID if available, macOS version and the four functional tests. A model
is listed as verified only after someone has physically tested it and posted the
results.

## Patches

- Keep the change scoped: resource changes in `Resources/`, build logic in
  `scripts/`.
- Run `./scripts/bootstrap.sh && ./scripts/build.sh && ./scripts/validate.sh`
  before opening a pull request.
- Do not add other codecs or layouts to this distribution; it is intentionally
  single-layout.
- Do not copy code from GPL sources (including the Linux driver) into this
  BSD-licensed project. Linux may be cited as behavioural evidence only.
- Do not include Apple binaries, SDK contents, personal EFI dumps or secrets.

## Commit style

Short imperative subject, one logical change per commit. Mention the affected
pin, layout or script in the body when it is not obvious.

## Licence

Contributions are accepted under the repository licence (BSD-3-Clause, see
`LICENSE`).
