# Neovim highlight truth for native renderer

Onivim 3 will make Neovim authoritative for editor text highlights in the Native Renderer Slice. Swift mirrors Neovim highlight groups, extmarks, selections, diagnostics, virtual text, and plugin-provided highlighting into TextKit attributes rather than computing editor text highlights independently.

## Considered Options

- Neovim highlights are authoritative: preserves colorschemes, plugins, extmarks, diagnostics, selections, and editor semantics while moving rendering into TextKit.
- Swift/tree-sitter highlights are authoritative: gives a more native rendering pipeline, but diverges from Neovim plugins, colorschemes, and runtime state.
- Hybrid by layer: useful later for native-only adornments, but editor text highlights still need one source of truth.
