---
name: dolt-operations
description: Execute Dolt database operations — schema inspection, SQL queries, data migration, conflict resolution. Use when working directly with the Dolt database backend that powers beads.
tags: [dolt, database, sql, beads]
category: beads
metadata:
  version: "1.0"
  source: .agents/
---

# dolt-operations

Direct Dolt database operations for beads backend management.

## Overview

Dolt is a version-controlled SQL database that powers beads. This skill guides direct Dolt operations: inspecting schema, executing SQL queries, managing data, resolving conflicts, and performing migrations.

**Dolt storage location**: `.beads/dolt/` (typically gitignored unless configured otherwise)

## When to Use

- Inspecting issue database schema
- Running SQL queries to analyze or bulk-update issues
- Resolving Dolt merge conflicts
- Exporting/importing data for backup or migration
- Debugging data inconsistencies
- Performing complex queries that can't be expressed with `bd` CLI

## Prerequisites

- Beads initialized in project: `bd init` (creates `.beads/dolt/`)
- Dolt CLI installed (included in nix develop)
- Basic SQL knowledge

## Core Operations

### Database Initialization and Status

```bash
# Check Dolt status (from within project with .beads/)
dolt status

# See Dolt version and configuration
dolt version
dolt config list

# Show current branch
dolt branch

# See commit log
dolt log --oneline
```

### Schema Inspection

```bash
# List all tables in beads database
dolt tables

# Inspect specific table schema
dolt schema show issues
dolt schema show issues --json

# Show table structure in detail
dolt describe issues

# Example output:
# ┌───────────────────┬─────────┬────────┬─────────┐
# │ Field             │ Type    │ Null   │ Key     │
# ├───────────────────┼─────────┼────────┼─────────┤
# │ id                │ varchar │ NO     │ PRI     │
# │ title             │ varchar │ YES    │         │
# │ description       │ text    │ YES    │         │
# │ status            │ varchar │ YES    │         │
# │ priority          │ int     │ YES    │         │
# │ created_at        │ varchar │ YES    │         │
# │ updated_at        │ varchar │ YES    │         │
# └───────────────────┴─────────┴────────┴─────────┘

# List all tables with row counts
dolt sql -q "SELECT table_name, row_count FROM information_schema.tables \
  WHERE table_schema = 'beads' ORDER BY row_count DESC"
```

### Querying Issue Data

```bash
# Get all open issues, sorted by priority
dolt sql -q "SELECT id, title, priority, status \
  FROM issues \
  WHERE status = 'open' \
  ORDER BY priority ASC, created_at DESC"

# Count issues by type and status
dolt sql -q "SELECT type, status, COUNT(*) as count \
  FROM issues \
  GROUP BY type, status \
  ORDER BY type, status"

# Find issues with specific label
dolt sql -q "SELECT i.id, i.title, i.priority \
  FROM issues i \
  JOIN issue_labels il ON i.id = il.issue_id \
  WHERE il.label_name = 'nixos' \
  ORDER BY i.priority"

# Show issue dependencies
dolt sql -q "SELECT \
    d.source_id as 'from', \
    d.target_id as 'to', \
    d.relation_type as 'type' \
  FROM dependencies d \
  WHERE d.source_id = 'bd-a1b2' OR d.target_id = 'bd-a1b2' \
  ORDER BY d.created_at DESC"

# Find orphaned issues (no dependencies, never referenced)
dolt sql -q "SELECT i.id, i.title, i.created_at \
  FROM issues i \
  LEFT JOIN dependencies d ON i.id = d.source_id OR i.id = d.target_id \
  WHERE d.id IS NULL \
  AND i.status = 'closed' \
  ORDER BY i.created_at DESC \
  LIMIT 100"
```

### Data Modification via SQL

```bash
# Bulk update issue priority
dolt sql -q "UPDATE issues SET priority = 2 \
  WHERE type = 'chore' AND priority IS NULL"

# Bulk add label to issues matching criteria
# NOTE: This depends on actual table structure; use dolt schema show labels

# Archive old closed issues
dolt sql -q "INSERT INTO issues_archive \
  SELECT * FROM issues \
  WHERE status = 'closed' AND updated_at < date('2025-12-01')"

dolt sql -q "DELETE FROM issues \
  WHERE status = 'closed' AND updated_at < date('2025-12-01')"

# Commit changes
dolt add -A
dolt commit -m "Bulk update: archived old closed issues"
```

### Git-like Operations

