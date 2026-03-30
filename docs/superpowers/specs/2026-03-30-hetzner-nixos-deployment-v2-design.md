# Hetzner Cloud NixOS Deployment Design (v2)

Date: 2026-03-30
Status: Approved (design phase)
Scope: Minimal updates to existing flake-parts codebase for repeatable Hetzner deployment using only hcloud CLI + nixos-anywhere.

## 1) Architecture Overview

Recommended approach: Surgical update of existing `hbohlen-01` path (no flake rewrite).

Keep existing structure:
- `flake.nix`
- `nix/cells/nixos/default.nix`
- `nix/cells/nixos/modules/base.nix`
- `nix/cells/nixos/modules/disko.nix`
- `nix/cells/nixos/hosts/hbohlen-01/default.nix`

Add exactly one new top-level file:
- `deploy-hetzner.sh`

Boundary decisions:
- Re-target `hbohlen-01` to `x86_64-linux` for `cx31`.
- Keep `flake-parts` and existing cell layout.
- Use nixos-anywhere hardware scanning to generate host hardware config file in-repo and import it from host module.

Out of scope:
- Refactoring unrelated modules
- New deployment frameworks
- Terraform/Pulumi/Ansible

## 2) Component Design

### A. `deploy-hetzner.sh` (new)
Purpose: one-command deployment orchestrator.

Required behavior:
1. STEP 1 server create (or replace existing) with:
   - `TYPE=cx31` (user-approved default)
   - `IMAGE=ubuntu-24.04`
   - `LOCATION=hel1`
   - pre-injected SSH key name `my-deploy-key`
2. STEP 2 hardware check:
   - SSH polling until reachable
   - `ssh-keygen -R` before SSH and before every nixos-anywhere call
   - run nixos-anywhere hardware generation:
     - `--generate-hardware-config nixos-generate-config <repo-host-path>`
3. STEP 3 SSH checks:
   - explicit polling with clear retry logs and timeout failure
4. STEP 4 config check:
   - validate required local files/commands before install
5. STEP 5 update assumptions consumed by script:
   - flake target points to existing host output
6. STEP 6 install:
   - nixos-anywhere with `--debug --build-on-remote`

Operational requirements:
- Top-level variables for easy edits (`NAME`, `TYPE`, `LOCATION`, `IMAGE`, `FLAKE_TARGET`, etc.)
- Full logging to `deploy.log` via `tee -a`
- Explicit fail-gates after major commands with clear `FAIL at STEP X` messages
- Final success banner prints server IP

### B. `flake.nix` (minimal edit)
- Keep existing flake-parts layout.
- Ensure `disko` input exists (already present).
- No structural rewrite.

### C. `nix/cells/nixos/default.nix` (minimal edit)
- Keep existing `flake.nixosConfigurations` exposure.
- Change host system from `aarch64-linux` to `x86_64-linux` for `cx31`.
- Keep module list pattern intact.

### D. `nix/cells/nixos/modules/disko.nix` (replace layout details only)
- Keep same module location.
- Use Btrfs on root partition with subvolumes:
  - `/`
  - `/nix` with mount options `[ "compress=zstd" "noatime" ]`
  - `/home`
  - `/var`
  - `/tmp`
- Keep EFI system partition.

### E. `nix/cells/nixos/modules/base.nix` and/or host module (minimal edits)
- Configure Hetzner-compatible EFI GRUB bootloader.
- Keep `networking.useDHCP = true`.
- Ensure `system.stateVersion` is explicitly set.
- Remove initial passwords (SSH-key-only policy).
- Ensure authorized SSH key exists for both `root` and `hbohlen`.

### F. `nix/cells/nixos/hosts/hbohlen-01/default.nix` (minimal edit)
- Import generated hardware config path.
- Keep host-specific settings concise and focused.

## 3) Data Flow

1. Script creates/recreates Hetzner server.
2. Script resolves server IPv4.
3. Script clears stale known_hosts entry (`ssh-keygen -R`).
4. Script polls SSH reachability with retries.
5. Script runs nixos-anywhere hardware scan to generate hardware file in repo.
6. Script runs nixos-anywhere install with debug/build-on-remote.
7. Server reboots into NixOS.
8. Script verifies SSH for both `root` and `hbohlen`.
9. Script prints success + IP.

Artifacts:
- `deploy.log` (full transcript)
- generated `hardware-configuration.nix` in host path

## 4) Error Handling and Safety

Shell safety:
- `set -Eeuo pipefail`

Failure handling:
- After each major step, explicit failure gate and non-zero exit.
- Timeout-based SSH polling to avoid indefinite hangs.

Known-host hygiene:
- Always run `ssh-keygen -R <ip>` before SSH and nixos-anywhere invocations.

Existing-server policy (user-approved):
- If `NAME` exists: delete and recreate automatically.

Visibility:
- Use `--debug` for install traceability.
- Centralized logs in `deploy.log`.

## 5) Testing and Acceptance Criteria

Pre-flight checks:
- Required commands exist: `hcloud`, `nix`, `ssh`, `ssh-keygen`.
- hcloud auth/context available.

Functional checks:
- New server created as `cx31` in `hel1` using `ubuntu-24.04` and `my-deploy-key`.
- Hardware config generated from real machine via nixos-anywhere.
- Disk layout uses Btrfs subvolumes as specified.
- Bootloader, DHCP, stateVersion, and SSH key policy are applied.
- Initial passwords removed.
- Install executed with `--debug --build-on-remote`.

Completion checks:
- Script exits 0.
- Final output includes server IP.
- SSH checks pass for both `root` and `hbohlen`.
- `deploy.log` contains full step-by-step output.

## 6) Implementation Constraints

- Do not rewrite flake architecture.
- Only minimal file edits/additions.
- Use only hcloud CLI + nixos-anywhere for deployment flow.
- Keep all behavior deterministic and repeatable from the DO droplet.
