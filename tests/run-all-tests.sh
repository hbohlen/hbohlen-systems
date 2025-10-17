#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo "NixOS Configuration Test Suite"
echo "========================================"
echo ""

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

run_test() {
    local test_name="$1"
    local test_script="$2"
    
    echo "Running: $test_name"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if bash "$test_script"; then
        echo "✓ PASSED: $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "✗ FAILED: $test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    echo ""
}

cd "$(dirname "$0")"

run_test "Syntax Validation" "./test-syntax.sh"
run_test "Structure Validation" "./test-structure.sh"
run_test "Configuration Validation" "./test-configuration.sh"
run_test "Disko Configuration Validation" "./test-disko.sh"
run_test "Hardware Configuration Validation" "./test-hardware.sh"
run_test "Impermanence Module Validation" "./test-impermanence.sh"

echo "========================================"
echo "Test Summary"
echo "========================================"
echo "Total Tests:  $TOTAL_TESTS"
echo "Passed:       $PASSED_TESTS"
echo "Failed:       $FAILED_TESTS"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo "✓ All tests passed!"
    exit 0
else
    echo "✗ Some tests failed."
    exit 1
fi