## Context

The opencode web UI is currently defined as a NixOS module in `modules/opencode.nix`. It creates a systemd service `opencode-web` that runs `opencode web --port 8081 --hostname 127.0.0.1`. The service has no `User` or `Group` directive, so it defaults to running as `root` on NixOS.

The service is exposed over Tailscale, making it network-accessible within the tailnet. Running a network-facing service as root violates the principle of least privilege.

## Goals / Non-Goals

**Goals:**
- Run the opencode web service as user `hbohlen` instead of `root`
- Set working directory to `/home/hbohlen` for correct project access
- Maintain existing security hardening (`PrivateTmp`, `NoNewPrivileges`)
- Keep the change minimal and low-risk

**Non-Goals:**
- Changing the port, hostname, or Tailscale configuration
- Adding authentication or authorization layers
- Modifying how opencode itself works

## Decisions

### Decision: Add `user` option matching `gno.nix` pattern

**Choice**: Add a `user` option to `services.opencode` with default `"hbohlen"`, following the same pattern as `services.gno-daemon.user` in `modules/gno.nix`.

**Rationale**: The codebase already has a consistent pattern for this. The `gno.nix` module defines `user = lib.mkOption { type = lib.types.str; default = "hbohlen"; }` and uses it as `User = daemonCfg.user`. Matching this pattern keeps the codebase internally consistent and makes the module reusable without code changes if the username ever differs.

**Alternatives considered**:
- Hardcode `"hbohlen"` — simpler but breaks the established pattern and reduces reusability
- Use `DynamicUser = true` — would lose access to home directory, git config, and SSH agent

### Decision: Set `Environment = ["HOME=..."]` in addition to `WorkingDirectory`

**Choice**: Set both `WorkingDirectory` and `Environment = ["HOME=/home/hbohlen"]`.

**Rationale**: The `gno.nix` module does both. `WorkingDirectory` sets the CWD, but some tools look at `$HOME` explicitly (git, SSH, etc.). Setting both ensures correct behavior. The `gno-daemon` and `gno-serve` services in `gno.nix:56-58` and `gno.nix:82-84` follow this same pattern.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| Service fails if `hbohlen` user doesn't exist | User already exists; this is a home config |
| Port binding below 1024 would fail | Port is 8081 (unprivileged), no issue |
| File permissions on existing state | No persistent state directory exists yet |
