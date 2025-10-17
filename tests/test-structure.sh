#!/usr/bin/env bash
set -euo pipefail

echo "=== Structure Validation Test ==="
cd "$(dirname "$0")/.."

STRUCTURE_ERRORS=0

echo "Checking for required configuration files..."
required_files=(
    "configuration.nix"
    "disko.nix"
    "hardware-configuration.nix"
    "modules/impermanence.nix"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "  ✗ Missing required file: $file"
        STRUCTURE_ERRORS=$((STRUCTURE_ERRORS + 1))
    else
        echo "  ✓ Found: $file"
    fi
done

echo ""
echo "Checking configuration.nix imports..."
if grep -q "hardware-configuration.nix" configuration.nix; then
    echo "  ✓ Imports hardware-configuration.nix"
else
    echo "  ✗ Missing import of hardware-configuration.nix"
    STRUCTURE_ERRORS=$((STRUCTURE_ERRORS + 1))
fi

if grep -q "modules/impermanence.nix" configuration.nix; then
    echo "  ✓ Imports impermanence module"
else
    echo "  ✗ Missing import of impermanence module"
    STRUCTURE_ERRORS=$((STRUCTURE_ERRORS + 1))
fi

echo ""
echo "Checking module structure..."
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        if grep -qE "^\{|^{ config|^{ lib|^{ pkgs" "$file"; then
            echo "  ✓ $file has valid module structure"
        else
            echo "  ✗ $file may not have valid module structure"
            STRUCTURE_ERRORS=$((STRUCTURE_ERRORS + 1))
        fi
    fi
done

if [ $STRUCTURE_ERRORS -eq 0 ]; then
    echo ""
    echo "✓ All structure checks passed"
    exit 0
else
    echo ""
    echo "✗ Found $STRUCTURE_ERRORS structure error(s)"
    exit 1
fi