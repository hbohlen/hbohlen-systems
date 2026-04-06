## Context

The hbohlen-systems NixOS config runs on a Hetzner server (hbohlen-01) with home-manager managing user config. AI agents (opencode, pi, hermes-agent) are available via the `devShells.ai` flake output. tmux is minimally configured via home-manager with only extended-keys support (for pi compatibility).

The user needs a workflow for running multiple AI agents in parallel, each in an isolated git worktree, with easy navigation between agents and a plain terminal for running commands.

## Goals / Non-Goals

**Goals:**
- tmux available on the server and in devShells with sensible defaults
- tmux-resurrect for session persistence across reboots
- A fish script (`agent-menu`) that provides a TUI for managing agent sessions
- Each agent session runs in a git worktree with auto `nix develop`
- Easy switching between shell window and agent window within a session

**Non-Goals:**
- Multi-agent orchestration (that's workmux's domain, available if needed later)
- Remote tmux access (already possible via SSH)
- tmux plugin ecosystem beyond resurrect (no continuum, fzf, etc. for now)
- Auto-merging worktrees back (manual cleanup for now)

## Decisions

### 1. agent-menu as a Nix derivation, not a shellHook script

The agent-menu will be a proper Nix package built with `pkgs.writeShellApplication` (not `writeShellScriptBin` — `writeShellApplication` enables shellcheck and sets `PATH` correctly). It will be defined in `modules/tmux.nix` as a `let` binding and added to both devShells via `packages` list. This means:
- The script is in the Nix store (immutable, reproducible)
- Agent binary paths are resolved via Nix (e.g., `${pkgs.fish}/bin/fish`, `${llm-agents-packages.opencode}/bin/opencode`)
- No shellHook file copying — it's just on PATH when you enter the devShell

**Alternatives considered:**
- `pkgs.writeFishBin`: Would be ideal but `writeShellApplication` is more standard and fish scripts can be run via `fish <script>` anyway
- Standalone flake: Over-engineered, the script is ~100 lines
- NixOS module with systemd: Too heavy, menu is interactive

### 2. tmux config via home-manager structured options

The `modules/tmux.nix` will use home-manager's `programs.tmux` with structured options where possible:

```nix
programs.tmux = {
  enable = true;
  mouse = true;
  keyMode = "vi";
  terminal = "tmux-256color";
  plugins = with pkgs.tmuxPlugins; [ resurrect ];
  extraConfig = ''
    # Only things not covered by structured options
    set -g extended-keys on
    set -g extended-keys-format csi-u
    set -g @resurrect-strategy-nvim "session"
  '';
};
```

This keeps the config declarative and Nix-idiomatic. Raw `extraConfig` is reserved for options that home-manager doesn't expose as structured attrs.

### 3. Two windows per session (shell + agent)

Each session gets exactly two tmux windows:
- Window 0: plain fish shell in the worktree (for git, file inspection, debugging)
- Window 1: the coding agent running in the worktree

This is simpler than panes (agents benefit from full terminal width) and more predictable than variable layouts.

### 4. Git worktrees with naming convention

Branches: `agent/<type>-<date>[-<desc>]`
Example: `agent/opencode-20260406-auth-refactor`

Worktrees go in `<project>/.worktrees/agent-<type>-<date>/` following the existing `.worktrees/` convention in this repo.

### 5. nix develop in worktrees — flake resolution

A git worktree is a child directory of the project root, so `nix develop` invoked from the worktree directory will find `<project>/flake.nix` by walking up to the parent. This is the standard Nix flake resolution behavior — no special handling needed.

Each tmux window will be spawned with:
```bash
tmux new-window -n <name> -c <worktree-path> 'nix develop --command fish'
```

The `-c` flag sets the working directory, and `nix develop` evaluates the flake from that directory. If the project uses a specific devShell (e.g., `.#ai`), the agent-menu should detect this or accept it as a parameter.

### 6. tmux config lives in NixOS home-manager, devShell gets binary only

- `modules/tmux.nix`: home-manager module with full tmux config (resurrect, keybindings, etc.) — deployed to server via `nixos-rebuild`
- `modules/devshell.nix`: adds `tmux` to packages list — available in `nix develop` for local dev

The devShell doesn't need tmux config — it inherits the user's `~/.tmux.conf` from home-manager. The devShell just ensures the binary is available.

## Risks / Trade-offs

- **Worktree cleanup**: No automated merge/cleanup. Users must manually remove worktrees. → Mitigation: Add `agent-cleanup` helper function later. Git worktree removal is just `git worktree remove <path>`.
- **nix develop flake evaluation**: Each window runs `nix develop` which evaluates the flake. Slow for large flakes. → Mitigation: Nix evaluation is cached after first run within the same session. If performance becomes an issue, consider `nix develop --eval-cache`.
- **tmux-resurrect + nix develop**: Resurrect saves the running command. After reboot, it tries to re-run `nix develop --command fish` in the worktree path. If the flake changed or the worktree was removed, this fails silently. → Acceptable: user sees an empty pane and can re-launch.
- **Agent binary paths in Nix store**: The agent-menu script resolves agent paths at build time via Nix (e.g., `${llm-agents-packages.opencode}/bin/opencode`). This means the script must be rebuilt if agent packages change. → Acceptable: the script is rebuilt on `nix develop` / `nixos-rebuild` automatically.
- **Agent-specific launch commands**: Each agent (opencode, pi, hermes) has different CLI flags. The script hardcodes these via a case/switch. → Extensible: adding a new agent is a new case branch in the derivation.
- **worktree flake reference**: `nix develop` from a worktree resolves flake.nix from the worktree root. If the worktree is deep in a subdirectory, `nix develop` may not find it. → Mitigation: agent-menu always uses `-c <worktree-root>` so the working directory is correct.

## Migration Plan

1. Create `modules/tmux.nix` — home-manager tmux config (structured options + resurrect plugin) + agent-menu derivation
2. Update `modules/home.nix` — remove inline `programs.tmux` block, keep only SSH config
3. Update `modules/devshell.nix` — add `tmux` and `agent-menu` (via `self'.packages` or direct let binding) to both devShell package lists
4. Add `tmux.nix` to `modules/default.nix` imports (or keep it imported only via home.nix — decide based on existing pattern)
5. Build and test locally: `nix build .#checks.x86_64-linux` + `nix develop .#ai` to verify agent-menu is on PATH
6. Deploy to hbohlen-01: `nixos-rebuild switch --flake .#hbohlen-01`
7. Test end-to-end: run `agent-menu`, create session for each agent type, verify worktree isolation

No rollback complexity — tmux config is additive, old sessions continue working.

## Open Questions

- Should the menu support selecting from a list of known project paths, or always prompt for a path?
- Should agent sessions be named by project or by agent type? (Proposing project-based naming with agent type visible in status bar)
- tmux prefix key: keep `C-b` or switch to `C-a`? (Proposing `C-b` to match defaults, user can override)
