# Hetzner Cloud NixOS Deployment v2 Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Implement a repeatable one-command Hetzner deployment flow for `hbohlen-01` using only `hcloud` + `nixos-anywhere`, with minimal surgical edits to the existing flake-parts structure.

**Architecture:** Keep the current `flake.nix` + `nix/cells/nixos` layout intact and update only required behavior. Add one new orchestrator script (`deploy-hetzner.sh`) that creates/recreates the server, polls SSH, generates hardware config in-repo, then installs with `nixos-anywhere --debug --build-on-remote`. Add lightweight shell-based verification checks so each change follows a clear red/green loop.

**Tech Stack:** Nix flakes, flake-parts, NixOS modules, disko, bash, hcloud CLI, nixos-anywhere, ssh

---

### Task 1: Add a lightweight verification script skeleton

**Objective:** Create a local test harness that can fail fast and validate deployment assumptions.

**Files:**
- Create: `tests/hetzner/verify_design.sh`
- Create: `tests/hetzner/.gitkeep`

**Step 1: Write failing test**

Create `tests/hetzner/verify_design.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

pass() {
  echo "PASS: $1"
}

# Failing check first: deploy script must exist
[[ -f deploy-hetzner.sh ]] || fail "deploy-hetzner.sh is missing"

pass "deploy-hetzner.sh exists"
```

**Step 2: Run test to verify failure**

Run: `bash tests/hetzner/verify_design.sh`
Expected: FAIL — `deploy-hetzner.sh is missing`

**Step 3: Write minimal implementation**

Create empty placeholder deployment script:

```bash
#!/usr/bin/env bash
# placeholder - filled in next tasks
```

Then:

Run: `chmod +x deploy-hetzner.sh`

**Step 4: Run test to verify pass**

Run: `bash tests/hetzner/verify_design.sh`
Expected: PASS — `deploy-hetzner.sh exists`

**Step 5: Commit**

```bash
git add tests/hetzner/verify_design.sh tests/hetzner/.gitkeep deploy-hetzner.sh
git commit -m "test: add hetzner deployment verification harness"
```

---

### Task 2: Implement deploy script preflight + logging + top-level variables

**Objective:** Add deterministic script structure required by the spec (vars, logging, shell safety, fail gates).

**Files:**
- Modify: `deploy-hetzner.sh`
- Modify: `tests/hetzner/verify_design.sh`

**Step 1: Write failing test**

Append checks to `tests/hetzner/verify_design.sh`:

```bash
grep -q 'set -Eeuo pipefail' deploy-hetzner.sh || fail "missing strict shell safety"
grep -q 'exec > >(tee -a "${LOG_FILE}") 2>&1' deploy-hetzner.sh || fail "missing tee logging"
grep -q 'NAME="hbohlen-01"' deploy-hetzner.sh || fail "missing NAME variable"
grep -q 'TYPE="cx31"' deploy-hetzner.sh || fail "missing TYPE variable"
grep -q 'LOCATION="hel1"' deploy-hetzner.sh || fail "missing LOCATION variable"
grep -q 'IMAGE="ubuntu-24.04"' deploy-hetzner.sh || fail "missing IMAGE variable"
grep -q 'SSH_KEY_NAME="my-deploy-key"' deploy-hetzner.sh || fail "missing SSH_KEY_NAME variable"
```

**Step 2: Run test to verify failure**

Run: `bash tests/hetzner/verify_design.sh`
Expected: FAIL — one of the new checks missing

**Step 3: Write minimal implementation**

Replace `deploy-hetzner.sh` with:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

LOG_FILE="deploy.log"
NAME="hbohlen-01"
TYPE="cx31"
LOCATION="hel1"
IMAGE="ubuntu-24.04"
SSH_KEY_NAME="my-deploy-key"
FLAKE_TARGET=".#hbohlen-01"
HOST_PATH="nix/cells/nixos/hosts/hbohlen-01/hardware-configuration.nix"
SSH_USER_ROOT="root"
SSH_USER_ADMIN="hbohlen"
SSH_TIMEOUT_SECONDS=300
SSH_POLL_SECONDS=5

exec > >(tee -a "${LOG_FILE}") 2>&1

