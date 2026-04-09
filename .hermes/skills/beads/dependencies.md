# Skill: Dependency Management

### Purpose and Scope
Manage relationships between issues to enable dependency-aware execution. This skill ensures agents work on unblocked tasks and maintain proper issue hierarchies.

### Essential Commands

```bash
# Add dependencies
bd dep add bd-child bd-parent --type blocks  # Hard dependency (default)
bd dep add bd-related bd-source --type related  # Soft relationship
bd dep add bd-discovered bd-origin --type discovered-from  # Discovery tracking

# Remove dependencies
bd dep remove bd-child bd-parent

# View dependency structures
bd dep tree bd-epic-id --depth 3 --json
bd dep tree bd-epic-id --direction upstream --json  # What blocks this
bd dep tree bd-epic-id --direction downstream --json  # What this blocks

# Find circular dependencies
bd dep cycles --json

# Find ready and blocked work
bd ready --priority "0,1,2" --json
bd blocked --json
bd blocked --by bd-a1b2 --json  # What blocks specific issue
```

### Common Patterns and Best Practices

**Dependency-Aware Workflow:**
```bash
# Before starting work, check if ready
READY_CHECK=$(bd ready --json | jq -r 'length')
if [ "$READY_CHECK" -eq 0 ]; then
  BLOCKED_ISSUES=$(bd blocked --json | jq -r '.[].id')
  echo "No ready work. Blocked issues: $BLOCKED_ISSUES"
  # Optionally work on unblocking dependencies
else
  ISSUE_ID=$(bd ready --json | jq -r '.[0].id')
  echo "Starting work on: $ISSUE_ID"
  bd update $ISSUE_ID --claim --json
fi
```

**Hierarchical Issue Management (Epics):**
```bash
# Create epic (returns ID like bd-a3f8e9)
EPIC_ID=$(bd create "Auth system overhaul" -t epic -p 1 --json | jq -r '.id')

# Create auto-numbered subtasks
bd create "Design new auth flow" --parent $EPIC_ID -t task --json  # Becomes bd-a3f8e9.1
bd create "Implement OAuth2 provider" --parent $EPIC_ID -t task --json  # bd-a3f8e9.2
bd create "Update documentation" --parent $EPIC_ID -t task --json  # bd-a3f8e9.3

# View epic structure
bd dep tree $EPIC_ID --json
```

**Discovery Tracking:**
```bash
# When discovering new work during implementation
bd create "Found race condition in auth cache" \
  -t bug -p 0 \
  --description "Race condition between cache invalidation and auth checks" \
  --deps discovered-from:bd-current-issue \
  --json
```

### Integration with Project Workflows

**Kiro Spec Dependency Chain:**
```bash
# Kiro spec phases as dependencies
REQUIREMENTS_ID=$(bd create "Requirements analysis" --parent $EPIC_ID --json | jq -r '.id')
DESIGN_ID=$(bd create "System design" --parent $EPIC_ID --json | jq -r '.id')
IMPLEMENTATION_ID=$(bd create "Implementation" --parent $EPIC_ID --json | jq -r '.id')

# Set phase dependencies
bd dep add $DESIGN_ID $REQUIREMENTS_ID --type blocks
bd dep add $IMPLEMENTATION_ID $DESIGN_ID --type blocks

# Only requirements is initially ready
bd ready --json  # Shows only requirements issue
```

**NixOS Module Dependencies:**
```bash
# Module dependencies
BD_NIXPKGS=$(bd create "Update nixpkgs input" -t task --label "flake-update" --json | jq -r '.id')
BD_MODULE=$(bd create "Implement new module" -t task --label "nixos-module" --json | jq -r '.id')
BD_TEST=$(bd create "Test module" -t task --label "testing" --json | jq -r '.id')

# Dependency chain
bd dep add $BD_MODULE $BD_NIXPKGS  # Module depends on nixpkgs update
bd dep add $BD_TEST $BD_MODULE     # Testing depends on module
```

### Potential Pitfalls and Troubleshooting

1. **Circular dependencies**: Cause deadlocks where no work is ready
   - **Detection**: `bd dep cycles --json`
   - **Fix**: Break cycle by changing dependency type or restructuring

2. **Missing `discovered-from` tracking**: Lose context of how work was found
   - **Fix**: Always use `--deps discovered-from:<parent>` for discovered work

3. **Over-blocking**: Making everything block everything else
   - **Fix**: Use appropriate dependency types: `blocks` for hard dependencies, `related` for soft links

4. **Epic explosion**: Too many levels of hierarchy
   - **Fix**: Keep epics to 2-3 levels max; use labels for additional categorization
