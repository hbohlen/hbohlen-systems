## Context

The `llm-agents.nix` flake input is already wired into the project and provides 8 packages to the devShell, but `opencode` is missing from the list despite being used as a NixOS service via `modules/opencode.nix`.

Separately, the `gno-serve` systemd service in `modules/gno.nix` passes `--hostname 127.0.0.1` to `gno serve`, but the command only accepts `-p/--port`. This causes the service to fail or misparse arguments.

## Goals / Non-Goals

**Goals:**
- Make `opencode` available in the devShell alongside the other `llm-agents.nix` packages
- Fix `gno serve` ExecStart so the systemd service works correctly

**Non-Goals:**
- Changing how `gno` is sourced (still uses `nix run github:numtide/llm-agents.nix#gno`)
- Adding `gno` to the devShell packages (separate concern)
- Modifying the tailscale serve integration (already correct)

## Decisions

**devshell.nix**: Add `llm-agents-packages.opencode` to the existing packages list at the same location as the other `llm-agents` packages (after line 137, before `pi-nix-suite`).

**gno.nix line 83**: Remove `--hostname 127.0.0.1` from the ExecStart string. Keep `--port ${toString serveCfg.port}`. The service already binds to localhost implicitly since no external-facing flag is set, and the tailscale serve layer handles external access.

## Risks / Trade-offs

- Minimal risk — both changes are one-line edits to existing configuration
- No migration needed — changes take effect on next `nixos-rebuild switch`
