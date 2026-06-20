# One Neovim process per app window

Onivim 3 will run one embedded Neovim process per app window. Each window owns independent buffers, cwd/root projection, tabs, and later its own Coc instance. This isolates Neovim global state and keeps window lifecycle bugs local.

## Considered Options

- One Neovim process per app window: simplest isolation boundary and avoids cross-window collisions in cwd, buffers, tabs, commands, plugins, runtime state, and Coc state.
- One Neovim process per workspace: useful if one workspace later spans multiple windows, but adds lifecycle and sharing complexity before the first product needs it.
- One shared Neovim process for the whole app: most memory-efficient, but risks global-state collisions across windows.
