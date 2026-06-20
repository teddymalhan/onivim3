# Minimal Vim loop acceptance

Onivim 3 will define first-slice modal-input acceptance with the Minimal Vim Loop: insert-mode text entry, Escape to normal mode, `:w`, `:q`, `hjkl`, `i`, `a`, `x`, `dd`, and `u`. The Daily Editing Vim Suite follows as the next regression scope with visual mode, yank/paste, search, repeat, counts, word/line motions, and command-line editing.

## Considered Options

- Minimal Vim loop: proves the host input path, modal state, command-line entry, editing commands, save, quit, and undo without pretending to test all of Neovim.
- Daily-editing Vim loop: useful next, but too broad as the first acceptance gate.
- Full Vim behavior: delegated to Neovim; Onivim tests should focus on host integration not breaking representative input paths.
