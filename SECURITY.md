# Security policy

## Scope

In scope:

- The kext built from this repository (`AppleALC.kext`).
- The scripts in `scripts/` and the packaging output.
- Build or packaging behaviour that could modify a user's EFI or data.

Out of scope:

- AppleHDA, Core Audio, macOS or firmware defects.
- Third-party bootloaders, kexts or EFI configurations.
- Hardware failures.

## Reporting

A dedicated private disclosure channel has not been configured for this
repository.

Preferred route: use GitHub's private vulnerability reporting for this
repository if it is enabled (Security tab → Report a vulnerability). If it is not
available, open a minimal public issue stating that you have a security report
and ask for a private channel; do not include exploit details, personal data or
machine identifiers in the public issue.

## What to expect

- Acknowledgement when the report is seen.
- A fix or a documented limitation, depending on severity and reproducibility.
- Credit in the changelog unless you ask otherwise.

## Safe harbour

Good-faith research on your own hardware is welcome. Do not test against systems
you do not own or have permission to use.
