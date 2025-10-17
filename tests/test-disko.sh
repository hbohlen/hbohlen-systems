#!/usr/bin/env bash
set -euo pipefail

echo "=== Disko Configuration Validation Test ==="
cd "$(dirname "$0")/.."

DISKO_ERRORS=0

echo "Validating disko.nix configuration..."

if grep -q "disko.devices" disko.nix; then
    echo "  ✓ Disko devices section exists"
else
    echo "  ✗ Missing disko.devices configuration"
    DISKO_ERRORS=$((DISKO_ERRORS + 1))
fi

if grep -q "disk.main" disko.nix; then
    echo "  ✓ Main disk defined"
else
    echo "  ✗ Missing main disk definition"
    DISKO_ERRORS=$((DISKO_ERRORS + 1))
fi

if grep -q "boot.*=.*{" disko.nix; then
    echo "  ✓ Boot partition configured"
else
    echo "  ✗ Missing boot partition"
    DISKO_ERRORS=$((DISKO_ERRORS + 1))
fi

if grep -q "swap.*=.*{" disko.nix; then
    echo "  ✓ Swap partition configured"
else
    echo "  ✗ Missing swap partition"
    DISKO_ERRORS=$((DISKO_ERRORS + 1))
fi

if grep -q "type = \"luks\"" disko.nix; then
    echo "  ✓ LUKS encryption configured"
else
    echo "  ✗ Missing LUKS encryption"
    DISKO_ERRORS=$((DISKO_ERRORS + 1))
fi

if grep -q "type = \"btrfs\"" disko.nix; then
    echo "  ✓ Btrfs filesystem configured"
else
    echo "  ✗ Missing btrfs filesystem"
    DISKO_ERRORS=$((DISKO_ERRORS + 1))
fi

echo ""
echo "Checking btrfs subvolumes..."
required_subvolumes=("root" "home" "nix" "persist" "log" "tmp")
for subvol in "${required_subvolumes[@]}"; do
    if grep -q "\"$subvol\".*=.*{" disko.nix; then
        echo "  ✓ Subvolume '$subvol' defined"
    else
        echo "  ✗ Missing subvolume: $subvol"
        DISKO_ERRORS=$((DISKO_ERRORS + 1))
    fi
done

echo ""
echo "Checking SSD optimizations..."
if grep -q "discard" disko.nix; then
    echo "  ✓ TRIM/discard configured"
else
    echo "  ✗ Missing TRIM/discard configuration"
    DISKO_ERRORS=$((DISKO_ERRORS + 1))
fi

if grep -q "compress=zstd" disko.nix; then
    echo "  ✓ Compression enabled (zstd)"
else
    echo "  ✗ Missing compression configuration"
    DISKO_ERRORS=$((DISKO_ERRORS + 1))
fi

if [ $DISKO_ERRORS -eq 0 ]; then
    echo ""
    echo "✓ All disko checks passed"
    exit 0
else
    echo ""
    echo "✗ Found $DISKO_ERRORS disko configuration error(s)"
    exit 1
fi