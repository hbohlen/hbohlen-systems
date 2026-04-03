## 1. Create modules/home.nix

- [x] 1.1 Create `modules/home.nix` as a NixOS module (`{...}: { home-manager.users.hbohlen = {...}: { ... }; }`) containing:
  - home.stateVersion, homeDirectory, username, sessionVariables
  - programs.ssh config (moved from ssh.nix)
  - programs.tmux with extended keys config

## 2. Wire home.nix into NixOS config

- [x] 2.1 Add `./home.nix` to imports in `modules/nixos-configurations.nix`
- [x] 2.2 Add `home.nix` to the exclusion filter in `modules/default.nix`

## 3. Clean up ssh.nix

- [x] 3.1 Remove the `home-manager.users.hbohlen` block (lines 47-54) from `modules/ssh.nix`

## 4. Remove home-config.nix

- [x] 4.1 Delete `modules/home-config.nix`

## 5. Remove pi-nix-suite from devshell

- [x] 5.1 Remove `pi-nix-suite` package definition from `modules/devshell.nix` (line 12)
- [x] 5.2 Remove `pi-nix-suite` from packages list in `modules/devshell.nix` (line 139)
- [x] 5.3 Remove pi-nix-suite shellHook setup block from `modules/devshell.nix` (lines 155-161)

## 6. Delete pi-nix-suite directory

- [x] 6.1 Delete `nix/cells/pi-nix-suite/` directory

## 7. Verify

- [ ] 7.1 Run `nix flake check` to verify no evaluation errors
- [ ] 7.2 Run `nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel` to verify NixOS config evaluates
- [ ] 7.3 Deploy to server: `sudo nixos-rebuild switch --flake .#hbohlen-01`
- [ ] 7.4 Verify access: `ssh hbohlen@<tailscale-ip> 'whoami && hostname'`
- [ ] 7.5 Verify tmux: `ssh hbohlen@<tailscale-ip> 'tmux -V && cat ~/.config/tmux/tmux.conf'`
