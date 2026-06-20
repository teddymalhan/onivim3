# Pinned Neovim runtime with debug override

Onivim 3 will ship a pinned Neovim binary and runtime inside the macOS app bundle for product builds. External or system Neovim may be used only through an explicit developer debugging override.

## Considered Options

- Pinned bundled Neovim only: most reproducible for users, but less convenient for debugging protocol and runtime issues.
- System/Homebrew Neovim: fastest for development, but users would get different versions, runtime paths, plugin behavior, and breakage.
- Pinned bundled default with debug override: keeps product behavior reproducible while preserving a practical escape hatch for development.
