---
name: nix-eval-for-agents
description: Use when inspecting, exploring, or testing Nix flake outputs, options, packages, or configurations - especially in non-interactive/CI environments where nix repl is impractical
---

# Nix Evaluation for Agents

Use `nix eval` and `nix build` instead of `nix repl` for scripting, CI, and agent workflows.

## Quick Reference

| Task | Command |
|------|---------|
| Inspect a value | `nix eval .#path.to.value` |
| JSON output | `nix eval --json .#path` |
| Raw string output | `nix eval --raw .#path` (strings only!) |
| Fast eval (no instantiation) | `nix eval --read-only .#path` |
| List attribute names | `nix eval --json .#path --apply builtins.attrNames` |
| Show flake outputs | `nix flake show` |
| Dry-run build | `nix build .#target --dry-run` |
| Build with JSON | `nix build .#target --json --no-link` |
| Print store path | `nix build .#target --print-out-paths` |
| Run specific check | `nix build .#checks.x86_64-linux.checkName` |
| Test assertions | `nix eval .#path --apply (x: x == expected)` |
| Derivation details | `nix derivation show .#target` |
| Flake lock info | `nix flake metadata . --json` |
| List checks | `nix eval --json .#checks --apply builtins.attrNames` |
| List NixOS configs | `nix eval --json .#nixosConfigurations --apply builtins.attrNames` |
| List devShells | `nix eval --json .#devShells.x86_64-linux --apply builtins.attrNames` |

## Core Patterns

### Inspect Option Defaults

```bash
# Get a NixOS option's value (works for any type)
nix eval .#nixosConfigurations.hbohlen-01.config.services.opencode.port
# Output: 8081 (integer, no quotes)

# For strings, use --raw to remove quotes:
nix eval --raw .#nixosConfigurations.hbohlen-01.config.networking.hostName
# Output: hbohlen-01 (no quotes)

# Test option value with assertion
nix eval .#nixosConfigurations.hbohlen-01.config.services.opencode.port \
  --apply (p: p == 8081)
# Output: true

# Check if an option is defined
nix eval .#nixosConfigurations.hbohlen-01.config.services.opencode \
  --apply builtins.isAttrs
```

### Explore Package Outputs

```bash
# Get the store path (won't build, just evaluates)
nix eval --raw .#packages.x86_64-linux.hello

# List all packages in an attribute set
nix eval .#packages.x86_64-linux --apply builtins.attrNames --json
```

### Test Configuration Assembly

```bash
# Verify a NixOS config evaluates without error
nix eval .#nixosConfigurations.hbohlen-01.config.system.build.toplevel.drvPath

# Check hostName is correct
nix eval --raw .#nixosConfigurations.hbohlen-01.config.networking.hostName
```

### Inspect Dev Shell

```bash
# Verify devShell evaluates correctly (get drvPath)
nix eval --raw .#devShells.x86_64-linux.default.drvPath

# List available devShells
nix eval .#devShells.x86_64-linux --apply builtins.attrNames --json
# Output: ["ai","default"]

# Test devShell is a derivation
nix eval .#devShells.x86_64-linux.default.type --apply (t: t == "derivation")
```

### Run Targeted Checks

```bash
# Run only formatting check
nix build .#checks.x86_64-linux.formatting

# Run specific unit test (if using nix-unit)
nix build .#checks.x86_64-linux.testOpencodeEnableOptionDefault
```

## Performance Optimization

### `--read-only` Flag

Use `--read-only` to skip derivation instantiation — approximately **2x faster**:

```bash
# Normal eval (~2.2s) - evaluates and instantiates derivations
nix eval .#nixosConfigurations.hbohlen-01.config.networking.hostName

# Read-only eval (~1.0s) - only evaluates, no instantiation
nix eval --read-only .#nixosConfigurations.hbohlen-01.config.networking.hostName
```

**When to use `--read-only`:**
- Inspecting simple values (strings, integers, bools)
- Checking if an attribute exists
- Fast smoke tests before actual builds
- CI pipelines where speed matters

**When NOT to use `--read-only`:**
- When you need actual store paths (derivations need to be instantiated)
- When evaluating complex attrset that references derivations
- When `--json` or `--apply` returns derivation objects

### Fast Smoke Tests

| Method | Time | What it checks |
|--------|------|----------------|
| `nix build .#target --dry-run` | ~0.9s | Can it build? |
| `nix eval --read-only .#target.drvPath` | ~1.2s | Does it evaluate? |
| `nix eval .#target.drvPath` | ~2.2s | Full evaluation |

```bash
# Fastest smoke test: dry-run build
nix build .#checks.x86_64-linux.formatting --dry-run

# Alternative: check drvPath exists (faster than full eval)
nix eval --read-only .#checks.x86_64-linux.formatting.drvPath

# Structured result with dry-run
nix build .#checks.x86_64-linux.formatting --dry-run --json
```

