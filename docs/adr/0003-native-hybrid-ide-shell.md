# Native hybrid IDE shell

Onivim 3 will be a hybrid IDE shell rather than only a native Neovim GUI. SwiftUI/AppKit owns the workspace model, project navigation, panels, search, Git, diagnostics, tasks, settings, and non-editor flows; embedded Neovim owns editor panes and Vim behavior.

## Considered Options

- Native Neovim GUI: smaller scope, but leaves little product differentiation from VimR or Neovide.
- Onivim-style editor hiding Neovim: clearer branding, but confuses Neovim plugin/config expectations.
- Hybrid IDE shell: keeps a clean boundary between native workspace UX and Neovim editor semantics.
