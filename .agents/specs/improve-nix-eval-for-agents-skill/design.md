# Design: Improve nix-eval-for-agents Skill

## Overview

**Purpose**: Enhance the existing `nix-eval-for-agents` skill with performance optimizations, additional commands, and comprehensive patterns for agent-based Nix testing.

**Users**: AI agents working with Nix/NixOS projects in non-interactive environments.

**Impact**: Faster inspection times (2x improvement), broader command coverage, clearer decision guidance.

---

### Goals

- Document `--read-only` for 2x faster evaluation
- Add `nix derivation show` and `nix flake metadata` patterns
- Expand `--apply` testing patterns
- Create clear command decision matrix
- Add CI/CD integration patterns
- Improve error recovery guidance

### Non-Goals

- Adding `nix repl` patterns (interactive, not agent-friendly)
- Covering Nix language syntax (focused on commands)
- Documenting flake-parts internal mechanics
- Writing nix-unit test patterns

---

## Architecture

### Existing Skill Analysis

**Current State**: 164-line skill with basic `nix eval` and `nix build` patterns.

**Gaps Identified**:
1. Missing `--read-only` performance optimization
2. Missing `nix derivation show` for debugging
3. Missing `nix flake metadata` for lock inspection
4. Incomplete `--apply` patterns
5. No type-handling section
6. No CI/CD patterns
7. Decision matrix is minimal

### Skill Structure

```
SKILL.md (single file, target: ~300 lines)
├── Quick Reference Table (enhanced)
├── Core Patterns (expanded)
│   ├── Inspect Options (enhanced)
│   ├── Explore Packages (enhanced)
│   ├── NixOS Configs (new)
│   ├── Derivation Inspection (new)
│   └── Flake Metadata (new)
├── Performance Section (new)
│   ├── --read-only patterns
│   ├── Fast smoke tests
│   └── Timing comparison
├── Type Handling (new)
│   ├── Strings vs Integers
│   ├── Attrsets
│   └── Lists
├── Apply Patterns (expanded)
├── CI/CD Patterns (new)
├── Decision Matrix (expanded)
└── Error Recovery (enhanced)
```

### Technology Stack

| Layer | Tool | Role |
|-------|------|------|
| Skill | Markdown | Skill documentation |
| Commands | `nix eval`, `nix build`, `nix derivation`, `nix flake metadata` | Core tools |
| Parsing | `--json`, `jq` | Programmatic output |
| Performance | `--read-only`, `--dry-run` | Optimization flags |

---

## Requirements Traceability

| Requirement | Summary | Components |
|-------------|---------|------------|
| REQ-001 | Performance (`--read-only`) | Performance Section |
| REQ-002 | Derivation Inspection | Derivation Patterns |
| REQ-003 | Flake Metadata | Metadata Patterns |
| REQ-004 | Type Handling | Type Handling Section |
| REQ-005 | Apply Patterns | Apply Section |
| REQ-006 | Check Enumeration | NixOS Configs Section |
| REQ-007 | Fast Smoke Tests | Performance Section |
| REQ-008 | Error Recovery | Error Recovery Section |
| REQ-009 | CI/CD Integration | CI/CD Section |
| REQ-010 | Decision Matrix | Decision Section |

---

## Components and Interfaces

### Quick Reference Table

| Intent | Command Pattern |
|--------|-----------------|
| Inspect value | `nix eval .#path` |
| JSON output | `nix eval --json .#path` |
| Raw string | `nix eval --raw .#path` (strings only) |
| Fast eval | `nix eval --read-only .#path` |
| List attrs | `nix eval --json .#path --apply builtins.attrNames` |
| Smoke test | `nix build .#target --dry-run` |
| Derivation JSON | `nix derivation show .#target` |
| Lock info | `nix flake metadata . --json` |

### Performance Section

**Coverage**: REQ-001, REQ-007

**Patterns**:
```bash
# Normal eval (~2.2s)
nix eval .#nixosConfigurations.hbohlen-01.config.networking.hostName

# Read-only eval (~1.0s) - 2x faster
nix eval --read-only .#nixosConfigurations.hbohlen-01.config.networking.hostName

# Dry-run build (~0.9s) - fastest smoke test
nix build .#checks.x86_64-linux.formatting --dry-run

# Smoke test via drvPath (~1.2s)
nix eval --read-only .#checks.x86_64-linux.formatting.drvPath
```

### Derivation Inspection Section

**Coverage**: REQ-002

