# Staged plugin policy

Onivim 3 will keep the isolated default Neovim runtime minimal for the Editor-Core Slice: only Onivim runtime glue, no user plugin manager, and no arbitrary Neovim plugins. When the Coc Language Layer begins, the default runtime may add a curated app-owned plugin set such as Coc and selected language extensions.

## Considered Options

- Minimal embedded Neovim: best for proving launch, grid rendering, input, open/edit/save, and modal behavior without plugin noise.
- Curated plugin set: appropriate once language features begin, because Onivim can test and support a known runtime.
- User plugin manager from day one: flexible, but expands the support surface before the editor-core boundary is stable.
