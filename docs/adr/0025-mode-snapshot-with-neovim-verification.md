# Mode snapshot with Neovim verification

Onivim 3 will maintain a host-side Mode Snapshot from Neovim UI and mode events for low-latency input decisions. The native host may verify with `nvim_get_mode()` on ambiguous transitions or debug checks, but Neovim remains authoritative for mode state.

## Considered Options

- Query Neovim mode on demand: simplest to reason about, but adds latency and race risk to every input decision.
- Subscribe to mode/redraw events: gives low-latency input behavior, but requires careful state maintenance.
- Mode snapshot with verification: keeps input responsive while preserving Neovim as the authority when transitions are ambiguous.
