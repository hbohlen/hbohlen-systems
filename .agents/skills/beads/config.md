# Skill: Configuration & Advanced

### Purpose and Scope
Configure beads for project-specific needs and use advanced features. This skill optimizes beads for the hbohlen-systems environment.

### Essential Commands

```bash
# Configuration management
bd config get --json
bd config set database.path ".beads/db" --json
bd config set dolt.auto_commit "on" --json

# Backend management
bd backend list --json
bd backend switch dolt --json
bd backend status --json

# Performance and optimization
bd stats --json  # Database statistics
bd profile --json  # Performance profiling

# Advanced querying
bd query 'priority = 0 AND status = "open"' --json
bd query 'labels @> ["security"] AND updated_at > "2026-04-01"' --json

# Maintenance operations
bd vacuum --json  # Clean up database
bd reindex --json  # Rebuild indexes
```

### Common Patterns and Best Practices

**Project Configuration (config.toml):**
```toml
# .beads/config.toml
[database]
backend = "dolt"
path = ".beads/dolt"  # User prefers git-tracked

[dolt]
auto_commit = "on"
remote = "origin"
branch = "beads-sync"
commit_author = "AI Agent <agent@hbohlen-systems>"

[git]
worktree_aware = true
protected_branches = ["main", "master"]
hooks = true

[hooks]
pre_commit = ["bd sync"]
post_merge = ["bd sync --import"]
pre_push = ["bd sync"]

[agent]
name = "ai-agent"
sandbox = false
readonly = false
audit = true

[performance]
concurrent_nix_builds = 4
cache_warming = true
query_cache_size = "100MB"

[storage]
compression = "zstd"
auto_vacuum = "on"

# NixOS-specific
[nixos]
module_pattern = "**/nixos/**"
home_manager_pattern = "**/home-manager/**"
flake_pattern = "**/flake.nix"
```

**NixOS Optimization:**
```bash
# Configure for Nix build environment
bd config set performance.concurrent_nix_builds $(nproc) --json
bd config set storage.compression "zstd" --json

# Monitor performance
bd stats --json | jq '.performance'
bd profile --duration 30s --json  # Profile for 30 seconds
```

**Advanced Query Patterns:**
```bash
# Find security issues needing attention
bd query 'priority = 0 AND labels @> ["security"] AND status = "open"' --json

# Find stale issues (not updated in 7 days)
bd query 'updated_at < date("now", "-7 days") AND status = "open"' --json

# Find issues with specific dependency patterns
bd query 'EXISTS (SELECT 1 FROM dependencies WHERE type = "blocks")' --json

# Complex Kiro spec queries
bd query 'labels @> ["kiro-spec"] AND created_at > date("now", "-30 days")' --json
```

### Integration with Project Workflows

**NixOS-Specific Configuration:**
```bash
# Set up for hbohlen-systems environment
bd config set nixos.module_path "./nixos" --json
bd config set nixos.home_manager_path "./home" --json
bd config set git.protected_branches "[\"main\"]" --json

# Configure audit trail for AI agents
bd config set agent.audit true --json
bd config set agent.name "$AGENT_NAME" --json
```

**Performance Monitoring:**
```bash
# Regular health checks
bd doctor --json | jq -r '.health.status'

# Database statistics
bd stats --json | jq '
  {
    total_issues: .issues.total,
    open_issues: .issues.open,
    avg_priority: .issues.avg_priority,
    db_size_mb: .database.size_mb
  }
'

# Performance profiling during heavy loads
bd profile --json > profile-$(date +%s).json
```

### Potential Pitfalls and Troubleshooting

1. **Configuration drift**: Different agents have different configs
   - **Prevention**: Commit `.beads/config.toml` to git
   - **Check**: `bd config get --json` and compare

2. **Performance degradation** with large database
   - **Diagnosis**: `bd stats --json` shows size and indexes
   - **Fix**: `bd vacuum --json` and `bd reindex --json`

3. **Backend issues** (Dolt problems)
   - **Diagnosis**: `bd backend status --json`
   - **Recovery**: `bd doctor --fix` or switch backend temporarily

4. **Query performance issues**
   - **Diagnosis**: `bd profile --json` during slow queries
   - **Fix**: Add indexes or simplify query patterns
