# Neovim buffers are text truth

Onivim 3 will treat Neovim buffers as the authoritative text state. SwiftUI/AppKit presents editor state and requests edits, but it does not own editable text storage. Coc mirrors Neovim documents for language features, and native UI references Neovim buffer identifiers and change ticks when presenting diagnostics, completion anchors, hovers, and edits.

## Considered Options

- Neovim buffer truth: aligns with embedded Neovim and Coc, keeps Vim semantics authoritative, and avoids reconciliation.
- Swift document truth: gives native text ownership, but fights embedded Neovim and requires translating Vim semantics onto Swift storage.
- Dual source with sync: allows both sides to mutate text, but creates conflict resolution, latency, and correctness risk.