```bash
# See what changed in Dolt
dolt diff

# Show diff for specific table
dolt diff issues

# Show specific commit details
dolt show <commit-hash>

# Add and commit changes
dolt add -A
dolt commit -m "Fix: corrected issue priority values"

# See branch list
dolt branch -a

# Create new branch for experimental changes
dolt checkout -b experimental-cleanup

# Merge another branch
dolt merge main

# Push changes to remote (if configured)
dolt push origin beads-sync
```

### Conflict Resolution

```bash
# Check for conflicts after merge
dolt status

# View conflicts
dolt conflicts

# View conflicted table in detail
dolt conflicts show issues

# Resolve by using ours (current branch)
dolt conflicts resolve --ours issues

# Resolve by using theirs (merged branch)
dolt conflicts resolve --theirs issues

# Manually resolve (edit the table and resolve)
# See dolt documentation for detailed conflict resolution

# Finalize resolution
dolt add issues
dolt commit -m "Resolved merge conflict in issues table"
```

## Common Troubleshooting Queries

### Finding Data Integrity Issues

```bash
# Check for NULL ids (should never happen)
dolt sql -q "SELECT * FROM issues WHERE id IS NULL"

# Find issues with missing titles
dolt sql -q "SELECT id, type, status FROM issues \
  WHERE title IS NULL OR title = ''"

# Check for duplicate issue IDs (should never happen)
dolt sql -q "SELECT id, COUNT(*) as count FROM issues \
  GROUP BY id HAVING count > 1"

# Verify status values are valid
dolt sql -q "SELECT DISTINCT status FROM issues ORDER BY status"
# Expected: closed, in_progress, open

# Find issues with impossible state combinations
dolt sql -q "SELECT id, title, status, priority \
  FROM issues \
  WHERE (status = 'closed' AND updated_at > date('now')) \
  OR priority < 0 OR priority > 4"
```

### Analyzing Issue Load

```bash
# Recent issue creation rate
dolt sql -q "SELECT \
    DATE(created_at) as date, \
    COUNT(*) as issues_created \
  FROM issues \
  WHERE created_at > date('now', '-30 days') \
  GROUP BY DATE(created_at) \
  ORDER BY date DESC"

# Issues by priority distribution
dolt sql -q "SELECT priority, COUNT(*) as count \
  FROM issues \
  WHERE status = 'open' \
  GROUP BY priority \
  ORDER BY priority"

# Aging issues (old open issues)
dolt sql -q "SELECT id, title, priority, created_at \
  FROM issues \
  WHERE status = 'open' \
  AND created_at < date('now', '-30 days') \
  ORDER BY created_at ASC \
  LIMIT 20"

# Claimed but never closed (stuck work)
dolt sql -q "SELECT id, title, priority, claimed_by, claimed_at \
  FROM issues \
  WHERE status IN ('in_progress', 'claimed') \
  AND claimed_at < date('now', '-7 days') \
  AND updated_at < date('now', '-7 days')"
```

## Data Export and Migration

### Export for Backup

```bash
# Export entire database to SQL dump
dolt dump -r sql > beads-backup.sql

# Export specific table
dolt sql -q "SELECT * FROM issues" --format csv > issues-export.csv

# Export as JSON (for analysis)
dolt sql -q "SELECT * FROM issues WHERE status = 'open'" --format json > open-issues.json

# Export with Git history
dolt log --json > beads-history.json
```

### Import from Backup

```bash
# Restore from SQL dump
dolt source < beads-backup.sql

# Import CSV into table
dolt table import -u issues issues-export.csv

# Verify import
dolt sql -q "SELECT COUNT(*) as row_count FROM issues"
```

### Data Migration Workflow

```bash
# 1. Create migration branch
dolt checkout -b migrate-schema-v2

# 2. Create new table with updated schema
dolt sql -q "CREATE TABLE issues_v2 LIKE issues"
dolt sql -q "ALTER TABLE issues_v2 ADD COLUMN assigned_to VARCHAR(255)"

# 3. Migrate data
dolt sql -q "INSERT INTO issues_v2 \
  SELECT id, title, description, status, priority, \
         created_at, updated_at, NULL as assigned_to \
  FROM issues"

# 4. Verify counts match
dolt sql -q "SELECT 'issues' as table_name, COUNT(*) FROM issues \
  UNION ALL \
  SELECT 'issues_v2', COUNT(*) FROM issues_v2"

# 5. Rename tables (swap)
dolt sql -q "DROP TABLE issues_old"
dolt sql -q "ALTER TABLE issues RENAME TO issues_old"
dolt sql -q "ALTER TABLE issues_v2 RENAME TO issues"

# 6. Commit
dolt add -A
dolt commit -m "Migration: added assigned_to column to issues"

# 7. Test thoroughly before merging to main
dolt checkout main
dolt merge migrate-schema-v2
```

