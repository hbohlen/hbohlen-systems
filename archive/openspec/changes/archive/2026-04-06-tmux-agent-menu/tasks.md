## 1. tmux NixOS Module

- [x] 1.1 Create `modules/tmux.nix` with home-manager `programs.tmux` using structured options (mouse, vi keyMode, 256color terminal, resurrect plugin)
- [x] 1.2 Add extended-keys config via `extraConfig` (not available as structured option)
- [x] 1.3 Update `modules/home.nix` to remove inline `programs.tmux` block (lines 24-30), keep SSH config only
- [x] 1.4 Ensure `modules/tmux.nix` is imported (via home.nix or default.nix)

## 2. tmux + agent-menu in devShells

- [x] 2.1 Add `tmux` to `devShells.default` packages list in `modules/devshell.nix`
- [x] 2.2 Add `tmux` to `devShells.ai` packages list in `modules/devshell.nix`
- [x] 2.3 Add `agent-menu` derivation to `devShells.ai` packages list in `modules/devshell.nix`

## 3. agent-menu Nix Derivation

- [x] 3.1 Define `agent-menu` as a `pkgs.writeShellApplication` derivation in `modules/tmux.nix` with dependencies on `tmux`, `git`, `fish`, and agent packages
- [x] 3.2 Implement session listing: show existing tmux sessions with agent type, project name, and age
- [x] 3.3 Implement new session creation: agent type selection (opencode/pi/hermes) + project path prompt
- [x] 3.4 Implement git worktree creation with branch naming `agent/<type>-<date>` and path `<project>/.worktrees/agent-<type>-<date>/`
- [x] 3.5 Implement tmux session creation with two named windows (shell + agent), spawning via `tmux new-session` / `tmux new-window` with `-c <worktree-path>` and `nix develop --command fish`
- [x] 3.6 Implement session navigation: select existing session to attach

## 4. Integration and Testing

- [x] 4.1 Verify `nix build` passes with alejandra formatting check
- [x] 4.2 Verify `nix develop .#ai` has `agent-menu` on PATH
- [ ] 4.3 Test agent-menu session creation for opencode, pi, and hermes-agent
- [ ] 4.4 Test worktree isolation (changes in worktree don't affect main tree)
- [ ] 4.5 Test tmux-resurrect save/restore with agent sessions
- [x] 4.6 Deploy to hbohlen-01 via `nixos-rebuild switch --flake .#hbohlen-01` and verify end-to-end