## Type Handling

| Type | Example Value | Command | Output |
|------|---------------|---------|--------|
| String | `"hello"` | `--raw` | `hello` (no quotes) |
| Integer | `8081` | none | `8081` |
| Bool | `true` | none | `true` |
| Attrset | `{a=1;}` | `--json` | `{"a":1}` |
| List | `[1 2 3]` | `--json` | `[1,2,3]` |
| Derivation | `<derivation>` | `--raw .drvPath` | `/nix/store/...drv` |

### Type Inspection Commands

```bash
# String (use --raw to remove quotes)
nix eval --raw .#path.stringAttr

# Integer (no flag needed)
nix eval .#path.intAttr

# Bool (no flag needed)
nix eval .#path.boolAttr

# Attrset (use --json for full structure)
nix eval --json .#path.attrsetAttr

# List (use --json for full structure)
nix eval --json .#path.listAttr

# Derivation (access drvPath or outPath)
nix eval --raw .#path.derivationAttr.drvPath
nix eval --raw .#path.derivationAttr.outPath
```

### ⚠️ Warning: `--raw` Fails on Non-Strings

```bash
# WRONG - this fails because port is an integer
nix eval --raw .#nixosConfigurations.hbohlen-01.config.services.opencode.port

# CORRECT - integers output directly without quotes
nix eval .#nixosConfigurations.hbohlen-01.config.services.opencode.port
# Output: 8081

# Check type before using --raw
nix eval .#path --apply "builtins.isString"
```

## Derivation Inspection

Use `nix derivation show` to inspect build details without building:

```bash
# Show full derivation JSON
nix derivation show .#checks.x86_64-linux.statix

# Extract build command
nix derivation show .#checks.x86_64-linux.statix | jq -r '.[].env.buildCommand'

# List all input derivations
nix derivation show .#checks.x86_64-linux.statix | jq -r '.[].inputDrvs | keys[]'

# Show output paths
nix derivation show .#checks.x86_64-linux.statix | jq -r '.[].outputs | keys[]'

# Inspect environment variables
nix derivation show .#target | jq -r '.[].env | to_entries[] | "\(.key)=\(.value)"'
```

**When to use `nix derivation show`:**
- Debugging build failures
- Inspecting build environment variables
- Understanding what inputs a derivation depends on
- Verifying build commands before execution

## Flake Metadata Inspection

Use `nix flake metadata` to inspect lock file state:

```bash
# Get full metadata as JSON
nix flake metadata . --json

# Check last modified timestamp
nix flake metadata . --json | jq '.lastModified'

# Verify inputs are locked (not following)
nix flake metadata . --json | jq '.locked'

# Check for dirty git state
nix flake metadata . --json | jq '.dirty'

# Get flake revision
nix flake metadata . --json | jq '.revision'
```

**`nix flake metadata` vs `nix flake show`:**

| Command | Purpose | Output |
|---------|---------|--------|
| `nix flake show` | Structure discovery | Human-readable tree |
| `nix flake metadata` | Lock file state | JSON with timestamps, revisions |

## Check Enumeration Patterns

List available flake outputs without running them:

```bash
# List all checks (across all systems)
nix eval --json .#checks --apply builtins.attrNames

# List checks for specific system
nix eval --json .#checks.x86_64-linux --apply builtins.attrNames

# List all NixOS configurations
nix eval --json .#nixosConfigurations --apply builtins.attrNames

# List all devShells
nix eval --json .#devShells.x86_64-linux --apply builtins.attrNames

# List all packages for a system
nix eval --json .#packages.x86_64-linux --apply builtins.attrNames
```

**Contrast with `nix flake show`:**
```bash
# Human-readable discovery
nix flake show

# JSON for scripting
nix eval --json .#checks.x86_64-linux --apply builtins.attrNames | jq -r '.[]'
```

## Using `--apply` for Testing

The `--apply` flag lets you test expressions against flake outputs:

```bash
# Assert an attribute exists
nix eval .#packages.x86_64-linux --apply (pkgs: pkgs ? hello)

# Test option value equals expected
nix eval --json .#nixosConfigurations.hbohlen-01.config.services.opencode.port
# Compare output to expected: 8081

# Test boolean conditions
nix eval .#nixosConfigurations.hbohlen-01 --apply \
  "(cfg: cfg ? config && cfg.config ? services)"

# Test attribute type
nix eval .#path --apply "builtins.isAttrs"

# Test value equality
nix eval .#path --apply "(x: x == expected)"

# Combined checks
nix eval .#path --apply "(x: builtins.isAttrs x && x ? services)"

# Test list length
nix eval .#path --apply "(x: builtins.length x > 0)"

# Test string contains (NixOS >= 2.19)
nix eval .#path --apply "(x: builtins.stringLength x > 10)"
```

### ⚠️ Shell Quoting for `--apply`

When using `--apply` with complex expressions, use **double quotes** in bash:

