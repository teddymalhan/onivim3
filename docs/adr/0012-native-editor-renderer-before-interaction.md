# Native editor renderer before native interaction

Onivim 3 will approach native editor panes in two milestones. The first milestone is a Native Renderer Slice: TextKit displays mirrored Neovim buffer state while edits, cursor movement, selections, folds, undo, macros, marks, and registers still route through Neovim. The target milestone is Native Interaction Target: TextKit owns mouse selection, IME composition, scrolling, hit-testing, and accessibility while text mutations still commit through Neovim.

## Considered Options

- Native renderer only: safest first step because Neovim remains authoritative for every editing semantic.
- Native interaction layer: desired target for macOS feel, but must not take text mutation ownership away from Neovim.
- Native text subsystem: rejected because TextKit-owned text storage would contradict Neovim buffer truth and create a dual-source sync problem.
