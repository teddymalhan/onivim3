# Golden event replay and dual-render debug

Onivim 3 will prove Native Renderer Slice parity with Golden Event Replay and Dual-render Debug Mode. Recorded Neovim buffer, redraw, highlight, cursor, extmark, and virtual-text event streams are replayed into the Incremental Buffer Mirror for deterministic regression tests. A development mode can run the Neovim grid renderer and TextKit renderer side-by-side against the same editor state to diagnose real-world divergence.

## Considered Options

- Golden event replay: deterministic and suitable for regression testing mirror state without font or OS rendering flake.
- Screenshot diff tests: useful for visual smoke checks, but flaky across fonts, OS rendering, antialiasing, and display settings.
- Dual-render debug mode: excellent for diagnosis and real workloads, but not sufficient as the only regression method.
