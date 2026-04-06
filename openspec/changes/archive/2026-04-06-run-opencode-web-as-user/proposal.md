## Why

The opencode web UI systemd service currently runs as `root` because no `User` directive is set in the NixOS module. This is a security risk for a network-exposed service (served via Tailscale) and causes operational issues — git operations run as root instead of the correct user, and the service lacks access to the user's home directory and project files.

## What Changes

- A `user` option is added to `services.opencode` (default `"hbohlen"`), matching the pattern used by `services.gno-daemon` in `modules/gno.nix`
- The `opencode-web` systemd service sets `User`, `WorkingDirectory`, and `Environment = ["HOME=..."]` based on the configured user
- No changes to port, hostname, or Tailscale exposure

## Capabilities

### New Capabilities
- `opencode-web-service`: Configuration for the opencode web UI systemd service, including user, group, working directory, and security hardening

### Modified Capabilities
<!-- No existing specs to modify -->

## Impact

- `modules/opencode.nix` — adds `User`, `Group`, and `WorkingDirectory` to the systemd service config
- Requires `hbohlen` user to exist on the system (already does)
- No breaking changes — the service behavior is identical from the user's perspective, just running under a different user
