## Context

The server (hbohlen-01) is a Hetzner NixOS VPS accessed via SSH over Tailscale. Home-manager is used in two ways:
1. `modules/home-config.nix` — defines `flake.homeConfigurations.hbohlen` (standalone, not deployed to server)
2. `modules/ssh.nix` — embeds `home-manager.users.hbohlen` inline (runs on server via NixOS module)

The NixOS config in `nixos-configurations.nix` imports `home-manager.nixosModules.default`, enabling `home-manager.users.*` in NixOS modules. Only the inline usage (2) actually deploys to the server.

tmux is completely absent from the Nix config but is needed for pi-coding-agent workflows. pi requires `set -g extended-keys on` and `set -g extended-keys-format csi-u` in tmux config to handle modified keys (Shift+Enter, Ctrl+Enter) correctly.

## Goals / Non-Goals

**Goals:**
- Single source of truth for home-manager config in `modules/home.nix`
- tmux installed and configured for pi-coding-agent compatibility
- Remove dead code (home-config.nix, pi-nix-suite)

**Non-Goals:**
- Changing NixOS-level SSH or Tailscale config (access path stays untouched)
- Adding tmux plugins or extensive customization (just extended keys for now)
- Standalone home-manager usage (everything goes through NixOS module)

## Decisions

**`modules/home.nix`**: A new NixOS module that sets `home-manager.users.hbohlen` with all home-manager config. Follows the same pattern as `ssh.nix` — a NixOS module imported directly into `nixos-configurations.nix`, NOT auto-imported by `default.nix`. Must also be added to the exclusion list in `modules/default.nix`.

**SSH client config moves to home.nix**: The `programs.ssh` config from `ssh.nix` lines 47-54 moves here. The NixOS-level `services.openssh` (server-side) stays in `ssh.nix` unchanged.

**tmux via `programs.tmux`**: home-manager's tmux module provides sensible defaults (256 color, mouse, vi mode). We add only the extended keys config that pi requires. The tmux package is automatically included by home-manager.

**pi-nix-suite removal**: The extension's `TmuxManager` class was solving a problem pi's author says to solve by just using tmux directly. The Nix package and devshell integration add complexity without clear benefit. Removed in the same change since it's a small cleanup.

## Risks / Trade-offs

- **Lockout risk: NONE** — `services.openssh` and `services.tailscale` are not modified
- **home-manager rebuild risk**: If the new `home.nix` has syntax errors, `nixos-rebuild` will fail at build time (before deployment), so the server won't be affected
- **pi-nix-suite removal**: If anything depends on the pi-nix-suite binary in the devshell, it will stop being available. The devshell already has `pi` from `llm-agents.nix`.
