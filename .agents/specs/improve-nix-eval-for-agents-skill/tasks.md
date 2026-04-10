# Tasks: Improve nix-eval-for-agents Skill

## Implementation Task List

- [x] 1. Add Performance Section with --read-only and smoke test patterns
  - Document `--read-only` flag for 2x faster evaluation without derivation instantiation
  - Show timing comparison: normal eval (~2.2s) vs `--read-only` (~1.0s)
  - Document dry-run build as fastest smoke test (~0.9s)
  - Document drvPath inspection as alternative smoke test (~1.2s)
  - Provide clear guidance on when to use each approach
  - _Requirements: 1.1, 1.2, 7.1, 7.2, 7.3_

- [x] 2. Add Derivation Inspection Section
  - Document `nix derivation show` command syntax and JSON output format
  - Provide example for extracting build command: `jq -r '.[] | .env.buildCommand'`
  - Show how to list derivation inputs: `jq -r '.[] | .inputDrvs | keys[]'`
  - Explain use case: debugging build failures, inspecting env vars, understanding build inputs
  - _Requirements: 2.1, 2.2, 2.3_

- [x] 3. Add Flake Metadata Inspection Section
  - Document `nix flake metadata . --json` command pattern
  - Show how to extract `lastModified` timestamp
  - Demonstrate checking `locked` inputs state
  - Contrast with `nix flake show`: structure vs metadata (lock state)
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 4. (P) Add Type Handling Section
  - Create type handling table: String, Integer, Bool, Attrset, List, Derivation
  - Document `--raw` flag behavior and its failure on non-strings
  - Show how to inspect each type: `--raw`, `--json`, `--apply` patterns
  - Include derivation path access via `.drvPath` and `.outPath`
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 5. (P) Expand Apply Patterns Section
  - Add at least 4 `--apply` examples covering common testing patterns
  - Include existence check: `(x: x ? attr)`
  - Include type check: `(x: builtins.isAttrs x)`
  - Include value equality: `(x: x == expected)`
  - Include combined checks: `(x: builtins.isAttrs x && x ? services)`
  - Remind about shell quoting: use double quotes around lambda expressions
  - _Requirements: 5.1, 5.2, 5.3_

- [x] 6. (P) Add Check Enumeration Patterns
  - Document listing checks: `nix eval --json .#checks --apply builtins.attrNames`
  - Document listing NixOS configs: `nix eval --json .#nixosConfigurations --apply builtins.attrNames`
  - Document listing devShells: `nix eval --json .#devShells.x86_64-linux --apply builtins.attrNames`
  - Contrast with `nix flake show`: human-readable vs JSON for scripting
  - _Requirements: 6.1, 6.2, 6.3_

- [x] 7. (P) Add Error Recovery Section
  - Document error capture pattern: `2>&1 | head -50`
  - Document verbose mode: `--verbose` for full trace output
  - Provide safe attribute access pattern: `--apply "(x: x ? nested.attr)"`
  - Add reference to `flake-debug` skill for complex Nix errors
  - _Requirements: 8.1, 8.2, 8.3_

- [x] 8. (P) Add CI/CD Integration Section
  - Document JSON parsing with `jq`: `nix eval --json .#path | jq '.key'`
  - Emphasize `--no-link` for no workspace pollution
  - Show exit code patterns: `&& echo "OK" || echo "FAILED"`
  - Include parallel execution example: `nix build .#checks.{a,b,c} &`
  - _Requirements: 9.1, 9.2_

- [x] 9. (P) Expand Decision Matrix
  - Create comprehensive "When to Use Each" section with decision table
  - Include at least 8 scenarios: inspect value, need store path, just checking, inspect build, lock info, fast inspection, need JSON, clean string
  - Make table scannable with clear visual hierarchy
  - Cross-reference with newly added sections
  - _Requirements: 10.1, 10.2, 10.3_

- [x] 10. Update Quick Reference Table (final integration)
  - Add `--read-only` entry for fast evaluation
  - Add `nix derivation show` entry for derivation JSON
  - Add `nix flake metadata` entry for lock info
  - Ensure all new commands are represented
  - Reorder to match skill structure
  - _Requirements: 1.3, 2.1, 3.1_

---

## Summary

| Metric | Count |
|--------|-------|
| Major Tasks | 10 |
| Parallel Tasks | 6 (tasks 4-9) |
| Requirements Covered | 10 (REQ-001 through REQ-010) |

## Requirements Traceability

| Requirement | Tasks |
|-------------|-------|
| REQ-001: Performance `--read-only` | 1, 10 |
| REQ-002: Derivation Inspection | 2, 10 |
| REQ-003: Flake Metadata | 3, 10 |
| REQ-004: Type Handling | 4 |
| REQ-005: Apply Patterns | 5 |
| REQ-006: Check Enumeration | 6 |
| REQ-007: Fast Smoke Tests | 1 |
| REQ-008: Error Recovery | 7 |
| REQ-009: CI/CD Integration | 8 |
| REQ-010: Decision Matrix | 9 |
