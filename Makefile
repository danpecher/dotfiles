SHELL := /bin/bash
PROFILE ?= personal

.PHONY: help plan apply doctor snapshot validate macos-defaults cleanup-preview

help:
	@printf '%s\n' \
	  'make plan              Show drift; change nothing' \
	  'make apply             Reconcile dotfiles, Homebrew, extensions, and mise' \
	  'make doctor            Check desired state; change nothing' \
	  'make snapshot          Capture the current machine inventory' \
	  'make validate          Validate repository syntax and rendering' \
	  'make macos-defaults    Explicitly apply managed macOS preferences' \
	  'make cleanup-preview   Preview undeclared Homebrew packages' \
	  '' \
	  'PROFILE=personal is the default. PROFILE=minimal uses Brewfile.minimal.'

plan:
	@PROFILE="$(PROFILE)" ./scripts/05_plan.sh

apply:
	@PROFILE="$(PROFILE)" ./scripts/06_apply.sh

doctor:
	@PROFILE="$(PROFILE)" ./scripts/04_audit.sh

snapshot:
	@PROFILE="$(PROFILE)" ./scripts/05_snapshot.sh

validate:
	@PROFILE="$(PROFILE)" ./scripts/07_validate.sh

macos-defaults:
	@./scripts/03_macos-defaults.sh

cleanup-preview:
	@PROFILE="$(PROFILE)" ./scripts/08_cleanup-preview.sh
