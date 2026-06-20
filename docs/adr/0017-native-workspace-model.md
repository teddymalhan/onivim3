# Native workspace model

Onivim 3 will make the native host authoritative for workspace and project state. SwiftUI/AppKit owns opened folders, recent projects, file tree roots, search roots, Git roots, tasks, and project-level state. Neovim receives projected cwd/root updates for editor contexts rather than owning the product workspace model.

## Considered Options

- Native workspace model: aligns with the Hybrid IDE Shell and lets the product own project navigation, search, Git, tasks, and window state.
- Neovim cwd/workspace ownership: simpler initially, but weakens the native IDE shell and makes project behavior depend on editor internals.
- Coc workspace folders as source of truth: rejected because Coc is the language layer, not the product shell.
