## Context

This repository manages a single NixOS host (`hbohlen-01`) with integrated Home Manager configuration using flake-parts. The current structure evolved from a cell-based layout (`nix/cells/`) into a flat `modules/` directory containing a mix of NixOS system modules, Home Manager user modules, flake-parts modules, and host composition files -- all with no directory-level distinction between them.

Key structural problems:

1. **Mixed concerns in `modules/`**: Flake-parts modules (`devshell.nix`, `nixos-configurations.nix`) sit alongside NixOS system modules (`base.nix`, `ssh.nix`) and Home Manager modules (`tmux.nix`, `home.nix`), making it unclear which subsystem each file serves.

2. **Fragile auto-import pattern**: `modules/default.nix` auto-imports all `.nix` files except those on a hard-coded exclusion list. Adding a new NixOS module requires updating both the exclusion list and the explicit import list in `nixos-configurations.nix` -- these lists drift apart silently.

3. **Fragmented Home Manager config**: `home-manager.users.hbohlen` is defined in three separate files (`user.nix`, `home.nix`, `tmux.nix`) with overlapping keys (`home.stateVersion`, `programs.ssh`), creating merge conflicts and confusion about where HM config belongs.

4. **Stale references**: `deploy-hetzner.sh` still references the old `nix/cells/nixos/` paths, and the empty `nix/cells/` directory remains.

5. **No testing strategy for migration**: There is no incremental testing plan to validate that each structural change preserves system behavior.

## Goals / Non-Goals

**Goals:**

- Separate NixOS modules, Home Manager modules, flake-parts modules, and host definitions into distinct top-level directories with clear domain boundaries
- Define `home-manager.users.hbohlen` in exactly one composition file (`home/default.nix`) that explicitly imports atomic HM modules
- Replace the auto-import pattern with explicit imports at each composition boundary
- Use `home-manager.useGlobalPkgs = true` and `home-manager.useUserPackages = true` at a single clear location
- Enable incremental migration in small, testable phases where each phase leaves the system fully functional
- Provide a layered testing strategy (nix-unit, `nix flake check`, evaluation checks, NixOS build checks) with checkpoints at every phase
- Keep the refactoring practical for a personal infra repo -- explicit and readable over clever or abstract

**Non-Goals:**

- Making Home Manager standalone (it stays integrated into NixOS)
- Adding new features or services during the refactor (only structural changes)
- Adopting a framework like snowflake-lib or std that imposes its own layout conventions
- Creating a generic reusable module library (only organize what already exists)
- Changing the flake inputs or switching from flake-parts

## Decisions

### D1: Top-level directory domains

**Decision**: Use these top-level directories:

```
parts/       -- flake-parts modules (devshell, nixos-configurations)
hosts/       -- per-host composition files (hbohlen-01.nix, hardware configs)
nixos/       -- NixOS system modules (base, ssh, caddy, security, tailscale, etc.)
home/        -- Home Manager modules (tmux, ssh-client, session-vars)
pkgs/        -- custom package definitions (empty for now, reserved)
lib/         -- shared utility functions (empty for now, reserved)
tests/       -- nix-unit tests and evaluation tests (move from current location)
scripts/     -- deployment and utility scripts (deploy-hetzner.sh)
docs/        -- documentation and plans (keep current docs/ location)
secrets/     -- secret-related configuration (1password, opnix) reserved
```

**Rationale**: These domains map directly to the subsystem boundary in NixOS + Home Manager + flake-parts. Each directory has a clear, single responsibility. Reserved directories (`pkgs/`, `lib/`, `secrets/`) signal intent without creating empty stubs.

**Alternatives considered**:
- Keeping everything under `modules/` with subdirectories: rejected because it doesn't separate flake-parts from NixOS concerns at the directory level
- Using a `profiles/` + `modules/` split: rejected because "profiles" is ambiguous and doesn't align with flake-parts vocabulary

### D2: Home Manager composition model

**Decision**: Home Manager modules are atomic files under `home/` (e.g., `home/tmux.nix`, `home/ssh-client.nix`). A single `home/default.nix` defines `home-manager.users.hbohlen = { imports = [...]; }` and explicitly imports every HM module. `home-manager.useGlobalPkgs` and `home-manager.useUserPackages` are set in `parts/nixos-configurations.nix` alongside the `home-manager.nixosModules.default` import.

**Rationale**: One composition file for all HM config makes it trivial to find where HM is configured. Atomic modules within `home/` keep individual concerns separated. The `useGlobalPkgs`/`useUserPackages` settings belong at the same level where the HM NixOS module is imported, which is the flake-parts nixos-configurations module.

**Alternatives considered**:
- Letting each NixOS module contribute to `home-manager.users.hbohlen` inline: current approach, creates fragmentation and merge confusion
- Using `home-manager.users.hbohlen` in each `home/` module file without a composition file: loses the single clear definition point

### D3: Import strategy -- explicit imports at boundaries

**Decision**: Remove `modules/default.nix` auto-import entirely. Each domain has a `default.nix` that lists explicit imports:

- `parts/default.nix`: imports flake-parts modules explicitly
- `nixos/default.nix`: re-exports a list of NixOS modules for `imports = [...]`
- `home/default.nix`: defines `home-manager.users.hbohlen` with explicit `imports` list
- `hosts/hbohlen-01.nix`: imports `../nixos` and `../home` modules plus host-specific config

