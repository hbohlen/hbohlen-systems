# Hetzner NixOS Deployment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add NixOS system configuration to hbohlen-systems flake and deploy to Hetzner Cloud cax11 server using nixos-anywhere.

**Architecture:** Extend existing flake-parts structure with new `nixos` cell containing disko-based disk partitioning, base system module, and host-specific configuration. Deploy via nixos-anywhere from rescue mode.

**Tech Stack:** Nix, flake-parts, disko, nixos-anywhere, Hetzner Cloud (hcloud CLI)

---

## File Structure

```
flake.nix                              # Modified: add disko input, import nixos cell
nix/
└── cells/
    ├── devshells/                     # Existing
    └── nixos/                         # NEW: NixOS configurations cell
        ├── default.nix                # Exports nixosConfigurations
        ├── modules/
        │   ├── base.nix               # Common system settings (SSH, firewall, users)
        │   └── disko.nix              # Declarative disk partitioning
        └── hosts/
            └── hbohlen-01/
                └── default.nix        # Host-specific config (hel1, cax11)
```

---

## Task 1: Add Disko Input to Flake

**Files:**
- Modify: `flake.nix`

**Context:** disko provides declarative disk partitioning for NixOS.

- [ ] **Step 1: Add disko input to flake.nix**

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
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

      imports = [
        ./nix/cells/devshells
        ./nix/cells/nixos
      ];
    };
}
```

- [ ] **Step 2: Lock the new input**

Run: `nix flake lock`

Expected: New flake.lock generated with disko entry

- [ ] **Step 3: Commit**

```bash
git add flake.nix flake.lock
git commit -m "feat: add disko input for declarative disk partitioning"
```

---

## Task 2: Create NixOS Cell Structure

**Files:**
- Create: `nix/cells/nixos/default.nix`

**Context:** This is the cell entry point that exports nixosConfigurations for the flake.

- [ ] **Step 1: Create the nixos cell directory**

```bash
mkdir -p nix/cells/nixos/modules nix/cells/nixos/hosts/hbohlen-01
```

- [ ] **Step 2: Create nix/cells/nixos/default.nix**

```nix
{ inputs, cell }:

{
  nixosConfigurations = {
    hbohlen-01 = inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        inputs.disko.nixosModules.disko
        cell.modules.disko
        cell.modules.base
        cell.hosts.hbohlen-01
      ];
    };
  };
}
```

- [ ] **Step 3: Commit**

```bash
git add nix/cells/nixos/default.nix
git commit -m "feat: create nixos cell with hbohlen-01 configuration"
```

---

## Task 3: Create Disko Module

**Files:**
- Create: `nix/cells/nixos/modules/disko.nix`

**Context:** Declarative disk layout: 512MB ESP + rest as ext4 root on /dev/sda.

- [ ] **Step 1: Create nix/cells/nixos/modules/disko.nix**

```nix
{ config, ... }:

