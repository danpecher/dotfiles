# Update policy

The repository uses different update strategies according to how likely an
upstream change is to break the workstation.

## Rolling declarations

Homebrew formulae, casks, Mac App Store applications, and VS Code extensions
are declared by package name. Homebrew and the relevant application updater
choose the installed version. Review package additions and removals manually;
cleanup remains preview-only.

Fedora RPMs are likewise rolling within the installed Fedora release and are
declared by package name under `packages/`. Fedora upgrades remain an explicit
system operation. mise comes from its maintainer's COPR, and VS Code comes from
Microsoft's official RPM repository. Fedora does not package Starship, LazyGit,
or Yazi, so Linux resolves their `latest` releases through mise. Existing
machines update them only when `mise upgrade` is run; there is no unattended
updater.

## Exact pins

- Global mise runtimes use exact versions in `dot_config/mise/config.toml.tmpl`.
- Neovim plugins use `dot_config/nvim/lazy-lock.json`.
- tmux plugins use commit hashes in `scripts/02_setup.sh`.
- Linux Kanata uses a checksummed v1.11.0 upstream release archive.
- The simple-bar/AeroSpace integration is disabled and has no active pin.

Update pins intentionally in a normal reviewed commit. Validate after changing
them, and record all related lock or configuration changes together. There is
deliberately no unattended updater.

## Machine state

Raw installed-version snapshots are private, ignored diagnostics. The committed
Brewfiles, mise configuration, lockfiles, setup scripts, and `state/policy.md`
are the portable desired-state summary.
