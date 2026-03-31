---
name: flake-debug
description: Debug and fix Nix flake evaluation errors
type: manual
category: nix
tools: read, write, edit, bash
---

# Flake Debug

Systematically debug and fix Nix flake evaluation errors.

## Common Errors and Fixes

### "attribute 'X' missing"

1. Check what's available:
   ```bash
   nix flake show 2>&1 | head -50
   ```

2. Read the flake.nix to understand outputs structure

3. Fix the attribute path or add the missing output

### "infinite recursion"

1. Check for self-referential expressions
2. Look for `inherit (self) X` patterns
3. Use `builtins.seq` to break laziness if needed

### "cannot find flake"

1. Verify flake.nix exists in current directory
2. Check git tracking: `git ls-files flake.nix`
3. Flakes must be in git to be recognized

### "build failed"

1. Check the specific package build:
   ```bash
   nix build .#package --rebuild 2>&1 | tail -100
   ```

2. Look for missing dependencies
3. Check for compiler errors

## Debugging Workflow

1. Run `nix flake check` and capture full error
2. Identify the file and line mentioned
3. Read that section of code
4. Use `nix repl` to test the problematic expression
5. Apply minimal fix
6. Verify with `nix flake check`
