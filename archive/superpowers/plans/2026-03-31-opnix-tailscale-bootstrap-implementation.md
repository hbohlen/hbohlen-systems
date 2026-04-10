# OpNix + Tailscale Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Tailscale + opnix + 1Password CLI to hbohlen-systems NixOS config, enabling minimal-bootstrap new server deployment via setec relay.

**Architecture:** Add opnix as flake input. Create `opnix-bootstrap.nix` module that adds Tailscale with hardcoded authkey, 1password-cli, and a systemd oneshot service that fetches the opnix token from hbohlen-01's setec relay. Home Manager module fetches SSH keys from 1Password via opnix.

**Tech Stack:** NixOS, opnix (github:brizzbuzz/opnix), Tailscale setec, Home Manager, 1Password CLI

---

## File Map

```
flake.nix                                    # Add opnix + home-manager inputs
nix/cells/nixos/default.nix                  # Import opnix-bootstrap module
nix/cells/nixos/modules/opnix-bootstrap.nix  # Create: Tailscale + 1password-cli + bootstrap service
nix/cells/home/default.nix                   # Create: HM config for hbohlen user
nix/cells/home/programs/opnix-ssh.nix        # Create: SSH keys from opnix
```

---

## Task 1: Add opnix to flake + empty module

**Files:**
- Modify: `flake.nix:1-26`
- Create: `nix/cells/nixos/modules/opnix-bootstrap.nix`
- Modify: `nix/cells/nixos/default.nix:1-17`

- [ ] **Step 1: Add opnix input to flake.nix**

```nix
{
  description = "hbohlen-systems - dendritic personal infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opnix = {
      url = "github:brizzbuzz/opnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
```

- [ ] **Step 2: Create empty opnix-bootstrap.nix**

```nix
# Tailscale + opnix bootstrap module
{ config, pkgs, ... }:

{
  # Placeholder - will be filled in subsequent tasks
}
```

- [ ] **Step 3: Import opnix-bootstrap in nixos/default.nix**

```nix
{ inputs, ... }:
{
  flake.nixosConfigurations = {
    hbohlen-01 = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        inputs.disko.nixosModules.disko
        ./modules/disko.nix
        ./modules/base.nix
        ./modules/ssh-hardening.nix
        ./modules/tailscale-enhanced.nix
        ./modules/fail2ban.nix
        ./modules/opnix-bootstrap.nix  # ADD THIS
        ./hosts/hbohlen-01/default.nix
      ];
    };
  };
}
```

- [ ] **Step 4: Verify it builds**

Run: `nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel`
Expected: BUILD SUCCESS

- [ ] **Step 5: Commit**

```bash
git add flake.nix nix/cells/nixos/default.nix nix/cells/nixos/modules/opnix-bootstrap.nix
git commit -m "feat(nixos): add opnix input and empty bootstrap module"
```

---

## Task 2: Add Tailscale authkey (one-time manual)

**Files:**
- Modify: `nix/cells/nixos/modules/opnix-bootstrap.nix`

- [ ] **Step 1: Read tailscale authkey from 1Password** (manual step)

```bash
op read op://hbohlen-systems/tailscale/authKey
```

Copy the output. This is the one-time manual step for each new machine.

- [ ] **Step 2: Update opnix-bootstrap.nix with authkey**

```nix
# Tailscale + opnix bootstrap module
{ config, pkgs, ... }:

let
  # ONE-TIME MANUAL: Get this from: op read op://hbohlen-systems/tailscale/authKey
  tailscaleAuthKey = "tskey-auth-kJ1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ-1234567890ABCDEFGHIJKLMNOPQRSTUV";
  tailscaleTags = "tag:server,tag:prod";
in
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "server";
    extraUpFlags = [
      "--ssh"
      "--advertise-tags=${tailscaleTags}"
      "--authkey=${tailscaleAuthKey}"
    ];
  };

  systemd.services.tailscale.wantedBy = [ "multi-user.target" ];
}
```

- [ ] **Step 3: Verify it builds**

Run: `nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel`
Expected: BUILD SUCCESS

- [ ] **Step 4: Deploy and verify Tailscale connects**

Run: `nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel && nixos-rebuild switch --target-host root@hbohlen-01 --build-on-remote`

Then SSH to hbohlen-01 and run:
```bash
tailscale status
```
Expected: Shows hbohlen-01 as connected node

- [ ] **Step 5: Commit**

```bash
git add nix/cells/nixos/modules/opnix-bootstrap.nix
git commit -m "feat(nixos): add Tailscale with hardcoded authkey"
```

---

## Task 3: Add 1password-cli to system packages

**Files:**
- Modify: `nix/cells/nixos/modules/opnix-bootstrap.nix`

- [ ] **Step 1: Add 1password-cli to systemPackages**

