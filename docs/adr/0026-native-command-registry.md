# Native command registry

Onivim 3 will make the native host authoritative for product commands. SwiftUI/AppKit owns menus, keybindings, command palette entries, command dispatch, and command presentation. Neovim and Coc commands are projected into the Native Command Registry as providers; Vim `:` remains the embedded editor command-line rather than the product command palette.

## Considered Options

- Native command registry: aligns with the Hybrid IDE Shell and keeps menus, keybindings, and palette UX native while still exposing Neovim and Coc capabilities.
- Neovim command-line authority: Vim-faithful, but weakens product-level command discovery and native app integration.
- Separate command palettes: simpler initially, but duplicates command discovery and creates ambiguous keyboard behavior.
