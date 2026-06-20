# Bundled workspace search

Onivim 3 will ship a bundled ripgrep-style workspace text-search backend for native search and replace. SwiftUI/AppKit owns the search UI, result presentation, and replace flow; the bundled backend gives predictable performance, ignore handling, and result parsing across projects.

## Considered Options

- Bundled ripgrep-style backend: predictable for source trees and keeps native search UI product-owned.
- macOS Spotlight/FileProvider APIs: native, but unreliable for source trees, generated files, ignored files, and unsaved workspace workflows.
- Neovim `:grep` or quickfix: Vim-compatible, but makes workspace search behavior and result UI editor-owned.
