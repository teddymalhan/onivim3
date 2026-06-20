# Theme bridge with imports

Onivim 3 will use a Theme Bridge. Onivim product theme tokens are authoritative for native shell surfaces, and those tokens are projected into Neovim highlight groups and Coc/native language UI. Onivim may import VSCode themes and Neovim colorschemes into product tokens and editor highlight mappings, but the source theme formats are not authoritative at runtime.

## Considered Options

- Neovim theme drives editor and Onivim theme drives shell: simple split, but risks visual mismatch across editor, panels, diagnostics, and completion UI.
- Onivim theme only: cohesive, but discards the Neovim colorscheme ecosystem and future VSCode theme support.
- Theme bridge with imports: preserves native product tokens while supporting VSCode theme and Neovim colorscheme imports when mappings are possible.
