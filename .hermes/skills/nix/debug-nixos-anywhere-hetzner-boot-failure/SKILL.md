---
name: debug-nixos-anywhere-hetzner-boot-failure
description: Use when a nixos-anywhere deployment to Hetzner appears to install successfully, but the server never comes back on SSH after reboot, or when install logs show success but the VM stays unreachable.
---

# Debug nixos-anywhere Hetzner boot failure

## Overview

This is for the failure mode where nixos-anywhere finishes, writes disks, reports bootloader install success, and then the Hetzner Cloud server never becomes reachable again.

Core principle: separate "Nix config/build problem" from "installed system did not boot" before changing code.

## When to Use

Use when you see patterns like:
- `nixos-anywhere` reports install success
- bootloader install says success
- local `nix eval` / `nix build` works
- server stays `running` in `hcloud`, but SSH times out after reboot
- no clear userspace error is visible from the deploy host

Do not use this first for simple flake syntax/eval failures; fix those locally first.

## Quick Reference

1. Verify local flake builds
2. Confirm deploy log reached install + reboot
3. Verify server is running but SSH dead
4. Boot failed machine into Hetzner rescue mode
5. Mount installed filesystems, including Btrfs subvolumes if used
6. Inspect boot artifacts, fstab, enabled units, keys
7. Decide whether failure is bootloader/firmware mismatch vs network/userspace config

## Procedure

### 1. Prove the config itself builds

Run in the repo/worktree:

```bash
nix eval .#nixosConfigurations.<host>.config.system.stateVersion
nix build .#nixosConfigurations.<host>.config.system.build.toplevel --no-link
```

If this fails, stop. The issue is still local config/build, not a post-install boot failure.

### 2. Read the deploy log for the exact phase reached

Look for evidence that install actually completed, e.g.:
- `Installing for x86_64-efi platform.`
- `Installation finished. No error reported.`
- `installation finished!`

Also grep for earlier failed attempts that may reveal script issues:
- `FAIL at STEP`
- `aborted:`
- `error:`

Important: separate earlier script failures from the final failing attempt.

### 3. Confirm runtime symptom from Hetzner side

```bash
hcloud server describe <name>
ssh root@<ip>
```

Key pattern:
- `hcloud` says server is `running`
- SSH times out completely

That usually points to machine not reaching a usable booted state, not merely bad sshd config.

### 4. Boot into Hetzner rescue mode

Use rescue to inspect the installed disk without destroying evidence:

```bash
hcloud server enable-rescue --ssh-key <key-name> <name>
hcloud server poweroff <name>
hcloud server poweron <name>
ssh root@<ip>
```

## 5. Inspect disks and mount the installed system

First inspect block devices:

```bash
lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT,PARTLABEL
blkid
```

If Btrfs subvolumes are used, mount both top-level and the real root subvolume:

```bash
mount -o subvolid=5 /dev/sda2 /mnt/btrfs-top
btrfs subvolume list /mnt/btrfs-top
mount -o subvol=root /dev/sda2 /mnt/root
mount /dev/sda1 /mnt/root/boot
mount -o subvol=nix /dev/sda2 /mnt/root/nix
mount -o subvol=var /dev/sda2 /mnt/root/var
mount -o subvol=home /dev/sda2 /mnt/root/home
mount -o subvol=tmp /dev/sda2 /mnt/root/tmp
```

If you skip mounting subvolumes, `/etc/static` and store references can look broken when they are actually fine.

## 6. Inspect the installed boot and system artifacts

Check:
- boot partition contents
- generated `fstab`
- generated `hostname`
- final `sshd_config`
- enabled units (`dhcpcd`, `sshd`, etc.)
- authorized keys

Useful commands:

```bash
find /mnt/root/boot -maxdepth 4 -type f | sort | sed -n '1,120p'
cat /mnt/root/nix/store/*-etc-fstab
cat /mnt/root/nix/store/*-etc-hostname
sed -n '1,220p' /mnt/root/nix/store/*-sshd.conf-final
find /mnt/root/nix/store/*-system-units -maxdepth 3 | grep -E 'dhcpcd|sshd|network'
```

If journal files exist:

```bash
find /mnt/root/var/log/journal -maxdepth 3 -type f
journalctl --directory=/mnt/root/var/log/journal -n 200
```

Note: on early boot failure there may be no journal at all.

## 7. Interpret the evidence

### Case A: userspace/network issue

Signs:
- installed system files look complete
- bootloader type matches expected firmware mode
- journal exists and shows normal boot progress
- sshd or networking config is missing/bad

Then inspect sshd, authorized keys, DHCP/network config, firewall.

### Case B: bootloader/firmware mismatch

Signs:
- install succeeded fully
- server never returns on SSH
- no useful journal from installed system
- boot artifacts show EFI-only installation like:
  - GRUB installed for `x86_64-efi`
  - EFI partition exists
  - no BIOS boot partition / no BIOS-targeted install
- Hetzner VM appears running but never reaches userspace

This is a strong sign the installed OS never booted successfully.

## Common Hetzner-specific pitfall discovered

If the configuration is EFI-only:

```nix
boot.loader.grub.enable = true;
boot.loader.grub.efiSupport = true;
boot.loader.grub.device = "nodev";
boot.loader.efi.canTouchEfiVariables = false;
```

and the install log says:

```text
Installing for x86_64-efi platform.
```

but the VM never returns after reboot, suspect boot-mode mismatch before changing ssh/network settings.

In this failure mode, the system may be fully installed on disk, with valid `fstab`, enabled `dhcpcd`, enabled `sshd`, and correct keys, yet still never boot far enough to open SSH.

### Proven fix

Use a dual-mode GRUB install so the image can boot whether Hetzner presents EFI or legacy BIOS:

```nix
# base.nix
boot.loader.grub.enable = true;
boot.loader.grub.device = "/dev/sda";
boot.loader.grub.efiSupport = true;
boot.loader.grub.efiInstallAsRemovable = true;
boot.loader.efi.canTouchEfiVariables = false;
boot.kernelParams = [ "console=ttyS0,115200n8" "console=tty1" ];
```

```nix
# disko.nix (GPT)
partitions = {
  bios = {
    size = "1M";
    type = "EF02";
  };
  boot = {
    size = "512M";
    type = "EF00";
    content = {
      type = "filesystem";
      format = "vfat";
      mountpoint = "/boot";
    };
  };
  # root ...
};
```

Healthy install logs after this fix typically show both:

```text
Installing for i386-pc platform.
Installing for x86_64-efi platform.
```

If those appear and the box comes back on SSH, you have strong confirmation the issue was boot-mode mismatch, not userspace networking.

## Common Mistakes

- Treating a successful install log as proof the OS booted
- Debugging sshd first when port 22 never opens at all
- Forgetting to mount Btrfs subvolumes, making `/etc/static` symlinks appear broken
- Mixing earlier failed deploy attempts with the final failing attempt in the log
- Rebuilding config locally forever without checking the installed disk in rescue mode

## Outcome

After this workflow, you should be able to say one of two things with evidence:
1. "The Nix config is fine; the installed machine likely fails before userspace due to bootloader/firmware mismatch."
2. "The machine boots, but networking/sshd/keys are misconfigured in userspace."