die() {
  local msg="$1"
  echo "${msg}" >&2
  exit 1
}
```

**Step 4: Run test to verify pass**

Run: `bash tests/hetzner/verify_design.sh`
Expected: PASS for all checks so far

**Step 5: Commit**

```bash
git add deploy-hetzner.sh tests/hetzner/verify_design.sh
git commit -m "feat: add deploy script skeleton with strict mode and logging"
```

---

### Task 3: Add preflight command checks + STEP 1 create/recreate server

**Objective:** Implement deterministic server creation/replacement behavior and explicit fail gate.

**Files:**
- Modify: `deploy-hetzner.sh`
- Modify: `tests/hetzner/verify_design.sh`

**Step 1: Write failing test**

Append checks:

```bash
grep -q 'command -v hcloud' deploy-hetzner.sh || fail "missing hcloud preflight"
grep -q 'command -v nix' deploy-hetzner.sh || fail "missing nix preflight"
grep -q 'command -v ssh-keygen' deploy-hetzner.sh || fail "missing ssh-keygen preflight"
grep -q 'STEP 1: Create or recreate Hetzner server' deploy-hetzner.sh || fail "missing step 1 banner"
grep -q 'hcloud server delete "${NAME}" -y' deploy-hetzner.sh || fail "missing recreate policy"
grep -q 'hcloud server create' deploy-hetzner.sh || fail "missing server create command"
```

**Step 2: Run test to verify failure**

Run: `bash tests/hetzner/verify_design.sh`
Expected: FAIL — missing preflight and/or step 1 logic

**Step 3: Write minimal implementation**

Add to `deploy-hetzner.sh`:

```bash
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "FAIL at STEP 0: missing required command '$1'"
}

require_cmd hcloud
require_cmd nix
require_cmd ssh
require_cmd ssh-keygen

echo "STEP 1: Create or recreate Hetzner server"
if hcloud server describe "${NAME}" >/dev/null 2>&1; then
  echo "Server ${NAME} already exists; deleting per policy"
  hcloud server delete "${NAME}" -y || die "FAIL at STEP 1: failed deleting existing server"
fi

hcloud server create \
  --name "${NAME}" \
  --type "${TYPE}" \
  --image "${IMAGE}" \
  --location "${LOCATION}" \
  --ssh-key "${SSH_KEY_NAME}" \
  >/dev/null || die "FAIL at STEP 1: failed creating server"

SERVER_IP="$(hcloud server ip "${NAME}")"
[[ -n "${SERVER_IP}" ]] || die "FAIL at STEP 1: empty server IP"
echo "Server IP: ${SERVER_IP}"
```

**Step 4: Run test to verify pass**

Run: `bash tests/hetzner/verify_design.sh`
Expected: PASS for all checks so far

**Step 5: Commit**

```bash
git add deploy-hetzner.sh tests/hetzner/verify_design.sh
git commit -m "feat: add preflight checks and server create-or-recreate step"
```

---

### Task 4: Implement SSH polling + known_hosts hygiene + hardware generation

**Objective:** Add STEP 2-4 flow: reachable SSH polling, host key cleanup, and nixos-anywhere hardware config generation.

**Files:**
- Modify: `deploy-hetzner.sh`
- Modify: `tests/hetzner/verify_design.sh`

**Step 1: Write failing test**

Append checks:

```bash
grep -q 'STEP 2: Hardware check and generation' deploy-hetzner.sh || fail "missing step 2 banner"
grep -q 'STEP 3: SSH reachability check' deploy-hetzner.sh || fail "missing step 3 banner"
grep -q 'ssh-keygen -R "${SERVER_IP}"' deploy-hetzner.sh || fail "missing known_hosts cleanup"
grep -q 'nix run github:nix-community/nixos-anywhere --' deploy-hetzner.sh || fail "missing nixos-anywhere invocation"
grep -q -- '--generate-hardware-config nixos-generate-config' deploy-hetzner.sh || fail "missing hardware generation flag"
```

**Step 2: Run test to verify failure**

Run: `bash tests/hetzner/verify_design.sh`
Expected: FAIL — one or more checks missing

**Step 3: Write minimal implementation**

Add to `deploy-hetzner.sh`:

```bash
poll_ssh() {
  local user="$1"
  local waited=0
  while (( waited < SSH_TIMEOUT_SECONDS )); do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "${user}@${SERVER_IP}" true >/dev/null 2>&1; then
      return 0
    fi
    echo "SSH not ready for ${user}@${SERVER_IP} (waited ${waited}s/${SSH_TIMEOUT_SECONDS}s)"
    sleep "${SSH_POLL_SECONDS}"
    waited=$(( waited + SSH_POLL_SECONDS ))
  done
  return 1
}

