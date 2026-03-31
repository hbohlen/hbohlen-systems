---
name: nixos-remote-install
description: |
  Safely install or reinstall NixOS on a remote server without locking yourself out.
  Emphasizes SSH key verification, temporary fallbacks, and explicit approval gates.

triggers:
  - Installing NixOS on a remote server
  - nixos-anywhere or nixos-install on remote machine
  - Setting up NixOS with SSH-only access
  - Need to ensure SSH access after NixOS install
---

# NixOS Remote Installation with Safety Checks

## Safety-First Approach

This workflow prevents the #1 mistake in remote NixOS installs: **locking yourself out**.

### Prerequisites Check

```bash
# Verify current SSH access
ssh user@server "echo 'SSH works'"

# Check local SSH keys
ls -la ~/.ssh/
cat ~/.ssh/id_ed25519.pub
```

### Step 1: Prepare Configuration

**CRITICAL:** Write configs locally first, then copy to server. Remote heredocs often corrupt files.

```bash
# On local machine - prepare the flake
nix flake check .

# Create tarball to transfer
tar czf /tmp/nixos-config.tar.gz --exclude=.git --exclude=result .

# Copy to server (which has disks mounted at /mnt)
scp /tmp/nixos-config.tar.gz root@server:/mnt/root/
```

### Step 2: Verify SSH Keys Match

**BEFORE** running `nixos-install`, verify the SSH key in your config matches your actual key:

```bash
# Get key from config
grep "ssh-ed25519" /mnt/root/nix/cells/nixos/hosts/*/default.nix

# Compare with local key
cat ~/.ssh/id_ed25519.pub

# If they DON'T match - UPDATE THE CONFIG before proceeding
```

### Step 3: Add Temporary Password Fallback

Always set `initialPassword` for emergency console access:

```nix
# In your NixOS configuration
users.users.youruser = {
  isNormalUser = true;
  extraGroups = [ "wheel" ];
  openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3... your@key" ];
  initialPassword = "TEMP_PASSWORD_HERE";  # Remove after confirming SSH works
};

# Also set root password for emergency
users.users.root.initialPassword = "TEMP_PASSWORD_HERE";
```

Generate a random password:
```bash
openssl rand -base64 24 | tr -d "=+/" | cut -c1-20
```

### Step 4: Run Installation

```bash
# On the server (in installer environment)
cd /mnt/root
tar xzf nixos-config.tar.gz
nixos-install --flake .#hostname --no-root-passwd
```

### Step 4.5: Hetzner + nixos-anywhere preflight (critical)

When using Hetzner Cloud + `nixos-anywhere`, do these checks before creating/recreating servers:

```bash
# 1) Validate server type/location compatibility for YOUR account
hcloud server-type list -o columns=name,architecture | cat
hcloud location list | cat

# 2) Validate SSH key name exists in Hetzner project
hcloud ssh-key list -o columns=name,fingerprint | cat

# 3) Validate flake target actually exists
# (flake-parts usually exposes nixosConfigurations.<host>, not .#<host>)
nix eval .#nixosConfigurations.<host>.config.system.stateVersion
```

Important provider quirks found in practice:
- `hcloud server delete` does NOT support `-y`.
- Common "expected defaults" may not exist in your account/region (e.g., `cx31`, `hel1`, or a key name like `my-deploy-key`).
- Prefer script variables for `TYPE`, `LOCATION`, and `SSH_KEY_NAME`, and verify them before destructive operations.
- For scripted `nixos-anywhere` runs, prefer an absolute flake path like `"${REPO_ROOT}#host"` rather than relying on `.#...` from an implicit cwd.
- Hardware-generation runs can fail if nixos-anywhere tries to read destination substituter config from a flake that does not expose `nix.settings.substituters`; in that case pass `--no-use-machine-substituters`.

### Step 4.6: Hetzner bootloader choice (critical)

If the install target is Hetzner Cloud x86 and you are not 100% certain which firmware path the VM will use, avoid an EFI-only bootloader setup.

Prefer a dual-mode GRUB layout:

```nix
boot.loader.grub.enable = true;
boot.loader.grub.device = "/dev/sda";
boot.loader.grub.efiSupport = true;
boot.loader.grub.efiInstallAsRemovable = true;
boot.loader.efi.canTouchEfiVariables = false;
```

and in the GPT disk layout add both:
- a tiny BIOS boot partition (`EF02`)
- an EFI system partition (`EF00`)

This prevents the failure mode where `nixos-anywhere` reports success, the server reboots, and the VM never comes back on SSH because the OS was installed but not bootable in the firmware mode Hetzner presented.

### Step 5: Reboot with Safety Protocol

**NEVER reboot without testing access first.**

1. **Keep current terminal open** (your lifeline)
2. **Open second terminal**
3. **Test SSH** as the non-root user: `ssh user@server`
4. **Only then** reboot from first terminal:
   ```bash
   ssh root@server "reboot"
   ```
5. **Wait 30-60 seconds**, then test again in second terminal

### Step 6: Post-Install Hardening (Approval Gates)

After confirming access, remove temporary passwords:

```nix
# Remove these lines from configuration:
# users.users.youruser.initialPassword = "...";
# users.users.root.initialPassword = "...";

# Add proper security:
users.mutableUsers = false;  # Prevent password changes outside Nix
```

**Each hardening change requires explicit user approval:**
- Present the change
- User tests in second terminal
- Only then proceed to next change

## Common Pitfalls

1. **SSH key mismatch** - Config has old/wrong key → Locked out
2. **No recovery path** (password or console plan) - Key/auth issue → Locked out
3. **Corrupted config transfer** - Heredocs mangled syntax → Install fails
4. **Rebooting without testing** - SSH broken → Locked out
5. **Disabling root login before user works** → Locked out
6. **Invalid Hetzner type/location pair** - API rejects create (`unsupported location for server type`)
7. **Wrong Hetzner SSH key name** - API rejects create (`SSH Key not found`)
8. **Wrong flake output target** - `nix eval`/install fails (use `.#nixosConfigurations.<host>` when applicable)
9. **Using relative flake references in scripts** - hardware generation/install runs from the wrong cwd; prefer absolute flake paths
10. **Destination substituter lookup failure during hardware generation** - fix with `--no-use-machine-substituters`
11. **EFI-only bootloader on Hetzner x86** - install succeeds but server never returns after reboot; prefer dual-mode GRUB + EF02 BIOS partition
12. **Using unsupported hcloud flags** - e.g., `hcloud server delete -y` fails

## Verification Checklist

Before `nixos-install`:
- [ ] SSH key in config matches `~/.ssh/id_ed25519.pub`
- [ ] `initialPassword` set for both root and user
- [ ] `PermitRootLogin` will be disabled (verify non-root access works)
- [ ] Configuration validates: `nix flake check`

Before reboot:
- [ ] Second terminal open and ready
- [ ] Test command prepared: `ssh user@server`
- [ ] Temporary password noted

After reboot:
- [ ] SSH as non-root user works
- [ ] Password login works (test as fallback)
- [ ] `sudo` works for the user
- [ ] Remove temporary passwords from config
- [ ] Run `nixos-rebuild switch` to apply hardened config

## Emergency Recovery

If locked out:
1. Use Hetzner/DigitalOcean/etc. console access (VNC)
2. Login with temporary password
3. Fix SSH/config issues
4. Rebuild: `nixos-rebuild switch`

## Related Skills

- `nix-dendritic-pattern` - Project structure
- `nix-flake-devshell` - Local development environment