# Coc-first catalog, then VSCode API shim

Onivim 3 will prefer maintained Coc extensions for initial language-feature support. A VSCode API shim may be added later for selected Marketplace language extensions when no adequate Coc extension exists, but arbitrary VSCode extension host parity is not the initial architecture.

## Considered Options

- Coc-first catalog: fastest route to working language features inside embedded Neovim, with the smallest editor-model conflict.
- VSCode API shim inside Coc: useful for selected language extensions later, but only after the native host and Coc language layer have stable boundaries.
- Separate VSCode extension host process: broadest compatibility, but creates conflicting Swift, Neovim, and VSCode workspace/editor models.
