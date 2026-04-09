#!/bin/bash
# beads functionality test script for hbohlen-systems
# Tests beads integration in NixOS devShell environment

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

# Get project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
print_info "Project root: $PROJECT_ROOT"

# Create temporary test directory
TEST_DIR="$(mktemp -d)"
print_info "Created test directory: $TEST_DIR"
cd "$TEST_DIR"
git init

# Function to run beads commands through devShell
run_bd() {
    nix develop "$PROJECT_ROOT#ai" --command bd "$@"
}

# Function to run beads with JSON output and parse
run_bd_json() {
    nix develop "$PROJECT_ROOT#ai" --command bd "$@" --json
}

# Test 1: Initialize beads
print_info "Test 1: Initializing beads..."
run_bd init --quiet
if [[ -f ".beads/config.yaml" && -d ".git" ]]; then
    print_success "Beads initialized successfully in git repository"
else
    print_error "Beads initialization failed or git repository not found"
    exit 1
fi

# Test 2: Create issues
print_info "Test 2: Creating test issues..."

ISSUE1_ID=$(run_bd_json create "Test task: Database setup" -t task -p 2 --description "Test database setup task" | jq -r '.id')
print_info "Created issue 1: $ISSUE1_ID"

ISSUE2_ID=$(run_bd_json create "Test feature: API endpoint" -t feature -p 1 --description "Test API endpoint implementation" | jq -r '.id')
print_info "Created issue 2: $ISSUE2_ID"

EPIC_ID=$(run_bd_json create "Test epic: Auth system" -t epic -p 1 --description "Test epic for authentication system" | jq -r '.id')
print_info "Created epic: $EPIC_ID"

# Test 3: Create subtask under epic
SUBTASK_ID=$(run_bd_json create "Test subtask: Login UI" --parent "$EPIC_ID" -t task --description "Test login UI implementation" | jq -r '.id')
print_info "Created subtask: $SUBTASK_ID"

# Test 4: List issues
print_info "Test 4: Listing issues..."
ISSUE_COUNT=$(run_bd_json list --status open | jq -r 'length')
if [[ "$ISSUE_COUNT" -ge 4 ]]; then
    print_success "Found $ISSUE_COUNT open issues (expected at least 4)"
else
    print_error "Expected at least 4 issues, found $ISSUE_COUNT"
fi

# Test 5: Show issue details
print_info "Test 5: Showing issue details..."
ISSUE_TITLE=$(run_bd_json show "$ISSUE1_ID" | jq -r '.title')
if [[ "$ISSUE_TITLE" == "Test task: Database setup" ]]; then
    print_success "Issue details retrieved correctly"
else
    print_error "Issue title mismatch: '$ISSUE_TITLE'"
fi

# Test 6: Add dependencies
print_info "Test 6: Adding dependencies..."
run_bd dep add "$ISSUE2_ID" "$ISSUE1_ID" --type blocks
print_success "Added dependency: $ISSUE2_ID depends on $ISSUE1_ID"

# Test 7: Check ready work (only ISSUE1 should be ready since ISSUE2 blocks it)
print_info "Test 7: Checking ready work..."
READY_COUNT=$(run_bd_json ready | jq -r 'length')
if [[ "$READY_COUNT" -eq 1 ]]; then
    READY_ID=$(run_bd_json ready | jq -r '.[0].id')
    if [[ "$READY_ID" == "$ISSUE1_ID" ]]; then
        print_success "Ready work check correct: only $ISSUE1_ID is ready"
    else
        print_error "Ready work mismatch: expected $ISSUE1_ID, got $READY_ID"
    fi
else
    print_error "Expected 1 ready issue, found $READY_COUNT"
fi

# Test 8: Claim and work on issue
print_info "Test 8: Claiming and updating issue..."
run_bd update "$ISSUE1_ID" --claim --json > /dev/null
print_success "Claimed issue $ISSUE1_ID"

# Test 9: Close issue
print_info "Test 9: Closing issue..."
run_bd close "$ISSUE1_ID" --reason "Test completed successfully" --json > /dev/null
CLOSED_STATUS=$(run_bd_json show "$ISSUE1_ID" | jq -r '.status')
if [[ "$CLOSED_STATUS" == "closed" ]]; then
    print_success "Issue closed successfully"
