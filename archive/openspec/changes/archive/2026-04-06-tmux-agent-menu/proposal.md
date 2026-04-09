## Why

AI coding agents (opencode, pi, hermes-agent) need tmux for session persistence, background processes, and running multiple agents in parallel. Currently tmux is minimally configured in home-manager (extended keys only) and absent from the devShells. There is no workflow for spawning agents in isolated git worktrees with auto-configured nix environments.

## What Changes

- Add `tmux` and `tmuxPlugins.resurrect` to NixOS home-manager config with sensible defaults (mouse, 256-color, vi mode, resurrect persistence)
- Add `tmux` to both `devShells.default` and `devShells.ai` packages
- Create an agent launcher fish script (`agent-menu`) that presents a TUI to:
  - List existing tmux sessions (with agent type and last-active time)
  - Create new sessions: pick agent (opencode/pi/hermes), specify project path
  - Spawn sessions in git worktrees with branch naming convention `agent/<type>-<date>-<desc>`
  - Auto-run `nix develop` in each tmux window
  - Provide two windows per session: `shell` (prefix+0) and `agent` (prefix+1)
- Remove the minimal tmux config from `home.nix` and replace with full config via a dedicated tmux NixOS module

## Capabilities

### New Capabilities

- `tmux-agent-menu`: Agent session launcher with TUI menu, worktree creation, agent spawning, and session navigation
- `tmux-config`: Declarative tmux configuration (resurrect, keybindings, status bar, 256-color, vi mode)

## Impact

- `modules/tmux.nix`: New file — home-manager `programs.tmux` config (structured options: mouse, vi, 256color, resurrect plugin) + `agent-menu` derivation via `pkgs.writeShellApplication`
- `modules/home.nix`: Remove inline `programs.tmux` block (lines 24-30), keep SSH config
- `modules/devshell.nix`: Add `tmux` to both devShell package lists; add `agent-menu` derivation to `devShells.ai` packages
- `modules/default.nix`: Import `tmux.nix` if not already pulled in via home.nix
