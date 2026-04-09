# Skill: Workflow Orchestration

### Purpose and Scope
Use formulas, molecules, gates, and wisps for complex, repeatable workflows. This skill enables automation of common project tasks.

### Essential Commands

```bash
# Formula management
bd pour nixos-module --var name="tailscale" --var description="VPN mesh" --json
bd pour --dry-run kiro-spec --var feature="auth" --json  # Preview

# Molecule management
bd mol list --json
bd mol show mol-abc123 --json
bd mol archive mol-abc123 --json  # Archive completed molecule

# Gate management
bd gate approve gate-xyz --approver "ai-agent" --json
bd gate skip gate-xyz --reason "Emergency deployment" --json
bd show gate-xyz --json  # Check gate status

# Wisp management (ephemeral)
bd wisp create quick-test --var test="integration" --json
bd wisp update wisp-abc.1 --claim --json
bd wisp close wisp-abc.1 --json
```

### Common Patterns and Best Practices

**Formula Lifecycle:**
```toml
# Example: .beads/formulas/nixos-module.toml
formula = "nixos-module"
description = "Create a NixOS module"
version = "1.0.0"
type = "workflow"

[vars]
name = { required = true, pattern = "^[a-z][a-z0-9-]*$" }
description = { required = true, default = "NixOS module" }

[[steps]]
id = "create-module"
title = "Create module {{.name}}"
type = "task"
description = "Create NixOS module {{.name}}"

[[steps]]
id = "add-options"
title = "Add configuration options"
type = "task"
description = "Add NixOS options for {{.name}}"
needs = ["create-module"]

[[steps]]
id = "document"
title = "Document module"
type = "task"
description = "Add documentation for {{.name}}"
needs = ["add-options"]
```

**Molecule Execution:**
```bash
# Create molecule from formula
MOL_ID=$(bd pour nixos-module --var name="tailscale" --json | jq -r '.id')

# Work through steps
bd update $MOL_ID.1 --claim --json  # Step 1: create-module
# ... implement ...
bd close $MOL_ID.1 --reason "Module structure created" --json

bd ready --json  # Now shows $MOL_ID.2 (add-options)
bd update $MOL_ID.2 --claim --json
# ... continue ...
```

**Gate Coordination:**
```bash
# Human approval gate
GATE_ID=$(bd show $MOL_ID.3 --json | jq -r '.gate')  # Get gate ID from step
bd gate approve $GATE_ID --approver "ai-agent" --json

# Timer gate (auto-progresses after time)
# Check if timer expired
bd show $GATE_ID --json | jq -r '.status'

# GitHub gate (waits for CI)
# Gate auto-closes when CI passes
```

### Integration with Project Workflows

**NixOS Module Creation Workflow:**
```bash
# Complete module creation workflow
bd pour nixos-module \
  --var name="postgresql-ha" \
  --var description="High-availability PostgreSQL cluster" \
  --json

# Results in molecule with steps:
# 1. create-module (task)
# 2. add-options (task) 
# 3. document (task)
# 4. test (gate - human approval)
# 5. merge (task)
```

**Kiro Spec Execution Workflow:**
```bash
# Kiro spec as formula
bd pour kiro-spec \
  --var feature="multi-agent-routing" \
  --var phase="implementation" \
  --json

# Steps might include:
# 1. requirements-review (gate)
# 2. design-approval (gate)
# 3. implementation (task)
# 4. validation (task)
# 5. deployment (gate)
```

**CI/CD Pipeline as Formula:**
```toml
# .beads/formulas/nixos-test.toml
formula = "nixos-test"
description = "Test NixOS configuration"
version = "1.0.0"

[[steps]]
id = "build"
title = "Build configuration"
type = "task"

[[steps]]
id = "test-vm"
title = "Test in VM"
type = "task"
needs = ["build"]

[[steps]]
id = "deploy-approval"
title = "Deployment approval"
type = "gate"
gate_type = "human"
approvers = ["lead-engineer"]
needs = ["test-vm"]
```

### Potential Pitfalls and Troubleshooting

1. **Formula validation errors**
   - **Diagnosis**: `bd pour --dry-run` shows errors
   - **Fix**: Check TOML syntax and variable definitions

2. **Stuck gates**
   - **Check**: `bd show <gate-id> --json`
   - **Bypass**: `bd gate skip <gate-id> --reason "Emergency" --json`

3. **Molecule step dependencies wrong**
   - **Check**: `bd mol show <mol-id> --json` shows dependency graph
   - **Fix**: May need to recreate molecule with corrected formula

4. **Wisp data loss** (by design)
   - **Note**: Wisps are ephemeral and don't sync
   - **Workaround**: Export important wisp results with `bd wisp export`