```nix
  environment.systemPackages = with pkgs; [
    tailscale
    _1password-cli
  ];
```

Full file:

```nix
# Tailscale + opnix bootstrap module
{ config, pkgs, ... }:

let
  # ONE-TIME MANUAL: Get this from: op read op://hbohlen-systems/tailscale/authKey
  tailscaleAuthKey = "tskey-auth-kJ1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ-1234567890ABCDEFGHIJKLMNOPQRSTUV";
  tailscaleTags = "tag:server,tag:prod";
in
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "server";
    extraUpFlags = [
      "--ssh"
      "--advertise-tags=${tailscaleTags}"
      "--authkey=${tailscaleAuthKey}"
    ];
  };

  systemd.services.tailscale.wantedBy = [ "multi-user.target" ];

  environment.systemPackages = with pkgs; [
    tailscale
    _1password-cli
  ];
}
```

- [ ] **Step 2: Verify it builds**

Run: `nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel`
Expected: BUILD SUCCESS

- [ ] **Step 3: Deploy and verify op CLI**

Run: `nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel && nixos-rebuild switch --target-host root@hbohlen-01 --build-on-remote`

Then SSH to hbohlen-01 and run:
```bash
op --version
```
Expected: `2.x.x` or similar version output

- [ ] **Step 4: Commit**

```bash
git add nix/cells/nixos/modules/opnix-bootstrap.nix
git commit -m "feat(nixos): add 1password-cli to system packages"
```

---

## Task 4: Add setec bootstrap service on hbohlen-01

**Files:**
- Modify: `nix/cells/nixos/modules/opnix-bootstrap.nix`

- [ ] **Step 1: Add opnix-bootstrap systemd service**

Replace the module content with:

```nix
# Tailscale + opnix bootstrap module
{ config, pkgs, ... }:

let
  # ONE-TIME MANUAL: Get this from: op read op://hbohlen-systems/tailscale/authKey
  tailscaleAuthKey = "tskey-auth-kJ1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ-1234567890ABCDEFGHIJKLMNOPQRSTUV";
  tailscaleTags = "tag:server,tag:prod";
in
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "server";
    extraUpFlags = [
      "--ssh"
      "--advertise-tags=${tailscaleTags}"
      "--authkey=${tailscaleAuthKey}"
    ];
  };

  systemd.services.tailscale.wantedBy = [ "multi-user.target" ];

  environment.systemPackages = with pkgs; [
    tailscale
    _1password-cli
  ];

  # Bootstrap service: fetch opnix token from setec relay on hbohlen-01
  systemd.services.opnix-bootstrap = {
    description = "Fetch opnix token from setec relay and hydrate secrets";
    after = [ "network.target" "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeScript "opnix-bootstrap.sh" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail

        # Wait for Tailscale to be ready
        sleep 10

        # Fetch token from hbohlen-01 setec relay
        TOKEN=$(tailscale --host=setec setec get opnix-token 2>/dev/null || echo "")

        if [ -n "$TOKEN" ]; then
          echo "$TOKEN" > /etc/opnix-token
          chmod 600 /etc/opnix-token
          echo "opnix token fetched and stored"
        else
          echo "WARNING: Could not fetch opnix token from setec relay"
        fi
      '';
    };
  };
}
```

- [ ] **Step 2: Verify it builds**

Run: `nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel`
Expected: BUILD SUCCESS

- [ ] **Step 3: Deploy and verify service exists**

Run: `nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel && nixos-rebuild switch --target-host root@hbohlen-01 --build-on-remote`

Then SSH to hbohlen-01 and run:
```bash
systemctl status opnix-bootstrap
```
Expected: `active (exited)` or similar

- [ ] **Step 4: Check if token was fetched**

Run on hbohlen-01:
```bash
cat /etc/opnix-token | head -c 20
```
Expected: Shows first 20 chars of token (or empty if setec not configured)

- [ ] **Step 5: Commit**

```bash
git add nix/cells/nixos/modules/opnix-bootstrap.nix
git commit -m "feat(nixos): add opnix-bootstrap systemd service"
```

---

## Task 5: Add Home Manager SSH keys via opnix

**Files:**
- Modify: `flake.nix`
- Create: `nix/cells/home/default.nix`
- Create: `nix/cells/home/programs/opnix-ssh.nix`
- Modify: `nix/cells/nixos/modules/opnix-bootstrap.nix` (add home-manager module import)

- [ ] **Step 1: Add home-manager input to flake.nix**

```nix
    opnix = {
      url = "github:brizzbuzz/opnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

- [ ] **Step 2: Create nix/cells/home/default.nix**

```nix
{ inputs, ... }:

