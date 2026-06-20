# Theme bridge with Native Coc UI

Onivim 3 will implement the Theme Bridge alongside Native Coc UI rather than during the first Editor-Core Slice. Neovim highlights can carry editor colors during the grid-rendered editor-core phase. Theme tokens become load-bearing when native completion, hover, diagnostics, quick picks, language panels, and future native editor rendering need consistent product colors.

## Considered Options

- Theme Bridge after Editor-Core Slice: improves visual cohesion early, but delays language-feature work before native language UI needs it.
- Theme Bridge alongside Native Coc UI: aligns theme infrastructure with the first native language surfaces that require it.
- Theme Bridge after Native Renderer Slice: too late because native Coc UI already needs shared diagnostic, completion, hover, and panel colors.