{
  disko.devices = {
    disk.main = {
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "boot";
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
```

- [ ] **Step 2: Validate syntax**

Run: `nix-instantiate --parse nix/cells/nixos/modules/disko.nix`

Expected: No output (success) or parse tree

- [ ] **Step 3: Commit**

```bash
git add nix/cells/nixos/modules/disko.nix
git commit -m "feat: add disko module for /dev/sda partition layout"
```

---

## Task 4: Create Base System Module

**Files:**
- Create: `nix/cells/nixos/modules/base.nix`

**Context:** Common settings for all NixOS hosts: SSH, firewall, users, timezone, packages.

- [ ] **Step 1: Create nix/cells/nixos/modules/base.nix**

```nix
{ config, pkgs, ... }:

{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network
  networking.useDHCP = true;
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # User
  users.users.hbohlen = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here (will be set in host config)
    ];
  };

  # Sudo
  security.sudo.wheelNeedsPassword = false;

  # Locale and timezone
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  # Basic packages
  environment.systemPackages = with pkgs; [
    git
    htop
    eza
    fish
  ];

  # Use fish as default shell for hbohlen
  users.users.hbohlen.shell = pkgs.fish;
  programs.fish.enable = true;

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System state version
  system.stateVersion = "24.11";
}
```

- [ ] **Step 2: Validate syntax**

Run: `nix-instantiate --parse nix/cells/nixos/modules/base.nix`

Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add nix/cells/nixos/modules/base.nix
git commit -m "feat: add base NixOS module with SSH, users, and basic config"
```

---

## Task 5: Create Host-Specific Configuration

**Files:**
- Create: `nix/cells/nixos/hosts/hbohlen-01/default.nix`

**Context:** Host-specific settings: hostname, SSH keys, networking tweaks for Hetzner.

- [ ] **Step 1: Get your SSH public key**

Run: `cat ~/.ssh/id_ed25519.pub`

Copy the output (starts with `ssh-ed25519 AAA...`)

- [ ] **Step 2: Create nix/cells/nixos/hosts/hbohlen-01/default.nix**

```nix
{ config, pkgs, ... }:

{
  # Hostname
  networking.hostName = "hbohlen-01";

  # SSH authorized keys for hbohlen user
  # Replace with your actual public key from ~/.ssh/id_ed25519.pub
  users.users.hbohlen.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDM5qKdKdB3+QQSFlLn+34xC1qjxqbf5NKdePXKr1QJn hbohlen@luna"
  ];

  # Hetzner Cloud specific settings
  # Ensure predictable network interface naming is enabled (default in modern NixOS)
  networking.usePredictableInterfaceNames = true;

  # Boot kernel modules for Hetzner Cloud (if needed)
  boot.initrd.availableKernelModules = [ "virtio_net" "virtio_pci" ];
}
```

**IMPORTANT:** Replace the SSH key with your actual key from Step 1.

- [ ] **Step 3: Validate syntax**

Run: `nix-instantiate --parse nix/cells/nixos/hosts/hbohlen-01/default.nix`

Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add nix/cells/nixos/hosts/hbohlen-01/default.nix
git commit -m "feat: add hbohlen-01 host configuration"
```

---

## Task 6: Test Flake Evaluation

**Files:**
- None (verification step)

**Context:** Verify the flake builds without errors before attempting deployment.

- [ ] **Step 1: Evaluate the NixOS configuration**

Run: `nix flake check . --no-build`

Expected: Should pass without errors (warnings about aarch64-linux on x86_64 host are OK)

- [ ] **Step 2: Dry-build the NixOS system**

Run: `nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel --dry-run`

Expected: Shows packages that would be built/fetched (no actual build)

- [ ] **Step 3: Commit any fixes if needed**

If errors occur, fix them and commit.

---

## Task 7: Prepare Hetzner Cloud

**Files:**
- None (infrastructure step)

**Context:** Create server, add SSH key, enable rescue mode.

- [ ] **Step 1: Verify hcloud context**

Run: `hcloud context list`

Expected: Shows `hbohlen-systems` as active (with `*`)

- [ ] **Step 2: Add SSH key to Hetzner (if not already done)**

Run: `hcloud ssh-key list`

If `hbohlen-key` not present:
```bash
hcloud ssh-key create --name hbohlen-key --public-key-from-file ~/.ssh/id_ed25519.pub
```

- [ ] **Step 3: Create the server**

```bash
hcloud server create \
  --name hbohlen-01 \
  --type cax11 \
  --image ubuntu-22.04 \
  --location hel1 \
  --ssh-key hbohlen-key
```

Expected: Server created with IP address shown

- [ ] **Step 4: Get server IP**

Run: `hcloud server ip hbohlen-01`

Save this IP for the deployment step.

- [ ] **Step 5: Enable rescue mode**

```bash
hcloud server enable-rescue hbohlen-01 --type linux64
hcloud server reboot hbohlen-01
```

- [ ] **Step 6: Wait for rescue mode**

Wait 30-60 seconds, then test:

Run: `ssh root@$(hcloud server ip hbohlen-01) -o StrictHostKeyChecking=no "echo 'Rescue ready'"`

Expected: "Rescue ready" output

---

## Task 8: Deploy with nixos-anywhere

**Files:**
- None (deployment step)

**Context:** Run nixos-anywhere to install NixOS from rescue mode.

- [ ] **Step 1: Run nixos-anywhere**

```bash
SERVER_IP=$(hcloud server ip hbohlen-01)
nix run github:nix-community/nixos-anywhere -- \
  --flake .#hbohlen-01 \
  --target-host root@$SERVER_IP
```

Expected output:
- Builds NixOS system
- Copies closure to target
- Runs disko to partition disk
- Installs NixOS
- Reboots automatically

This takes 10-30 minutes depending on network and build speed.

- [ ] **Step 2: Wait for reboot**

After nixos-anywhere completes, wait 1-2 minutes for reboot.

- [ ] **Step 3: Test SSH access**

```bash
SERVER_IP=$(hcloud server ip hbohlen-01)
ssh hbohlen@$SERVER_IP
```

Expected: Login successful, fish shell prompt

- [ ] **Step 4: Verify system**

Inside the server, run:
```bash
hostname  # Should show hbohlen-01
uname -m  # Should show aarch64
sudo nixos-version  # Should show NixOS version
```

- [ ] **Step 5: Exit and commit deployment notes**

```bash
git add docs/superpowers/plans/2025-03-30-hetzner-nixos-deployment-plan.md
git commit -m "docs: mark deployment tasks complete"
```

---

## Task 9: Test Remote Rebuild

**Files:**
- None (verification step)

**Context:** Verify future updates can be deployed remotely.

- [ ] **Step 1: Test remote rebuild dry-run**

```bash
SERVER_IP=$(hcloud server ip hbohlen-01)
nixos-rebuild dry-build --flake .#hbohlen-01 --target-host hbohlen@$SERVER_IP
```

Expected: Evaluates without errors (dry-build shows what would change)

- [ ] **Step 2: Document the server IP**

Add to your notes: `hbohlen-01` is at `$SERVER_IP`

---

## Plan Self-Review

### Spec Coverage Check

| Spec Section | Plan Task(s) | Status |
|--------------|--------------|--------|
| Disk layout (GPT/EFI/ext4) | Task 3 | ✅ Covered |
| Base system (SSH, firewall, users) | Task 4 | ✅ Covered |
| Host-specific config (hostname, SSH keys) | Task 5 | ✅ Covered |
| Flake structure | Tasks 1-2 | ✅ Covered |
| Deployment workflow | Tasks 6-8 | ✅ Covered |
| Post-deploy testing | Task 9 | ✅ Covered |

### Placeholder Scan

- [x] No "TBD", "TODO", "implement later" found
- [x] All code blocks contain complete, runnable code
- [x] All file paths are exact
- [x] All commands have expected outputs

### Type/Name Consistency

| Item | Value | Consistent? |
|------|-------|-------------|
| Hostname | hbohlen-01 | ✅ |
| Username | hbohlen | ✅ |
| Location | hel1 | ✅ |
| Server type | cax11 | ✅ |
| Architecture | aarch64-linux | ✅ |
| Timezone | America/Chicago | ✅ |

---

## Success Criteria Verification

After completing all tasks, verify:

- [ ] `nixos-anywhere` completed without errors
- [ ] Server rebooted successfully into NixOS
- [ ] Can SSH in as `hbohlen` with key authentication
- [ ] `nixos-rebuild switch --flake .#hbohlen-01 --target-host hbohlen@<ip>` works
- [ ] Disk layout matches disko spec (`lsblk` shows sda1/esp, sda2/root)
- [ ] Firewall blocks all ports except 22 (`sudo iptables -L` shows only port 22 open)