```bash
# WRONG - single quotes prevent variable expansion
nix eval .#path --apply '(x: x == expected)'

# CORRECT - double quotes allow proper lambda syntax
nix eval .#path --apply "(x: x == expected)"

# For complex expressions, escape inner quotes
nix eval .#path --apply "(x: x ? nested.attr)"
```

## Error Recovery

### Capturing Errors

```bash
# Capture error output
nix eval .#broken.path 2>&1 | head -50

# Get full error with context
nix eval .#broken.path 2>&1

# Debug with verbose trace
nix eval --verbose .#path
```

### Safe Attribute Access

```bash
# Check nested attribute exists before accessing
nix eval .#path --apply "(x: x ? nested.attr)"

# Safe deep access pattern
nix eval .#nixosConfigurations.hbohlen-01.config --apply \
  "(cfg: if cfg ? services && cfg ? networking then true else false)"

# Check NixOS config is valid before accessing
nix eval .#nixosConfigurations.hbohlen-01.config.system.build.toplevel.drvPath
```

### For Complex Nix Errors

For complex evaluation errors that are hard to debug:
- Use the **`flake-debug`** skill for detailed error analysis

## CI/CD Integration

### JSON Output for Parsing

```bash
# Get as JSON array
nix eval --json .#checks.x86_64-linux --apply builtins.attrNames

# Pipe to jq for filtering
nix eval --json .#packages.x86_64-linux --apply builtins.attrNames | jq -r '.[]'

# Extract specific values
nix eval --json .#path | jq '.key'
```

### No Workspace Pollution

```bash
# Build without creating result symlink
nix build .#target --no-link

# Build with JSON output
nix build .#target --json --no-link

# Run multiple builds without pollution
nix build .#checks.x86_64-linux.{statix,deadnix,formatting} --no-link
```

### Exit Code Patterns

```bash
# Check if evaluation succeeds
nix eval .#path && echo "OK" || echo "FAILED"

# CI pipeline pattern
nix eval --read-only .#path.drvPath && \
  echo "Evaluation OK" || \
  { echo "Evaluation failed"; exit 1; }

# Smoke test in CI
nix build .#checks.x86_64-linux.formatting --dry-run && \
  echo "Buildable" || echo "Not buildable"
```

### Parallel Execution

```bash
# Run checks in parallel (background jobs)
nix build .#checks.x86_64-linux.statix --no-link &
nix build .#checks.x86_64-linux.deadnix --no-link &
nix build .#checks.x86_64-linux.formatting --no-link &
wait

# Or use make-style parallel builds
make -j$(nproc) checks
```

## JSON for Parsing

Always use `--json` when you need to parse output:

```bash
# Get as JSON array
nix eval --json .#checks.x86_64-linux --apply builtins.attrNames

# Pipe to jq for filtering
nix eval --json .#packages.x86_64-linux --apply builtins.attrNames | jq -r '.[]'
```

## Build Verification Patterns

```bash
# Dry-run to check for evaluation errors without building
nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel --dry-run

# Build check (no link creation)
nix build .#checks.x86_64-linux.formatting --no-link

# JSON build results for parsing
nix build .#packages.x86_64-linux.hello --json --no-link
```

## Decision Matrix: When to Use Each

| Scenario | Command | Reason |
|----------|---------|--------|
| Inspect a simple value | `nix eval` | Fast, no building |
| Need a store path | `nix build` | Realizes derivation |
| Just checking it works | `--dry-run` | Fastest smoke test |
| Inspect build details | `nix derivation show` | Full JSON with env, inputs |
| Check lock file state | `nix flake metadata` | Revisions, timestamps |
| Fast inspection | `--read-only` | 2x faster |
| Parse output programmatically | `--json` | Valid JSON for jq |
| Get clean string | `--raw` | No quotes |
| Discover available outputs | `nix flake show` | Human-readable tree |
| List outputs for scripting | `nix eval --apply builtins.attrNames` | JSON array |
| Run checks | `nix build .#checks.*` | Actual execution |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using `nix repl` in scripts | Use `nix eval --expr '...'` |
| Using `--raw` on integers | Don't use `--raw` on non-strings; it fails |
| Missing `--raw` for strings | Strings will be quoted; add `--raw` |
| Forgetting `--json` for parsing | Without it, output is Nix syntax |
| Building unnecessarily | Use `nix eval` to inspect without building |
| Not using `--dry-run` first | Catch evaluation errors before build |
| Using `--apply` wrong | `--apply` receives the value: `(v: expression_on_v)` |
| Forgetting `--read-only` for speed | Add `--read-only` when you don't need store paths |

## Debugging with `nix eval`

```bash
# See full error context
nix eval .#broken.path 2>&1 | head -50

# Debug evaluation with trace
nix eval --verbose .#path

# Check what a function returns
nix eval --json .#path --apply "f: f inputValue"
```
