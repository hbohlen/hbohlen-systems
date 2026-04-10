# Tasks Document: clean-project

## 1. NixOS Core Services
- [x] Delete `nixos/gno.nix`.
- [x] Delete `nixos/caddy.nix`.
- [x] Modify `nixos/default.nix` to drop `gno` and `caddy` imports.

## 2. Home-Manager Refactor
- [x] Modify `home/default.nix` to convert from `flake-parts` syntax to standard `nixosModule`.
- [x] In `home/default.nix`, declare `programs.fish` and `programs.starship` implementations matching the previous `starshipConfig` strings.
- [x] In `home/default.nix`, add global `home.packages`: git, gh, dolt, nil, eza, ripgrep, zoxide, fzf, neovim, tmux, ast-grep, pi, qwen-code, hermes-agent, opencode, rtk, beads.

## 3. DevShell Cleanup
- [x] Modify `parts/devshell.nix` to remove `agent-menu` implementation completely.
- [x] Modify `parts/devshell.nix` to drop basic terminal packages and mapped LLM agents from both `.default` and `.ai` `devShells`.
- [x] Keep `omp`, `cli-proxy-api`, `ccusage-opencode`, `ccusage-pi`, `openspec` inside `.ai`.
- [x] Remove `fishConfig` and `starshipConfig` variables.

## 4. Evaluation Testing Fixes
- [x] Update `tests/evaluation/test-base.nix` to inject `{ _module.args.inputs = inputs; }` into the testing evaluator, fixing the test isolation evaluation crash caused by migrating `home/default.nix`.
- [x] Update `flake.nix` spacing tests (`alejandra`, `statix`, `deadnix`) to include more coverage if extra nix directories exist.

## 5. Verification
- [x] Run `nix flake check` or `nix build .#checks.x86_64-linux.alejandra-check` locally.
