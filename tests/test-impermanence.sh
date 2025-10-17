#!/usr/bin/env bash
set -euo pipefail

echo "=== Impermanence Module Validation Test ==="
cd "$(dirname "$0")/.."

IMP_ERRORS=0

echo "Validating modules/impermanence.nix..."

if grep -q "system.activationScripts.impermanence" modules/impermanence.nix; then
    echo "  ✓ Impermanence activation script configured"
else
    echo "  ✗ Missing impermanence activation script"
    IMP_ERRORS=$((IMP_ERRORS + 1))
fi

echo ""
echo "Checking persistent directory configuration..."
required_persist_dirs=(
    "/persist/etc/ssh"
    "/persist/var/log"
    "/persist/var/lib"
    "/persist/root"
    "/persist/home"
)

for dir in "${required_persist_dirs[@]}"; do
    if grep -q "$dir" modules/impermanence.nix; then
        echo "  ✓ Persistent directory configured: $dir"
    else
        echo "  ✗ Missing persistent directory: $dir"
        IMP_ERRORS=$((IMP_ERRORS + 1))
    fi
done

if grep -q "ln -sf" modules/impermanence.nix; then
    echo "  ✓ Symlink creation configured"
else
    echo "  ✗ Missing symlink creation"
    IMP_ERRORS=$((IMP_ERRORS + 1))
fi

echo ""
echo "Cross-checking with disko configuration..."
if grep -q "persist" ../disko.nix 2>/dev/null || grep -q "persist" disko.nix; then
    echo "  ✓ Persist subvolume defined in disko"
else
    echo "  ✗ Missing persist subvolume in disko"
    IMP_ERRORS=$((IMP_ERRORS + 1))
fi

if [ $IMP_ERRORS -eq 0 ]; then
    echo ""
    echo "✓ All impermanence checks passed"
    exit 0
else
    echo ""
    echo "✗ Found $IMP_ERRORS impermanence configuration error(s)"
    exit 1
fi