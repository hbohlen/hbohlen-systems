## Why

The devShell is missing `opencode` from its package list despite `llm-agents.nix` already being a flake input with `opencode` available. Additionally, the `gno-serve` systemd service passes an unsupported `--hostname` flag to `gno serve`, which only accepts `--port`/`-p`.

## What Changes

- Add `llm-agents-packages.opencode` to the devShell packages in `modules/devshell.nix`
- Fix `gno serve` ExecStart in `modules/gno.nix` to remove the `--hostname 127.0.0.1` argument (gno serve only accepts `-p/--port`)

## Capabilities

### New Capabilities

None — these are bug fixes to existing configuration.

### Modified Capabilities

None.

## Impact

- `modules/devshell.nix`: one-line addition to packages list
- `modules/gno.nix`: one-line edit to ExecStart in `gno-serve` systemd service
- No breaking changes, no new dependencies
