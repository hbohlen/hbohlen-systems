---
name: nix-dendritic-pattern
description: "Guide for implementing the dendritic pattern in Nix projects using flake-parts. Based on github.com/mightyiam/dendritic."
tags: [nix, flake, flake-parts, dendritic, architecture]
category: nix
metadata:
  author: hbohlen-systems implementation experience
  version: "1.0.0"
---

# Nix Dendritic Pattern

The dendritic pattern is an approach to organizing Nix flakes where each "cell" is a self-contained unit that can grow organically without affecting others.

## Core Structure

```
project/
├── flake.nix              # Root flake: inputs + loader
├── flake.lock             # Pinned dependencies
├── nix/
│   ├── cells/             # Each subdirectory is a cell
│   │   ├── cell-a/
│   │   │   └── default.nix
│   │   ├── cell-b/
│   │   │   └── default.nix
│   │   └── cell-c/
│   │       └── default.nix
│   └── lib/               # Shared utilities (optional)
└── ...
```

## Key Principles

1. **Self-Contained Cells**: Each cell exports its own attributes. No cell imports from another cell directly.
2. **Organic Growth**: Add new cells without modifying existing ones.
3. **Safe Deletion**: Remove a cell without breaking the rest of the system.
4. **Composability**: The root flake composes cells together.

## Basic flake.nix

```nix
{
  description = "Dendritic flake example";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      imports = [
        ./nix/cells/devshells
        ./nix/cells/packages
      ];
    };
}
```

## Cell Structure

A cell is just a module that flake-parts imports:

```nix
# nix/cells/devshells/default.nix
{ self, lib, config, pkgs, ... }:
{
  devShells.default = pkgs.mkShell {
    packages = with pkgs; [ git neovim ];
  };
}
```

## Common Cell Types

- `devshells/` — Development environments
- `packages/` — Custom packages
- `home/` — Home-manager configurations
- `nixos/` — System configurations
- `overlays/` — Nixpkgs overlays

## PerSystem vs Top-Level

Use `perSystem` for things that vary by system (packages, devShells):

```nix
{ config, lib, pkgs, ... }:
{
  perSystem = { config, self', inputs', pkgs, system, ... }: {
    devShells.default = pkgs.mkShell { ... };
    packages.default = pkgs.callPackage ./my-package { };
  };
}
```

Use top-level for flake outputs that don't vary by system (nixosConfigurations, homeConfigurations):

```nix
{ config, lib, ... }:
{
  flake = {
    nixosConfigurations.myhost = ...;
  };
}
```

## Benefits

- **Incremental**: Add one cell at a time
- **Isolated**: Changes to one cell don't cascade
- **Discoverable**: Each cell is a file you can read independently
- **Team-friendly**: Different people can own different cells

## Anti-Patterns

- ❌ Cells importing from each other directly
- ❌ Deep hierarchies (cells/subcells/subsubcells)
- ❌ Putting everything in one cell "temporarily"
- ❌ Complex cross-cell dependencies

## Testing a Cell

```bash
# Test devshell
cd /path/to/project
nix develop .#default

# Test package
nix build .#mypackage
nix run .#mypackage
```

## DevShell Testing Pattern

When a devShell shellHook auto-starts a shell (like fish), it breaks `nix develop --command` because `exec` replaces the process. Fix this by only exec-ing when running interactively:

```nix
shellHook = ''
  export SHELL=${pkgs.fish}/bin/fish

  # Only exec to fish in interactive terminals
  # This allows 'nix develop --command cmd' to work for testing
  if [[ -z "$FISH_VERSION" && -t 0 ]]; then
    exec ${pkgs.fish}/bin/fish
  fi
'';
```

**Why this matters:**
- Without the check: `nix develop --command fish --version` enters fish interactively instead of running the command
- With `-t 0` check: Commands execute properly, enabling automated testing

**Full testing example:**
```bash
# Test fish is available
nix develop --command fish --version

# Test packages in PATH
nix develop --command bash -c "which nvim rg eza"

# Test abbreviations loaded
nix develop --command fish -c "abbr --list"
```

## References

- Original: https://github.com/mightyiam/dendritic
- flake-parts: https://flake.parts