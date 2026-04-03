---
name: opnix-nixos-integration
description: Use when integrating 1Password secret injection into a NixOS or Home Manager configuration using the opnix module from github:brizzbuzz/opnix
---

# OpNix NixOS Integration

## Overview

OpNix provides declarative 1Password secret injection for NixOS, nix-darwin, and Home Manager. It fetches secrets from 1Password at activation time using a service account token, and writes them to disk with proper permissions.

## When to Use

- Adding 1Password secrets to a NixOS configuration
- Replacing hardcoded secrets in Nix config with 1Password references
- Setting up SSH keys from 1Password on a NixOS server
- Configuring Home Manager to inject user-level secrets

## Quick Reference

### Flake Input

```nix
inputs.opnix = {
  url = "github:brizzbuzz/opnix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

### Module Imports

| Platform | Import Path | Module |
|----------|-------------|--------|
| NixOS | `inputs.opnix.nixosModules.default` | `services.onepassword-secrets` |
| nix-darwin | `inputs.opnix.darwinModules.default` | `services.onepassword-secrets` |
| Home Manager | `inputs.opnix.homeManagerModules.default` | `programs.onepassword-secrets` |

### NixOS Module (`services.onepassword-secrets`)

```nix
services.onepassword-secrets = {
  enable = true;
  tokenFile = "/etc/opnix-token";

  secrets = {
    databasePassword = {
      reference = "op://Vault/Item/field";
      owner = "postgres";
      group = "postgres";
      mode = "0600";
      services = [ "postgresql" ];  # restart on change
    };
  };
};
```

**Key rules:**
- Secret names must be camelCase: `databasePassword` ✓, `api_key` ✗
- At least one secret OR configFile required when `enable = true`
- Creates `opnix-secrets.service` systemd oneshot at boot
- Gracefully degrades if token file is missing (warns, keeps existing secrets)
- Output: `/var/lib/opnix/secrets/<name>` (or custom `path`)

### Home Manager Module (`programs.onepassword-secrets`)

```nix
programs.onepassword-secrets = {
  enable = true;
  tokenFile = "/etc/opnix-token";

  secrets = {
    sshPrivateKey = {
      reference = "op://hbohlen-systems/ssh/private_key";
      path = ".ssh/id_ed25519";  # relative to $HOME
      mode = "0600";
    };
  };
};
```

**Key rules:**
- Paths are relative to `$HOME`
- Runs during `home-manager switch` activation (not a systemd service)
- User must be able to read `tokenFile` (group `users` or `onepassword-secrets`)

### Inline HM Integration (NixOS + Home Manager together)

```nix
# In nixos/default.nix or host config
modules = [
  inputs.home-manager.nixosModules.default
  inputs.opnix.nixosModules.default
  {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.sharedModules = [
      inputs.opnix.homeManagerModules.default
    ];
    home-manager.users.myuser = import ../home/programs/secrets.nix;
  }
];
```

## Token Permissions

The token file must be readable by whichever process fetches secrets:

| Context | Runs As | Token Permissions Needed |
|---------|---------|------------------------|
| NixOS `opnix-secrets.service` | root | `root:root 640` works |
| HM via `nixos-rebuild switch` | root | `root:root 640` works |
| HM via `home-manager switch` | user | `root:users 644` or user-specific token |
| HM via systemd service | user | `root:users 644` or add user to group |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| `enable = true` with empty `secrets = {}` | Add at least one secret or set `enable = false` |
| Secret name `api_key` (underscore) | Use `apiKey` (camelCase) |
| HM can't read token (permission denied) | Set token to `root:users 644` or use user-specific token |
| NixOS and HM both configure Tailscale | Deduplicate — keep Tailscale in one module only |
| Tailscale authkey managed by opnix + hardcoded | Pick one; having both creates conflicts |
| Forgot `sharedModules` for HM | HM module not imported; `programs.onepassword-secrets` unknown |

## Full Example: NixOS + HM SSH Keys

```nix
# nix/cells/nixos/default.nix
{ inputs, ... }:
{
  flake.nixosConfigurations.myhost = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      inputs.home-manager.nixosModules.default
      inputs.opnix.nixosModules.default
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.sharedModules = [
          inputs.opnix.homeManagerModules.default
        ];
        home-manager.users.myuser = {
          programs.onepassword-secrets = {
            enable = true;
            tokenFile = "/etc/opnix-token";
            secrets = {
              sshPrivateKey = {
                reference = "op://MyVault/SSH/private_key";
                path = ".ssh/id_ed25519";
                mode = "0600";
              };
            };
          };
        };
      }
    ];
  };
}
```
