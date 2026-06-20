# Native Coc UI from the start

Onivim 3 will present Coc language-layer features through SwiftUI/AppKit rather than initially relying on Neovim-rendered Coc UI. Completion, hover, diagnostics, quick picks, output, notifications, and extension management are native product surfaces even when Coc remains the language-feature provider.

## Considered Options

- Neovim-rendered Coc UI first: fastest path to working behavior, but delays the native product feel and makes the first editor look like a terminal UI.
- Native Coc UI from the start: higher integration cost, but aligns with the hybrid IDE shell goal and avoids designing against temporary Vim UI affordances.
- Split UI ownership: useful later as a fallback strategy, but ambiguous as the primary architecture.
