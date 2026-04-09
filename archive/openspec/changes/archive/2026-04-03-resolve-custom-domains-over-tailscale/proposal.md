## Why

Caddy's virtualHosts use custom hostnames (`gno.hbohlen.systems`, `opencode.hbohlen.systems`) with `tls internal` and `bind tailscale/<name>`. The caddy-tailscale plugin creates Tailscale nodes accessible at MagicDNS names (`gno.taile0585b.ts.net`, `opencode.taile0585b.ts.net`), but:

1. **No DNS resolution** — `gno.hbohlen.systems` and `opencode.hbohlen.systems` have no DNS records pointing to their Tailscale IPs. They resolve nowhere.
2. **TLS hostname mismatch** — `tls internal` issues Caddy-internal CA certificates for the virtualHost names. Connecting via the MagicDNS names (`*.taile0585b.ts.net`) fails with `tlsv1 alert internal error` because the cert doesn't cover those hostnames.
3. **No working access path** — Neither the custom names (no DNS) nor the MagicDNS names (cert mismatch) work. The services are unreachable from the browser.

Verified: `curl -sk --resolve "gno.hbohlen.systems:443:100.86.16.104" https://gno.hbohlen.systems` returns the GNO UI successfully, proving the backend and Caddy routing work — only DNS and TLS are broken.

## What Changes

- Switch virtualHost hostnames from custom names to Tailscale MagicDNS names (`gno.taile0585b.ts.net`, `opencode.taile0585b.ts.net`)
- Remove `tls internal` so the caddy-tailscale plugin handles TLS provisioning natively (Tailscale provides HTTPS certs for `*.ts.net` names via its coordination server)
- Make the tailnet suffix configurable via a NixOS option, since it varies per tailnet

## Capabilities

### New Capabilities

- Services accessible via browser at their MagicDNS URLs over HTTPS on the tailnet

### Modified Capabilities

- `gno-serve` hostname option default changes from `gno.hbohlen.systems` to `gno.taile0585b.ts.net`
- `caddy.opencodeHost` option default changes from `opencode.hbohlen.systems` to `opencode.taile0585b.ts.net`
- `tls internal` removed from both virtualHost configs

## Impact

- `modules/caddy.nix`: update default `opencodeHost`, remove `tls internal` from virtualHost extraConfig
- `modules/gno.nix`: update default `hostname`, remove `tls internal` from virtualHost extraConfig
- `modules/hosts/hbohlen-01.nix`: no changes needed (uses defaults)
- Existing tailscale node names (`gno`, `opencode`) unchanged — the `bind tailscale/<name>` directives stay the same
