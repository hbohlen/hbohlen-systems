# Skill: Core Issue Management

### Purpose and Scope
Manage the basic issue lifecycle: creation, viewing, updating, and closing issues. This skill forms the foundation of all beads workflows.

### Essential Commands (Always with `--json`)

```bash
# Create issues (always include description for context)
bd create "Implement NixOS module for service X" \
  -t task -p 2 \
  --description "Create a NixOS module that provides service X with configuration options" \
  --json

# List and filter issues
bd list --status open --priority "0,1,2" --type "task,feature" --json
bd list --label-any "nixos,kiro-spec" --json
bd search "authentication" --status open --json

# View issue details
bd show bd-a1b2 --json
bd show bd-a1b2 --full --json  # Includes comments

# Update issues (claim work, modify fields)
bd update bd-a1b2 --claim --json
bd update bd-a1b2 --priority 0 --add-label "urgent,security" --json
bd update bd-a1b2 --title "Updated: Implement auth module" --description "Revised scope..." --json

# Close issues (always provide reason)
bd close bd-a1b2 --reason "Implemented in PR #123, tested on staging" --json
bd reopen bd-a1b2 --json  # Reopen if needed
```

### Common Patterns and Best Practices

**Daily Workflow Pattern:**
```bash
# Start of session: Find ready work
READY_ISSUES=$(bd ready --json | jq -r '.[].id')
if [ -n "$READY_ISSUES" ]; then
  FIRST_ISSUE=$(echo "$READY_ISSUES" | head -1)
  bd update $FIRST_ISSUE --claim --json
  echo "Claimed issue: $FIRST_ISSUE"
else
  echo "No ready work. Check blocked issues or create new work."
fi

# During work: Regular updates
bd update $ISSUE_ID --add-label "in-progress" --json

# Completion: Close with detailed reason
bd close $ISSUE_ID --reason "Implemented with tests, documented in README" --json
```

**Issue Creation Best Practices:**
- Always include `--description` with sufficient context for future agents
- Use appropriate issue types: `task` (implementation), `feature` (new functionality), `bug` (defects), `epic` (large features), `chore` (maintenance)
- Set realistic priorities: 0 (critical), 1 (high), 2 (normal), 3 (low), 4 (backlog)
- Apply 2-4 relevant labels for filtering

### Integration with Project Workflows

**Kiro Spec Integration:**
```bash
# Kiro spec creation → beads epic
bd create "Feature: Multi-agent coordination system" \
  -t epic -p 1 \
  --description "Kiro spec for multi-agent coordination using beads routing" \
  --label "kiro-spec,multi-agent" \
  --json

# Kiro task generation → beads subtasks
bd create "Design routing configuration format" \
  --parent bd-epic-id \
  -t task -p 2 \
  --description "Design TOML/JSON format for .beads/routes.jsonl" \
  --label "kiro-design" \
  --json
```

**NixOS Module Development:**
```bash
# NixOS module issue
bd create "Create NixOS module for tailscale" \
  -t task -p 2 \
  --description "Implement tailscale.nix module with auth key management" \
  --label "nixos-module,security,networking" \
  --json
```

### Potential Pitfalls and Troubleshooting

1. **Missing `--json` flag**: Causes output formatting issues for AI parsing
   - **Fix**: Always include `--json` for programmatic access

2. **Insufficient description**: Makes issues hard to understand later
   - **Fix**: Always provide detailed `--description` including context, requirements, references

3. **Wrong issue type**: Confuses workflow tracking
   - **Fix**: Use consistent types: `task` for implementation work, `feature` for new capabilities, `bug` for fixes

4. **Forgetting to claim work**: Multiple agents might work on same issue
   - **Fix**: Always use `bd update <id> --claim --json` when starting work
