# Native renderer before Coc

Onivim 3 will move the Native Renderer Slice before Coc/native language UI. After the Editor-Core Slice and native terminal panel work, the roadmap prioritizes a native TextKit-backed editor renderer before investing deeply in Coc integration, Native Coc UI, Theme Bridge, or VSCode API shim work.

## Considered Options

- Native renderer before Coc: prioritizes the native editor feel and reduces dependence on a long-lived Neovim grid renderer before language UI becomes complex.
- Coc before native renderer: reaches VSCode/Vim hybrid language UX sooner, but risks building native language surfaces around a temporary editor renderer.
- Compatibility mode earlier: helps existing Neovim users sooner, but delays the product's native editor identity.