{
  flake.homeConfigurations.hbohlen = inputs.home-manager.lib.homeManagerConfiguration {
    system = "x86_64-linux";
    homeDirectory = "/home/hbohlen";
    username = "hbohlen";
    modules = [
      ./programs/opnix-ssh.nix
    ];
  };
}
```

- [ ] **Step 3: Create nix/cells/home/programs/opnix-ssh.nix**

```nix
# SSH keys fetched from 1Password via opnix
{ config, pkgs, ... }:

{
  # Note: opnix integration requires OP_SERVICE_ACCOUNT_TOKEN
  # This is set via the opnix-bootstrap service in the NixOS module

  programs.ssh = {
    enable = true;
    extraConfig = ''
      # Use SSH agent socket
      IdentityAgent ~/.ssh/agent.sock
    '';
  };

  # Placeholder - actual opnix secrets will be configured once
  # the bootstrap service sets the token
  home.sessionVariables = {
    OP_SERVICE_ACCOUNT_TOKEN_FILE = "/etc/opnix-token";
  };
}
```

- [ ] **Step 4: Import home-manager module in hbohlen-01 host config**

Modify `nix/cells/nixos/hosts/hbohlen-01/default.nix`:

```nix
{ lib, inputs, ... }:

let
  deployKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICP6MnCIoDGFnx42wAmVgoNxaHxEtRnOF10d3q/xOIZG hbohlen@hetzner";
in
{
  imports = lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  # Hostname
  networking.hostName = "hbohlen-01";

  # SSH authorized keys for root and hbohlen
  users.users.root.openssh.authorizedKeys.keys = [ deployKey ];
  users.users.hbohlen.openssh.authorizedKeys.keys = [ deployKey ];

  # Home Manager
  imports = [ inputs.home-manager.nixosModules.default ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.hbohlen = import ../../home/programs/opnix-ssh.nix;

  # Hetzner Cloud specific settings
  networking.usePredictableInterfaceNames = true;
  boot.initrd.availableKernelModules = [
    "virtio_net"
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
  ];
}
```

**Note:** The home-manager import style may need adjustment based on how flake-parts handles it. If the above causes build errors, use this alternative in `default.nix`:

```nix
{ inputs, ... }:
{
  # home-manager is managed via its own flake output
  # The hbohlen home config is built via: nix build .#homeConfigurations.hbohlen.activationPackage
}
```

And update the host's default.nix to remove the HM imports for now.

- [ ] **Step 5: Verify it builds**

Run: `nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel`
Expected: BUILD SUCCESS (may need iteration on HM import style)

- [ ] **Step 6: Commit**

```bash
git add flake.nix nix/cells/home nix/cells/nixos/hosts/hbohlen-01/default.nix
git commit -m "feat(home): add home-manager and SSH key placeholder"
```

---

## Task 6: Full integration test on hbohlen-01

**Files:**
- None (all changes already made)

- [ ] **Step 1: Ensure hbohlen-01 setec is serving the opnix token**

On hbohlen-01 (or wherever op CLI is signed in):
```bash
TOKEN="$(op read op://hbohlen-systems/opnix/token --no-newline)"
tailscale setec put opnix-token "$TOKEN"
tailscale setec status
```
Expected: Shows `opnix-token` secret

- [ ] **Step 2: Rebuild hbohlen-01 with all changes**

Run: `nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel && nixos-rebuild switch --target-host root@hbohlen-01 --build-on-remote`

- [ ] **Step 3: Verify Tailscale connected**

On hbohlen-01:
```bash
tailscale status
```
Expected: Shows hbohlen-01 as "Connected"

- [ ] **Step 4: Verify opnix-bootstrap ran**

On hbohlen-01:
```bash
systemctl status opnix-bootstrap
cat /etc/opnix-token | wc -c  # Should be > 0
```
Expected: Service active, token file has content

- [ ] **Step 5: Verify 1password-cli works**

On hbohlen-01:
```bash
op --version
```
Expected: Version output

- [ ] **Step 6: Commit with all changes**

```bash
git add -A
git commit -m "feat: complete Tailscale + opnix bootstrap on hbohlen-01"
```

---

## Verification Checklist

After all tasks complete:

- [ ] `nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel` succeeds
- [ ] `tailscale status` shows hbohlen-01 connected
- [ ] `systemctl status opnix-bootstrap` shows active
- [ ] `/etc/opnix-token` exists and has content
- [ ] `op --version` returns version
- [ ] Home Manager builds without error (if HM integration completed)

---

## Dependencies

- Task 2 requires Task 1 (opnix input must exist)
- Task 3 requires Task 2 (authkey flow)
- Task 4 requires Task 3 (1password-cli available)
- Task 5 can run in parallel with Tasks 1-4 but must deploy after them
- Task 6 requires all previous tasks

---

## Out of Scope

- setec server configuration (assumed running on hbohlen-01)
- opnix token rotation
- SSH agent systemd user service
- New machine deployment (this plan focuses on hbohlen-01 as test bed)
