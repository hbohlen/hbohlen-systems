---
name: hetzner-nixos-redeploy-upgrade
description: Use when operating a Hetzner Cloud NixOS host after initial bring-up, especially when deciding between an in-place upgrade and a destructive redeploy, or when documenting caveats for future recovery.
tags: [nix, nixos, hetzner, deploy, upgrade, redeploy]
category: nix
metadata:
  author: hbohlen-systems implementation experience
  version: "1.0.0"
---

# Hetzner NixOS Redeploy and Upgrade

## Overview

Hetzner day-2 operations split into two very different paths:
1. in-place upgrade/config change
2. destructive redeploy/reinstall

Core principle: never use a reinstall script for normal upgrades, and never assume a successful install log means the machine actually booted.

## When to Use

Use when:
- a Hetzner NixOS server already exists and you need to change or recover it
- deciding between `nixos-rebuild switch` and `nixos-anywhere`/reinstall
- documenting or reviewing caveats before resizing, rebuilding, or redeploying a server
- preserving knowledge for future disaster recovery

Do not use this for generic local Nix flake development with no remote server involved.

## Quick Reference

### In-place upgrade
Use for:
- package updates
- service config changes
- most host module changes

Pattern:
```bash
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
nixos-rebuild switch --flake .#<host> --target-host <user>@<ip-or-hostname> --use-remote-sudo
```

### Full redeploy
Use for:
- broken bootloader or disk layout
- unrecoverable server
- intentional clean reinstall

Pattern:
```bash
./deploy-hetzner.sh
```

Warning: if the script deletes an existing server of the same name, it is a reinstall tool, not an upgrade tool.

## Hetzner Caveats Checklist

Before destructive redeploy:
- verify Hetzner server type exists
- verify Hetzner SSH key name exists
- verify type/location pair is valid
- verify flake target evaluates locally
- verify you really want to destroy the old server
- verify attached data/volumes/backups are accounted for

Common pitfalls seen in practice:
- `Server Type not found`
- `SSH Key not found`
- `unsupported location for server type`
- host key mismatch after recreate
- stale generated hardware config
- wrong disk device assumption (`/dev/sda`)
- install succeeds but server never returns after reboot

## Bootloader Rule for Hetzner x86

If firmware mode is uncertain, avoid EFI-only installs.

Prefer dual-mode GRUB:
```nix
boot.loader.grub.enable = true;
boot.loader.grub.device = "/dev/sda";
boot.loader.grub.efiSupport = true;
boot.loader.grub.efiInstallAsRemovable = true;
boot.loader.efi.canTouchEfiVariables = false;
boot.kernelParams = [ "console=ttyS0,115200n8" "console=tty1" ];
```

And in GPT disk layout include both:
- BIOS boot partition `EF02`
- EFI system partition `EF00`

Healthy reinstall logs often show both:
- `Installing for i386-pc platform.`
- `Installing for x86_64-efi platform.`

If install says success but SSH never comes back, suspect boot-mode mismatch before debugging sshd.

## nixos-anywhere Caveats

For scripted hardware generation or install:
- prefer absolute flake paths in scripts
- clear known hosts before SSH and nixos-anywhere runs
- if hardware generation fails around `nix.settings.substituters`, pass:
```bash
--no-use-machine-substituters
```
- fail explicitly if generated hardware config is missing or empty

## Upgrade vs Redeploy Decision

Use upgrade when:
- the server is reachable
- disk layout is unchanged
- bootloader assumptions are unchanged
- change can be applied by switching generations

Use redeploy when:
- SSH is dead and recovery is not worth it
- bootloader/disko changes are involved
- machine is misinstalled or unrecoverable
- you intentionally want a fresh server

## Recovery Flow When Machine Never Returns

1. confirm local flake still builds
2. confirm install log reached install + reboot
3. confirm Hetzner says machine is still running
4. boot machine into rescue mode
5. inspect partition table, boot files, fstab, enabled units, keys
6. distinguish userspace issue from boot failure

Strong boot-failure pattern:
- install success
- no SSH after reboot
- no useful journal
- files are on disk
- boot path does not match actual firmware mode

## Common Mistakes

- treating reinstall as a normal upgrade
- skipping a local `nix build` before touching the server
- forgetting to remove stale known_hosts entries after recreate
- assuming generated hardware config is timeless
- changing server class/architecture and assuming old boot/disk assumptions still apply
- trusting "installation finished" without verifying post-reboot SSH

## Verification Before Claiming Success

For upgrade:
```bash
ssh <user>@<host> 'hostname && systemctl is-active sshd'
```

For redeploy:
```bash
ssh root@<ip> 'hostname && uname -a'
ssh <user>@<ip> 'whoami && systemctl is-active sshd dhcpcd'
```

Only call the operation successful after fresh SSH verification on the final booted system.