# JSON-RPC for Host UI RPC

Onivim 3 will use JSON-RPC for the Host UI RPC path between the Coc language layer and the native host. Neovim remains on its existing MessagePack-RPC/UI protocol; Coc native UI requests use JSON-RPC because the UI path benefits more from debuggability, schema evolution, and straightforward Node/Swift implementation than from compact binary encoding.

## Considered Options

- JSON-RPC: boring, inspectable, versionable, and easy to implement from Node and Swift.
- MessagePack-RPC: matches Neovim and reduces payload size, but is harder to inspect and evolve by hand.
- Custom framed binary protocol: adds bespoke maintenance risk without being on the editor hot path.
