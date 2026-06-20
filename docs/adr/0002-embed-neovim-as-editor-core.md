# Embed Neovim as editor core

Onivim 3 will bundle and launch Neovim as an embedded subprocess rather than linking a Vim-compatible engine directly. SwiftUI/AppKit owns the macOS product surface, while Neovim owns modal editing, buffers, plugins, LSP, terminal behavior, and editor state over MessagePack-RPC/UI events.

## Considered Options

- `libvim`: closer to Onivim 2 and simpler C interop, but requires rebuilding too much of the modern editor ecosystem.
- Linked `libnvim`: avoids a process boundary, but increases ABI/build coupling.
- Embedded Neovim subprocess: accepts RPC/protocol complexity to retain Vim behavior and the Neovim ecosystem immediately.
