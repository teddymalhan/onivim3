# Onivim 3

Onivim 3 is a native macOS code editor whose product surface is SwiftUI/AppKit while an embedded Neovim process owns Vim semantics and editor-core behavior.

## Language

**Native Host**:
The macOS application shell responsible for windows, menus, panels, commands, and platform integration.
_Avoid_: Shell, wrapper, app chrome

**Native Command Registry**:
The product-owned command system for menus, keybindings, command palette entries, and command execution. Neovim and Coc commands are projected into it as providers, while Vim `:` remains the embedded editor command-line.
_Avoid_: Command palette, Neovim commands, command bridge

**Neovim-first Keybindings**:
The keybinding policy where editor-focused keys, including Command-modified shortcuts such as `Cmd-S` and `Cmd-O`, are offered to Neovim-style mappings before native app shortcuts unless a focused native UI surface explicitly owns the interaction.
_Avoid_: macOS shortcuts, native-first shortcuts, shortcut compatibility

**Native Focus Ownership**:
The input exception to Neovim-first keybindings: a focused native control such as a command-palette search field, file rename field, settings text field, extension search box, or quick-pick filter owns its local text input and navigation until Escape returns focus to the editor.
_Avoid_: Global Neovim input, focus exception, native input mode

**Split Settings Model**:
The configuration policy where Onivim product settings own native UI, workspace, shell, and app behavior, while Neovim configuration owns mappings, editor options, and modal/editor semantics; Coc settings later belong to the language layer.
_Avoid_: Unified settings, Neovim-only settings, app-only settings

**Theme Bridge**:
The theming model where Onivim exposes native product theme tokens, projects them into Neovim highlight groups and Coc/native language UI, and can import VSCode themes or Neovim colorschemes into those tokens when possible.
_Avoid_: Neovim theme, VSCode theme, shell theme

**Theme Bridge Milestone**:
The roadmap placement for theming work: implement the Theme Bridge alongside Native Coc UI, when native completion, hover, diagnostics, and language panels require shared product tokens.
_Avoid_: Early theme work, late theme import, visual polish

**Theme Import**:
The future capability that converts a VSCode theme or Neovim colorscheme into Onivim product tokens plus editor highlight mappings without making the source theme format authoritative.
_Avoid_: Theme parity, theme compatibility, colorscheme support

**Hybrid IDE Shell**:
The native workspace surface that owns project navigation, panels, search, Git, diagnostics, tasks, settings, and non-editor flows while delegating editor panes to the embedded editor core.
_Avoid_: Native Neovim GUI, wrapper, IDE frontend

**Staged Terminal Ownership**:
The terminal policy where early terminal support may reuse Neovim terminal buffers through the grid renderer, but the product target is native host-owned terminal panels for IDE tasks and workspace workflows.
_Avoid_: Neovim terminal, terminal compatibility, terminal panel

**Native Terminal Target**:
The later terminal architecture where Swift/AppKit owns PTY lifecycle, terminal panels, task integration, shell profiles, and workspace terminal state instead of delegating product terminal behavior to Neovim terminal buffers.
_Avoid_: Terminal rewrite, external terminal, PTY bridge

**Panel Terminal Slice**:
The first native terminal milestone where Swift/AppKit provides terminal panels for shells and tasks without making terminals editor-tab content.
_Avoid_: Terminal editor, terminal tab, embedded shell

**Terminal Editor Target**:
The later terminal milestone where native terminal sessions may appear as editor tab or editor group content after panel terminal behavior is stable.
_Avoid_: Terminal pane, VSCode terminal, terminal document

**Terminal Replacement Milestone**:
The roadmap placement for terminal work: build the native host-owned PTY terminal immediately after the Editor-Core Slice, before native TextKit editor rendering and Coc/native language UI.
_Avoid_: Later terminal, terminal follow-up, language-first terminal

