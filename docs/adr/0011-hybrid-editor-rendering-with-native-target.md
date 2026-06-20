# Hybrid editor rendering with native target

Onivim 3 will initially render editor panes from Neovim UI grid output while the native host owns surrounding IDE surfaces and Native Coc UI. This keeps Vim behavior, highlights, signs, folds, virtual text, cursor state, and plugin rendering correct while the product prioritizes a later native TextKit-backed editor pane fed by Neovim buffer truth.

## Considered Options

- Neovim grid rendering only: most faithful and fastest to correctness, but does not reach the desired native editor feel.
- Native TextKit editor immediately: best macOS feel, but risks correctness across cursor state, selections, folds, extmarks, IME, virtual text, and plugin rendering before the core is stable.
- Hybrid editor rendering with native target: uses Neovim grid first, builds native IDE surfaces now, and treats native editor rendering as the next major rendering milestone.
