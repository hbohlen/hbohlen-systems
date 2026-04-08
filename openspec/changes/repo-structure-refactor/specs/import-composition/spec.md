## ADDED Requirements

### Requirement: Explicit imports at domain composition boundaries

Each domain directory SHALL have a `default.nix` that explicitly lists all modules in that domain. No domain SHALL use auto-discovery of `.nix` files.

#### Scenario: parts/ default.nix composition
- **WHEN** `flake.nix` imports `./parts`
- **THEN** all flake-parts modules are included via explicit imports in `parts/default.nix`
- **AND** no `builtins.readDir`-based auto-import is used

#### Scenario: nixos/ default.nix composition
- **WHEN** a host composition file imports `../nixos`
- **THEN** all NixOS system modules are included via explicit imports in `nixos/default.nix`
- **AND** no `builtins.readDir`-based auto-import is used

#### Scenario: home/ default.nix composition
- **WHEN** the host composition imports `../home`
- **THEN** `home/default.nix` defines `home-manager.users.hbohlen = { ... }` with an explicit `imports` list referencing each atomic HM module
- **AND** no `builtins.readDir`-based auto-import is used

### Requirement: Home Manager config defined once at composition boundary

`home-manager.users.hbohlen` SHALL be defined in exactly one file: `home/default.nix`. No other file SHALL define `home-manager.users.hbohlen` at the top level.

#### Scenario: Searching for HM config composition
- **WHEN** a contributor searches for where `home-manager.users.hbohlen` is defined
- **THEN** the only file containing this attribute path is `home/default.nix`
- **AND** individual HM modules in `home/` contribute via `imports` inside the user block, not by defining `home-manager.users.hbohlen` themselves

#### Scenario: Individual HM modules are atomic
- **WHEN** a contributor opens `home/tmux.nix`
- **THEN** it contains only the HM module options for tmux (e.g., `programs.tmux = { ... }`)
- **AND** it does NOT contain `home-manager.users.hbohlen` wrapping

### Requirement: HM global settings defined at nixos-configurations level

`home-manager.useGlobalPkgs` and `home-manager.useUserPackages` SHALL be set to `true` in `parts/nixos-configurations.nix`, in the same module that imports `home-manager.nixosModules.default`.

#### Scenario: Locating HM global settings
- **WHEN** a contributor searches for where `home-manager.useGlobalPkgs` is set
- **THEN** it is found in `parts/nixos-configurations.nix`
- **AND** it is set to `true`
- **AND** `home-manager.useUserPackages` is also `true` in the same file

### Requirement: Host composition explicitly imports domain modules

Each host file in `hosts/` SHALL explicitly import from `../nixos`, `../home`, and flake inputs. No host file SHALL import from `modules/`.

#### Scenario: hbohlen-01 host composition
- **WHEN** building `nixosConfigurations.hbohlen-01`
- **THEN** `hosts/hbohlen-01.nix` explicitly imports `../nixos` and `../home`
- **AND** `parts/nixos-configurations.nix` references the host file at `../hosts/hbohlen-01.nix`
- **AND** no import path references `modules/`