**Native Workspace Model**:
The product-owned model for opened folders, recent projects, file tree roots, search roots, Git roots, tasks, and project-level state; Neovim receives projected cwd/root updates for editor contexts.
_Avoid_: Neovim workspace, Coc workspace, project state

**Native File Tree**:
The product-owned file explorer for workspace files, active-file reveal, rename, delete, drag/drop, and Git decorations. Neovim receives opened files and may contribute commands, but it does not own file-tree UI.
_Avoid_: Neovim file tree, explorer plugin, project tree

**File Tree Command Providers**:
The extension point where Neovim or later Coc commands can appear in native file-tree context menus and command palette actions without taking ownership of the file tree.
_Avoid_: File tree plugins, command bridge, context menu integration

**Native Search Surfaces**:
The product-owned UI for file-name quick open, workspace text search, replace flows, and later symbol search. Backends may include system APIs, bundled search tools, Neovim commands, or Coc/LSP providers.
_Avoid_: Neovim search, search plugin, grep UI

**Bundled Workspace Search**:
The workspace text-search backend shipped with Onivim, using ripgrep-style behavior so native search and replace have predictable performance, ignore handling, result parsing, and product-owned UI.
_Avoid_: Spotlight search, Neovim grep, system search

**Native Source Control**:
The product-owned Git/source-control model and UI for changes, decorations, diffs, staging, commits, branches, and status. Neovim may open buffers or contribute commands, but it does not own source-control surfaces.
_Avoid_: Neovim Git, Git plugin, SCM plugin

**Hybrid Git Backend**:
The Git implementation policy where Onivim uses the `git` CLI for mutating and user-facing workflows to preserve config, hooks, and credential behavior, with optional watcher or library support later for measured status performance.
_Avoid_: libgit2 backend, shell Git, Git wrapper

**Source Control Command Providers**:
The extension point where Neovim or later Coc commands can appear in native source-control context menus and command palette actions without taking ownership of source-control UI.
_Avoid_: Git command bridge, SCM provider, plugin action

**In-buffer Vim Search**:
The embedded editor search behavior where Vim `/` and related motions remain Neovim-owned and scoped to editor buffers rather than replacing native workspace search.
_Avoid_: Workspace search, native find, global search

**Window Editor Runtime**:
The per-window embedded Neovim runtime. Each app window owns an independent Neovim process, buffers, cwd projection, tabs, and later Coc instance to isolate global editor state.
_Avoid_: Shared Neovim, global editor process, workspace process

**Retained Engine**:
A non-UI subsystem carried forward because it owns behavior that is expensive or risky to rebuild immediately.
_Avoid_: Legacy dependency, old code, ported module

**Embedded Editor Core**:
A bundled subprocess that owns modal editing, buffers, plugins, LSP, terminal behavior, and editor state while the native host owns macOS product UX.
_Avoid_: Backend, hidden Neovim, engine process

**Pinned Neovim Runtime**:
The product runtime policy: ship a specific Neovim binary and runtime inside the app bundle by default, with external/system Neovim allowed only as a developer debugging override.
_Avoid_: System Neovim, user Neovim, runtime dependency

**Isolated Onivim Config**:
The default Neovim configuration policy where Onivim uses its own app-owned config, data, cache, runtime additions, and plugin set instead of loading the user's normal Neovim configuration.
_Avoid_: Default config, bundled config, clean Neovim

**Staged Plugin Policy**:
The default-runtime plugin policy: start with only Onivim runtime glue for the Editor-Core Slice, then add a curated app-owned plugin set when the Coc Language Layer begins.
_Avoid_: Plugin manager, user plugins, arbitrary runtime

**Neovim Compatibility Mode**:
A later opt-in mode that loads a user's existing Neovim configuration and plugins for compatibility/debugging at the cost of reproducible product behavior.
_Avoid_: User config, system config, escape hatch

**Editor-Core Slice**:
The first vertical slice: launch bundled Neovim, render its UI grid, route keyboard input to it, and support opening, editing, and saving files with modal behavior intact.
_Avoid_: Foundation slice, Neovim spike, terminal editor

