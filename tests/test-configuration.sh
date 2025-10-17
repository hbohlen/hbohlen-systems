#!/usr/bin/env bash
set -euo pipefail

echo "=== Configuration Validation Test ==="
cd "$(dirname "$0")/.."

CONFIG_ERRORS=0

echo "Validating configuration.nix settings..."

test_config_option() {
    local option="$1"
    local description="$2"
    
    if grep -q "$option" configuration.nix; then
        echo "  ✓ $description is configured"
        return 0
    else
        echo "  ✗ Missing: $description ($option)"
        CONFIG_ERRORS=$((CONFIG_ERRORS + 1))
        return 1
    fi
}

test_config_option "boot.loader.systemd-boot.enable" "Systemd-boot bootloader"
test_config_option "boot.loader.efi.canTouchEfiVariables" "EFI variables"
test_config_option "fileSystems.\"/\"" "Root filesystem"
test_config_option "fileSystems.\"/home\"" "Home filesystem"
test_config_option "fileSystems.\"/nix\"" "Nix store filesystem"
test_config_option "fileSystems.\"/persist\"" "Persistent storage"
test_config_option "users.users.hbohlen" "User account"

# Hostname check - handle multi-line format
if grep -q "hostName" configuration.nix; then
    echo "  ✓ Hostname is configured"
else
    echo "  ✗ Missing: Hostname"
    CONFIG_ERRORS=$((CONFIG_ERRORS + 1))
fi

test_config_option "networkmanager.enable" "NetworkManager"
test_config_option "hardware.bluetooth.enable" "Bluetooth support"

# Sudo check - handle attribute set format
if grep -q "security.sudo" configuration.nix; then
    echo "  ✓ Sudo configuration is configured"
else
    echo "  ✗ Missing: Sudo configuration"
    CONFIG_ERRORS=$((CONFIG_ERRORS + 1))
fi

echo ""
echo "Validating btrfs mount options..."
if grep -q "compress=zstd" configuration.nix; then
    echo "  ✓ Compression enabled (zstd)"
else
    echo "  ✗ Missing compression option"
    CONFIG_ERRORS=$((CONFIG_ERRORS + 1))
fi

if grep -q "noatime" configuration.nix; then
    echo "  ✓ noatime option set"
fi

echo ""
echo "Validating AMD hardware configuration..."
if grep -q "kvm-amd" configuration.nix; then
    echo "  ✓ AMD virtualization support"
else
    echo "  ✗ Missing AMD virtualization support"
    CONFIG_ERRORS=$((CONFIG_ERRORS + 1))
fi

echo ""
echo "Checking system state version..."
if grep -qE "system.stateVersion.*=.*\"[0-9]+\.[0-9]+\"" configuration.nix; then
    VERSION=$(grep -oE "system.stateVersion.*=.*\"[0-9]+\.[0-9]+\"" configuration.nix | grep -oE "[0-9]+\.[0-9]+")
    echo "  ✓ System state version set to: $VERSION"
else
    echo "  ✗ System state version not properly set"
    CONFIG_ERRORS=$((CONFIG_ERRORS + 1))
fi

if [ $CONFIG_ERRORS -eq 0 ]; then
    echo ""
    echo "✓ All configuration checks passed"
    exit 0
else
    echo ""
    echo "✗ Found $CONFIG_ERRORS configuration error(s)"
    exit 1
fi