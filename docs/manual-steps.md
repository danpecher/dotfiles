# Manual setup boundaries

The repository manages dotfiles, declared packages, editor extensions, mise
runtimes, and selected macOS defaults. The following require manual setup or a
separate secret/data backup:

- Apple ID and App Store authentication
- macOS Accessibility, Input Monitoring, Screen Recording, and Full Disk Access
- Linux display output names and layouts. Add machine-specific Kanshi profiles
  after inspecting `swaymsg -t get_outputs`; the repository does not guess a
  dock or monitor topology.
- work MDM enrollment and employer certificates
- Touch ID, Secure Enclave keys, and passkeys
- application licenses and signed-in sessions
- Tailscale account authentication. On Linux the daemon is enabled
  automatically, but joining a tailnet remains explicit: `sudo tailscale up`.
- SSH private keys and recovery codes
- application databases, documents, and browser profiles
- Karabiner VirtualHID approval and Kanata Input Monitoring/Accessibility
  permissions. Karabiner supplies the driver; avoid enabling Karabiner mappings
  at the same time as Kanata because both can compete for keyboard input.
  `make services` refuses to start Kanata while mappings remain in the selected
  Karabiner profile; after they are disabled it enables Kanata at boot through
  the root Homebrew service.
- On Fedora, Kanata runs as a root systemd service and loads `uinput` at boot;
  this avoids granting the interactive user broad access to all input devices.
- npm authentication. Keep tokens out of `.zshenv`, `.npmrc`, and this repository;
  inject `NPM_TOKEN` from a password manager or the macOS Keychain instead.

Run `make snapshot` after completing these steps so their installed applications
and system extensions remain visible in the machine inventory.
