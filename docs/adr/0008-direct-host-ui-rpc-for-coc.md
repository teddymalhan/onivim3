# Direct host UI RPC for Coc

Onivim 3 will add a dedicated Host UI RPC path between the Coc language layer and the native host. Coc presentation requests, user choices, cancellation, and presentation-state updates go directly between Coc and SwiftUI/AppKit rather than relaying through Neovim.

## Considered Options

- Direct Host UI RPC: best boundary for native UI and avoids inferring user-interface intent from Neovim state, but requires explicit lifecycle, protocol, and security design.
- Coc through Neovim relay: fewer processes/channels, but adds coupling, latency, and ambiguous ownership.
- Swift calls Coc indirectly through Neovim commands: useful for pull-style queries, but insufficient for native completion, hover, quick picks, notifications, and cancellation.