echo "STEP 2: Hardware check and generation"
ssh-keygen -R "${SERVER_IP}" >/dev/null 2>&1 || true
poll_ssh "${SSH_USER_ROOT}" || die "FAIL at STEP 2: root SSH did not become reachable"

mkdir -p "$(dirname "${HOST_PATH}")"
ssh-keygen -R "${SERVER_IP}" >/dev/null 2>&1 || true
nix run github:nix-community/nixos-anywhere -- \
  --generate-hardware-config nixos-generate-config "${HOST_PATH}" \
  --target-host "${SSH_USER_ROOT}@${SERVER_IP}" \
  || die "FAIL at STEP 2: hardware config generation failed"

echo "STEP 3: SSH reachability check"
ssh-keygen -R "${SERVER_IP}" >/dev/null 2>&1 || true
poll_ssh "${SSH_USER_ROOT}" || die "FAIL at STEP 3: root SSH polling timeout"

echo "STEP 4: Validate required local files"
[[ -f flake.nix ]] || die "FAIL at STEP 4: flake.nix missing"
[[ -f nix/cells/nixos/default.nix ]] || die "FAIL at STEP 4: nixos cell missing"
[[ -f "${HOST_PATH}" ]] || die "FAIL at STEP 4: hardware config not generated"
```

**Step 4: Run test to verify pass**

Run: `bash tests/hetzner/verify_design.sh`
Expected: PASS for all checks so far

**Step 5: Commit**

```bash
git add deploy-hetzner.sh tests/hetzner/verify_design.sh
git commit -m "feat: add SSH polling and hardware config generation flow"
```

---

### Task 5: Implement STEP 5-6 install flow + final success banner

**Objective:** Complete installation logic with explicit fail gates and final SSH verification for both users.

**Files:**
- Modify: `deploy-hetzner.sh`
- Modify: `tests/hetzner/verify_design.sh`

**Step 1: Write failing test**

Append checks:

```bash
grep -q 'STEP 5: Validate flake target assumptions' deploy-hetzner.sh || fail "missing step 5 banner"
grep -q 'nix eval "${FLAKE_TARGET}.config.system.stateVersion"' deploy-hetzner.sh || fail "missing flake target eval"
grep -q 'STEP 6: Install NixOS with nixos-anywhere' deploy-hetzner.sh || fail "missing step 6 banner"
grep -q -- '--debug --build-on-remote' deploy-hetzner.sh || fail "missing required nixos-anywhere flags"
grep -q 'SUCCESS: Hetzner NixOS deployment complete' deploy-hetzner.sh || fail "missing success banner"
```

**Step 2: Run test to verify failure**

Run: `bash tests/hetzner/verify_design.sh`
Expected: FAIL — missing step 5/6 logic

**Step 3: Write minimal implementation**

Add to `deploy-hetzner.sh`:

```bash
echo "STEP 5: Validate flake target assumptions"
nix eval "${FLAKE_TARGET}.config.system.stateVersion" >/dev/null \
  || die "FAIL at STEP 5: flake target ${FLAKE_TARGET} does not evaluate"

echo "STEP 6: Install NixOS with nixos-anywhere"
ssh-keygen -R "${SERVER_IP}" >/dev/null 2>&1 || true
nix run github:nix-community/nixos-anywhere -- \
  --debug --build-on-remote \
  --flake "${FLAKE_TARGET}" \
  --target-host "${SSH_USER_ROOT}@${SERVER_IP}" \
  || die "FAIL at STEP 6: nixos-anywhere install failed"

echo "Post-install SSH verification"
ssh-keygen -R "${SERVER_IP}" >/dev/null 2>&1 || true
poll_ssh "${SSH_USER_ROOT}" || die "FAIL at STEP 6: root SSH failed after install"
poll_ssh "${SSH_USER_ADMIN}" || die "FAIL at STEP 6: hbohlen SSH failed after install"

