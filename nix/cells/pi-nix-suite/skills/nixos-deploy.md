---
name: nixos-deploy
description: Deploy NixOS configuration to remote hosts
type: manual
category: deployment
tools: read, write, edit, bash
---

# NixOS Deploy

Deploy NixOS configurations to remote hosts using nixos-rebuild or deployment tools.

## When to Use

- Deploying system configuration changes
- Setting up new NixOS hosts
- Rolling back failed deployments
- Managing multiple NixOS machines

## Prerequisites

- SSH access to target host
- NixOS configuration in repository
- Proper secrets management (sops-nix or agenix)

## Workflow

### Local Deployment (same machine)

1. Check current configuration:
   ```bash
   nixos-rebuild dry-build --flake .#hostname
   ```

2. Build and switch:
   ```bash
   sudo nixos-rebuild switch --flake .#hostname
   ```

3. Verify:
   ```bash
   systemctl status
   nixos-version
   ```

### Remote Deployment

1. Build locally, copy closure:
   ```bash
   nixos-rebuild switch --flake .#hostname --target-host root@hostname
   ```

2. Or use deploy-rs:
   ```bash
   deploy .#hostname --hostname remote-host
   ```

## Rollback

If something goes wrong:
```bash
sudo nixos-rebuild switch --rollback
```

## Common Issues

- Build failures: Check `nix flake check` first
- SSH issues: Verify keys and host availability
- Disk space: Check `/nix/store` usage
- Boot issues: Check `boot.loader` configuration
