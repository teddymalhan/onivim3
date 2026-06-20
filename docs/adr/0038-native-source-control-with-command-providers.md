# Native source control with command providers

Onivim 3 will make SwiftUI/AppKit authoritative for Git and source-control surfaces. Native Source Control owns changes, decorations, diffs, staging, commits, branches, and status. Neovim may open diff/file buffers or contribute Git-related commands through context menus or the Native Command Registry, but Neovim plugins do not own source-control UI.

## Considered Options

- Native source control only: cleanest Hybrid IDE Shell boundary and the first implementation target.
- Neovim Git plugins: powerful for Vim users, but would make source-control UX editor-owned instead of product-owned.
- Native source control with command providers: keeps native ownership while allowing Neovim and later Coc commands to participate in Git workflows.
