# Portable Linux Sway notes

The supported Linux targets are Fedora, Debian, Ubuntu, and Arch-family
distributions using systemd. The same chezmoi-managed Sway environment is used
on each; only native repositories and package names differ.

| Distribution | Package manager | Editor package | Validation target |
| --- | --- | --- | --- |
| Fedora | DNF; Microsoft archive on ARM64 | Microsoft VS Code | Fedora 44 |
| Ubuntu | APT | Microsoft VS Code | Ubuntu 24.04 LTS |
| Debian | APT | Microsoft VS Code | Debian 13 |
| Arch family | Pacman | Code OSS | Current Arch repositories |

Fast-moving user CLI tools are installed through mise so they expose identical
commands on every distribution. Native package managers own system components,
including Sway, Foot, PipeWire, portals, NetworkManager, Tailscale, and systemd
services.

Microsoft's Fedora RPM is not published for ARM64. On that architecture the
setup installs the current official VS Code ARM64 archive under
`~/.local/opt/vscode` and creates a user-local launcher; x86_64 Fedora uses the
RPM repository normally.

The pinned Kanata release archive targets x86_64 Linux. On an ARM64 VM, include
`kanata` in `SKIP_STEPS`; the VM receives keyboard input after host-side
remapping, so a guest remapper is normally unnecessary.

## Session basics

- `Super+Return`: terminal
- `Super+D`: application launcher
- `Super+H/J/K/L` or arrow keys: move focus
- `Super+Shift+H/J/K/L` or arrow keys: move a window
- `Super+1` through `Super+0`: switch workspace
- `Super+Shift+1` through `Super+0`: move a window to a workspace
- `Super+Ctrl+L`: lock
- `Super+Shift+Q`: close the focused window
- `Super+R`: resize mode
- `Print`: capture the focused output
- `Shift+Print`: select and capture a region

Screenshots are stored in `~/Pictures/Screenshots`. The screenshot helper uses
only `swaymsg`, `jq`, `grim`, and `slurp`, avoiding distro-specific `grimshot`
packaging.

The setup installs a checksummed JetBrainsMono Nerd Font under
`~/.local/share/fonts`; Foot, Waybar, Sway, Rofi, Dunst, and VS Code use its
`JetBrainsMono Nerd Font Mono` family. Fontconfig uses grayscale antialiasing
with slight hinting, and Foot uses DPI-aware sizing plus gamma-correct blending.
Natural scrolling is enabled for touchpads and mouse wheels.

## Tailscale

Bootstrap installs Tailscale, enables `tailscaled`, and leaves authentication
explicit. Connect a machine when desired with:

```bash
sudo tailscale up
```

## Machine-specific display layout

Run `swaymsg -t get_outputs`, then add named profiles to
`~/.config/kanshi/config`. The committed file intentionally contains no guessed
monitor names or dock topology.

## Kanata

Bootstrap installs a checksummed upstream Kanata binary at
`/usr/local/bin/kanata`, loads `uinput`, and enables the root
`kanata.service`. Inspect it with:

```bash
systemctl status kanata.service
journalctl -u kanata.service
```

The service runs as root instead of granting the login user access to every
input device.
