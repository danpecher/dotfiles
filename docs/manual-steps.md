# Manual setup boundaries

The repository manages dotfiles, declared packages, editor extensions, mise
runtimes, and selected macOS defaults. The following require manual setup or a
separate secret/data backup:

- Apple ID and App Store authentication
- macOS Accessibility, Input Monitoring, Screen Recording, and Full Disk Access
- work MDM enrollment and employer certificates
- Touch ID, Secure Enclave keys, and passkeys
- application licenses and signed-in sessions
- SSH private keys and recovery codes
- application databases, documents, and browser profiles
- Übersicht simple-bar preferences (stored in WebKit local storage; the widget
  source itself is pinned and installed automatically)
- Karabiner VirtualHID approval and Kanata Input Monitoring/Accessibility
  permissions. Karabiner supplies the driver; avoid enabling Karabiner mappings
  at the same time as Kanata because both can compete for keyboard input.
- npm authentication. Keep tokens out of `.zshenv`, `.npmrc`, and this repository;
  inject `NPM_TOKEN` from a password manager or the macOS Keychain instead.

Run `make snapshot` after completing these steps so their installed applications
and system extensions remain visible in the machine inventory.
