## 1. Update caddy.nix — add tailnet suffix option and update defaults

- [x] 1.1 Add `services.caddy.tailnetSuffix` option (type: str, default: `"taile0585b.ts.net"`)
- [x] 1.2 Change default `opencodeHost` from `"opencode.hbohlen.systems"` to `"opencode.${config.services.caddy.tailnetSuffix}"`
- [x] 1.3 Remove `tls internal` from the opencode virtualHost `extraConfig`

## 2. Update gno.nix — use tailnet suffix and remove tls internal

- [x] 2.1 Change default `hostname` from `"gno.hbohlen.systems"` to `"gno.${config.services.caddy.tailnetSuffix}"` (reference `config.services.caddy.tailnetSuffix` from caddy.nix)
- [x] 2.2 Remove `tls internal` from the gno virtualHost `extraConfig`

## 3. Verify

- [x] 3.1 Run `nix eval .#nixosConfigurations.hbohlen-01.config.system.build.toplevel --apply 'x: x'` to verify NixOS config evaluates without errors
- [x] 3.2 Run `nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel` to verify full build succeeds
- [x] 3.3 Deploy to server: `sudo nixos-rebuild switch --flake .#hbohlen-01` (or dry-activate first)
- [x] 3.4 Verify Caddy logs show no TLS errors: `journalctl -u caddy -n 20`
- [x] 3.5 Test GNO access: `curl -s https://gno.taile0585b.ts.net | head -5` (from tailnet-connected machine)
- [x] 3.6 Test opencode access: `curl -s https://opencode.taile0585b.ts.net | head -5` (from tailnet-connected machine)
