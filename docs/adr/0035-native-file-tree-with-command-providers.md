# Native file tree with command providers

Onivim 3 will make SwiftUI/AppKit authoritative for the file tree. The native file tree owns workspace file display, active-file reveal, rename, delete, drag/drop, and Git decorations. Neovim receives opened files and may contribute file-related commands through context menus or the Native Command Registry, but Neovim plugins do not own the file-tree UI.

## Considered Options

- Native file tree only: cleanest Hybrid IDE Shell boundary and the first implementation target.
- Neovim plugin file tree: fastest if using netrw/telescope/oil-style plugins, but violates the native workspace model.
- Native file tree with command providers: preserves native ownership while allowing Neovim and later Coc commands to participate in file actions.
