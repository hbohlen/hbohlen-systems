# Hetzner Cloud NixOS Deployment Design

**Date:** 2025-03-30
**Status:** Approved
**Goal:** Deploy NixOS to a Hetzner Cloud cax11 server using nixos-anywhere with declarative disk partitioning.

---

## 1. Architecture Overview

Deploy NixOS (aarch64-linux) to a Hetzner Cloud cax11 server using nixos-anywhere with declarative disk partitioning via disko.

### Components

| Component | Purpose |
|-----------|---------|
| Flake extension | Add `nixosConfigurations` output to existing hbohlen-systems flake |
| Disko module | Declarative disk layout (GPT → EFI partition + root partition with ext4) |
| NixOS system config | Basic services (SSH, firewall), user account, SSH keys |
| nixos-anywhere | Deploys from local machine to fresh Hetzner server |
| Hetzner bootstrap | Rescue mode provides environment for initial install |

### Data Flow

```
Your laptop → nixos-anywhere → Hetzner Rescue (kexec) → NixOS install → Reboot → Running NixOS
```

### Server Specs

- **Type:** cax11 (ARM, 2 cores, 4GB RAM, 40GB disk)
- **Location:** hel1 (Helsinki)
- **Architecture:** aarch64-linux
- **Cost:** ~€3.29/month

---

## 2. Flake Structure

### New Files

```
nix/
└── cells/
    └── nixos/
        ├── default.nix          # Exports nixosConfigurations
        ├── modules/
        │   ├── base.nix         # Common system settings
        │   └── disko.nix        # Disk partitioning config
        └── hosts/
            └── hbohlen-01/
                └── default.nix  # Host-specific config
```

### Flake.nix Changes

- Add `disko` input for declarative partitioning
- Import the nixos cell
- `aarch64-linux` already supported in systems list

---

## 3. System Configuration

### Disk Layout (modules/disko.nix)

- **Device:** `/dev/sda` (Hetzner's standard disk)
- **Partition 1:** 512MB EFI System Partition (FAT32)
- **Partition 2:** Remainder (~39.5GB) as root (ext4)

### Base System (modules/base.nix)

| Setting | Value |
|---------|-------|
| SSH | Enabled, key-only auth, port 22 |
| Firewall | Allow SSH only |
| User | hbohlen |
| Sudo | Passwordless sudo for user |
| Timezone | America/Chicago |
| Locale | en_US.UTF-8 |
| Basic packages | git, htop, eza, fish |

### Host-Specific (hosts/hbohlen-01/default.nix)

| Setting | Value |
|---------|-------|
| Hostname | hbohlen-01 |
| Bootloader | systemd-boot (UEFI) |
| Network | DHCP (Hetzner's standard) |

---

## 4. Deployment Workflow

### Prerequisites (One-Time)

1. Generate SSH key pair if needed:
   ```bash
   ssh-keygen -t ed25519 -C "hbohlen@hetzner"
   ```

2. Add SSH public key to Hetzner Cloud:
   ```bash
   # Find your SSH key (usually ~/.ssh/id_ed25519.pub or ~/.ssh/id_rsa.pub)
   ls ~/.ssh/*.pub
   
   # Add it to Hetzner (replace with your actual key path)
   hcloud ssh-key create --name hbohlen-key --public-key-from-file ~/.ssh/id_ed25519.pub
   ```

### Deployment Steps

1. Create the server:
   ```bash
   hcloud server create \
     --name hbohlen-01 \
     --type cax11 \
     --image ubuntu-22.04 \
     --location hel1 \
     --ssh-key hbohlen-key
   ```

2. Enable rescue mode and reboot:
   ```bash
   hcloud server enable-rescue hbohlen-01 --type linux64
   hcloud server reboot hbohlen-01
   sleep 30  # Wait for rescue to come up
   ```

3. Deploy with nixos-anywhere (no installation needed, runs via nix):
   ```bash
   SERVER_IP=$(hcloud server ip hbohlen-01)
   nix run github:nix-community/nixos-anywhere -- \
     --flake .#hbohlen-01 \
     --target-host root@$SERVER_IP
   ```

4. Server reboots automatically. Verify access (ssh as hbohlen):
   ```bash
   ssh hbohlen@$SERVER_IP
   ```

### Post-Deploy Management

Future configuration changes:
```bash
nixos-rebuild switch --flake .#hbohlen-01 --target-host hbohlen-01
```

---

## 5. Success Criteria

- [ ] `nixos-anywhere` completes without errors
- [ ] Server reboots successfully into NixOS
- [ ] Can SSH in as user with key authentication
- [ ] `nixos-rebuild switch` works for future updates
- [ ] Disk layout matches disko specification
- [ ] Firewall blocks all ports except SSH

---

## 6. Future Extensions (Out of Scope)

These are noted but NOT part of this deployment:

- Reverse proxy (nginx/caddy) for web services
- Secrets management (sops-nix or agenix)
- Automated backups
- Monitoring/logging
- Additional services (containers, databases)
- DNS/configuration management

---

## 7. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Rescue mode SSH fails | Verify SSH key uploaded correctly, wait 60s after reboot |
| nixos-anywhere network issues | Retry deployment; check Hetzner firewall rules |
| Wrong disk device | Verify `/dev/sda` exists in rescue mode before deploy |
| aarch64 build issues | Use binary cache, verify flake supports aarch64-linux |

---

## 8. References

- [nixos-anywhere documentation](https://github.com/nix-community/nixos-anywhere)
- [disko documentation](https://github.com/nix-community/disko)
- [Hetzner Cloud CLI docs](https://hcloud-cli.readthedocs.io/)
