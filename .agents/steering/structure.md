# Project Structure

## Organization Philosophy

**Dendritic Growth**: The project grows organically through flake-parts modules that compose naturally. New concerns (e.g., a new host, a new shared module, a new deployment workflow) are added as sibling parts or modules, not nested layers. This mirrors how a tree grows—branches spread outward, not downward.

Each directory has a clear responsibility, and new files following the established patterns do not require structural changes.

## Directory Patterns

### `/parts/` — Flake-Parts Modules
**Purpose**: Declarative Nix modules that compose all project outputs (devshell, nixos-configurations, home-manager, checks, tests).

**Pattern**:
- `default.nix` — Imports all parts
- `devshell.nix` — Development environment (shells, tools, scripts)
- `nixos-configurations.nix` — NixOS system definitions
- `home-manager.nix` — Home Manager configurations (usually composed from `/home/`)

**Convention**: Each part uses `flake-parts.lib.importApply` or `mkFlakeModules` to maintain composability.

### `/nixos/` — Shared NixOS Modules
**Purpose**: Reusable NixOS configuration modules (e.g., security hardening, SSH setup, services).

**Example Modules**:
- `base.nix` — Common base configuration (packages, locale, timezone)
- `security.nix` — SSH hardening, firewall, fail2ban
- `ssh.nix` — SSH daemon and key management
- `tailscale.nix` — Tailscale VPN configuration
- `disko.nix` — Disk partitioning and filesystems
- `user.nix` — User creation and group membership

**Convention**: Modules are composable via `imports = [ ... ]` and use standard NixOS module options (no deep nesting).

### `/home/` — Home Manager Configuration
**Purpose**: Declarative user environment (dotfiles, shell, applications, editor config).

**Example Files**:
- `default.nix` — Main Home Manager configuration, imports all sub-modules
- `session-vars.nix` — Environment variables and aliases
- `ssh-client.nix` — SSH client config (`~/.ssh/config`)
- `tmux.nix` — Tmux configuration

**Convention**: Each concern is a separate `.nix` file; `default.nix` imports and composes them.

### `/hosts/` — Per-Host Configurations
**Purpose**: Machine-specific NixOS configurations (hardware, hostname, role-specific modules).

**Pattern**:
- `<hostname>.nix` — Main host configuration, imports shared modules and hardware config
- `<hostname>-hardware-configuration.nix` — Hardware detection output from `nixos-generate-config`

**Example**:
- `hbohlen-01.nix` — Hetzner Cloud server config (imports `/nixos/` modules)
- `hbohlen-01-hardware-configuration.nix` — Hetzner-specific hardware (VM, disk layout)

**Convention**: Minimal host-specific logic; most configuration lives in `/nixos/` modules for reuse.

### `/lib/` — Utility Functions
**Purpose**: Shared Nix functions and helpers for configuration.

**Convention**: Well-documented with type annotations; exposed at flake root as `lib.*`.

### `/scripts/` — Deployment & Admin Scripts
**Purpose**: Bash/shell scripts for deployment, backup, monitoring, and manual administration.

**Examples**:
- `deploy.sh` — Wrapper for `nixos-anywhere`
- `backup.sh` — Backup orchestration
- `health-check.sh` — System health monitoring

### `/secrets/` — Secret References
**Purpose**: 1Password secret references and opnix configuration (never store plain secrets here).

**Pattern**:
- File structure mirrors intended secret location
- Files contain 1Password reference expressions (e.g., `op://vault/item/field`)
- opnix module injects these at Nix evaluation time

**Convention**: Secrets are never version-controlled in plain text; reference format is documented in relevant module.

### `/tests/` — Automated Tests
**Purpose**: Unit tests (nix-unit) and evaluation tests for Nix code.

**Subfolders**:
- `unit/` — nix-unit tests for functions and modules
- `evaluation/` — Tests that configurations evaluate without errors

**Convention**: Test names match module/function names; each test is independent and idempotent.

### `/pkgs/` — Custom Packages
**Purpose**: Local package definitions for tools or applications not in nixpkgs.

**Pattern**: Each custom package is a separate `.nix` file; `default.nix` returns attrset of all packages.

### `/.agents/` — Agent Workflow & Infrastructure-as-Spec
**Purpose**: Canonical home for all infrastructure specs, skills, and agent orchestration.

**Subfolders**:
- `specs/` — Feature specs (requirements, design, tasks, implementation)
- `skills/` — Reusable agent skills (deployment, testing, security hardening)
- `steering/` — Project memory (this file, tech.md, structure.md)
- `rules/` — Workflow rules and constraints
- `templates/` — Scaffolding templates for specs and steering
- `workflows/` — Agent workflow definitions

**Convention**: No agent-specific tooling directories (e.g., `.cursor/`, `.gemini/`); all agent context lives in `.agents/steering/`.

### `/docs/` — Human-Facing Documentation
**Purpose**: User guides, runbooks, architecture diagrams (for humans, not agents).

**Pattern**:
- `AGENTS.md` — Documents the spec-driven workflow (links to `.agents/AGENTS.md`)
- Feature-specific guides (e.g., `deployment.md`, `security.md`)
- Architecture diagrams (Mermaid, kept in Markdown)

**Convention**: Mirrors `.agents/specs/` structure when applicable; archives old runbooks to `/archive/docs/`.

### `/archive/` — Deprecated & Historical Work
**Purpose**: Previous iterations, abandoned experiments, and historical context.

**Subfolders**:
- `openspec/` — Archived OpenSpec attempts
- `plans/` — Old project plans
- `superpowers/` — Experimental agent integrations

**Convention**: Archive is append-only; nothing is deleted. History informs future decisions.

## Naming Conventions

- **Files**: `kebab-case.nix` for module files; `PascalCase.nix` for type definitions
- **Hosts**: `<shortname>-<number>.nix` (e.g., `hbohlen-01.nix`)
- **Functions**: `camelCase` in Nix
- **Modules**: Descriptive, single-concern names (e.g., `security.nix`, not `misc.nix`)
- **Specs**: `kebab-case-feature-name/` (e.g., `1password-secret-rotation/`)

## Import Organization

### Nix Imports
```nix
# Relative imports (common for local modules)
imports = [
  ./base.nix
  ./security.nix
];

# Inputs from flake (for external dependencies)
{ inputs, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.opnix.nixosModules.opnix
  ];
}
```

### No Path Aliases
Nix doesn't use path aliases; imports are relative (`./`) or from flake inputs.

## Code Organization Principles

1. **Single Responsibility**: Each module handles one concern (security, SSH, services, etc.).
2. **Composability**: Modules don't depend on execution order; they declare what they need via `imports` and options.
3. **No Circular Dependencies**: A module may not import anything that imports it.
4. **Reusable Over Specific**: Modules in `/nixos/` are generic; host-specific logic stays in `/hosts/`.
5. **Dendritic, Not Hierarchical**: New modules are peers, not nested. Avoid creating subdirectories within `/nixos/` unless a clear domain emerges (e.g., `nixos/services/`, `nixos/security/`).

---
_Updated: April 9, 2026 | Reflects post-refactor dendritic architecture and spec-driven workflow integration_
