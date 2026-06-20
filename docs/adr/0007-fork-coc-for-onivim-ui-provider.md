# Fork Coc for Onivim UI provider

Onivim 3 will fork or patch Coc early to add an Onivim UI provider. Coc remains the language-feature layer, but presentation requests for completion, hover, quick picks, diagnostics, output, notifications, and extension management are routed to the native host instead of Neovim UI primitives.

## Considered Options

- Coc fork with Onivim UI provider: highest maintenance cost, but gives SwiftUI/AppKit first-class ownership of language UI.
- Companion Coc extension: lower maintenance, but cannot cleanly intercept every Coc UI path and would leak Vim UI behavior.
- Neovim event scraping: avoids Coc patches, but is fragile because native UI would infer intent from rendered Vim state.
