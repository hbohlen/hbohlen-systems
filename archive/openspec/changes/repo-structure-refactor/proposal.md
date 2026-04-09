## Why

The repository has evolved organically from a cell-based structure to a flat `modules/` directory, accumulating structural debt: NixOS modules and flake-parts modules are mixed in the same flat folder with no directory-level distinction, Home Manager configuration is fragmented across multiple files with overlapping `home-manager.users.hbohlen` blocks, and a fragile auto-import pattern in `modules/default.nix` requires manually maintaining an exclusion list that drifts from the explicit import list in `nixos-configurations.nix`. Refactoring now provides clearer separation of concerns, safer incremental migration, and reduces the risk of merge conflicts and import errors as the configuration grows.

## What Changes

- Replace the flat `modules/` directory with domain-separated top-level directories: `parts/`, `hosts/`, `nixos/`, `home/`, `pkgs/`, `lib/`, `tests/`, `scripts/`, `docs/`, `secrets/`
- Consolidate all `home-manager.users.hbohlen` configuration into a single composition point under `home/`, eliminating the current duplication between `user.nix` and `home.nix`
- Remove the fragile `modules/default.nix` auto-import pattern with its manual exclusion list; replace with explicit imports at composition boundaries
- Move `modules/hosts/` to top-level `hosts/`
- Move flake-parts modules (`devshell.nix`, `nixos-configurations.nix`) to `parts/`
- Move NixOS system modules to `nixos/` with atomic modules preserved as individual files
- Move Home Manager modules to `home/` with atomic modules preserved as individual files
- Fix stale references in `deploy-hetzner.sh` that point to non-existent `nix/cells/` paths
- Remove the empty `nix/cells/` directory
- Define `home-manager.useGlobalPkgs = true` and `home-manager.useUserPackages = true` in a single, clear location
- Establish a layered incremental testing strategy using nix-unit, `nix flake check`, evaluation checks, and targeted NixOS build checks at every migration phase

## Capabilities

### New Capabilities
- `repo-layout`: Defines the target directory structure, domain responsibilities, and composition boundaries for the repository
- `import-composition`: Defines how modules are imported and composed at each boundary, replacing auto-import with explicit imports
- `migration-testing`: Defines the layered incremental testing strategy for validating each migration phase

### Modified Capabilities
- `devshell`: Flakes-parts devshell module moves from `modules/devshell.nix` to `parts/devshell.nix`
- `tmux-config`: Home Manager tmux configuration moves from `modules/tmux.nix` to `home/tmux.nix` with a single composition point at `home/default.nix`

## Impact

- All NixOS module files move from `modules/` to domain-specific directories (`nixos/`, `home/`, `parts/`, `hosts/`)
- `modules/default.nix` (auto-import) is removed entirely
- `modules/nixos-configurations.nix` imports change from `./module-name.nix` to `../nixos/module-name.nix`, `../home/default.nix`, etc.
- `deploy-hetzner.sh` path references must be updated from `nix/cells/nixos/...` to `nixos/...`, `hosts/...`
- `tests/` structure adjusts import paths to match new module locations
- `flake.nix` import of `./modules` changes to `./parts`
- GNO module, opencode module paths update in host composition and test files