**Patterns**:
```bash
# Show full derivation JSON
nix derivation show .#checks.x86_64-linux.statix

# Extract build command
nix derivation show .#target | jq -r '.[] | .env.buildCommand'

# List inputs
nix derivation show .#target | jq -r '.[] | .inputDrvs | keys[]'
```

### Flake Metadata Section

**Coverage**: REQ-003

**Patterns**:
```bash
# Get lock info
nix flake metadata . --json

# Check last modified
nix flake metadata . --json | jq '.lastModified'

# Verify inputs are locked
nix flake metadata . --json | jq '.locked'
```

### Type Handling Section

**Coverage**: REQ-004

| Type | Example Value | Command | Output |
|------|---------------|---------|--------|
| String | `"hbohlen-01"` | `--raw` | `hbohlen-01` |
| Integer | `8081` | none | `8081` |
| Bool | `true` | none | `true` |
| Attrset | `{a=1;}` | `--json` | `{"a":1}` |
| List | `[1 2 3]` | `--json` | `[1,2,3]` |
| Derivation | `<derivation>` | `--raw .drvPath` | `/nix/store/...drv` |

### Apply Patterns Section

**Coverage**: REQ-005

```bash
# Test attribute exists
nix eval .#path --apply "(x: x ? attr)"

# Test type
nix eval .#path --apply "builtins.isAttrs"

# Test value equality
nix eval .#path --apply "(x: x == expected)"

# Combine checks
nix eval .#path --apply "(x: builtins.isAttrs x && x ? services)"
```

### NixOS Configs Section

**Coverage**: REQ-006

```bash
# List all NixOS configurations
nix eval --json .#nixosConfigurations --apply builtins.attrNames

# List all checks per system
nix eval --json .#checks.x86_64-linux --apply builtins.attrNames

# List all devShells
nix eval --json .#devShells.x86_64-linux --apply builtins.attrNames
```

### CI/CD Section

**Coverage**: REQ-009

```bash
# JSON for parsing
nix eval --json .#path | jq '.key'

# No workspace pollution
nix build .#target --no-link --json

# Exit codes
nix eval .#path && echo "OK" || echo "FAILED"

# Parallel execution (in scripts)
nix build .#checks.{statix,deadnix,formatting} --no-link &
```

### Decision Matrix Section

**Coverage**: REQ-010

| Scenario | Command | Reason |
|----------|---------|--------|
| Inspect value | `nix eval` | No building |
| Need store path | `nix build` | Realizes derivation |
| Just checking | `--dry-run` | Fastest |
| Inspecting build | `nix derivation show` | Full details |
| Lock info | `nix flake metadata` | Lock file state |
| Fast inspection | `--read-only` | 2x faster |
| Need JSON | `--json` | Parseable |
| Clean string | `--raw` | No quotes |

### Error Recovery Section

**Coverage**: REQ-008

```bash
# Capture error
nix eval .#broken 2>&1 | head -50

# Verbose trace
nix eval --verbose .#path

# Safe attribute access
nix eval .#path --apply "(x: x ? nested.attr)"

# Reference to flake-debug skill
# For complex Nix errors, use: flake-debug skill
```

---

## Testing Strategy

### Unit Tests (Skill Verification)

1. **Performance verification**: Run timing comparison on `--read-only` vs normal
2. **Command accuracy**: Verify all example commands execute correctly
3. **JSON parsing**: Test `--json` output is valid JSON
4. **Type handling**: Test `--raw` fails on integers (expected behavior)
5. **Apply patterns**: Verify assertions return `true`/`false`

### Integration Tests

1. **Agent simulation**: Run task scenarios with/without skill
2. **Timing tests**: Verify smoke tests complete under 3 seconds
3. **Error handling**: Verify error patterns work as documented

### Validation Commands

```bash
# Verify skill loads (syntax check)
head -10 SKILL.md

# Verify commands work
nix eval --read-only .#checks.x86_64-linux.statix.drvPath
nix derivation show .#checks.x86_64-linux.statix | jq empty
nix flake metadata . --json | jq empty
```

---

## Supporting References

### Command Help Locations

- `nix eval --help`
- `nix build --help`
- `nix derivation --help`
- `nix flake metadata --help`

### Related Skills

- `flake-debug` - For complex Nix debugging (link in Error Recovery)
- `nixos-remote-install` - Uses similar patterns (potential cross-reference)

### Nix Documentation

- [Nix Manual: nix eval](https://nixos.org/manual/nix/stable/command-ref/nix-eval.html)
- [Nix Manual: nix build](https://nixos.org/manual/nix/stable/command-ref/nix-build.html)
- [Nix Manual: nix derivation](https://nixos.org/manual/nix/stable/command-ref/nix-derivation.html)
