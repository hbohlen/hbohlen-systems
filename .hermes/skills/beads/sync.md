# Skill: Sync & Data Management

### Purpose and Scope
Manage database synchronization, data integrity, and integration with git. This skill is critical for data preservation and collaboration.

### Essential Commands

```bash
# CRITICAL: Always sync at end of work session
bd sync

# Export/Import for backup and migration
bd export -o beads-backup-$(date +%Y%m%d).jsonl
bd import -i beads-backup.jsonl --orphan-handling resurrect

# Git hook management
bd hooks install  # Install git hooks for auto-sync
bd hooks status --json
bd hooks uninstall

# Database maintenance and health checks
bd doctor --fix
bd doctor --verbose --json

# Migration between versions
bd migrate --inspect --json
bd migrate --dry-run --json
bd migrate --cleanup --json

# System information
bd info --json
bd stats --json
bd version --json
```

### Common Patterns and Best Practices

**Session Management Workflow:**
```bash
# Start of session
bd prime  # Get AI-optimized context
bd info --whats-new --json  # Check for updates

# During session - regular work
# ... issue management commands ...

# End of session (MANDATORY)
bd sync
echo "Session sync complete. Database committed and pushed."

# Optional: Create backup
bd export -o session-backup-$(date +%Y%m%d-%H%M%S).jsonl
```

**Git Integration Workflow:**
```bash
# Initialize with git integration
bd init --branch beads-sync --quiet

# Install hooks (recommended for auto-sync)
bd hooks install

# Worktree awareness (automatic)
# When working in git worktrees, beads auto-uses embedded mode

# Conflict resolution after git merges
bd doctor --fix
```

**Backup Strategy:**
```bash
# Daily backup script
BACKUP_FILE="beads-backup-$(date +%Y%m%d).jsonl"
bd export -o $BACKUP_FILE
gzip $BACKUP_FILE
# Upload to backup storage...

# Restore from backup
gunzip beads-backup-20250409.jsonl.gz
bd import -i beads-backup-20250409.jsonl --orphan-handling resurrect
```

### Integration with Project Workflows

**NixOS CI/CD Integration:**
```bash
# In CI pipeline - sandbox mode for ephemeral environments
bd --sandbox list --json
bd --sandbox ready --json

# Export results from CI run
bd --sandbox export -o ci-results.jsonl

# Import into main database
bd import -i ci-results.jsonl --orphan-handling allow
```

**Kiro Spec Data Management:**
```bash
# Export Kiro spec issues for review
bd export --label kiro-spec -o kiro-spec-review.jsonl

# Import updated spec
bd import -i updated-kiro-spec.jsonl --orphan-handling strict
```

### Potential Pitfalls and Troubleshooting

1. **Forgetting `bd sync`**: Risk of data loss
   - **Prevention**: Make `bd sync` last command in agent session
   - **Recovery**: Check if unsynced data exists with `bd info --json`

2. **Git merge conflicts** in beads data
   - **Detection**: `bd doctor` will report conflicts
   - **Resolution**: `bd doctor --fix` or manual conflict resolution

3. **Database corruption**
   - **Prevention**: Regular backups with `bd export`
   - **Recovery**: Restore from backup or use `bd doctor --fix`

4. **Hook failures**
   - **Diagnosis**: `bd hooks status --json`
   - **Fix**: Reinstall with `bd hooks install --force`
