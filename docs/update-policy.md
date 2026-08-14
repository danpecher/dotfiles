# Update policy

The repository uses different update strategies according to how likely an
upstream change is to break the workstation.

## Rolling declarations

Homebrew formulae, casks, Mac App Store applications, and VS Code extensions
are declared by package name. Homebrew and the relevant application updater
choose the installed version. Review package additions and removals manually;
cleanup remains preview-only.

Native Linux packages roll within the installed distribution release and are
declared by package name under `packages/`. Distribution upgrades remain an
explicit system operation. Linux installs mise and VS Code/Code OSS through
distribution-specific adapters. Portable CLI tools whose native names or
availability differ—including Atuin, Bat, Delta, direnv, eza, fd, Glow,
Starship, LazyGit, ShellCheck, shfmt, Watchexec, Yazi, yq, and zoxide—resolve as
`latest` through mise. tmuxinator uses mise's RubyGems backend; mitmproxy and
pgcli use its isolated pipx backend. Existing machines update them only when
`mise upgrade` is run; there is no unattended updater.

Fedora ARM64 uses Microsoft's rolling stable VS Code archive because Microsoft
does not publish an ARM64 RPM. Upgrade it explicitly with
`FORCE_VSCODE_ARCHIVE=1 make packages`; there is no background updater.

## Exact pins

- Global mise runtimes use exact versions in `dot_config/mise/config.toml.tmpl`.
- Neovim plugins use `dot_config/nvim/lazy-lock.json`.
- tmux plugins use commit hashes in `scripts/02_setup.sh`.
- Linux JetBrainsMono Nerd Font uses the checksummed v3.5.0 upstream archive.
- Linux Kanata uses a checksummed v1.11.0 upstream release archive.
- The simple-bar/AeroSpace integration is disabled and has no active pin.

Update pins intentionally in a normal reviewed commit. Validate after changing
them, and record all related lock or configuration changes together. There is
deliberately no unattended updater.

## Machine state

Raw installed-version snapshots are private, ignored diagnostics. The committed
Brewfiles, mise configuration, lockfiles, setup scripts, and `state/policy.md`
are the portable desired-state summary.
