# Native focus ownership

Onivim 3 will make focused native controls own their local input even though editor-focused keybindings are Neovim-first. Command-palette search fields, file rename fields, settings text fields, extension search boxes, quick-pick filters, and similar native controls handle text input and local navigation until Escape returns focus to the editor.

## Considered Options

- Focused native control owns text input: preserves usable SwiftUI/AppKit controls while keeping editor focus Neovim-first.
- Neovim receives all input globally: maximally Vim-pure, but makes native controls awkward and undermines the Hybrid IDE Shell.
- Per-surface manual exceptions: flexible, but risks inconsistent focus and Escape behavior across panels.