echo "SUCCESS: Hetzner NixOS deployment complete"
echo "Server IP: ${SERVER_IP}"
```

**Step 4: Run test to verify pass**

Run: `bash tests/hetzner/verify_design.sh`
Expected: PASS for all checks

**Step 5: Commit**

```bash
git add deploy-hetzner.sh tests/hetzner/verify_design.sh
git commit -m "feat: complete nixos-anywhere install flow with fail gates"
```

---

### Task 6: Retarget host architecture to cx31 (`x86_64-linux`)

**Objective:** Align NixOS configuration architecture with Hetzner `cx31`.

**Files:**
- Modify: `nix/cells/nixos/default.nix:4-11`
- Modify: `tests/hetzner/verify_design.sh`

**Step 1: Write failing test**

Append check:

```bash
grep -q 'system = "x86_64-linux";' nix/cells/nixos/default.nix || fail "host architecture not x86_64-linux"
```

**Step 2: Run test to verify failure**

Run: `bash tests/hetzner/verify_design.sh`
Expected: FAIL — currently `aarch64-linux`

**Step 3: Write minimal implementation**

Edit `nix/cells/nixos/default.nix`:

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
        ./hosts/hbohlen-01/default.nix
      ];
    };
  };
}
```

**Step 4: Run test to verify pass**

Run:
- `bash tests/hetzner/verify_design.sh`
- `nix eval .#nixosConfigurations.hbohlen-01.pkgs.stdenv.hostPlatform.system`

Expected:
- PASS from script
- `"x86_64-linux"` from `nix eval`

**Step 5: Commit**

```bash
git add nix/cells/nixos/default.nix tests/hetzner/verify_design.sh
git commit -m "fix: retarget hbohlen-01 to x86_64-linux for cx31"
```

---

### Task 7: Replace disko root layout with Btrfs subvolumes

**Objective:** Implement required partitioning: EFI + Btrfs root with specified subvolumes.

**Files:**
- Modify: `nix/cells/nixos/modules/disko.nix` (entire file)
- Modify: `tests/hetzner/verify_design.sh`

**Step 1: Write failing test**

Append checks:

```bash
grep -q 'format = "btrfs";' nix/cells/nixos/modules/disko.nix || fail "disko root is not btrfs"
grep -q 'subvolumes = {' nix/cells/nixos/modules/disko.nix || fail "missing btrfs subvolumes"
grep -q 'mountpoint = "/nix";' nix/cells/nixos/modules/disko.nix || fail "missing /nix subvolume"
grep -q 'compress=zstd' nix/cells/nixos/modules/disko.nix || fail "missing compress=zstd mount option"
grep -q 'noatime' nix/cells/nixos/modules/disko.nix || fail "missing noatime mount option"
```

**Step 2: Run test to verify failure**

Run: `bash tests/hetzner/verify_design.sh`
Expected: FAIL — current file uses ext4 root

**Step 3: Write minimal implementation**

Replace `nix/cells/nixos/modules/disko.nix` with:

```nix
{ ... }:

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
              type = "btrfs";
              subvolumes = {
                root = { mountpoint = "/"; };
                nix = {
                  mountpoint = "/nix";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                home = { mountpoint = "/home"; };
                var = { mountpoint = "/var"; };
                tmp = { mountpoint = "/tmp"; };
              };
            };
          };
        };
      };
    };
  };
}
```

**Step 4: Run test to verify pass**

Run:
- `bash tests/hetzner/verify_design.sh`
- `nix-instantiate --parse nix/cells/nixos/modules/disko.nix`

Expected:
- PASS from script
- Nix parse success (no syntax error)

**Step 5: Commit**

```bash
git add nix/cells/nixos/modules/disko.nix tests/hetzner/verify_design.sh
git commit -m "feat: switch disko root to btrfs subvolumes"
```

---

### Task 8: Update base module for Hetzner-compatible boot + SSH key-only policy

**Objective:** Ensure bootloader + SSH policy match design constraints without passwords.

**Files:**
- Modify: `nix/cells/nixos/modules/base.nix:5-64`
- Modify: `tests/hetzner/verify_design.sh`

**Step 1: Write failing test**

Append checks:

