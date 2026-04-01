# Design: Dendritic Refactor

**Date:** 2026-04-01
**Status:** Draft
**Scope:** Full refactor of hbohlen-systems nix structure to pure dendritic pattern with testing

---

## Goal

Refactor the hbohlen-systems flake from its current tangled cell-based structure to a pure dendritic pattern where every `.nix` file is a flake-parts module representing one aspect (feature). Add a three-layer testing strategy so agents can verify changes without deploying to real hardware.

## Problem

The current structure has:
- 4 cells (`devshells`, `nixos`, `home`, `pi-nix-suite`) with inconsistent patterns
- The `home` cell is orphaned (not imported in `flake.nix`)
- Modules are flat with no clear grouping — 10 modules in `nix/cells/nixos/modules/`
- Duplication: `opnix-bootstrap.nix` and `tailscale-enhanced.nix` define the same Tailscale config
- Host config mixes service configuration with host-specific settings
- No testing — changes require deploying to verify
- No clear pattern for agents to follow when adding features

## Target Architecture

```
hbohlen-systems/
├── flake.nix                          # Root: inputs + nix-unit + module loading
├── modules/
│   ├── base.nix                       # nixpkgs config, stateVersion, locale, nix settings
│   ├── user.nix                       # hbohlen user (nixos + homeManager in one file)
│   ├── ssh.nix                        # SSH server + client config
│   ├── tailscale.nix                  # Tailscale + 1Password secrets
│   ├── caddy.nix                      # Caddy reverse proxy with Tailscale
│   ├── security.nix                   # fail2ban, firewall rules
│   ├── disko.nix                      # Disk partitioning layout
│   ├── gno.nix                        # GNO daemon + serve
│   ├── opencode.nix                   # opencode web UI systemd service
│   ├── devshell.nix                   # devShell packages, fish config, shellHook
│   └── hosts/
│       └── hbohlen-01.nix             # Host composition: hostname, hardware, aspect selection
├── tests/
│   ├── unit/
│   │   ├── default.nix                # nix-unit test suite entry point
│   │   ├── test-options.nix           # Module option evaluation tests
│   │   └── test-outputs.nix           # Flake output existence tests
│   └── evaluation/
│       ├── default.nix                # Module evaluation test entry point
│       ├── test-base.nix              # Base module evaluates
│       ├── test-ssh.nix               # SSH module evaluates
│       ├── test-tailscale.nix         # Tailscale module evaluates
│       └── test-services.nix          # Service modules evaluate
├── apps/
│   └── oh-my-pi-web/
├── nix/cells/pi-nix-suite/            # Kept as-is (shell commands + TS extension)
├── tailscale/
│   └── acl.hujson
├── docs/
├── deploy-hetzner.sh
└── .envrc
```

### What changes

| Current | New | Notes |
|---------|-----|-------|
| `nix/cells/nixos/default.nix` | `modules/` | Cell replaced by flat module dir |
| `nix/cells/devshells/default.nix` | `modules/devshell.nix` | Merged into single aspect file |
| `nix/cells/home/default.nix` | `modules/user.nix` | Merged into user aspect |
| `nix/cells/home/programs/opnix-ssh.nix` | `modules/ssh.nix` | Merged with ssh-hardening |
| `nix/cells/nixos/modules/base.nix` | `modules/base.nix` | Moved, stripped SSH/user config |
| `nix/cells/nixos/modules/ssh-hardening.nix` | `modules/ssh.nix` | Merged with opnix-ssh |
| `nix/cells/nixos/modules/opnix-bootstrap.nix` | `modules/tailscale.nix` | Merged with tailscale-enhanced |
| `nix/cells/nixos/modules/tailscale-enhanced.nix` | `modules/tailscale.nix` | Merged with opnix-bootstrap |
| `nix/cells/nixos/modules/fail2ban.nix` | `modules/security.nix` | Renamed, firewall rules added |
| `nix/cells/nixos/modules/caddy-tailscale.nix` | `modules/caddy.nix` | Simplified |
| `nix/cells/nixos/modules/gno-daemon.nix` | `modules/gno.nix` | Merged with gno-serve |
| `nix/cells/nixos/modules/gno-serve.nix` | `modules/gno.nix` | Merged with gno-daemon |
| `nix/cells/nixos/modules/opencode.nix` | `modules/opencode.nix` | Moved |
| `nix/cells/nixos/modules/disko.nix` | `modules/disko.nix` | Moved |
| `nix/cells/nixos/hosts/hbohlen-01/` | `modules/hosts/hbohlen-01.nix` | Flattened to single file |
| `nix/cells/pi-nix-suite/` | `nix/cells/pi-nix-suite/` | **Unchanged** — not a config aspect |

