# Portable desired-state summary

The committed desired state consists of:

- `Brewfile` and `Brewfile.minimal` for named software declarations
- `packages/fedora-*.txt` for Fedora CLI and Sway declarations
- `packages/vscode-extensions.txt` for Fedora's cross-platform editor extensions
- `dot_config/mise/config.toml.tmpl` for exact global runtime versions
- `dot_config/nvim/lazy-lock.json` and pinned tmux commits for plugin versions
- chezmoi source files for portable user configuration
- `scripts/macos-defaults.tsv` for audited scalar macOS preferences
- explicit bootstrap code for permissions, accounts, services, and other state
  that cannot be represented as a regular file

Raw application, service, extension, and package inventories are local evidence,
not policy. Promote an observed item only by editing the appropriate declaration
and reviewing the change.
