#!/bin/bash
# Basic beads functionality test for hbohlen-systems
# Tests beads integration in NixOS devShell environment without jq dependency

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get project root directory (assuming script is in docs/beads/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
print_info "Project root: $PROJECT_ROOT"

# Create temporary test directory
TEST_DIR="$(mktemp -d)"
print_info "Created test directory: $TEST_DIR"
cd "$TEST_DIR"
git init > /dev/null 2>&1

# Function to run beads commands through devShell
run_bd() {
    nix develop "$PROJECT_ROOT#ai" --command bd "$@"
}

# Test 1: Initialize beads
print_info "Test 1: Initializing beads..."
run_bd init --quiet
if [[ -f ".beads/config.yaml" && -d ".git" ]]; then
    print_success "Beads initialized successfully"
else
    print_error "Beads initialization failed"
    exit 1
fi

# Test 2: Create issues (without --json flag, use default output)
print_info "Test 2: Creating test issues..."
run_bd create "Test task: Database setup" -t task -p 2 --description "Test database setup task"
if [[ $? -eq 0 ]]; then
    print_success "Created test task"
else
    print_error "Failed to create test task"
    exit 1
fi

run_bd create "Test feature: API endpoint" -t feature -p 1 --description "Test API endpoint implementation"
if [[ $? -eq 0 ]]; then
    print_success "Created test feature"
else
    print_error "Failed to create test feature"
    exit 1
fi

# Test 3: List issues
print_info "Test 3: Listing issues..."
LIST_OUTPUT=$(run_bd list --status open)
if echo "$LIST_OUTPUT" | grep -q "Test task: Database setup" && \
   echo "$LIST_OUTPUT" | grep -q "Test feature: API endpoint"; then
    print_success "List shows both created issues"
else
    print_error "List doesn't show expected issues"
    exit 1
fi

# Test 4: Show issue details (get issue ID from list)
print_info "Test 4: Getting issue details..."
# Extract first issue ID (format: bd-xxxx)
ISSUE_ID=$(run_bd list --status open | grep -o "bd-[a-z0-9]*" | head -1)
if [[ -n "$ISSUE_ID" ]]; then
    SHOW_OUTPUT=$(run_bd show "$ISSUE_ID")
    if echo "$SHOW_OUTPUT" | grep -q "Test task: Database setup"; then
        print_success "Show command works for issue $ISSUE_ID"
    else
        print_error "Show command output unexpected"
        exit 1
    fi
else
    print_error "Could not extract issue ID"
    exit 1
fi

# Test 5: Update issue
print_info "Test 5: Updating issue..."
run_bd update "$ISSUE_ID" --claim
if [[ $? -eq 0 ]]; then
    print_success "Updated issue (claimed)"
else
    print_error "Failed to update issue"
    exit 1
fi

# Test 6: Close issue
print_info "Test 6: Closing issue..."
run_bd close "$ISSUE_ID" --reason "Test completed"
if [[ $? -eq 0 ]]; then
    print_success "Closed issue"
else
    print_error "Failed to close issue"
    exit 1
fi

# Verify issue is closed
CLOSED_CHECK=$(run_bd list --status closed)
if echo "$CLOSED_CHECK" | grep -q "$ISSUE_ID"; then
    print_success "Issue appears in closed list"
else
    print_error "Issue not found in closed list"
    exit 1
fi

# Test 7: Sync
print_info "Test 7: Syncing database..."
run_bd sync
if [[ $? -eq 0 ]]; then
    print_success "Sync completed"
else
    print_error "Sync failed"
    exit 1
fi

# Test 8: NixOS-specific pattern
print_info "Test 8: Testing NixOS pattern..."
run_bd create "Test NixOS module" -t task \
    --description "Test NixOS module creation" \
    --label "nixos-module,testing"
if [[ $? -eq 0 ]]; then
    print_success "Created NixOS-labeled issue"
else
    print_error "Failed to create NixOS issue"
    exit 1
fi

# Test 9: Kiro spec pattern
print_info "Test 9: Testing Kiro spec pattern..."
run_bd create "Kiro spec: Test feature" -t epic \
    --description "Test Kiro spec workflow" \
    --label "kiro-spec"
if [[ $? -eq 0 ]]; then
    print_success "Created Kiro spec issue"
else
    print_error "Failed to create Kiro spec issue"
    exit 1
fi

# Test 10: Check ready work
print_info "Test 10: Checking ready work..."
READY_OUTPUT=$(run_bd ready)
if [[ -n "$READY_OUTPUT" ]]; then
    print_success "Ready command works (output: $(echo "$READY_OUTPUT" | wc -l) lines)"
else
    print_info "Ready command returned empty (may be expected if no unblocked work)"
fi

# Summary
print_info "========================================"
print_info "Test Summary"
print_info "========================================"
print_success "All basic tests passed!"
print_info "Tested:"
print_info "  - init, create, list, show, update, close, sync"
print_info "  - NixOS label pattern"
print_info "  - Kiro spec pattern"
print_info "  - ready work check"
print_info ""
print_info "Test directory: $TEST_DIR"
print_info "To clean up: rm -rf $TEST_DIR"
print_info "========================================"

# Clean up
print_info "Cleaning up test directory..."
cd /tmp
rm -rf "$TEST_DIR"
print_success "Test completed and cleaned up"
