#!/usr/bin/env bash
set -euo pipefail

echo "=== Hardware Configuration Validation Test ==="
cd "$(dirname "$0")/.."

HW_ERRORS=0

echo "Validating hardware-configuration.nix..."

if grep -q "hardware.graphics" hardware-configuration.nix; then
    echo "  ✓ Graphics hardware configured"
else
    echo "  ✗ Missing graphics configuration"
    HW_ERRORS=$((HW_ERRORS + 1))
fi

if grep -q "amdgpu" hardware-configuration.nix; then
    echo "  ✓ AMD GPU driver configured"
else
    echo "  ✗ Missing AMD GPU driver"
    HW_ERRORS=$((HW_ERRORS + 1))
fi

if grep -q "hardware.cpu.amd.updateMicrocode" hardware-configuration.nix; then
    echo "  ✓ AMD microcode updates enabled"
else
    echo "  ✗ Missing AMD microcode updates"
    HW_ERRORS=$((HW_ERRORS + 1))
fi

if grep -q "powerManagement" hardware-configuration.nix; then
    echo "  ✓ Power management configured"
else
    echo "  ✗ Missing power management configuration"
    HW_ERRORS=$((HW_ERRORS + 1))
fi

echo ""
echo "Checking laptop-specific features..."

if grep -q "libinput" hardware-configuration.nix; then
    echo "  ✓ Touchpad support (libinput) configured"
else
    echo "  ✗ Missing touchpad support"
    HW_ERRORS=$((HW_ERRORS + 1))
fi

if grep -q "bluetooth" hardware-configuration.nix; then
    echo "  ✓ Bluetooth support configured"
else
    echo "  ✗ Missing bluetooth configuration"
    HW_ERRORS=$((HW_ERRORS + 1))
fi

if grep -q "pipewire" hardware-configuration.nix; then
    echo "  ✓ Audio (pipewire) configured"
else
    echo "  ✗ Missing audio configuration"
    HW_ERRORS=$((HW_ERRORS + 1))
fi

if [ $HW_ERRORS -eq 0 ]; then
    echo ""
    echo "✓ All hardware checks passed"
    exit 0
else
    echo ""
    echo "✗ Found $HW_ERRORS hardware configuration error(s)"
    exit 1
fi