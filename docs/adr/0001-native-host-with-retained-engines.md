# Native host with retained engines

Onivim 3 will be a native macOS application, but it will selectively retain proven editor engines from Onivim 2 or adjacent libraries when rebuilding them would put modal correctness, syntax fidelity, terminal behavior, extension behavior, or input latency at risk. The native host owns the macOS product surface; retained engines are allowed behind explicit boundaries rather than translated mechanically into Swift.

## Considered Options

- Full native rewrite: simpler dependency graph, higher risk of regressing editor behavior.
- Mechanical code translation: preserves too much of the old architecture and does not create a native macOS design.
- Native host with retained engines: keeps high-risk behavior stable while allowing the UI and platform model to become native.
