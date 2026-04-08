#!/usr/bin/env bash
set -Eeuo pipefail

# ==============================
# Hetzner deployment parameters
# ==============================
LOG_FILE="deploy.log"
NAME="hbohlen-01"
TYPE="cpx32"
LOCATION="hel1"
IMAGE="ubuntu-24.04"
SSH_KEY_NAME="hbohlen-key"

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
FLAKE_TARGET="${REPO_ROOT}#hbohlen-01"
FLAKE_EVAL_TARGET="${REPO_ROOT}#nixosConfigurations.hbohlen-01"
HOST_HARDWARE_PATH="${REPO_ROOT}/hosts/hbohlen-01-hardware-configuration.nix"

SSH_USER_ROOT="root"
SSH_USER_ADMIN="hbohlen"
SSH_POLL_SECONDS=5
SSH_TIMEOUT_SECONDS=300

exec > >(tee -a "${LOG_FILE}") 2>&1

die() {
  local msg="$1"
  echo "$msg" >&2
  exit 1
}

step() {
  echo
  echo "============================================================"
  echo "$1"
  echo "============================================================"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "FAIL at STEP 0: missing required command '$1'"
}

clear_known_host() {
  local ip="$1"
  ssh-keygen -R "$ip" >/dev/null 2>&1 || true
}

ssh_ping() {
  local user="$1"
  local ip="$2"
  ssh \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=5 \
    "${user}@${ip}" \
    true >/dev/null 2>&1
}

poll_ssh() {
  local user="$1"
  local ip="$2"
  local waited=0

  while (( waited < SSH_TIMEOUT_SECONDS )); do
    if ssh_ping "$user" "$ip"; then
      echo "SSH reachable for ${user}@${ip}"
      return 0
    fi

    echo "SSH not ready for ${user}@${ip} (waited ${waited}s/${SSH_TIMEOUT_SECONDS}s, retry in ${SSH_POLL_SECONDS}s)"
    sleep "$SSH_POLL_SECONDS"
    waited=$(( waited + SSH_POLL_SECONDS ))
  done

  return 1
}

ensure_requirements() {
  require_cmd hcloud
  require_cmd nix
  require_cmd ssh
  require_cmd ssh-keygen

  hcloud context active >/dev/null 2>&1 || die "FAIL at STEP 0: hcloud context is not configured"
}

ensure_local_files() {
  [[ -f "${REPO_ROOT}/flake.nix" ]] || die "FAIL at STEP 4: flake.nix missing"
  [[ -f "${REPO_ROOT}/nixos/default.nix" ]] || die "FAIL at STEP 4: nixos/default.nix missing"
  [[ -f "${REPO_ROOT}/nixos/base.nix" ]] || die "FAIL at STEP 4: nixos/base.nix missing"
  [[ -f "${REPO_ROOT}/nixos/disko.nix" ]] || die "FAIL at STEP 4: nixos/disko.nix missing"
  [[ -f "${REPO_ROOT}/hosts/hbohlen-01.nix" ]] || die "FAIL at STEP 4: host module missing"
  [[ -f "${HOST_HARDWARE_PATH}" ]] || die "FAIL at STEP 4: generated hardware config missing at ${HOST_HARDWARE_PATH}"
}

resolve_server_ip() {
  local ip
  ip="$(hcloud server ip "${NAME}")" || die "FAIL at STEP 1: unable to resolve server IP"
  [[ -n "$ip" ]] || die "FAIL at STEP 1: empty server IP"
  echo "$ip"
}

main() {
  ensure_requirements

  step "STEP 1: Create or recreate Hetzner server"
  if hcloud server describe "${NAME}" >/dev/null 2>&1; then
    echo "Server ${NAME} exists; deleting per policy before recreate"
    hcloud server delete "${NAME}" || die "FAIL at STEP 1: failed to delete existing server"
  fi

  hcloud server create \
    --name "${NAME}" \
    --type "${TYPE}" \
    --image "${IMAGE}" \
    --location "${LOCATION}" \
    --ssh-key "${SSH_KEY_NAME}" \
    >/dev/null || die "FAIL at STEP 1: failed to create server"

  local server_ip
  server_ip="$(resolve_server_ip)"
  echo "Created server ${NAME} at IP ${server_ip}"

  step "STEP 2: Hardware check and generation"
  clear_known_host "${server_ip}"
  poll_ssh "${SSH_USER_ROOT}" "${server_ip}" || die "FAIL at STEP 2: root SSH was never reachable"

  mkdir -p "$(dirname "${HOST_HARDWARE_PATH}")"
  rm -f "${HOST_HARDWARE_PATH}"
  clear_known_host "${server_ip}"
  nix run github:nix-community/nixos-anywhere -- \
    --flake "${FLAKE_TARGET}" \
    --phases kexec \
    --no-use-machine-substituters \
    --generate-hardware-config nixos-generate-config "${HOST_HARDWARE_PATH}" \
    --target-host "${SSH_USER_ROOT}@${server_ip}" \
    || die "FAIL at STEP 2: hardware config generation failed"

  [[ -s "${HOST_HARDWARE_PATH}" ]] \
    || die "FAIL at STEP 2: hardware config file was not written"

  step "STEP 3: SSH checks"
  clear_known_host "${server_ip}"
  poll_ssh "${SSH_USER_ROOT}" "${server_ip}" || die "FAIL at STEP 3: root SSH polling timeout"

  step "STEP 4: Config check"
  ensure_local_files
  echo "Config checks passed"

  step "STEP 5: Validate flake target assumptions"
  nix eval "${FLAKE_EVAL_TARGET}.config.system.stateVersion" >/dev/null \
    || die "FAIL at STEP 5: flake eval target ${FLAKE_EVAL_TARGET} does not evaluate"
  nix eval "${FLAKE_EVAL_TARGET}.config.boot.loader.grub.device" >/dev/null \
    || die "FAIL at STEP 5: bootloader settings do not evaluate"
  echo "Flake target ${FLAKE_TARGET} evaluates successfully"

  step "STEP 6: Install NixOS"
  clear_known_host "${server_ip}"
  nix run github:nix-community/nixos-anywhere -- \
    --debug \
    --build-on-remote \
    --flake "${FLAKE_TARGET}" \
    --target-host "${SSH_USER_ROOT}@${server_ip}" \
    || die "FAIL at STEP 6: nixos-anywhere install failed"

  clear_known_host "${server_ip}"
  poll_ssh "${SSH_USER_ROOT}" "${server_ip}" || die "FAIL at STEP 6: post-install root SSH failed"
  clear_known_host "${server_ip}"
  poll_ssh "${SSH_USER_ADMIN}" "${server_ip}" || die "FAIL at STEP 6: post-install ${SSH_USER_ADMIN} SSH failed"

  echo
  echo "✅ SUCCESS: Hetzner NixOS deployment complete"
  echo "Server IP: ${server_ip}"
}

main "$@"
