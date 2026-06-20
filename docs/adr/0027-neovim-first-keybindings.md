# Neovim-first keybindings

Onivim 3 will use Neovim-first keybindings for editor-focused input. Keys, including Command-modified shortcuts such as `Cmd-S` and `Cmd-O`, are offered to Neovim-style mappings before native app shortcuts unless a focused native UI surface explicitly owns the interaction. Native macOS shortcut conventions are less important than preserving Vim-style keybinding behavior.

## Considered Options

- Native-first Command shortcuts: aligns with macOS conventions, but makes editor behavior less Vim-like and creates surprise for Neovim users.
- Neovim-first keybindings: preserves Vim/Neovim mapping expectations and lets users treat Onivim as a Vim-first editor, at the cost of standard macOS shortcut behavior.
- Context stack with reserved native shortcuts: balanced for ordinary macOS apps, but not aligned with the chosen Vim-first product identity.
