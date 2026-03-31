# Hetzner NixOS Redeploy and Upgrade Runbook

Date: 2026-03-31
Status: Verified against a successful live deployment from this worktree
Scope: Day-2 operations for `hbohlen-01` on Hetzner Cloud

## 1. Two different operations

Do not treat these as the same thing.

### A. In-place upgrade / config change
Use this when:
- you changed NixOS configuration
- you want to update packages
- you want to move to a new generation without replacing the VM

This should preserve the existing server and disk.

Recommended pattern:
```bash
nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel
nixos-rebuild switch --flake .#hbohlen-01 --target-host hbohlen@<server-ip> --use-remote-sudo
```

### B. Full redeploy / reinstall
Use this when:
- bootloader or disk layout is broken
- you want a clean reinstall
- the machine is unrecoverable over SSH
- you intentionally want to recreate the server

This is destructive.

Recommended command:
```bash
./deploy-hetzner.sh
```

Important: `deploy-hetzner.sh` deletes any existing server with the same name before recreating it.

## 2. Current known-good deployment shape

Verified successful on 2026-03-31.

Server settings:
- Name: `hbohlen-01`
- Type: `cpx32`
- Location: `hel1`
- Image: `ubuntu-24.04`
- Hetzner SSH key name: `hbohlen-key`

Flake target:
- `#hbohlen-01`
- eval target: `#nixosConfigurations.hbohlen-01`

Disk / boot shape:
- GPT disk on `/dev/sda`
- tiny BIOS boot partition: `EF02`
- EFI partition: `EF00`
- Btrfs root with subvolumes:
  - `/`
  - `/nix`
  - `/home`
  - `/var`
  - `/tmp`
- GRUB installed in dual-mode:
  - BIOS install to `/dev/sda`
  - EFI install to `/boot`
  - `efiInstallAsRemovable = true`

Why dual-mode matters:
- the earlier EFI-only install completed but the VM never came back after reboot
- dual-mode GRUB fixed this
- treat bootloader/firmware mismatch as the highest-risk Hetzner caveat

## 3. Caveats that bit us already

### 1. Wrong Hetzner server type names fail immediately
Seen in log:
- `Server Type not found: cx31`

Use:
- `cpx32`

Not:
- `cx31`

### 2. Wrong SSH key name fails immediately
Seen in log:
- `SSH Key not found: my-deploy-key`

Use:
- `hbohlen-key`

### 3. Some server types are not available in some locations
Seen in log:
- `unsupported location for server type`

Do not assume every Hetzner type is available in every location.
If changing `TYPE` or `LOCATION`, verify them together before a real deploy.

### 4. EFI-only boot was not enough
The install succeeded but the server never returned on SSH.

Fix that worked:
- BIOS boot partition `EF02`
- GRUB install to `/dev/sda`
- keep EFI support
- `efiInstallAsRemovable = true`

If the server installs but never comes back, suspect boot mode mismatch first.

### 5. nixos-anywhere hardware generation was flaky until the script used an absolute flake path
Older failures included:
- `aborted: --flake or --store-paths must be set`
- errors around `nix.settings.substituters`

Current stable pattern in `deploy-hetzner.sh`:
- use absolute repo-root flake path
- pass `--no-use-machine-substituters`
- fail if generated hardware file is missing or empty

### 6. Known-host cleanup matters
This workflow recreates the VM at the same IP.

Always clear stale host keys before:
- manual SSH checks
- each nixos-anywhere call

Pattern used by script:
```bash
ssh-keygen -R <ip>
```

If you forget this, you can misdiagnose host-key mismatch as a deployment failure.

### 7. `deploy-hetzner.sh` is a reinstall tool, not an upgrade tool
It will delete the server if the same name already exists.
Use `nixos-rebuild switch` for normal changes.

### 8. `hardware-configuration.nix` is generated from the live machine
Path:
- `nix/cells/nixos/hosts/hbohlen-01/hardware-configuration.nix`

Implications:
- if server type changes, generated hardware details may change
- if the file is stale, you may carry the wrong assumptions into later deploys
- review diffs if you change server class or storage assumptions

### 9. Disk device is assumed to be `/dev/sda`
This is encoded in the disko module.
If Hetzner ever changes the presented device name, redeploy will be dangerous or fail.
Before major infrastructure changes, verify the target disk name from rescue or installer context.

### 10. Build strategy matters
Current install path uses:
- `--build-on-remote`

Implications:
- target machine needs enough RAM / network / cache access during install
- failures here may be cache/network/resource related, not config related

## 4. Safe workflow for normal config changes

From this worktree or repo root:
```bash
nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel
nixos-rebuild switch --flake .#hbohlen-01 --target-host hbohlen@<server-ip> --use-remote-sudo
```

Afterward verify:
```bash
ssh hbohlen@<server-ip> 'hostname && systemctl is-active sshd dhcpcd'
```

Use this for:
- package changes
- service config changes
- user config changes
- most host module edits

Avoid using this blindly for:
- disko layout changes
- major bootloader changes
- filesystem migration work

Those are closer to reinstall territory.

## 5. Safe workflow for full redeploy

### Before redeploying
Checklist:
- confirm you really want a destructive recreate
- confirm no data on the current VM needs saving
- confirm `hcloud` auth works
- confirm `hbohlen-key` still exists in Hetzner
- confirm desired `TYPE` and `LOCATION`
- review pending changes to:
  - `deploy-hetzner.sh`
  - `nix/cells/nixos/modules/base.nix`
  - `nix/cells/nixos/modules/disko.nix`
  - host module / hardware config

