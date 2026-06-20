# Hybrid Git backend

Onivim 3 will use a hybrid Git backend. The `git` CLI is the default backend for mutating and user-facing source-control workflows so Onivim preserves user Git config, hooks, credential helpers, and command behavior. Optional file watchers or library-backed status acceleration may be added later only for measured performance needs.

## Considered Options

- `git` CLI: best behavior parity with user environments, but requires async process management, parsing, and cancellation.
- libgit2: structured API and tighter control, but harder parity for credentials, hooks, config, and edge-case Git behavior.
- Hybrid Git backend: starts with CLI correctness and leaves room for targeted performance helpers without changing source-control ownership.