### What stays the same

- `flake.nix` inputs (nixpkgs, flake-parts, llm-agents, disko, home-manager, opnix)
- New input: `nix-unit` for testing
- `nix/cells/pi-nix-suite/` — shell commands and TypeScript extension, untouched
- `apps/oh-my-pi-web/` — web app, untouched
- `tailscale/acl.hujson` — ACL config, untouched
- `deploy-hetzner.sh` — deploy script, untouched

---

## Module Specifications

### flake.nix

Minimal root file. Declares inputs, loads flake-parts, imports modules and nix-unit.

```nix
{
  description = "hbohlen-systems - dendritic personal infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-unit = {
      url = "github:nix-community/nix-unit";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opnix = {
      url = "github:brizzbuzz/opnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

      imports = [
        inputs.nix-unit.modules.flake.default
        ./modules
      ];
    };
}
```

### modules/base.nix

Foundational system config. Stripped of SSH and user definitions (moved to their own aspects).

Contains: nixpkgs allowUnfree, GRUB bootloader, kernel params, DHCP, nix experimental features, locale, timezone, stateVersion.

### modules/user.nix

The `hbohlen` user across both NixOS and Home Manager.

- NixOS: user creation, wheel group, fish shell, SSH authorized keys
- Home Manager: stateVersion, SSH client config, session variables, `programs.ssh.enable`

No more separate `home/` cell. This is the single source of truth for the user.

### modules/ssh.nix

Merged from `ssh-hardening.nix` + `home/programs/opnix-ssh.nix`.

- NixOS: OpenSSH enable, cipher/MAC/KEX hardening, rate limiting, firewall rules for tailscale0
- Home Manager: SSH client config, IdentityAgent socket

### modules/tailscale.nix

Merged from `opnix-bootstrap.nix` + `tailscale-enhanced.nix`. Removes duplication.

- Tailscale enable, openFirewall, routing features, SSH, advertise-tags
- 1Password secrets: caddyTailscaleAuthKey
- Tailscale package in systemPackages

### modules/caddy.nix

Current `caddy-tailscale.nix` simplified. Caddy with Tailscale plugin, virtual host for opencode reverse proxy.

### modules/security.nix

fail2ban configuration + firewall rules extracted from `base.nix`.

- fail2ban: sshd jail, sshd-tailscale jail, daemon settings
- Firewall: allowed TCP ports, interface-specific rules

### modules/disko.nix

Disk partitioning layout. Moved as-is from current location.

### modules/gno.nix

Merged from `gno-daemon.nix` + `gno-serve.nix`.

- Options: enable, port, user, collectionPath, hostname
- Two systemd services: gno-daemon, gno-serve
- Tailscale serve configuration for GNO web UI

### modules/opencode.nix

opencode web UI systemd service. Moved as-is.

### modules/devshell.nix

Merged from `devshells/default.nix` + `config/fish.nix`.

- `perSystem.devShells.default` with all packages
- Fish config inline (no separate file)
- shellHook with starship, zoxide, direnv, pi-nix-suite setup
- pi-nix-suite package referenced from `../nix/cells/pi-nix-suite`

### modules/hosts/hbohlen-01.nix

Host composition only. No service configuration — just enables and host-specific settings.

- Hostname, hardware-configuration import
- Deploy SSH keys (root + hbohlen)
- Hetzner Cloud settings (predictable interfaces, kernel modules)
- Service enable flags: `services.opencode.enable`, `services.gno-daemon.enable`, `services.gno-serve.enable`, `services.caddy.tailscaleEnable`

---

## Testing Strategy

### Layer 1: Static Checks

Run on every `nix flake check`:

| Check | Tool | What it catches |
|-------|------|-----------------|
| formatting | `alejandra -c .` | Inconsistent formatting |
| linting | `statix check .` | Anti-patterns, style issues |
| dead code | `deadnix .` | Unused variables, unreachable code |

### Layer 2: Unit Tests (nix-unit)

