# Coc language layer before VSCode parity

Onivim 3 will use Coc inside embedded Neovim as the first language-feature and extension bridge. The near-term compatibility target is language extensions and VSCode-like editor capabilities, not arbitrary VSCode Marketplace extension parity.

## Considered Options

- Coc extensions only: fastest and already Neovim-native, but smaller than the VSCode Marketplace.
- True VSCode extension host parity: matches the broadest ecosystem, but requires implementing large parts of the `vscode` API and reconciling VSCode's editor/workspace model with Neovim's model.
- Language extension compatibility first: uses Coc for immediate language features and leaves room to adapt selected Marketplace language extensions later.
