# Skill: Multi-agent Coordination

### Purpose and Scope
Coordinate work between multiple AI agents using routing, pinning, and coordination patterns. This skill enables scalable multi-agent workflows.

### Essential Commands

```bash
# Routing configuration
bd route add "frontend/**" --destination "frontend-repo" --priority 2 --json
bd route list --json
bd route remove "frontend/**" --json

# Work assignment (pinning)
bd pin bd-a1b2 --for frontend-agent --start --json
bd pin bd-a1b2 --release --json  # Release when done
bd hook --json  # Show pinned work for current agent

# Agent coordination
bd audit --json  # Record agent interactions
bd reserve path/to/file --for agent-name --json  # File reservation
bd reserve --release path/to/file --json  # Release reservation

# Cross-repo dependencies
bd dep add bd-repo1-issue bd-repo2-issue --cross-repo --json
```

### Common Patterns and Best Practices

**Routing Configuration:**
```json
// .beads/routes.jsonl
{"route": "nixos/**", "destination": "hbohlen-systems", "priority": 1}
{"route": "home-manager/**", "destination": "hbohlen-systems", "priority": 2}
{"route": "docs/**", "destination": "hbohlen-systems", "priority": 3}
{"route": "frontend/**", "destination": "frontend-repo", "priority": 2, "agent": "frontend-agent"}
{"route": "backend/**", "destination": "backend-repo", "priority": 2, "agent": "backend-agent"}
```

**Agent Work Assignment:**
```bash
# Agent startup sequence
AGENT_NAME="nixos-agent"
bd prime --agent $AGENT_NAME

# Check for assigned work
PinnedWork=$(bd hook --json | jq -r '.[].id')
if [ -n "$PinnedWork" ]; then
  echo "Found pinned work: $PinnedWork"
  bd update $PinnedWork --claim --json
else
  # Find routable work
  AvailableWork=$(bd ready --route "nixos/**" --json | jq -r '.[0].id')
  if [ -n "$AvailableWork" ]; then
    bd pin $AvailableWork --for $AGENT_NAME --start --json
    bd update $AvailableWork --claim --json
  fi
fi
```

**Coordination Patterns:**

1. **Sequential Handoff**:
   ```bash
   # Agent A completes work
   bd close $ISSUE_A --reason "Implemented, ready for Agent B" --json
   
   # Creates gate for Agent B
   # Agent B checks for gates assigned to them
   bd ready --gate --json
   ```

2. **Parallel Work**:
   ```bash
   # Create epic with subtasks
   EPIC_ID=$(bd create "Performance optimization" -t epic --json | jq -r '.id')
   
   # Parallel subtasks (no dependencies between them)
   bd create "Optimize database queries" --parent $EPIC_ID --json
   bd create "Cache implementation" --parent $EPIC_ID --json
   bd create "Frontend bundler optimization" --parent $EPIC_ID --json
   
   # Multiple agents can work in parallel
   ```

3. **Fan-out/Fan-in**:
   ```bash
   # Agent 1: Creates multiple subtasks (fan-out)
   for SUBTASK in "task1" "task2" "task3"; do
     bd create "$SUBTASK" --parent $EPIC_ID --json
   done
   
   # Multiple agents work on subtasks in parallel
   # Agent 2: Waits for all subtasks, integrates (fan-in)
   bd create "Integration" --parent $EPIC_ID --json
   # Set dependencies: integration blocks all subtasks
   ```

### Integration with Project Workflows

**Project Agent Infrastructure:**
```bash
# Integration with tmux worktrees
# agent-menu already manages worktrees
# beads can integrate by checking current worktree

# Agent coordination through existing infrastructure
# 1. agent-menu creates worktree
# 2. beads checks worktree context
# 3. beads routes work to appropriate agent/worktree
# 4. Progress tracked through beads issues
```

**NixOS Multi-agent Testing:**
```bash
# Route NixOS testing work
bd route add "nixos-test/**" --destination "test-agent" --priority 1 --json

# Test agent picks up work
bd ready --route "nixos-test/**" --json
```

### Potential Pitfalls and Troubleshooting

1. **Routing conflicts**: Multiple routes match same issue
   - **Resolution**: Routes evaluated in order; first match wins
   - **Fix**: Order routes from specific to general

2. **Agent contention**: Multiple agents try to claim same work
   - **Prevention**: Use `bd pin --start` to formally assign
   - **Detection**: `bd hook` shows current pins

3. **Cross-repo dependency breaks**: Target repo unavailable
   - **Detection**: `bd doctor` reports cross-repo issues
   - **Workaround**: Use local issues with detailed references

4. **File reservation conflicts**
   - **Check**: `bd reserve --status path/to/file --json`
   - **Resolution**: Wait for release or negotiate with reserving agent
