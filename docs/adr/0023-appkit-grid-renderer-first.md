# AppKit grid renderer first

Onivim 3 will initially render the Neovim UI grid with an AppKit drawing surface using row/cell drawing primitives. A Metal/CoreText renderer remains a later optimization only if profiling shows the AppKit Grid Renderer cannot meet latency, animation, or glyph-rendering requirements.

## Considered Options

- AppKit grid renderer: simplest credible first renderer for a Neovim grid while avoiding SwiftUI per-cell overhead.
- Metal/CoreText renderer: likely best for a highly optimized editor grid, but premature before correctness and measured bottlenecks.
- SwiftUI text views per row or cell: fastest to prototype, but likely too allocation-heavy and janky for editor rendering.
