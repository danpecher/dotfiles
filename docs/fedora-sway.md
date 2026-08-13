# Fedora Sway notes

The supported Linux target is Fedora Sway Spin or Fedora Workstation with the
personal profile's Sway package set. The current pinned Kanata release archive
targets x86_64 Linux. On an ARM64 VM, include `kanata` in `SKIP_STEPS`; the VM
receives keyboard input after host-side remapping, so a guest remapper is
normally unnecessary.

## Session basics

- `Super+Return`: terminal
- `Super+D`: application launcher
- `Super+H/J/K/L` or arrow keys: move focus
- `Super+Shift+H/J/K/L` or arrow keys: move a window
- `Super+1` through `Super+0`: switch workspace
- `Super+Shift+1` through `Super+Shift+0`: move a window to a workspace
- `Super+Ctrl+L`: lock
- `Super+Shift+Q`: close the focused window
- `Super+R`: resize mode
- `Print`: capture the current output
- `Shift+Print`: select and capture a region

Screenshots are stored in `~/Pictures/Screenshots`.

The setup installs a checksummed JetBrainsMono Nerd Font under
`~/.local/share/fonts`; Foot, Waybar, Sway, Rofi, Dunst, and VS Code use its
`JetBrainsMono Nerd Font Mono` family so terminal and status icons render
correctly. Fontconfig uses grayscale antialiasing with slight hinting, and Foot
uses DPI-aware sizing plus gamma-correct blending for clearer text.

Natural scrolling is enabled for both touchpads and mouse wheels.

## Tailscale

The bootstrap installs Tailscale from Fedora, enables `tailscaled`, and leaves
account authentication explicit. Connect the VM when desired with:

```bash
sudo tailscale up
```

## Machine-specific display layout

Run `swaymsg -t get_outputs`, then add named profiles to
`~/.config/kanshi/config`. The committed file intentionally contains no guessed
monitor names or dock topology.

## Kanata

The bootstrap installs a checksummed upstream Kanata binary at
`/usr/local/bin/kanata`, loads the `uinput` kernel module, and enables the root
`kanata.service`. Inspect it with:

```bash
systemctl status kanata.service
journalctl -u kanata.service
```

The service runs as root instead of granting the login user access to every
input device.
