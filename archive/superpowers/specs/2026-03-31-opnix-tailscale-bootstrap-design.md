# OpNix + Tailscale Bootstrap Design

**Date:** 2026-03-31
**Status:** Draft
**Approach:** Setec relay for minimal-bootstrap server deployment

## Overview

Add Tailscale, 1Password (opnix), and 1Password CLI to the hbohlen-systems NixOS configuration. The goal is a **minimal-bootstrap** process for new Hetzner servers that:

1. Installs base NixOS via nixos-anywhere (no secrets needed at install time)
2. Server auto-connects to Tailscale (authkey hardcoded in NixOS config)
3. Server fetches opnix token from setec running on hbohlen-01
4. opnix hydrates remaining secrets from 1Password automatically
5. SSH agent configured via Home Manager

**Design principle:** Reduce human intervention to the absolute minimum. The ideal bootstrap should be: `nixos-anywhere → wait → done`.

## Context

### The Chicken-and-Egg Problem (Solved)

- `OP_SERVICE_ACCOUNT_TOKEN` lives in 1Password
- Need the token to use opnix to fetch other secrets
- But how do you get the token initially?

**Old solution:** Manual paste from DO droplet (2 manual steps)

**New solution:** Use setec on hbohlen-01 as a relay:
- hbohlen-01 already has op CLI signed in
- hbohlen-01 runs `tailscale setec` to serve the token
- New servers fetch from setec via tailnet (1 automatic step)

### Source of Truth

| Secret | Location | Served By |
|--------|----------|-----------|
| opnix token | 1Password `op://hbohlen-systems/opnix/token` | hbohlen-01 setec |
| tailscale authkey | 1Password `op://hbohlen-systems/tailscale/authKey` | opnix (after token set) |
| SSH keys | 1Password `op://hbohlen-systems/ssh/*` | opnix (after token set) |

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          hbohlen-01 (existing server)                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────┐   │
│  │ Tailscale       │  │ setec           │  │ op CLI                  │   │
│  │ (connected)     │──│ (secret relay)  │──│ (1Password vault)       │   │
│  └─────────────────┘  └────────┬────────┘  └─────────────────────────┘   │
│                                │                                            │
│                     tailscale setec serve                                  │
└────────────────────────────────┼─────────────────────────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │    NEW HETZNER SERVER   │
                    │                         │
                    │  Phase 1: Install       │
                    │  ┌───────────────────┐ │
                    │  │ nixos-anywhere    │ │
                    │  │ Tailscale authkey │ │
                    │  │ HARDCODED in nix  │ │
                    │  └───────────────────┘ │
                    │           │             │
                    │           ▼             │
                    │  Phase 2: Bootstrap     │
                    │  ┌───────────────────┐ │
                    │  │ systemd oneshot:  │ │
                    │  │ setec get token  │ │
                    │  │ opnix token set │ │
                    │  │ nixos-rebuild   │ │
                    │  └───────────────────┘ │
                    │           │             │
                    │           ▼             │
                    │  Phase 3: Running       │
                    │  ┌───────────────────┐ │
                    │  │ Tailscale online  │ │
                    │  │ SSH agent ready   │ │
                    │  │ Secrets hydrated  │ │
                    │  └───────────────────┘ │
                    └─────────────────────────┘
```

## One-Time Setup (hbohlen-01)

**Run once to store the opnix token in setec:**

```bash
# On hbohlen-01 (or DO droplet with op CLI signed in)
TOKEN="$(op read op://hbohlen-systems/opnix/token --no-newline)"
tailscale setec put opnix-token "$TOKEN"
```

**Verify setec is running on hbohlen-01:**
```bash
tailscale setec status
```

## NixOS Module: opnix-bootstrap.nix

**Location:** `nix/cells/nixos/modules/opnix-bootstrap.nix`

```nix
{ config, pkgs, ... }:

{
  # Tailscale with hardcoded authkey (from 1Password, set once)
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "server";
    extraUpFlags = [
      "--ssh"
      "--advertise-tags=tag:server,tag:prod"
      "--authkey=${secretsConfig.tailscaleAuthKey}"
    ];
  };

  systemd.services.tailscale.wantedBy = [ "multi-user.target" ];
  environment.systemPackages = [ pkgs.tailscale pkgs._1password-cli ];

  # Setec service for serving secrets to other tailnet machines
  # (only on hbohlen-01, not new servers)
}
```

**Note:** The tailscale authkey must be obtained once from 1Password and hardcoded in the flake. This is a one-time manual step when setting up a new machine.

## Bootstrap Service (Automatic)

**Location:** `nix/cells/nixos/modules/opnix-bootstrap.nix`

A systemd oneshot service runs on first boot to fetch the opnix token from setec:

```nix
{ config, pkgs, ... }:

