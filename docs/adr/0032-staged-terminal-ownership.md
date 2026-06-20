# Staged terminal ownership

Onivim 3 may reuse Neovim terminal buffers through the grid renderer for early terminal support, but this is not the target terminal architecture. The product target is native host-owned terminal panels for IDE tasks and workspace workflows, with Swift/AppKit owning PTY lifecycle, shell profiles, task integration, and workspace terminal state.

## Considered Options

- Neovim terminal buffers first: cheapest early path because the grid renderer already displays terminal buffers, but it keeps terminal UX inside Neovim editor semantics.
- Native terminal panel first: best product boundary for a Hybrid IDE Shell, but expands scope before the Editor-Core Slice is stable.
- Staged terminal ownership: permits early reuse of Neovim terminal behavior while making native terminal panels the near-term target rather than a distant cleanup.
