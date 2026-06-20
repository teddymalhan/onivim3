# Incremental buffer mirror for native renderer

Onivim 3 will feed the Native Renderer Slice with an Incremental Buffer Mirror. Swift maintains TextKit state from Neovim buffer change events, redraw/highlight events, cursor events, and extmark updates instead of polling full or ranged buffer snapshots. Neovim remains buffer truth; the mirror is a presentation cache.

## Considered Options

- Neovim buffer pull snapshots: simpler, but risks latency, stale ranges, excess copying, and fragile invalidation.
- Neovim event mirror: more work, but matches the direction needed for a serious native renderer while preserving Neovim as authoritative state.
- Coc/LSP document mirror: rejected because Coc comes later in the roadmap and language-layer documents are not editor rendering truth.
