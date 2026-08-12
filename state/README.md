# Observed state

`make snapshot` writes a reviewable inventory under `state/observed/<hostname>`.
These files describe what is installed; they are not automatically promoted to
the desired Brewfile or applied to another machine.

This separation is intentional: observed state catches drift without preserving
every experiment forever.