The `parts/nixos-configurations.nix` module references the host file(s), which compose everything.

**Rationale**: Explicit imports make composition boundaries visible. Adding a module requires adding it in exactly one place (the domain's `default.nix` or the host composition), not maintaining an exclusion list in parallel. This is slightly more verbose but prevents silent import errors.

**Alternatives considered**:
- Auto-import within domains only: still creates surprise and makes debugging harder
- A single `flake.nix` that imports everything: loses domain-level organization

### D4: Migration approach -- move-and-verify phases

**Decision**: Migrate in small phases, each ending with a verified checkpoint:

1. **Phase 0**: Establish baseline (all current tests pass, `nix flake check` is green)
2. **Phase 1**: Create target directories, add `default.nix` files with explicit imports (system still uses `modules/`)
3. **Phase 2**: Move flake-parts modules to `parts/`, update `flake.nix` to import `./parts` instead of `./modules`
4. **Phase 3**: Move host definitions to `hosts/`, update `nixos-configurations.nix`
5. **Phase 4**: Move NixOS system modules to `nixos/`, update host imports
6. **Phase 5**: Consolidate and move Home Manager modules to `home/`
7. **Phase 6**: Move tests to `tests/` with updated paths
8. **Phase 7**: Move scripts, update `deploy-hetzner.sh` paths, clean up `nix/cells/`
9. **Phase 8**: Remove `modules/` directory, verify end-to-end

Each phase must pass all tests and leave the system deployable.

**Rationale**: Small phases mean small diffs, easy rollback, and clear progress. Each phase can be a separate commit or even a separate branch merged incrementally.

**Alternatives considered**:
- Big-bang migration: too risky, hard to debug if something breaks
- Using symlinks during transition: adds complexity and confusion

### D5: Testing strategy -- layered incremental validation

**Decision**: Each migration phase validates via these layers:

1. **Static**: `nix flake check` (alejandra, statix, deadnix)
2. **Unit**: nix-unit (option assertions, output checks)
3. **Evaluation**: NixOS module evaluation tests (each module evaluates in isolation)
4. **Build**: `nixos-rebuild build` or `nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel`
5. **Targeted**: After HM migration, verify HM evaluation builds correctly

Every phase must pass all applicable layers before proceeding.

**Rationale**: Catches regressions at the earliest possible point. Nix evaluation errors often surface path issues immediately, making structural refactors safe.

## Risks / Trade-offs

- **[Path changes break imports]** → Mitigation: Each phase creates target directories with correct `default.nix` files first, then updates importers, then removes old files. Verify with `nix flake check` after each step.
- **[Home Manager merge conflicts during phase 5]** → Mitigation: Consolidate all HM config into `home/default.nix` in a single step; test evaluation before committing. The current duplication between `user.nix` and `home.nix` must be resolved carefully.
- **[Deploy script references break]** → Mitigation: Phase 7 updates `deploy-hetzner.sh` paths; test with a dry-run before committing.
- **[Test files reference old paths]** → Mitigation: Phase 6 updates all test imports; run nix-unit and evaluation tests before removing old paths.
- **[Git history becomes harder to follow]** → Mitigation: Each phase is a separate commit with a descriptive message like `refactor: move flake-parts modules to parts/`. Git can track file renames with `--follow`.
- **[Cognitive overhead from many small phases]** → Mitigation: Each phase is independently verifiable. If a phase introduces an error, `git revert` that single commit. No phase depends on a later phase's completion to function.

## Migration Plan

Each phase results in a working system:

1. **Phase 0**: Baseline -- verify all tests pass, document current state
2. **Phase 1**: Scaffolding -- create target directories with `default.nix` stubs, wire into `flake.nix` alongside `modules/`
3. **Phase 2**: Flake-parts -- move `devshell.nix` and `nixos-configurations.nix` to `parts/`, update `flake.nix`
4. **Phase 3**: Hosts -- move `hosts/` subdirectory to top-level `hosts/`, update `nixos-configurations.nix` import path
5. **Phase 4**: NixOS modules -- move system modules to `nixos/`, update host composition imports
6. **Phase 5**: Home Manager -- consolidate all HM config into `home/default.nix` with atomic HM modules, update host composition
7. **Phase 6**: Tests -- update test import paths, verify all tests pass from new locations
8. **Phase 7**: Scripts and cleanup -- move `deploy-hetzner.sh` to `scripts/`, remove `modules/`, remove `nix/cells/`
9. **Phase 8**: Final validation -- full `nix flake check`, nix-unit, evaluation tests, NixOS build

**Rollback**: Each phase is a separate commit. To rollback, `git revert` the specific phase commit. No phase modifies data or deployed state; only file organization changes.

## Open Questions

- Should `tailscale/acl.hujson` move into `nixos/` or stay at the repo root? (Recommendation: keep at root in `tailscale/` since it's not a Nix module)
- Should the `apps/oh-my-pi-web/` directory be moved under `pkgs/` or stay as `apps/`? (Recommendation: leave as `apps/` since it's a separate project, not a Nix package)
- Should `secrets/` directory be created now or only when non-opnix secret management is needed? (Recommendation: create now as empty with a README, to establish the convention)