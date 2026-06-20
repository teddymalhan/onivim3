# Editor-core acceptance path

Onivim 3 will define the Editor-Core Slice by an ordered acceptance path:

1. Open the app, open a file, edit with modal input, save, quit, and reopen the file to verify persistence.
2. Open the app from the CLI with a file path, edit, and save.
3. Open a folder, use the native file tree, open a file, edit, and save.

## Considered Options

- App-file-edit-save first: proves the embedded Neovim process, grid renderer, input path, save path, and persistence with the fewest product surfaces.
- CLI file path next: proves developer workflow and launch argument routing.
- Folder/file-tree flow next: proves the native workspace shell without blocking the editor-core proof on project UI.
- All at once: rejected as a first milestone because failures would be harder to localize.
