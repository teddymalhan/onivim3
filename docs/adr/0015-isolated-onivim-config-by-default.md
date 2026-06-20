# Isolated Onivim config by default

Onivim 3 will run embedded Neovim with an isolated Onivim-owned configuration by default. Product builds use app-owned config, data, cache, runtime additions, and plugin sets instead of loading the user's normal `~/.config/nvim` configuration. A Neovim Compatibility Mode may be added later as an explicit opt-in escape hatch.

## Considered Options

- Load user Neovim config by default: maximizes Neovim compatibility, but makes product behavior unpredictable and hard to support.
- Isolated Onivim config by default: keeps product behavior reproducible and gives the app a stable baseline.
- Two modes: default isolated Onivim behavior with a later opt-in compatibility mode for users who want their existing Neovim setup.
