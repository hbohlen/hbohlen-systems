# Research: Error Handling and Recovery in Integrated Workflow

## Overview

This document covers error handling and recovery strategies for an integrated workflow using:
- **JJ (Jujutsu)** - Version control
- **BD (Beads)** - Issue tracking  
- **Pi Coding Agent** - AI coding agent

---

## 1. JJ (Jujutsu) Error Handling & Recovery

### 1.1 Operation Log - The Safety Net

JJ maintains an **operation log** that records every operation modifying the repo. This is JJ's primary recovery mechanism.

```bash
# View operation log
jj op log

# Undo the last operation
jj undo

# Undo a specific operation by ID
jj undo --at-operation <operation-id>

# Restore repo to a previous state
jj op restore <operation-id>

# Redo (after undo)
jj redo
```

**Key concepts:**
- Operations are identified by a hash (e.g., `zzz`)
- Use `@` to reference current operation
- Parent/child operators: `@-`, `@+`
- Each operation contains a snapshot (view) of the repo state

### 1.2 Working Copy Snapshots

JJ automatically snapshots the working copy whenever you run a `jj` command. This provides protection against:
- Accidental file deletion
- Broken changes
- AI agent mishaps

```bash
# See current working copy state
jj st

# See working copy in the operation log
jj log -p -r @

# Restore working copy to a specific revision
jj checkout <revision>
```

### 1.3 Abandoned Commits

When you rebase or amend commits, the old versions become "abandoned" but are NOT immediately deleted. They can be recovered:

```bash
# Find abandoned commits
jj log -r 'all()'

# Restore an abandoned commit
jj adopt <abandoned-change-id>

# Or create a new change from abandoned
jj duplicate <abandoned-change-id>
```

### 1.4 Conflict Resolution

JJ handles conflicts differently than Git - they're recorded as "first-class conflicts" that can be resolved later:

```bash
# See conflicts in working copy
jj st

# List all conflicts in repo
jj log -r 'conflicts()'

# Resolve a conflict (edit the file normally)
# Then:
jj resolve <file>

# Usejj fix to auto-resolve (formatting, etc.)
jj fix
```

**Key insight:** Unlike Git, you CAN commit conflicts and resolve them later. This is huge for AI agents - they don't need to resolve conflicts immediately.

### 1.5 Common JJ Errors & Solutions

| Error | Solution |
|-------|----------|
| "Nothing changed" after push | Use `jj git push --change` or create bookmark first |
| Bookmark not moving | Use `jj bookmark move` (no "current bookmark" concept) |
| Commit not visible in log | Use `jj log -r 'all()'` to see all commits |
| Working copy conflicts | Use `jj st` to see, resolve or abandon |

---

## 2. Beads (BD) Error Handling

### 2.1 Local State Recovery

BD uses Dolt (Git-like SQL database) for persistence. Recovery options:

```bash
# Check BD status
bd status

# View recent operations
bd dolt sql -q "SELECT * FROM issues ORDER BY updated_at DESC LIMIT 10"

# Reset to known good state
bd dolt checkout main
bd dolt reset --hard HEAD
```

### 2.2 Sync Issues

```bash
# Force sync with remote
bd sync

# Push to remote
bd dolt push

# Pull from remote
bd dolt pull
```

### 2.3 JSONL Backup

BD exports to `.beads/issues.jsonl` for backup:
```bash
# Manual backup
bd export > backup.jsonl

# Restore from backup
bd import < backup.jsonl
```

---

## 3. Pi Coding Agent Recovery

### 3.1 Session Context Loss

When context is compacted or lost:

1. **Check BD** for current task: `bd ready`
2. **Check JJ** for uncommitted work: `jj st`
3. **Check JJ operation log**: `jj op log`

### 3.2 File Recovery Strategies

```bash
# View recent working copy changes
jj diff

# Restore specific files
jj checkout --from=<revision> -- <file>

# See all file versions
jj file history <file>
```

### 3.3 Agent Best Practices

1. **Commit frequently** - JJ makes this cheap
2. **Use descriptive messages** - Helps with recovery
3. **Track progress in BD** - Survives session compaction
4. **Check JJ status before major operations** - Always know where you are

---

## 4. Integrated Workflow Recovery Checklist

When something goes wrong in the integrated workflow:

### Step 1: Assess JJ State
```bash
jj st          # What's in working copy?
jj op log      # Recent operations?
jj log         # Recent commits
```

### Step 2: Assess BD State
```bash
bd ready       # What's the current task?
bd show <id>   # Get task details
```

### Step 3: Recovery Actions

| Scenario | Action |
|----------|--------|
| Lost uncommitted work | `jj undo` or `jj op restore` |
| Abandoned commit needed | `jj log -r 'all()'` → find → `jj adopt` |
| Lost BD state | `bd dolt pull` or restore from JSONL |
| Wrong branch/bookmark | `jj bookmark move` or `jj rebase` |
| Context lost | Re-read BD task, check JJ for work in progress |

---

## 5. Prevention Strategies

### 5.1 JJ Habits for AI Agents
- Use `jj git init --colocate` for existing git repos
- Run `jj st` before any potentially destructive operation
- Use `jj describe -m` for descriptive messages
- Enable auto-save by just running JJ commands frequently

### 5.2 BD Habits
- Always claim tasks before working: `bd update <id> --claim`
- Add notes as you work: `bd update <id> --notes "..."`
- Close tasks when done: `bd close <id> --reason "..."`
- Sync regularly: `bd sync`

### 5.3 Recovery Commands Reference Card

```bash
# JJ Recovery
jj op log                    # See history
jj undo                      # Undo last operation
jj redo                      # Redo
jj op restore <op>           # Restore to specific operation
jj log -r 'all()'            # See ALL commits (including abandoned)
jj adopt <change-id>         # Recover abandoned change
jj st                        # Check current state

# BD Recovery  
bd ready                     # Get current work
bd show <id>                 # Get task context
bd sync                      # Sync with remote
bd dolt pull                 # Pull latest

# Combined Workflow
jj st && bd ready            # Quick status check
```

---

## Sources

- https://docs.jj-vcs.dev/latest/operation-log/
- https://docs.jj-vcs.dev/latest/FAQ/
- https://docs.jj-vcs.dev/latest/technical/conflicts/
- https://www.panozzaj.com/blog/2025/11/22/avoid-losing-work-with-jujutsu-jj-for-ai-coding-agents/
- https://steveklabnik.github.io/jujutsu-tutorial/branching-merging-and-conflicts/conflicts.html
- https://zerowidth.com/2025/what-ive-learned-from-jj/
