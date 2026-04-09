## 1. Phase 0 -- Baseline Verification

- [ ] 1.1 Run `nix flake check` and verify all checks pass (formatting, statix, deadnix)
- [ ] 1.2 Run `nix-unit` and verify all unit tests pass with current paths
- [ ] 1.3 Run evaluation tests and verify all pass
- [ ] 1.4 Run `nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel` and verify it succeeds
- [ ] 1.5 Commit baseline state with message `refactor: baseline before repo structure migration`

## 2. Phase 1 -- Scaffolding

- [ ] 2.1 Create `parts/` directory with `default.nix` that lists explicit imports (initially importing from `../modules/devshell.nix` and `../modules/nixos-configurations.nix`)
- [ ] 2.2 Create `hosts/` directory, move `modules/hosts/hbohlen-01.nix` and `modules/hosts/hbohlen-01-hardware-configuration.nix` to `hosts/`
- [ ] 2.3 Create `nixos/` directory with `default.nix` that re-exports a list of NixOS modules (initially referencing `../modules/` paths)
- [ ] 2.4 Create `home/` directory with `default.nix` that defines `home-manager.users.hbohlen = { imports = [...]; }` with explicit imports (initially referencing `../modules/` paths)
- [ ] 2.5 Create `pkgs/`, `lib/`, `secrets/` directories with README files indicating reserved intent
- [ ] 2.6 Create `scripts/` directory
- [ ] 2.7 Update `flake.nix` to import `./parts` alongside `./modules` (dual import during transition)
- [ ] 2.8 Run `nix flake check` and verify scaffolding doesn't break anything
- [ ] 2.9 Commit with message `refactor: add target directory scaffolding alongside modules/`

## 3. Phase 2 -- Move Flake-Parts Modules

- [ ] 3.1 Move `modules/devshell.nix` to `parts/devshell.nix`
- [ ] 3.2 Move `modules/nixos-configurations.nix` to `parts/nixos-configurations.nix`
- [ ] 3.3 Update `parts/default.nix` to import from local paths (`./devshell.nix`, `./nixos-configurations.nix`)
- [ ] 3.4 Update `parts/nixos-configurations.nix` to reference `../hosts/hbohlen-01.nix` for host composition
- [ ] 3.5 Update `parts/nixos-configurations.nix` to import `../nixos` and `../home` for module lists
- [ ] 3.6 Update `flake.nix` to import `./parts` instead of `./modules`
- [ ] 3.7 Remove old `modules/devshell.nix` and `modules/nixos-configurations.nix`
- [ ] 3.8 Run static checks: `nix flake check`
- [ ] 3.9 Run nix-unit tests and verify all pass
- [ ] 3.10 Run evaluation tests and verify all pass
- [ ] 3.11 Run NixOS build: `nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel`
- [ ] 3.12 Commit with message `refactor: move flake-parts modules to parts/`

## 4. Phase 3 -- Move Host Definitions

- [ ] 4.1 Verify `hosts/` directory exists with host files (moved in Phase 1 scaffolding)
- [ ] 4.2 Update `hosts/hbohlen-01.nix` imports to reference `../nixos` and `../home` instead of local module paths
- [ ] 4.3 Update `parts/nixos-configurations.nix` to reference `../hosts/hbohlen-01.nix`
- [ ] 4.4 Remove `modules/hosts/` directory (now empty after move)
- [ ] 4.5 Run static checks, nix-unit, evaluation tests, and NixOS build
- [ ] 4.6 Commit with message `refactor: move host definitions to hosts/`

## 5. Phase 4 -- Move NixOS System Modules

- [ ] 5.1 Move `modules/base.nix` to `nixos/base.nix`
- [ ] 5.2 Move `modules/ssh.nix` to `nixos/ssh.nix`
- [ ] 5.3 Move `modules/security.nix` to `nixos/security.nix`
- [ ] 5.4 Move `modules/caddy.nix` to `nixos/caddy.nix`
- [ ] 5.5 Move `modules/tailscale.nix` to `nixos/tailscale.nix`
- [ ] 5.6 Move `modules/disko.nix` to `nixos/disko.nix`
- [ ] 5.7 Move `modules/gno.nix` to `nixos/gno.nix`
- [ ] 5.8 Move `modules/opencode.nix` to `nixos/opencode.nix`
- [ ] 5.9 Update `nixos/default.nix` to import from local paths instead of `../modules/`
- [ ] 5.10 Update `hosts/hbohlen-01.nix` to import from `../nixos` instead of local module paths
- [ ] 5.11 Update all evaluation test files in `tests/evaluation/` to reference `../nixos/` paths
- [ ] 5.12 Remove imported files from `modules/` that have been moved
- [ ] 5.13 Run static checks, nix-unit, evaluation tests, and NixOS build
- [ ] 5.14 Commit with message `refactor: move NixOS system modules to nixos/`

