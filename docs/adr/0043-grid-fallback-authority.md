# Grid fallback authority

Onivim 3 will keep the Neovim grid renderer as the correctness fallback during the Native Renderer Slice. If the TextKit mirror is missing, stale, or invalid, Onivim shows the Neovim grid or marks the pane degraded rather than presenting incorrect native text. The native renderer must earn authority through parity and verification.

## Considered Options

- Grid fallback authority: prioritizes correctness while the TextKit mirror matures and gives users a trustworthy fallback.
- TextKit stays visible and heals eventually: preserves native feel, but risks stale text, stale highlights, incorrect cursor state, and misleading diagnostics.
- Crash/assert policy: useful in development tests, but not a product fallback strategy.
