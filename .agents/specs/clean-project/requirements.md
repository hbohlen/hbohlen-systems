# Requirements Document: clean-project

## Introduction
Clean up project workspace and configuration mapping:
1. Remove `gno` and `caddy` services.
2. Ensure `opencode` operates locally only.
3. Migrate `home-manager` configuration from standalone to embedded inside NixOS.
4. Clean up `nix develop .#ai` devShell by moving frequently used terminal tools to `home-manager`.
5. Keep specific tools in `.#ai` devShell.
6. Move `qwen-code`, `hermes-agent`, `opencode`, and `rtk` to `home-manager`.
7. Remove `agent-menu` completely.

## Requirements

### 1. NixOS and Services Refactor
**Objective:** As a system administrator, I want to remove deprecated services and deeply integrate home-manager, so that the configuration is lean and centrally managed without proxy overhead.

#### Acceptance Criteria
1.1 Where the system boots, the system shall not load `gno` or `caddy` service units.
1.2 Where `opencode` is provisioned, the system shall bind it to `127.0.0.1` locally.
1.3 Where the user configuration is built, the system shall evaluate `home-manager` as a seamless submodule to the NixOS configuration.

### 2. DevShell Optimization
**Objective:** As a developer, I want my `ai` devShell to load quickly by migrating global utilities to `home-manager`, so that my local worktree environments provision instantly.

#### Acceptance Criteria
2.1 When evaluating `devShells.default`, the system shall not load any packages that have been moved to global home-manager.
2.2 When evaluating `devShells.ai`, the system shall strictly include only `omp`, `cli-proxy-api`, `ccusage-opencode`, `ccusage-pi`, and `openspec`.
2.3 Where `fish` and `starship` configs are evaluated, the system shall assign them via native `home-manager` modules (`programs.fish` and `programs.starship`) rather than custom `writeTextFile` derivations.
2.4 When running terminal sessions, the system shall not reference or include `agent-menu`.

### 3. CI/CD Validation
**Objective:** As a release engineer, I want the flake tests to encompass all directories, so that refactoring validations are comprehensive.

#### Acceptance Criteria
3.1 When `alejandra-check` runs, the system shall check format compliance across all standard flake directories (including roots and components).
