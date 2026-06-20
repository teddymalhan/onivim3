# Display-only native renderer slice

Onivim 3 will keep the Native Renderer Slice display-only. TextKit displays mirrored Neovim state, but it does not own mouse selection, IME ownership, drag/drop, accessibility editing, scrolling, hit-testing, or text mutation in that milestone. Those behaviors wait for the Native Interaction Target.

## Considered Options

- Display-only renderer slice: keeps the milestone focused on mirror correctness, highlight mapping, cursor state, and fallback behavior.
- Basic mouse/scroll interaction: tempting for native feel, but mixes interaction ownership into the same milestone as renderer parity.
- Full native interaction immediately: rejected because it combines the hardest renderer and input problems before the mirror has earned trust.
