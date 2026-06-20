# Panel terminal before editor terminal

Onivim 3 will build the first native terminal milestone as terminal panels for shells and tasks. Native terminal sessions may become editor tab or editor group content later, after panel terminal behavior is stable.

## Considered Options

- Panel terminal only: clean IDE model for shells and tasks, but less flexible than VSCode-style terminal editors.
- Terminal editor tabs immediately: flexible, but mixes terminal lifecycle into editor group semantics before the native terminal is proven.
- Panel first, editor terminal later: proves PTY lifecycle, terminal rendering, input, shell profiles, and task hooks before adding editor-tab placement.
