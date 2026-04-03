## Why

Home-manager configuration is fragmented across two locations: `home-config.nix` defines a standalone `flake.homeConfigurations.hbohlen` that isn't deployed to the server, while `ssh.nix` embeds an inline `home-manager.users.hbohlen` block for SSH client config that actually runs on hbohlen-01. This split means home-manager config in `home-config.nix` is dead code on the server.

Additionally, tmux is not installed or configured anywhere, but is needed for pi-coding-agent multi-agent workflows (pi requires `extended-keys` config to work inside tmux).

Finally, the `pi-nix-suite` extension (Nix package + devshell integration) is over-engineered and should be removed — pi's own philosophy recommends using tmux directly rather than building orchestration layers.

## What Changes

- Create `modules/home.nix` — a NixOS module bundling all home-manager config (stateVersion, homeDirectory, SSH client, tmux) under `home-manager.users.hbohlen`
- Add `programs.tmux` with extended keys config for pi compatibility
- Remove inline `home-manager.users.hbohlen` block from `modules/ssh.nix` (keep NixOS-level `services.openssh` only)
- Delete `modules/home-config.nix` (standalone home-manager output, unused on server)
- Remove `pi-nix-suite` from `modules/devshell.nix` (package definition, packages list, shellHook setup)
- Delete `nix/cells/pi-nix-suite/` directory

## Capabilities

### New Capabilities

- tmux available on the server with extended keys support for pi-coding-agent
- Declarative tmux config managed through NixOS deploy

### Modified Capabilities

- home-manager config consolidated from 2 locations into 1 NixOS module

## Impact

- `modules/home.nix`: new file
- `modules/ssh.nix`: remove lines 47-54 (home-manager block)
- `modules/home-config.nix`: delete
- `modules/devshell.nix`: remove pi-nix-suite references (line 12, 139, 155-161)
- `nix/cells/pi-nix-suite/`: delete entire directory
- `modules/nixos-configurations.nix`: add `./home.nix` to imports list
- `modules/default.nix`: add `home.nix` to exclusion list (it's a NixOS module, not a flake-parts module)
- No changes to `services.openssh` or `services.tailscale` (access path untouched)
