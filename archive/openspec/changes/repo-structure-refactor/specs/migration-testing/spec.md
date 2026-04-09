## ADDED Requirements

### Requirement: Every migration phase has a test checkpoint

Each migration phase SHALL conclude with a verification checkpoint that runs all applicable test layers before proceeding to the next phase.

#### Scenario: Phase 2 checkpoint (flake-parts move)
- **WHEN** flake-parts modules have been moved to `parts/` and `flake.nix` updated
- **THEN** `nix flake check` SHALL pass (formatting, statix, deadnix)
- **AND** nix-unit tests SHALL pass
- **AND** evaluation tests for all modules SHALL pass
- **AND** `nixosConfigurations.hbohlen-01` SHALL evaluate successfully

#### Scenario: Phase 5 checkpoint (Home Manager consolidation)
- **WHEN** all Home Manager config has been consolidated under `home/`
- **THEN** `nix flake check` SHALL pass
- **AND** nix-unit tests for HM-related modules SHALL pass
- **AND** the full NixOS configuration SHALL evaluate with HM enabled
- **AND** `home-manager.users.hbohlen` is defined in exactly one file

### Requirement: Static checks layer runs at every checkpoint

`nix flake check` SHALL include formatting (alejandra), linting (statix), and dead code detection (deadnix). This layer runs at every phase checkpoint.

#### Scenario: Formatting check
- **WHEN** the static check layer runs
- **THEN** alejandra formatting check passes for all `.nix` files
- **AND** statix reports no issues
- **AND** deadnix reports no dead code

### Requirement: nix-unit tests updated for new paths

After test files are moved to `tests/`, nix-unit tests SHALL reference modules at their new paths (`../nixos/`, `../home/`, etc.) and all tests SHALL pass.

#### Scenario: Unit tests reference new module paths
- **WHEN** nix-unit tests are run after migration
- **THEN** all test files import modules from `../nixos/` and `../home/` paths
- **AND** all test assertions pass

### Requirement: NixOS evaluation tests cover each domain module

For each NixOS system module in `nixos/`, an evaluation test SHALL exist in `tests/evaluation/` that verifies the module evaluates without errors in a minimal NixOS configuration.

#### Scenario: New nixos module has evaluation test
- **WHEN** a new NixOS module is added to `nixos/`
- **THEN** a corresponding evaluation test exists in `tests/evaluation/`
- **AND** the test constructs a minimal NixOS config importing just that module
- **AND** the test evaluates without errors

### Requirement: Phase 0 baseline established before any changes

Before any structural changes are made, all existing tests SHALL be verified to pass, establishing a baseline.

#### Scenario: Baseline verification
- **WHEN** the migration starts at Phase 0
- **THEN** `nix flake check` passes
- **AND** nix-unit tests pass
- **AND** evaluation tests pass
- **AND** `nixosConfigurations.hbohlen-01` builds successfully