{
  # ... tailscale config above ...

  # Bootstrap service: fetch opnix token from setec relay
  systemd.services.opnix-bootstrap = {
    description = "Fetch opnix token from setec relay and hydrate secrets";
    after = [ "network.target" "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c ''
        # Wait for Tailscale to be ready
        sleep 5

        # Fetch token from hbohlen-01 setec
        TOKEN=$(tailscale --host=setec setec get opnix-token 2>/dev/null || echo "")

        if [ -n \"$TOKEN\" ]; then
          # Store token
          echo \"$TOKEN\" > /etc/opnix-token
          chmod 600 /etc/opnix-token

          # Run nixos-rebuild to hydrate secrets
          # This runs in a subshell to avoid tearing down the network
          (
            export HOME=/root
            cd /root
            nixos-rebuild switch --flake .#default --target-host root@localhost --build-on-remote
          ) || true
        fi
      '';
    };
  };
}
```

**How it works:**
1. Service runs once on first boot (Type=oneshot, RemainAfterExit=yes)
2. Waits for Tailscale to connect
3. Uses `tailscale --host=setec` to talk to hbohlen-01's setec
4. Fetches `opnix-token` secret
5. Stores token at `/etc/opnix-token`
6. Triggers nixos-rebuild to fetch remaining secrets from 1Password

## Home Manager Module: opnix-ssh.nix

**Location:** `nix/cells/home/home-manager/opnix-ssh.nix`

```nix
{ config, pkgs, opnix, ... }:

{
  programs.onepassword-secrets = {
    enable = true;
    secrets = {
      sshPrivateKey = {
        reference = "op://hbohlen-systems/ssh/private_key";
        path = ".ssh/id_ed25519";
        mode = "0600";
      };
      sshPublicKey = {
        reference = "op://hbohlen-systems/ssh/public_key";
        path = ".ssh/id_ed25519.pub";
        mode = "0644";
      };
    };
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "*" = {
        extraOptions = {
          IdentityAgent = "%h/.ssh/agent.sock";
        };
      };
    };
  };
}
```

## New Machine Bootstrap Flow

```
┌──────────────────────────────────────────────────────────────┐
│ 1. Operator runs nixos-anywhere                              │
│    ./deploy-hetzner.sh new-server                            │
│                                                              │
│    Tailscale authkey is hardcoded in NixOS config            │
│    (one-time manual step: copy from 1Password)              │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│ 2. Server boots, Tailscale auto-connects                    │
│                                                              │
│    systemd service starts tailscaled                        │
│    tailscale up --authkey=<hardcoded-key>                   │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│ 3. opnix-bootstrap.service runs automatically                │
│                                                              │
│    - Waits for Tailscale (sleep 5)                          │
│    - tailscale --host=setec get opnix-token                 │
│    - Stores token at /etc/opnix-token                       │
│    - Triggers nixos-rebuild switch                          │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│ 4. opnix hydrates remaining secrets                         │
│                                                              │
│    - tailscale authkey refreshed from 1Password              │
│    - SSH keys written to ~/.ssh/                             │
│    - Home Manager activates with SSH agent                   │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│ 5. Server fully configured                                  │
│                                                              │
│    - Tailscale connected (verified)                         │
│    - SSH via Tailscale works                                │
│    - Secrets available from 1Password                       │
└──────────────────────────────────────────────────────────────┘
```

## 1Password Vault Structure

Required items in vault `hbohlen-systems`:

| Item Name | Field | Purpose |
|-----------|-------|---------|
| `opnix` | `token` | Service account token for opnix (served via setec) |
| `tailscale` | `authKey` | Tailscale auth key (hardcoded in NixOS config) |
| `ssh` | `private_key` | SSH private key (ED25519) |
| `ssh` | `public_key` | SSH public key |

## One-Time Steps for New Machine Setup

1. **Get tailscale authkey from 1Password** (manual):
   ```
   op read op://hbohlen-systems/tailscale/authKey
   ```
   Add to the NixOS config for the new machine.

2. **Update hbohlen-01 setec** (if token rotated):
   ```
   TOKEN="$(op read op://hbohlen-systems/opnix/token --no-newline)"
   tailscale setec put opnix-token "$TOKEN"
   ```

## Flake Updates Required

1. Add opnix input:
```nix
opnix = {
  url = "github:brizzbuzz/opnix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

2. Add to NixOS module imports in `nix/cells/nixos/default.nix`

3. Add home-manager input and configuration

## Out of Scope (Future Work)

- Full SSH agent integration with `op ssh-agent` (requires systemd user service)
- Automatic SSH hardening after Tailscale verification
- Homedir encryption for SSH keys at rest
- GPG key management via opnix
- Multi-user support (root vs. hbohlen user bootstrap)
- setec server configuration for NixOS module (hbohlen-01 uses existing setup)

## Verification Steps

1. After bootstrap, verify Tailscale connected:
   ```bash
   ssh root@NEW_SERVER_IP "tailscale status"
   ```

2. Verify opnix token was fetched:
   ```bash
   ssh root@NEW_SERVER_IP "cat /etc/opnix-token | head -c 20"
   ```

3. Verify SSH keys installed:
   ```bash
   ssh hbohlen@NEW_SERVER_IP "ls -la ~/.ssh/"
   ```

4. Test SSH via Tailscale:
   ```bash
   tailscale ssh hbohlen@NEW_SERVER_IP
   ```
