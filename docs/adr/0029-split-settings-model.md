# Split settings model

Onivim 3 will split configuration ownership by domain. Onivim product settings own native UI, workspace, shell, window, and app behavior. Neovim configuration owns mappings, editor options, modal behavior, and editor semantics. Coc settings later belong to the language layer.

## Considered Options

- Split settings model: keeps product settings native while preserving Neovim expectations for mappings and editor behavior.
- Everything through Neovim config: Vim-pure, but makes native product settings awkward and couples app UX to Lua/Vimscript.
- Everything through Onivim settings: simpler native UI, but weakens Neovim compatibility and mapping expectations.
