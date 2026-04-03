## 1. Add opencode to devShell

- [x] 1.1 Add `llm-agents-packages.opencode` to the packages list in `modules/devshell.nix`

## 2. Fix gno serve command

- [x] 2.1 Remove `--hostname 127.0.0.1` from the ExecStart in `modules/gno.nix` line 83

## 3. Verify

- [x] 3.1 Run `nix flake check` to verify no evaluation errors
- [x] 3.2 Confirm `opencode` is available in `nix develop` shell
- [x] 3.3 Confirm `gno serve --help` shows correct usage