```bash
grep -q 'boot.loader.grub.enable = true;' nix/cells/nixos/modules/base.nix || fail "missing grub enable"
grep -q 'boot.loader.grub.efiSupport = true;' nix/cells/nixos/modules/base.nix || fail "missing grub EFI support"
grep -q 'boot.loader.grub.device = "nodev";' nix/cells/nixos/modules/base.nix || fail "missing grub device nodev"
grep -q 'networking.useDHCP = true;' nix/cells/nixos/modules/base.nix || fail "DHCP not enabled"
grep -q 'PasswordAuthentication = false;' nix/cells/nixos/modules/base.nix || fail "password auth not disabled"
grep -q 'KbdInteractiveAuthentication = false;' nix/cells/nixos/modules/base.nix || fail "kbd interactive auth not disabled"
```

**Step 2: Run test to verify failure**

Run: `bash tests/hetzner/verify_design.sh`
Expected: FAIL — base module currently uses systemd-boot and redacted placeholders

**Step 3: Write minimal implementation**

Update boot/SSH section in `nix/cells/nixos/modules/base.nix`:

```nix
{ pkgs, ... }:

{
  # Hetzner-compatible EFI GRUB bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.device = "nodev";
  boot.loader.efi.canTouchEfiVariables = false;

  networking.useDHCP = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.hbohlen = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  security.sudo.wheelNeedsPassword = false;
  system.stateVersion = "24.11";
}
```

**Step 4: Run test to verify pass**

Run:
- `bash tests/hetzner/verify_design.sh`
- `nix-instantiate --parse nix/cells/nixos/modules/base.nix`

Expected: PASS + parse success

**Step 5: Commit**

```bash
git add nix/cells/nixos/modules/base.nix tests/hetzner/verify_design.sh
git commit -m "fix: align base module with hetzner EFI grub and ssh key-only policy"
```

---

### Task 9: Update host module with hardware import + root/hbohlen authorized keys + remove initial passwords

**Objective:** Make host file consume generated hardware config and enforce no initial passwords.

**Files:**
- Modify: `nix/cells/nixos/hosts/hbohlen-01/default.nix` (entire file)
- Create: `nix/cells/nixos/hosts/hbohlen-01/hardware-configuration.nix`
- Modify: `tests/hetzner/verify_design.sh`

**Step 1: Write failing test**

Append checks:

```bash
grep -q './hardware-configuration.nix' nix/cells/nixos/hosts/hbohlen-01/default.nix || fail "missing hardware import"
grep -q 'users.users.root.openssh.authorizedKeys.keys' nix/cells/nixos/hosts/hbohlen-01/default.nix || fail "missing root authorized key"
grep -q 'users.users.hbohlen.openssh.authorizedKeys.keys' nix/cells/nixos/hosts/hbohlen-01/default.nix || fail "missing hbohlen authorized key"
! grep -q 'initialPassword' nix/cells/nixos/hosts/hbohlen-01/default.nix || fail "initialPassword must be removed"
```

**Step 2: Run test to verify failure**

Run: `bash tests/hetzner/verify_design.sh`
Expected: FAIL — missing import/root key and contains initialPassword

**Step 3: Write minimal implementation**

Create placeholder `nix/cells/nixos/hosts/hbohlen-01/hardware-configuration.nix`:

```nix
{ ... }:
{
  # Generated by nixos-anywhere --generate-hardware-config
}
```

Replace `nix/cells/nixos/hosts/hbohlen-01/default.nix` with:

```nix
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "hbohlen-01";

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICP6MnCIoDGFnx42wAmVgoNxaHxEtRnOF10d3q/xOIZG hbohlen@hetzner"
  ];

  users.users.hbohlen.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICP6MnCIoDGFnx42wAmVgoNxaHxEtRnOF10d3q/xOIZG hbohlen@hetzner"
  ];

  networking.usePredictableInterfaceNames = true;
  boot.initrd.availableKernelModules = [ "virtio_net" "virtio_pci" "virtio_blk" "virtio_scsi" ];
}
```

**Step 4: Run test to verify pass**

Run:
- `bash tests/hetzner/verify_design.sh`
- `nix-instantiate --parse nix/cells/nixos/hosts/hbohlen-01/default.nix`

Expected: PASS + parse success

**Step 5: Commit**

```bash
git add nix/cells/nixos/hosts/hbohlen-01/default.nix nix/cells/nixos/hosts/hbohlen-01/hardware-configuration.nix tests/hetzner/verify_design.sh
git commit -m "feat: import hardware config and enforce key-only access for root and hbohlen"
```