## 6. Phase 5 -- Consolidate and Move Home Manager

- [ ] 6.1 Create atomic HM modules in `home/`: extract `programs.tmux` config from `modules/tmux.nix` into `home/tmux.nix`
- [ ] 6.2 Create `home/ssh-client.nix` extracting SSH client config from `modules/home.nix` and `modules/user.nix`
- [ ] 6.3 Create `home/session-vars.nix` extracting sessionVariables from `modules/home.nix`
- [ ] 6.4 Create `home/git.nix` or other HM modules as needed from existing `modules/home.nix` and `modules/user.nix`
- [ ] 6.5 Write `home/default.nix` with `home-manager.users.hbohlen = { imports = [ ./tmux.nix ./ssh-client.nix ./session-vars.nix ... ]; ... }`
- [ ] 6.6 Set `home-manager.useGlobalPkgs = true` and `home-manager.useUserPackages = true` in `parts/nixos-configurations.nix`
- [ ] 6.7 Remove `home-manager.users.hbohlen` definitions from `modules/user.nix`, `modules/home.nix`, and `modules/tmux.nix`
- [ ] 6.8 Remove `modules/user.nix` and `modules/home.nix` after consolidation (move any remaining NixOS-level user config to `nixos/user.nix` or `nixos/base.nix`)
- [ ] 6.9 Remove `modules/tmux.nix` (replaced by `home/tmux.nix`)
- [ ] 6.10 Update `hosts/hbohlen-01.nix` to import `../home` for HM modules
- [ ] 6.11 Add evaluation test for `home/` module composition
- [ ] 6.12 Run static checks, nix-unit, evaluation tests, and NixOS build
- [ ] 6.13 Verify HM config evaluates correctly with `home-manager.users.hbohlen` defined in exactly one file
- [ ] 6.14 Commit with message `refactor: consolidate Home Manager modules into home/`

## 7. Phase 6 -- Update Tests

- [ ] 7.1 Update `tests/unit/default.nix` to reference modules at new paths (`../nixos/`, `../home/`, `../parts/`)
- [ ] 7.2 Update `tests/unit/test-options.nix` module imports to reference `../nixos/caddy.nix`, `../nixos/gno.nix`, `../nixos/opencode.nix`
- [ ] 7.3 Update `tests/unit/test-outputs.nix` to reference `../parts/devshell.nix`
- [ ] 7.4 Update `tests/evaluation/` test files to import from `../nixos/` and `../home/`
- [ ] 7.5 Run nix-unit tests and verify all pass
- [ ] 7.6 Run evaluation tests and verify all pass
- [ ] 7.7 Commit with message `refactor: update test imports for new directory structure`

## 8. Phase 7 -- Scripts and Cleanup

- [ ] 8.1 Move `deploy-hetzner.sh` to `scripts/deploy-hetzner.sh`
- [ ] 8.2 Update path references in `deploy-hetzner.sh`: change `nix/cells/nixos/modules/` to `nixos/`, `nix/cells/nixos/hosts/` to `hosts/`
- [ ] 8.3 Remove `modules/default.nix` (the auto-import file)
- [ ] 8.4 Remove empty `modules/` directory
- [ ] 8.5 Remove empty `nix/cells/` directory
- [ ] 8.6 Remove stale `result` symlink if present
- [ ] 8.7 Clean up any dead `home-config.nix` references in the exclusion list (now irrelevant since `modules/` is removed)
- [ ] 8.8 Verify `flake.nix` no longer references `./modules`
- [ ] 8.9 Run static checks, nix-unit, evaluation tests, and NixOS build
- [ ] 8.10 Commit with message `refactor: remove modules/, clean up stale paths and scripts`

## 9. Phase 8 -- Final Validation

- [ ] 9.1 Run `nix flake check` and verify all checks pass
- [ ] 9.2 Run `nix-unit` and verify all tests pass
- [ ] 9.3 Run evaluation tests and verify all pass
- [ ] 9.4 Run `nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel`
- [ ] 9.5 Verify `grep -r "modules/" --include="*.nix"` finds no references to old `modules/` paths
- [ ] 9.6 Verify `grep -r "nix/cells/" --include="*.nix" --include="*.sh"` finds no references to old cell paths
- [ ] 9.7 Verify `home-manager.users.hbohlen` appears in exactly one file (`home/default.nix`)
- [ ] 9.8 Verify `home-manager.useGlobalPkgs` and `home-manager.useUserPackages` are set in `parts/nixos-configurations.nix`
- [ ] 9.9 Commit with message `refactor: final validation of repo structure migration`