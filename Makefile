SHELL := /bin/bash
PROFILE ?= personal

.PHONY: help diff plan apply packages services bootstrap doctor snapshot validate validate-linux validate-linux-packages lint format watch macos-defaults cleanup-preview

help:
	@printf '%s\n' \
	  'make diff              Browse chezmoi-managed file drift with Delta' \
	  'make plan              Compatibility alias for make diff' \
	  'make apply             Reconcile chezmoi-managed files only' \
	  'make packages          Install declared packages, runtimes, and plugins' \
	  'make services          Configure/start declared background services' \
	  'make bootstrap         Run interactive first-machine provisioning' \
	  'make doctor            Check desired state; change nothing' \
	  'make snapshot          Capture the current machine inventory' \
	  'make validate          Validate repository syntax and rendering' \
	  'make validate-linux    Render both profiles and parse Sway in Linux' \
	  'make validate-linux-packages  Check package names in four distro repositories' \
	  'make lint              Run ShellCheck on managed shell scripts' \
	  'make format            Format managed shell scripts with shfmt' \
	  'make watch             Re-run validation whenever files change' \
	  'make macos-defaults    Explicitly apply managed macOS preferences' \
	  'make cleanup-preview   Preview undeclared Homebrew packages' \
	  '' \
	  'PROFILE=personal is the default. PROFILE=minimal omits personal desktop integrations.' \
	  'SKIP_STEPS=github,kanata omits selected optional bootstrap/setup steps.'

diff:
	@PROFILE="$(PROFILE)" ./scripts/05_plan.sh

plan: diff

apply:
	@PROFILE="$(PROFILE)" ./scripts/06_apply.sh

packages:
	@PROFILE="$(PROFILE)" ./scripts/02_setup.sh packages

services:
	@PROFILE="$(PROFILE)" ./scripts/02_setup.sh services

bootstrap:
	@PROFILE="$(PROFILE)" ./scripts/01_bootstrap.sh

doctor:
	@PROFILE="$(PROFILE)" ./scripts/04_audit.sh

snapshot:
	@PROFILE="$(PROFILE)" ./scripts/05_snapshot.sh

validate:
	@PROFILE="$(PROFILE)" ./scripts/07_validate.sh

validate-linux:
	@PROFILE="$(PROFILE)" ./scripts/09_validate-linux.sh

validate-linux-packages:
	@PROFILE="$(PROFILE)" ./scripts/10_validate-linux-packages.sh

lint:
	@shellcheck --severity=warning scripts/*.sh bin/executable_ios-build

format:
	@shfmt -w -i 4 -ci -bn scripts bin/executable_ios-build

watch:
	@watchexec --clear --restart -- make validate

macos-defaults:
	@./scripts/03_macos-defaults.sh

cleanup-preview:
	@PROFILE="$(PROFILE)" ./scripts/08_cleanup-preview.sh
