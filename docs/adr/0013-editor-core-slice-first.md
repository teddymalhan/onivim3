# Editor-core slice first

Onivim 3 will build the Editor-Core Slice before Coc integration or native TextKit editor rendering. The first vertical slice launches bundled Neovim, renders its UI grid, routes keyboard input to it, and supports opening, editing, and saving files with modal behavior intact.

## Considered Options

- Editor-core slice: proves the embedded Neovim boundary, UI grid rendering, input path, file lifecycle, and modal behavior before higher-level IDE surfaces depend on it.
- Language-UI slice: validates Coc and native language UI early, but depends on a stable editor core that does not exist yet.
- Native-renderer slice: moves toward the desired TextKit target, but risks building against an unstable Neovim buffer/input/rendering boundary.
