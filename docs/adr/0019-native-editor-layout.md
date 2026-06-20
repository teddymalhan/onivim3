# Native editor layout

Onivim 3 will make SwiftUI/AppKit authoritative for visible editor layout. The native host owns editor groups, split direction, tab presentation, focus, and pane placement. Neovim remains authoritative for buffers and editing semantics, but its buffers and windows are projected into native editor panes rather than making Neovim splits and tabs the product layout.

## Considered Options

- Native editor layout: best aligned with the Hybrid IDE Shell and macOS product direction, but requires explicit mapping between native panes and Neovim buffer/window state.
- Neovim-owned splits: fastest and faithful to Vim, but would make the product a Neovim GUI rather than a native IDE shell.
- Staged hybrid layout: smaller first slice, but delays the chosen product boundary and risks building UI around temporary Neovim split behavior.
