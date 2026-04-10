# Requirements: Improve nix-eval-for-agents Skill

## Feature Description

Enhance the `nix-eval-for-agents` skill to provide agents with a comprehensive toolkit for efficiently testing and inspecting Nix/NixOS configurations without relying on interactive tools like `nix repl`.

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Structure** | Single skill (164 lines) | Splitting hurts discoverability; 164 lines is manageable |
| **Alternatives** | Skip `nix-instantiate` | `nix eval` is the modern replacement for all agent use cases |
| **Examples** | Keep project-specific examples | Concrete examples aid understanding; agents adapt to their project |
| **Debugging** | Reference existing `flake-debug` skill | Don't duplicate; link to it |

---

## Requirements

### REQ-001: Performance Optimization
**Status:** New content needed

The skill MUST document `--read-only` flag for faster evaluation.

**Details:**
- `--read-only` skips derivation instantiation, ~2x faster
- Use when: inspecting values, checking existence, smoke tests
- Don't use when: need store paths or actual builds

**Acceptance Criteria:**
- [ ] `--read-only` appears in Quick Reference table
- [ ] Timing comparison shown (normal eval vs `--read-only`)
- [ ] Clear guidance on when to use each

---

### REQ-002: Derivation Inspection
**Status:** New content needed

The skill MUST include `nix derivation show` for inspecting derivation details.

**Details:**
- Use when: debugging build failures, inspecting env vars, understanding build inputs
- Returns full JSON with env, inputs, outputs, builder

**Acceptance Criteria:**
- [ ] `nix derivation show` syntax and example documented
- [ ] Use case: debugging build command failures
- [ ] Example extracting key fields from JSON output

---

### REQ-003: Flake Metadata Inspection
**Status:** New content needed

The skill MUST include `nix flake metadata` for inspecting lock file state.

**Details:**
- Use when: checking last modified, inputs, locked revisions, flake health
- Works on any flake URL, not just local

**Acceptance Criteria:**
- [ ] `nix flake metadata` documented with `--json` example
- [ ] Use case: verifying inputs are locked vs following
- [ ] Contrast with `nix flake show` (structure vs metadata)

---

### REQ-004: Nix Type Handling
**Status:** Expand existing content

The skill MUST provide clear guidance on handling all Nix value types.

**Details:**
- Strings: `--raw` removes quotes (but fails on non-strings)
- Integers/bools: no flag, direct output
- Attrsets: `--json` or `--apply builtins.attrNames`
- Lists: `--json` or `--apply builtins.length`
- Derivations: show `drvPath` or `outPath`

**Acceptance Criteria:**
- [ ] Type handling table in Quick Reference or dedicated section
- [ ] Warning prominently placed: `--raw` fails on non-strings
- [ ] Examples for each type

---

### REQ-005: Comprehensive `--apply` Patterns
**Status:** Expand existing content

The skill MUST expand `--apply` documentation with common testing patterns.

**Details:**
- Testing existence: `(x: x ? attr)`
- Testing type: `(x: builtins.isAttrs x)`
- Testing value: `(x: x == expected)`
- Combining checks: `(x: builtins.isAttrs x && x ? services)`

**Acceptance Criteria:**
- [ ] At least 4 `--apply` examples covering common patterns
- [ ] Syntax reminder: `--apply` receives the value as argument
- [ ] Warning about quoting in shell (use double quotes around lambda)

---

### REQ-006: Check Enumeration Patterns
**Status:** New content needed

The skill MUST include patterns for listing available flake outputs without running them.

**Details:**
- List checks: `nix eval --json .#checks --apply builtins.attrNames`
- List NixOS configs: `nix eval --json .#nixosConfigurations --apply builtins.attrNames`
- List devShells: `nix eval --json .#devShells.x86_64-linux --apply builtins.attrNames`

**Acceptance Criteria:**
- [ ] Commands documented for listing each output type
- [ ] Use case: discovering what checks/configs exist
- [ ] Contrast with `nix flake show` (human-readable vs JSON)

---

### REQ-007: Fast Smoke Tests
**Status:** New content needed

The skill MUST include patterns for rapid evaluation sanity checks.

**Details:**
- Goal: verify something evaluates without building
- `nix eval --read-only .#path.drvPath` - fastest (~1.2s)
- `nix build .#path --dry-run` - checks derivability (~0.9s)
- `nix build .#path --dry-run --json` - structured result

**Acceptance Criteria:**
- [ ] Timing comparison between methods
- [ ] Decision guidance: which to use when
- [ ] Pattern: "just check it evaluates" vs "check it builds"

---

### REQ-008: Error Recovery Patterns
**Status:** New content needed

The skill MUST include patterns for handling evaluation errors gracefully.

**Details:**
- Use stderr: `2>&1 | head -50`
- Verbose mode: `--verbose` for trace output
- Safe access: `--apply (x: x ? nested.attr)` before deep access
- Timeout consideration: mention `--timeout` if available

**Acceptance Criteria:**
- [ ] Pattern for capturing and viewing errors
- [ ] Safe access pattern before diving into nested attrs
- [ ] Link/reference to `flake-debug` skill for complex errors

---

### REQ-009: CI/CD Integration
**Status:** New content needed

The skill MUST include patterns suitable for non-interactive/CI environments.

**Details:**
- JSON output: `--json` for programmatic parsing
- No workspace pollution: `--no-link`
- Exit codes: successful commands exit 0, errors exit non-zero
- Parallel execution: `nix build .#checks.x86_64-linux.{a,b,c} &`

**Acceptance Criteria:**
- [ ] JSON parsing patterns with `jq`
- [ ] `--no-link` usage emphasized
- [ ] Example CI script snippet (optional)

---

### REQ-010: Command Decision Matrix
**Status:** Improve existing content

The skill MUST include clear decision guidance for choosing between commands.

**Details:**
- `nix eval` vs `nix build` vs `nix flake check`
- `--raw` vs `--json` vs default
- `--read-only` vs normal eval

**Acceptance Criteria:**
- [ ] Decision table in "When to Use Each" section
- [ ] At least 6 rows covering common scenarios
- [ ] Visual hierarchy making it scannable

---

## Out of Scope

- Interactive `nix repl` patterns
- Building actual NixOS systems (only inspection/testing)
- Nix language tutorial
- nix-unit test writing
- `nix-instantiate` (replaced by `nix eval`)
- flake-parts internal mechanics (document generic patterns)

---

## Success Metrics

After implementation:
1. An agent should be able to inspect any flake output without building
2. An agent should know which command to use for each scenario
3. Typical inspection tasks should complete in <3 seconds
4. The skill should be usable in CI/CD without modification
