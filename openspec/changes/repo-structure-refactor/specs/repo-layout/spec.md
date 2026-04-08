## ADDED Requirements

### Requirement: Repository uses domain-separated top-level directories

The repository SHALL organize NixOS configuration, Home Manager configuration, flake-parts modules, host definitions, tests, scripts, and documentation into distinct top-level directories by domain:

- `parts/` for flake-parts modules
- `hosts/` for per-host composition files and hardware configurations
- `nixos/` for NixOS system modules
- `home/` for Home Manager user modules
- `tests/` for nix-unit and evaluation tests
- `scripts/` for deployment and utility scripts
- `docs/` for documentation and plans
- `pkgs/`, `lib/`, `secrets/` reserved for future use

#### Scenario: New contributor navigates the repository
- **WHEN** a new contributor opens the repository root
- **THEN** they see directories named by subsystem domain (`parts/`, `hosts/`, `nixos/`, `home/`, `tests/`, `scripts/`, `docs/`)
- **AND** each directory name clearly indicates the kind of module it contains

#### Scenario: Adding a new NixOS module
- **WHEN** a new NixOS system module is created (e.g., `docker.nix`)
- **THEN** it SHALL be placed in `nixos/docker.nix`
- **AND** it SHALL be added to the imports list in `nixos/default.nix`

#### Scenario: Adding a new Home Manager module
- **WHEN** a new Home Manager module is created (e.g., `git.nix`)
- **THEN** it SHALL be placed in `home/git.nix`
- **AND** it SHALL be added to the imports list in `home/default.nix`

### Requirement: Reserved directories signal intent without creating stubs

The `pkgs/`, `lib/`, and `secrets/` directories SHALL exist with a README indicating their intended purpose but SHALL NOT contain empty stub files or boilerplate Nix modules.

#### Scenario: Reserved directory exists
- **WHEN** a contributor looks at the repository root
- **THEN** `pkgs/`, `lib/`, and `secrets/` directories exist
- **AND** each contains a README describing its intended purpose
- **AND** no empty Nix files or boilerplate modules exist in these directories

### Requirement: No auto-import pattern in domain directories

Domain `default.nix` files SHALL use explicit import lists, not auto-discovery of `.nix` files via `builtins.readDir`.

#### Scenario: Adding a module to nixos/
- **WHEN** a new module file is added to `nixos/`
- **THEN** it MUST be explicitly added to `nixos/default.nix` imports to be included in the system configuration

#### Scenario: Module file exists but is not imported
- **WHEN** a `.nix` file exists in `nixos/` but is not listed in `nixos/default.nix`
- **THEN** that module SHALL NOT be included in any NixOS configuration
- **AND** the `nix flake check` formatting and lint checks SHALL pass regardless