---

### Task 10: Validate integrated configuration + run deployment dry checks

**Objective:** Verify whole system evaluates and deployment script is syntactically valid before real execution.

**Files:**
- Modify: `tests/hetzner/verify_design.sh` (optional final assertions)

**Step 1: Write failing test**

Append final eval checks:

```bash
nix eval .#nixosConfigurations.hbohlen-01.config.system.stateVersion >/dev/null 2>&1 \
  || fail "nixos configuration does not evaluate"
```

**Step 2: Run test to verify failure**

Run: `bash tests/hetzner/verify_design.sh`
Expected: If any integration issue exists, FAIL with explicit message

**Step 3: Write minimal implementation**

Fix any discovered integration issue (usually module typo, missing import, or syntax mismatch).

**Step 4: Run test to verify pass**

Run:
- `bash tests/hetzner/verify_design.sh`
- `bash -n deploy-hetzner.sh`
- `nix flake check --no-build`

Expected:
- Verification script PASS
- Shell syntax OK
- Flake check passes evaluation

**Step 5: Commit**

```bash
git add tests/hetzner/verify_design.sh deploy-hetzner.sh nix/cells/nixos/default.nix nix/cells/nixos/modules/disko.nix nix/cells/nixos/modules/base.nix nix/cells/nixos/hosts/hbohlen-01/default.nix nix/cells/nixos/hosts/hbohlen-01/hardware-configuration.nix
git commit -m "test: add final integrated verification checks for hetzner deployment v2"
```

---

### Task 11: Execute real deployment and verify acceptance criteria

**Objective:** Perform the actual deployment and validate required outcomes.

**Files:**
- Runtime artifact: `deploy.log`
- Runtime artifact: `nix/cells/nixos/hosts/hbohlen-01/hardware-configuration.nix` (overwritten by generation step)

**Step 1: Write failing test**

Use acceptance checks that fail before deployment:

```bash
hcloud server describe hbohlen-01 >/dev/null 2>&1 && echo "unexpected preexisting server" && exit 1 || true
```

**Step 2: Run test to verify failure**

Run: `bash tests/hetzner/verify_design.sh`
Expected: PASS for static checks (deployment not run yet)

**Step 3: Write minimal implementation**

Run real deployment:

```bash
./deploy-hetzner.sh
```

**Step 4: Run test to verify pass**

Run:

```bash
SERVER_IP="$(hcloud server ip hbohlen-01)"
ssh root@"${SERVER_IP}" true
ssh hbohlen@"${SERVER_IP}" true
grep -q 'SUCCESS: Hetzner NixOS deployment complete' deploy.log
```

Expected:
- both SSH checks succeed
- `deploy.log` contains full transcript and success banner

**Step 5: Commit**

```bash
git add deploy.log nix/cells/nixos/hosts/hbohlen-01/hardware-configuration.nix
git commit -m "chore: record successful hetzner nixos deployment artifacts"
```

---

## Acceptance Criteria Traceability

- Server create/recreate with `cx31` + `ubuntu-24.04` + `hel1` + `my-deploy-key`: Tasks 3 and 11
- SSH polling with timeout and retry logs: Task 4
- `ssh-keygen -R` before SSH and nixos-anywhere: Tasks 4 and 5
- Hardware config generation via nixos-anywhere into host path: Task 4 and 11
- Install with `--debug --build-on-remote`: Task 5
- Host architecture `x86_64-linux`: Task 6
- Disk layout Btrfs subvolumes + `/nix` mount options: Task 7
- Hetzner EFI GRUB + DHCP + explicit stateVersion + key-only auth: Task 8 and 9
- Host imports generated hardware config: Task 9
- Logging to `deploy.log` and final IP banner: Tasks 2 and 5

## Notes (DRY/YAGNI)

- No Terraform/Pulumi/Ansible introduced.
- No flake architecture rewrite.
- Single new top-level executable only: `deploy-hetzner.sh`.
- Test harness intentionally lightweight (bash + grep + nix eval) to avoid new framework dependencies.

## Save Plan

```bash
git add docs/plans/2026-03-30-hetzner-nixos-deployment-v2-implementation-plan.md
git commit -m "docs: add hetzner nixos deployment v2 implementation plan"
```