**Editor-Core Acceptance Path**:
The ordered proof that the first vertical slice works: first open a file in the app, edit with modal input, save, quit, and reopen to verify persistence; then open a file from the CLI; then open a folder, use the native file tree, open a file, edit, and save.
_Avoid_: Smoke test, first demo, launch checklist

**Minimal Vim Loop**:
The modal-input acceptance scope: insert-mode text entry, Escape to normal mode, `:w`, `:q`, `hjkl`, `i`, `a`, `x`, `dd`, and `u`.
_Avoid_: Vim support, modal editing, input smoke test

**Native Text Input Path**:
The first-slice input policy where the editor surface implements AppKit text input behavior, including composition-aware text entry, while still translating accepted input and commands into Neovim.
_Avoid_: Raw key mapping, keyboard shim, input bridge

**Mode Snapshot**:
The host-side view of Neovim's current mode, maintained from Neovim UI/mode events for low-latency input decisions and verified with `nvim_get_mode()` on ambiguous transitions or debug checks.
_Avoid_: Host mode, input mode, mode cache

**Daily Editing Vim Suite**:
The next regression scope after acceptance: visual mode, yank/paste, search, repeat, counts, word/line motions, and command-line editing.
_Avoid_: Full Vim parity, Neovim test suite, modal coverage

**Buffer Truth**:
The rule that Neovim buffers are the authoritative text state; Swift presents and requests edits, while Coc mirrors Neovim documents for language features.
_Avoid_: Document model, text store, source of truth

**Hybrid Editor Rendering**:
The rendering strategy where editor panes initially display Neovim UI grid output for correctness while native SwiftUI/AppKit owns surrounding IDE surfaces and the product prioritizes a later native TextKit-backed editor pane.
_Avoid_: Native editor, grid renderer, temporary renderer

**Native Renderer Priority**:
The roadmap choice to move the Native Renderer Slice before Coc/native language UI so Onivim reaches a native-feeling editor pane before investing deeply in language-extension surfaces.
_Avoid_: Coc-first roadmap, language-first editor, renderer follow-up

**AppKit Grid Renderer**:
The initial Neovim grid renderer implemented as an AppKit drawing surface using row/cell drawing primitives rather than SwiftUI views per cell.
_Avoid_: SwiftUI grid, terminal view, text view

**Metal Grid Renderer**:
A later optimized Neovim grid renderer considered only if profiling shows the AppKit Grid Renderer cannot meet latency, animation, or glyph-rendering requirements.
_Avoid_: Renderer rewrite, GPU renderer, fast path

**Native Editor Layout**:
The visible editor-pane layout owned by SwiftUI/AppKit, including editor groups, split direction, tab presentation, focus, and placement; Neovim buffers and windows are projected into those panes rather than owning product layout.
_Avoid_: Neovim splits, Vim tabs, editor grid

**Native Layout Translation**:
The target behavior where Vim layout commands such as `:split`, `:vsplit`, `:tabnew`, `:only`, and `Ctrl-w` navigation map to native editor groups, splits, tabs, and focus.
_Avoid_: Neovim layout, split emulation, layout bridge

**Limited Layout Slice**:
The first-slice policy that does not expose Neovim splits/tabs as product UI and may clearly reject or defer Vim layout commands until Native Layout Translation exists.
_Avoid_: Broken splits, hidden support, nested layout

**Native Renderer Slice**:
The first native editor milestone where TextKit displays mirrored Neovim buffer state while edits, cursor movement, selections, folds, undo, macros, marks, and registers still route through Neovim.
_Avoid_: Native editor ownership, native text model, TextKit source

**Display-only Renderer Slice**:
The Native Renderer Slice scope where TextKit displays mirrored Neovim state but does not own mouse selection, IME ownership, drag/drop, accessibility editing, scrolling, hit-testing, or text mutation.
_Avoid_: Basic native interaction, TextKit interaction, partial interaction

