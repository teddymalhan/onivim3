# Native layout translation target

Onivim 3 will target Native Layout Translation: Vim layout commands such as `:split`, `:vsplit`, `:tabnew`, `:only`, and `Ctrl-w` navigation map to native editor groups, splits, tabs, and focus. For the first Editor-Core Slice, Onivim will not expose Neovim splits or tabs as product UI and may clearly reject or defer Vim layout commands until native translation exists.

## Considered Options

- Translate Vim layout commands to native layout: consistent with Native Editor Layout, but requires explicit command interception and state mapping.
- Allow Neovim internal layout inside native panes: easier initially, but creates nested layout confusion and weakens native layout ownership.
- Disable or limit Vim layout commands initially: honest for the first slice, but must be replaced by native translation to satisfy Vim expectations.
