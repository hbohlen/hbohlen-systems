# JJ (Jujutsu) Integration with Beads, Git, and PI

## Overview

This document outlines how to integrate Jujutsu (jj) with the workflow orchestrator, tracking jj operations in beads, and leveraging jj within the PI coding agent.

## What is Jujutsu (jj)?

Jujutsu is a version control system that uses Git as a storage backend while providing a different user experience. Key features:

- **Working-copy-as-a-commit**: Changes are automatically recorded as commits
- **No staging area**: All changes are always visible
- **Operation log**: Every operation is recorded, enabling undo at any point
- **Anonymous branches**: No need to create branch names for every change
- **Automatic rebase**: Descendant commits are automatically rebased when you modify ancestors
- **Change IDs**: Unique identifiers that persist across rewrites

## JJ + Git Integration

### Colocated Workspaces

JJ can work in two modes:

1. **Colocated (default)**: `.jj` and `.git` directories coexist, sharing the same working copy
   - JJ automatically imports from and exports to Git on every command
   - You can mix `jj` and `git` commands freely
   - Git tools work seamlessly (IDE, build tools)

2. **Non-colocated**: Git repo is hidden inside `.jj/repo/store/git`
   - Cleaner separation between jj and git operations
   - Must manually run `jj git import` and `jj git export`

### Key Commands

```bash
# Create a new jj repo (colocated by default)
jj git init myproject

# Clone a Git repo into jj
jj git clone https://github.com/user/repo

# Sync with remote
jj git push
jj git pull

# Import/Export (for non-colocated)
jj git import
jj git export

# Check status
jj st
jj log
```

### How JJ Tracks Git Operations

In colocated workspaces, JJ's operation log (`jj op log`) records:
- `git import` operations (when git refs change)
- `git export` operations (when jj changes are pushed to git)
- Git operations appear as "import git refs" in the operation log

## Beads + JJ Integration

### Tracking JJ Operations in Beads

The operation log provides a natural integration point for beads:

```bash
# View operation log
jj op log

# Get specific operation details
jj op show <operation-id>

# Undo operations
jj undo          # Undo last operation
jj op restore <operation-id>  # Restore to specific operation
```

### Integration Patterns

1. **Automatic Operation Tracking**
   - Parse `jj op log` output to extract operation metadata
   - Store operation IDs in beads for cross-referencing
   - Track which beads issue triggered which jj operation

2. **Change ID to Beads Mapping**
   - JJ Change IDs (e.g., `qpvuntsm`) are stable across rewrites
   - Map change IDs to beads issue IDs
   - Enables tracking work items across history rewrites

3. **Workspace Management**
   - JJ supports multiple working copies (`jj workspace`)
   - Each workspace can be mapped to different beads worktrees
   - Enables parallel development streams

### Proposed Beads Commands for JJ

```bash
# Track jj operation with a beads issue
bd jj track <bead-id> --change-id=<jj-change-id>

# Link beads issue to jj change
bd jj link <bead-id> <jj-change-id>

# Show jj operations for a beads issue
bd jj ops <bead-id>

# Import jj operation context into beads notes
bd jj import <operation-id>
```

## PI + JJ Integration

### PI Hooks for JJ

PI can leverage hooks to integrate with jj:

1. **Post-Operation Hooks**: Run after jj commands
   - Parse operation log for new changes
   - Update beads with operation metadata
   - Trigger downstream actions

2. **Workspace Hooks**: Manage jj workspaces
   - Create workspaces for new beads worktrees
   - Sync workspace state with beads status

### Implementation Strategy

```python
# pi-hooks/jj_integration.py

import subprocess
import json
from pathlib import Path

def get_jj_operations(since=None):
    """Get jj operations since a given point."""
    cmd = ["jj", "op", "log", "--json"]
    if since:
        cmd.extend(["--at-op", since])
    result = subprocess.run(cmd, capture_output=True, text=True)
    return [json.loads(line) for line in result.stdout.strip().split('\n')]

def track_beads_operation(beads_id, jj_change_id):
    """Link a beads issue to a jj change."""
    # Add jj change ID to beads notes
    subprocess.run([
        "bd", "update", beads_id,
        "--notes", f"jj change: {jj_change_id}"
    ])

def sync_workspace(beads_id):
    """Ensure jj workspace matches beads worktree."""
    worktree_path = Path(f".worktrees/{beads_id}")
    if not worktree_path.exists():
        # Create new workspace
        subprocess.run(["jj", "workspace", "new", str(worktree_path)])
```

### JJ as Backend for PI

Since jj provides:
- **Operation logging**: Complete audit trail
- **Change IDs**: Stable identifiers across rewrites
- **Multiple workspaces**: Parallel development support
- **Git compatibility**: Works with existing tooling

PI could potentially use jj as a VCS backend for:
1. Workspace management
2. Operation tracking and undo
3. Change correlation across sessions

## Recommended Integration Steps

1. **Phase 1: Basic Tracking**
   - Create hooks that parse `jj op log`
   - Store operation metadata in beads notes
   - Map change IDs to beads issues

2. **Phase 2: Workspace Integration**
   - Implement `bd jj` commands
   - Create workspaces for worktrees
   - Sync status between beads and jj

3. **Phase 3: Advanced Features**
   - Automatic change ID linking
   - Operation replay for session recovery
   - Cross-repo change tracking

## References

- [JJ Git Compatibility Documentation](https://docs.jj-vcs.dev/latest/git-compatibility/)
- [JJ Operation Log](https://docs.jj-vcs.dev/latest/operation-log/)
- [JJ Git Command Reference](https://docs.jj-vcs.dev/latest/git-command-table/)
- [JJ Git Comparison](https://docs.jj-vcs.dev/latest/git-comparison/)
