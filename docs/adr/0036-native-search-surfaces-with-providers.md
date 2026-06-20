# Native search surfaces with providers

Onivim 3 will make SwiftUI/AppKit authoritative for search UI. Native search surfaces own file-name quick open, workspace text search, replace flows, and later symbol search. Search backends may include system APIs, bundled search tools, Neovim commands, or Coc/LSP providers. Vim `/` remains Neovim-owned in-buffer search rather than replacing native workspace search.

## Considered Options

- Native search owns workspace search and quick open: clean product boundary, but should not hard-code a single backend.
- Neovim-owned search: Vim-faithful, but weakens the Hybrid IDE Shell and native workspace model.
- Native search with provider backends: keeps native UI ownership while allowing efficient or editor-aware search providers underneath.
