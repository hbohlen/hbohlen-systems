# Technology Stack

## Architecture

**Dendritic Flake-Parts Pattern**: Uses `flake-parts` to compose infrastructure as modular Nix expressions ("dendrites") that grow organically without forced layering. Each concern (devshell, nixos-configurations, home-manager, tests) is a separate part that inherits inputs and outputs naturally.

## Core Technologies

- **Language**: Nix (declarative infrastructure language)
- **Base Framework**: NixOS (immutable Linux distribution)
- **Module System**: `flake-parts` (flake-based module composition)
- **Home Configuration**: Home Manager (declarative dotfiles and user environment)
- **Disk Management**: Disko (declarative partitioning and filesystem provisioning)
- **Secrets Management**: 1Password + `opnix` module (secret injection into Nix configs)
- **VPN/Routing**: Tailscale (zero-trust network)
- **Deployment Target**: Hetzner Cloud (primary), local systems (secondary)

## Key Libraries

- **llm-agents.nix**: LLM-powered agent orchestration patterns
- **nix-unit**: Unit testing framework for Nix
- **alejandra**: Opinionated Nix formatter (all code must pass checks)
- **statix**: Linter for Nix code quality
- **deadnix**: Dead code detection in Nix

## Development Standards

### Code Formatting
- **Formatter**: `alejandra` (non-negotiable, checked in CI)
- **Target**: All Nix files under `flake.nix`, `parts/`, `hosts/`, `nixos/`, `home/`, `tests/`, `lib/`, `scripts/`

### Linting & Quality
- **Linter**: `statix` (catches anti-patterns)
- **Dead Code**: `deadnix` (removes unused bindings)
- **Type Safety**: Leverage Nix's type system; document module interfaces explicitly

### Testing
- **Unit Tests**: `nix-unit` for Nix functions and modules
- **Evaluation Tests**: Check that configurations evaluate without errors
- **Integration**: NixOS configuration build tests on target hardware

## Development Environment

### Required Tools
- Nix flakes support (Nix 2.4+)
- `direnv` and `nix-direnv` (recommended, auto-loads devshell on cd)
- Git (for flake inputs and version tracking)

### Common Commands

```bash
# Development
nix flake show              # List all outputs
nix develop                 # Enter devshell

# Building
nix build .#nixosConfigurations.<host>.config.system.build.toplevel  # Build NixOS config
nix build .#homeConfigurations.<user>@<host>.activation-script       # Build Home Manager

# Testing
nix flake check             # Run all checks (formatting, linting, dead code)
nix flake check --offline   # Faster check without fetching

# Deployment
nixos-anywhere --flake .#<host> root@<target-ip>  # Remote NixOS install
home-manager switch --flake .#<user>@<host>      # Activate Home Manager config
```

## Key Technical Decisions

1. **Dendritic Over Hierarchical**: Resist the urge to create deeply nested module directories. New features and hosts grow as sibling parts, not nested modules.

2. **Flake-Parts for Composability**: Each concern (`devshell.nix`, `nixos-configurations.nix`, `tests/`, etc.) is a part that composes cleanly; avoids monolithic `flake.nix`.

3. **Spec-Driven Infrastructure Changes**: All significant infrastructure changes go through `.agents/specs/` workflow (requirements → design → tasks → implementation) to document decisions.

4. **Secrets via 1Password + opnix**: Never hardcode secrets. Use opnix module to inject 1Password service account secrets at Nix evaluation time.

5. **Hetzner-First Deployment**: Primary infrastructure lives on Hetzner Cloud; `nixos-anywhere` is the canonical deployment tool.

---
_Updated: April 9, 2026 | Reflects post-refactor dendritic architecture_