Integrated via `inputs.nix-unit.modules.flake.default`. Tests are pure Nix expressions.

**`tests/unit/default.nix`** — Entry point, imports all test files:
```nix
{ inputs, pkgs, ... }:
{
  imports = [
    ./test-options.nix
    ./test-outputs.nix
  ];
  _module.args = { inherit inputs pkgs; };
}
```

**`tests/unit/test-options.nix`** — Module option evaluation:
- Verify custom options exist (services.opencode.enable, services.gno-daemon.enable, services.caddy.tailscaleEnable)
- Verify default values are correct

**`tests/unit/test-outputs.nix`** — Flake output existence:
- Verify `nixosConfigurations.hbohlen-01` exists
- Verify `devShells.<system>.default` exists
- Verify `homeConfigurations.hbohlen` exists

### Layer 3: Module Evaluation Tests

Verify each module evaluates without errors using `pkgs.nixos []`. No VM needed.

**`tests/evaluation/default.nix`** — Entry point:
```nix
{ pkgs, inputs, ... }:
let
  evalModule = module: (pkgs.nixos [ module ]).config.system.build.toplevel;
in
{
  base = evalModule ../modules/base.nix;
  ssh = evalModule ../modules/ssh.nix;
  # ... etc
}
```

These are added to `checks.${system}` as derivations that build the evaluated config.

### Flake Checks Summary

Running `nix flake check` executes:
1. `checks.<system>.formatting` — alejandra
2. `checks.<system>.statix` — statix
3. `checks.<system>.deadnix` — deadnix
4. `checks.<system>.nix-unit` — unit tests (auto-wired by nix-unit flake-parts module)
5. `checks.<system>.eval-*` — module evaluation tests

---

## Dendritic Principles Applied

1. **Every file is a module** — Every `.nix` in `modules/` is imported by flake-parts
2. **One aspect per file** — `ssh.nix` does SSH. `tailscale.nix` does Tailscale. Period.
3. **Cross-cutting in one file** — `user.nix` configures the user across NixOS and Home Manager
4. **No manual import chains** — flake-parts imports `./modules` which loads all `.nix` files
5. **Host composition** — `hosts/hbohlen-01.nix` only declares which aspects apply to this host
6. **No specialArgs** — shared values via flake-parts options or let-bindings within modules
7. **File path = documentation** — The filename tells you what the module does

---

## Migration Strategy

Work on `feature/dendritic-refactor` branch. Build incrementally.

### Order

1. **Foundation** — `flake.nix` + `modules/base.nix`
2. **DevShell** — `modules/devshell.nix` (verify devShell still works)
3. **User + Auth** — `modules/user.nix` + `modules/ssh.nix`
4. **Networking** — `modules/tailscale.nix` + `modules/caddy.nix` + `modules/security.nix`
5. **Services** — `modules/disko.nix` + `modules/gno.nix` + `modules/opencode.nix`
6. **Host** — `modules/hosts/hbohlen-01.nix`
7. **Testing** — `tests/unit/` + `tests/evaluation/`
8. **Cleanup** — Delete old `nix/cells/` tree (except `pi-nix-suite`)

### Verification

After each step:
- `nix flake check` passes
- `nix develop` enters a working devShell
- No evaluation errors

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Pure dendritic over hybrid** | Cleanest for agents — predictable file locations, no nesting to navigate |
| **Auto-import via flake-parts** | No manual `imports = []` chains — adding a module = adding a file |
| **Merge related modules** | `gno-daemon` + `gno-serve` → `gno.nix` — they're tightly coupled |
| **Merge duplicated modules** | `opnix-bootstrap` + `tailscale-enhanced` → `tailscale.nix` — same config, two files |
| **Keep pi-nix-suite separate** | It's a package, not a config aspect. Not ready for packaging yet. |
| **nix-unit over custom tests** | Standard tool, flake-parts integration, fast (C++ evaluator) |
| **Module eval tests over VM tests** | No KVM needed, fast, catches 95% of errors. VM tests can be added later. |
| **alejandra over nixfmt** | More widely adopted in the community, stricter formatting |

---

## Out of Scope

- Packaging the pi-nix-suite TypeScript extension
- VM integration tests (can be added later)
- CI/GitHub Actions setup
- Refactoring `apps/oh-my-pi-web/`
- Changes to `tailscale/acl.hujson`
- Changes to `deploy-hetzner.sh`
