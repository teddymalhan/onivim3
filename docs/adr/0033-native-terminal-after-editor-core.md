# Native terminal after Editor-Core Slice

Onivim 3 will build the native host-owned PTY terminal immediately after the Editor-Core Slice, before Coc/native language UI or native TextKit editor rendering. Neovim terminal buffers may be reused only as an early bridge; they are not the product terminal target.

## Considered Options

- Native terminal immediately after Editor-Core Slice: prioritizes the Hybrid IDE Shell and prevents Neovim terminal behavior from becoming sticky product architecture.
- Native terminal after Native Coc UI: keeps language UX first, but delays a core workspace/IDE surface.
- Native terminal after Native Renderer Slice: rejected because it would let terminal ownership remain inside Neovim too long.
