# Observed state

`make snapshot` writes a private inventory under `state/observed/<hostname>`.
These ignored files describe what is installed; they are not committed,
automatically promoted to the desired Brewfile, or applied to another machine.

This separation is intentional: observed state helps local investigation
without publishing a detailed machine inventory or preserving every experiment
forever. Portable policy lives in `state/policy.md` and the declaration files it
references.