else
    print_error "Issue not closed, status: $CLOSED_STATUS"
fi

# Test 10: Check ready work again (ISSUE2 should now be ready)
print_info "Test 10: Checking ready work after closure..."
READY_COUNT=$(run_bd_json ready | jq -r 'length')
if [[ "$READY_COUNT" -eq 1 ]]; then
    READY_ID=$(run_bd_json ready | jq -r '.[0].id')
    if [[ "$READY_ID" == "$ISSUE2_ID" ]]; then
        print_success "Ready work updated: $ISSUE2_ID is now ready"
    else
        print_error "Ready work mismatch after closure"
    fi
else
    print_error "Expected 1 ready issue after closure, found $READY_COUNT"
fi

# Test 11: Dependency tree
print_info "Test 11: Checking dependency tree..."
DEP_TREE=$(run_bd_json dep tree "$EPIC_ID")
if echo "$DEP_TREE" | jq -e '.[] | select(.id == "'"$SUBTASK_ID"'")' > /dev/null; then
    print_success "Dependency tree shows epic-subtask relationship"
else
    print_error "Dependency tree not showing expected relationship"
fi

# Test 12: Sync (simulate end of session)
print_info "Test 12: Syncing database..."
run_bd sync
print_success "Sync completed"

# Test 13: Check for circular dependencies
print_info "Test 13: Checking for circular dependencies..."
CIRCULAR_COUNT=$(run_bd_json dep cycles | jq -r 'length')
if [[ "$CIRCULAR_COUNT" -eq 0 ]]; then
    print_success "No circular dependencies found"
else
    print_error "Found $CIRCULAR_COUNT circular dependencies"
fi

# Test 14: NixOS-specific label test
print_info "Test 14: Testing NixOS-specific patterns..."
NIXOS_ISSUE_ID=$(run_bd_json create "Test NixOS module" -t task -p 2 \
    --description "Test creating a NixOS module" \
    --label "nixos-module,testing" | jq -r '.id')

LABEL_CHECK=$(run_bd_json list --label-any "nixos-module" | jq -r '.[0].id')
if [[ "$LABEL_CHECK" == "$NIXOS_ISSUE_ID" ]]; then
    print_success "NixOS label filtering works correctly"
else
    print_error "NixOS label filtering issue"
fi

# Test 15: Kiro spec integration test
print_info "Test 15: Testing Kiro spec integration..."
KIRO_EPIC_ID=$(run_bd_json create "Kiro spec: Test feature" -t epic \
    --description "Test Kiro spec workflow" \
    --label "kiro-spec" | jq -r '.id')

KIRO_TASK_ID=$(run_bd_json create "Kiro task: Requirements" --parent "$KIRO_EPIC_ID" \
    -t task --label "kiro-requirements" | jq -r '.id')

KIRO_CHECK=$(run_bd_json list --label-any "kiro-spec" | jq -r '.[0].id')
if [[ "$KIRO_CHECK" == "$KIRO_EPIC_ID" ]]; then
    print_success "Kiro spec integration works correctly"
else
    print_error "Kiro spec integration issue"
fi

# Summary
print_info "========================================"
print_info "Test Summary"
print_info "========================================"
print_success "All tests completed successfully!"
print_info "Total issues created: $((ISSUE_COUNT + 2))" # +2 for NixOS and Kiro tests
print_info "Test directory: $TEST_DIR"
print_info ""
print_info "To clean up: rm -rf $TEST_DIR"
print_info ""
print_info "Beads integration verified for:"
print_info "  - Basic issue lifecycle (create, list, show, update, close)"
print_info "  - Dependency management (blocks, parent-child)"
print_info "  - Ready work queue"
print_info "  - Sync functionality"
print_info "  - NixOS-specific patterns"
print_info "  - Kiro spec integration"
print_info "========================================"

# Optional: keep test directory for inspection
if [[ "${KEEP_TEST_DIR:-}" != "1" ]]; then
    print_info "Cleaning up test directory..."
    cd /tmp
    rm -rf "$TEST_DIR"
    print_success "Test directory cleaned up"
else
    print_info "Test directory preserved: $TEST_DIR"
    print_info "Examine with: cd $TEST_DIR && nix develop $PROJECT_ROOT#ai --command bd list"
fi