Recommended pre-checks:
```bash
hcloud context active
hcloud ssh-key describe hbohlen-key
nix eval .#nixosConfigurations.hbohlen-01.config.boot.loader.grub.device
nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel --no-link
bash -n deploy-hetzner.sh
```

### Run the redeploy
```bash
./deploy-hetzner.sh
```

### After redeploying
Verify both accounts:
```bash
ssh root@<server-ip> 'hostname && uname -a'
ssh hbohlen@<server-ip> 'whoami && hostname && systemctl is-active sshd dhcpcd'
```

## 6. Recovery path if the machine does not come back

If install appears to succeed but SSH never returns:
1. suspect boot failure first
2. check Hetzner server status with `hcloud server describe`
3. enable rescue mode and reboot into rescue
4. inspect:
   - partition table
   - presence of BIOS boot partition + EFI partition
   - `/boot/grub/grub.cfg`
   - whether NixOS filesystems/subvolumes exist
5. compare against the known-good dual-mode layout above

Strong signal of bootloader mismatch:
- install logs say success
- machine remains `running`
- port 22 never comes back
- rescue inspection shows files on disk but no usable boot path

## 7. Upgrading server size or class later

### If only resizing within compatible x86 Hetzner plans
Probably fine, but still verify:
- architecture remains x86_64
- expected disk device remains `/dev/sda`
- network / firmware behavior did not change

Suggested order:
1. snapshot/back up anything important
2. resize in Hetzner if desired
3. boot and verify
4. if hardware assumptions changed, regenerate `hardware-configuration.nix` on the next reinstall workflow

### If changing architecture or doing a more radical server move
Treat it as a fresh deployment project, not a minor tweak.
Do not assume this runbook still applies unchanged.

## 8. Canonical evidence from the successful deployment

Successful log markers:
- `Installing for i386-pc platform.`
- `Installing for x86_64-efi platform.`
- `✅ SUCCESS: Hetzner NixOS deployment complete`
- post-install SSH succeeded for both `root` and `hbohlen`

Keep `deploy.log` from successful runs when changing this workflow.

## 9. Recommended future improvements

Good next improvements if this becomes a repeated workflow:
- add a non-destructive `upgrade-hetzner.sh` wrapper for `nixos-rebuild switch`
- add a preflight mode to `deploy-hetzner.sh`
- ignore or rotate `deploy.log`
- document snapshot/backup procedure before destructive redeploys
- add explicit validation for `TYPE` + `LOCATION`

## 10. If Tailscale is already manually enabled: bootstrap 1Password + opnix

Use this when:
- server is already up
- you already ran `tailscale up --authkey=...` manually
- you now want `/etc/opnix-token` and Home Manager env wiring on that host

Important clarification:
- this workflow does **not** use an `opnix token set` command
- opnix reads `OP_SERVICE_ACCOUNT_TOKEN_FILE`, which is set to `/etc/opnix-token` in Home Manager
- token setup here means creating `/etc/opnix-token` (automatically via `opnix-bootstrap.service`, or manually as a fallback)

### Step 1: Ensure the relay machine has the current opnix token in setec

On `hbohlen-01` (or any host with `op` signed in and `tailscale setec` access):

```bash
TOKEN="$(op read op://hbohlen-systems/opnix/token --no-newline)"
tailscale setec put opnix-token "$TOKEN"
unset TOKEN
tailscale setec status
```

### Step 2: Apply this repo's NixOS config to the existing server

From your local repo checkout:

```bash
nixos-rebuild switch --flake .#hbohlen-01 --target-host hbohlen@<server-ip> --use-remote-sudo
```

Why this step matters:
- installs `tailscale` and `1password-cli` (`_1password-cli`)
- installs the `opnix-bootstrap` systemd oneshot service
- installs Home Manager config that sets `OP_SERVICE_ACCOUNT_TOKEN_FILE=/etc/opnix-token`

### Step 3: Run the bootstrap service now

On the target server:

```bash
sudo systemctl start opnix-bootstrap.service
sudo systemctl status opnix-bootstrap.service --no-pager
sudo ls -l /etc/opnix-token
```

Expected result:
- `/etc/opnix-token` exists
- mode is `600`
- owner is `root`

Manual fallback (if you need to set token file yourself):

```bash
TOKEN="$(sudo tailscale --host=setec setec get opnix-token)"
printf '%s' "$TOKEN" | sudo tee /etc/opnix-token >/dev/null
unset TOKEN
sudo chmod 600 /etc/opnix-token
```

### Step 4: Verify token retrieval from setec path

On the target server:

```bash
sudo tailscale status
sudo tailscale --host=setec setec get opnix-token | head -c 12 && echo
```

If that command fails:
- confirm `tailscale` is connected
- confirm the relay host name `setec` resolves in your tailnet
- re-run Step 1 to refresh the stored token

### Step 5: Verify Home Manager wiring for user sessions

Log in as `hbohlen` and check:

```bash
echo "$OP_SERVICE_ACCOUNT_TOKEN_FILE"
```

Expected:
- `/etc/opnix-token`

If empty in the current shell, start a new login shell (or SSH session) so session vars are reloaded.
