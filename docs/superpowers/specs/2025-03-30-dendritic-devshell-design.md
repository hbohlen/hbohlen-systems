# Design: Dendritic DevShell Branch

**Date:** 2025-03-30  
**Status:** Approved, ready for implementation  
**Scope:** First experimental branch of hbohlen-systems

---

## Goal

A minimal, working devShell that provides a reproducible environment for working on this project, demonstrating the dendritic pattern while solving an immediate need.

## Scope

Single branch only. No system config, no home-manager, no other tools yet. Just a devShell that can be entered with `nix develop`.

## Architecture

```
hbohlen-systems/
├── flake.nix                    # Root: inputs, dendritic cell loading
├── flake.lock                   # Pinned dependencies
├── nix/
│   ├── cells/
│   │   └── devshells/
│   │       └── default.nix      # The devShell definition
│   └── lib/                     # (minimal for now)
├── docs/superpowers/specs/      # Design docs live here
└── .envrc                       # direnv entry point
```

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| **flake-parts** | Modular, composable — each future branch adds its own file without touching root |
| **dendritic cells** | Self-contained units; `cells/devshells/` is the first "branch" |
| **fish + starship** | Fast, clean prompt reduces cognitive load; starship shows only git branch/status |
| **zoxide (z)** | Fuzzy jump to directories — no path memorization needed |
| **direnv** | Auto-activate devShell when entering project; removes "did I remember to nix develop?" friction |
| **Abbreviations over aliases** | Fish expands on space — you see the full command, reduces "what does this do?" uncertainty |
| **pi from llm-agents.nix** | Immediate access to the tool you want to experiment with |
| **nixos-unstable** | Latest packages, good for development tools |

## Package List

### Core
- `fish` — shell
- `starship` — prompt (minimal config)
- `direnv` + `nix-direnv` — environment auto-loading

### Navigation & Search
- `eza` — modern `ls` replacement
- `ripgrep` — fast text search
- `zoxide` — smart directory jumping
- `fzf` — fuzzy finder (for completions)

### Editor & Dev Tools
- `neovim` — editor
- `git` — version control

### AI/Agents
- `pi` — from `github:numtide/llm-agents.nix`

### LSPs & Formatters
- `nil` — Nix LSP
- `lua-language-server` — Lua LSP
- `stylua` — Lua formatter
- `ast-grep` — structural code search

## Fish Configuration

Managed within the devShell, not global system config:

```fish
# Initialize tools
starship init fish | source
zoxide init fish | source

# Abbreviations (expand on space, show full command)
abbr -a g git
abbr -a gs 'git status'
abbr -a gd 'git diff'
abbr -a gl 'git log --oneline -15'
abbr -a n nvim
abbr -a l 'eza --icons --group-directories-first'
abbr -a ll 'eza -la --icons --group-directories-first'
abbr -a lt 'eza --tree --icons'
```

## Starship Configuration

Minimal, ADHD-friendly:
- Show current directory (truncated if deep)
- Show git branch and dirty state only
- No hostname, no time, no complex symbols
- Fast rendering

## Flake Inputs

- `nixpkgs` — `github:nixos/nixpkgs/nixos-unstable`
- `flake-parts` — `github:hercules-ci/flake-parts`
- `llm-agents` — `github:numtide/llm-agents.nix`

## Success Criteria

1. `nix develop` enters a shell with fish as the default
2. `fish` shows starship prompt with git info
3. All packages available: neovim, rg, eza, zoxide, direnv, pi
4. `direnv allow` + entering project auto-activates the shell
5. `z <partial-path>` jumps to matching directory
6. `abbr -a` shows the defined abbreviations
7. `pi --version` (or equivalent) works

## Out of Scope (Future Branches)

- Home-manager configuration
- System configuration (NixOS)
- Custom pi plugins/extensions
- Hermes skills
- AI workflows
- Dotfiles management
- Other shells (bash, zsh)

## Rationale for Starting Here

This devShell solves an immediate problem (reproducible dev environment) while establishing the dendritic pattern. Once working, it becomes the environment for building all future branches. The small scope avoids paralysis and allows quick iteration.

## Next Branches (Not Part of This Spec)

1. **home-manager** — dotfiles, user-level configuration
2. **pi-custom** — custom pi commands/workflows
3. **hermes-skills** — self-learning AI workflows
4. **system-config** — NixOS system configuration (if applicable)