**Incremental Buffer Mirror**:
The native renderer data source where Swift maintains TextKit state from Neovim buffer change events, redraw/highlight events, cursor events, and extmark updates instead of polling full snapshots.
_Avoid_: Buffer snapshot, Coc document mirror, polling renderer

**Grid Fallback Authority**:
The native renderer safety policy where the Neovim grid remains the correctness fallback during the Native Renderer Slice; if the TextKit mirror is missing, stale, or invalid, Onivim shows the grid or marks the pane degraded rather than presenting incorrect native text.
_Avoid_: TextKit authority, eventual healing, stale native view

**Golden Event Replay**:
The deterministic native-renderer regression method: recorded Neovim buffer, redraw, highlight, cursor, extmark, and virtual-text event streams are replayed into the Incremental Buffer Mirror and checked against expected TextKit state.
_Avoid_: Screenshot test, renderer snapshot, replay fixture

**Dual-render Debug Mode**:
The development diagnostic mode where the Neovim grid renderer and TextKit native renderer run side-by-side against the same editor state to expose mirror divergence in real workloads.
_Avoid_: Renderer comparison, debug renderer, visual parity mode

**Neovim Highlight Truth**:
The native renderer highlight policy where Swift mirrors Neovim highlight groups, extmarks, selections, diagnostics, virtual text, and plugin-provided highlighting into TextKit attributes rather than computing editor text highlights independently.
_Avoid_: Swift syntax highlighting, tree-sitter highlight truth, native highlights

**Native Interaction Target**:
The later native editor milestone where TextKit owns mouse selection, IME composition, scrolling, hit-testing, and accessibility while text mutations still commit through Neovim.
_Avoid_: Native text subsystem, dual editor, Swift buffer truth

**Coc Language Layer**:
The Neovim-side Node.js extension and language-feature layer that provides VSCode-like completion, diagnostics, hover, code actions, snippets, configuration, commands, and LSP integration through Coc extensions.
_Avoid_: VSCode host, extension host, language server

**Native Coc UI**:
The SwiftUI/AppKit presentation of Coc language-layer features such as completion, hover, diagnostics, quick picks, output, notifications, and extension management.
_Avoid_: Coc UI, Vim UI, native overlay

**Onivim UI Provider**:
The forked Coc integration point that routes Coc presentation requests to the native host instead of Neovim UI primitives.
_Avoid_: UI bridge, Coc fork, presentation adapter

**Host UI RPC**:
The dedicated process-to-process protocol between the Coc language layer and native host for UI requests, user choices, cancellation, and presentation-state updates.
_Avoid_: Neovim relay, socket bridge, UI channel

**Host UI JSON-RPC**:
The JSON-RPC form of Host UI RPC, chosen for debuggability, versioning, and straightforward Node/Swift implementation rather than byte-level efficiency.
_Avoid_: MessagePack UI RPC, custom binary protocol, host socket

**Language Extension Compatibility**:
The goal of running or adapting VSCode Marketplace language extensions for editor-language capabilities before supporting arbitrary UI-heavy VSCode extensions.
_Avoid_: VSCode parity, Marketplace parity, Coc compatibility

**Coc-first Catalog**:
The initial extension catalog strategy: prefer maintained Coc extensions for language features and only adapt VSCode Marketplace language extensions when no adequate Coc extension exists.
_Avoid_: Marketplace-first, extension marketplace, compatibility catalog

**VSCode API Shim**:
A future compatibility layer that lets selected VSCode Marketplace language extensions call `require("vscode")` while mapping supported APIs onto the Coc language layer and embedded editor core.
_Avoid_: VSCode host, full shim, marketplace runtime

**Behavioral Parity**:
A user-visible behavior from Onivim 2 that must continue to feel the same in Onivim 3.
_Avoid_: Compatibility, feature match

**Reference Behavior**:
An Onivim 2 behavior used to define intended Onivim 3 behavior without requiring the original implementation to survive.
_Avoid_: Clone, rewrite target