## Performance Optimization

### Create Indexes for Common Queries

```bash
# Index for status filtering (very common)
dolt sql -q "CREATE INDEX idx_issues_status ON issues(status)"

# Index for priority filtering
dolt sql -q "CREATE INDEX idx_issues_priority ON issues(priority)"

# Composite index for common filter combination
dolt sql -q "CREATE INDEX idx_issues_status_priority \
  ON issues(status, priority DESC)"

# Index on created_at for temporal queries
dolt sql -q "CREATE INDEX idx_issues_created_at ON issues(created_at)"

# Commit indexes
dolt add -A
dolt commit -m "Add: performance indexes for common queries"

# Verify indexes created
dolt sql -q "SELECT * FROM information_schema.statistics \
  WHERE table_schema = 'beads'"
```

### Query Explanation

```bash
# Analyze query performance
dolt sql -q "EXPLAIN SELECT id, title, priority FROM issues \
  WHERE status = 'open' ORDER BY priority"

# Extended explanation
dolt sql -q "EXPLAIN FORMAT=TREE SELECT id, title \
  FROM issues i \
  JOIN dependencies d ON i.id = d.source_id \
  WHERE d.target_id = 'bd-a1b2'"
```

## Safety Practices

### Before Making Major Changes

```bash
# 1. Create backup branch
dolt checkout -b backup-$(date +%s)

# 2. Do your work on main
dolt checkout main

# 3. Make changes
# ... do work ...

# 4. Verify changes before committing
dolt diff

# 5. Commit with descriptive message
dolt commit -m "Fix: description of change"

# 6. Push if configured
dolt push origin main
```

### Audit Trail

```bash
# See who made what changes
dolt log --oneline

# See changes by specific commit
dolt show <commit-hash>

# See changes to specific table
dolt log issues

# Restore to previous state if needed
dolt checkout <commit-hash> -- issues
```

## Common Workflows

### Fixing a Specific Issue's Data

```bash
# Find the issue
dolt sql -q "SELECT * FROM issues WHERE id = 'bd-a1b2'"

# Create branch for fix
dolt checkout -b fix-issue-bd-a1b2

# Update the issue
dolt sql -q "UPDATE issues SET priority = 1, status = 'open' \
  WHERE id = 'bd-a1b2'"

# Verify
dolt sql -q "SELECT * FROM issues WHERE id = 'bd-a1b2'"

# Commit
dolt add issues
dolt commit -m "Fix: corrected priority and status for bd-a1b2"

# Merge back to main
dolt checkout main
dolt merge fix-issue-bd-a1b2
```

### Periodic Cleanup

```bash
# Archive and remove very old issues (example: >1 year old closed issues)
dolt checkout -b cleanup-archive-2026

dolt sql -q "INSERT INTO archive_issues \
  SELECT * FROM issues \
  WHERE status = 'closed' AND updated_at < '2025-04-09'"

dolt sql -q "DELETE FROM issues \
  WHERE status = 'closed' AND updated_at < '2025-04-09'"

dolt add -A
dolt commit -m "Cleanup: archived issues closed before 2025-04-09"

dolt checkout main
dolt merge cleanup-archive-2026
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Query returns no results but data should exist | Verify table name with `dolt tables` and column names with `dolt describe <table>`. Try `SELECT *` to see available data. |
| Merge conflict in Dolt | Use `dolt conflicts` to see conflicts, then `dolt conflicts resolve` to fix. See Conflict Resolution section. |
| Dolt won't start | Run `dolt doctor` and fix suggested issues. Check `.beads/dolt/` directory permissions. |
| Changes disappeared after merge | Check branch with `dolt branch -a` and verify you merged from correct branch. Use `dolt log` to trace history. |
| Performance degradation | Check indexes with `dolt sql` query on `information_schema`. See Performance Optimization section. |

## See Also

- [`beads-workflow`](../beads-workflow/SKILL.md) — Beads CLI operations for issue management
- **Dolt documentation**: https://docs.dolthub.com/
- **SQL reference**: https://dev.mysql.com/doc/refman/8.0/en/
- **Reference docs** in `.agents/skills/beads/`: config.md, core.md, workflows.md
