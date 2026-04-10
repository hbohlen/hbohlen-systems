# Gap Analysis: clean-project

## Current State Investigation
The system currently uses a `flake-parts` architecture to expose variables across system configurations. 
- **home/default.nix**: Acts as a nested `perSystem` block rather than a classic NixOS integration. 
- **Tests**: `tests/evaluation/test-base.nix` runs isolated tests against `home/default.nix` by instantiating `pkgs.nixos [ ... ]`. 
- **devShells**: `parts/devshell.nix` manually maintains `fishConfig` and `starshipConfig` strings.

## Requirements Feasibility Analysis

| Requirement | Need | Gap Status |
|-------------|------|------------|
| 1.1 Remove caddy/gno | Delete files and imports | **Exists** (Simple file edits) |
| 1.2 opencode local | Native bind configuration | **Exists** (Already listens on 127.0.0.1) |
| 1.3 `home-manager` standard submodule | Refactor `home/default.nix` | **Missing** (`home/default.nix` refactoring breaks isolated testing) |
| 2.1 - 2.4 devShells | Migrate shell configs to home-manager | **Missing** (`programs.fish` and `starship` need to be explicitly configured inside `home-manager` to replace the shell derivations) |

## Discovered Architectural Gaps & Risks

### Risk 1: `test-base.nix` Evaluation Crash [High]
**The Gap:** If `home/default.nix` relies on standard `inputs` parameterizing via NixOS `specialArgs`, `tests/evaluation/test-base.nix` will inherently fail because it evaluates `pkgs.nixos` in a vacuum without supplying `inputs` to the module tree.
**Mitigation Strategy:** We must extend the testing blocks in `test-base.nix` to artificially supply `{ _module.args.inputs = inputs; }` to the test suite evaluator, so `home/default.nix` can safely resolve `llm-agents-packages`.

### Risk 2: Redundant DevShell Tooling [Low]
**The Gap:** `devshell.nix` manually writes `fish` definitions.
**Mitigation Strategy:** These derivations can be completely erased since moving the same configurations to `home-manager.programs.fish` securely provides this boundary globally.

## Recommended Approach
**Hybrid Modification.** We will clean out the target `nixos/*` units as originally proposed, but we must expand the scope of the implementation mapping to include fixing `test-base.nix` testing suites and accurately transitioning the native shell aliases into the `home-manager` boundary.

**Complexity Definition:** S (1-3 days). Existing patterns, minimal unknown dependencies.
