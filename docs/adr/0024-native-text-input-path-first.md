# Native text input path first

Onivim 3 will implement the first editor input path with AppKit text input behavior rather than only raw key-event translation. The editor surface should support composition-aware text entry while still translating accepted text and commands into Neovim so Neovim remains the source of editing truth.

## Considered Options

- Raw key-event translation: simpler for the Minimal Vim Loop, but risks building the first input architecture around a path that cannot handle macOS text input correctly.
- Native text input path: more first-slice work, but aligns with the macOS product goal and avoids deferring IME/dead-key architecture.
- Hybrid staged input: cheaper initially, but would require replacing the input path soon after acceptance.
