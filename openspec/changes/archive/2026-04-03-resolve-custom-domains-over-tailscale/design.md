## Context

The caddy-tailscale plugin (`github.com/tailscale/caddy-tailscale`) allows Caddy to bind directly to Tailscale interfaces. When configured with `bind tailscale/<name>`, it creates a Tailscale node named `<name>` that is accessible at `<name>.<tailnet>.ts.net` via Tailscale MagicDNS.

The current implementation uses `tls internal` (Caddy's built-in CA) to issue certificates for virtualHost names like `gno.hbohlen.systems`. This creates two problems:
1. MagicDNS resolves `gno.taile0585b.ts.net`, not `gno.hbohlen.systems`
2. Caddy's internal CA cert covers `gno.hbohlen.systems`, not `gno.taile0585b.ts.net`

Tailscale provides automatic HTTPS certificates for `*.ts.net` names through its coordination server. Removing `tls internal` lets the caddy-tailscale plugin use Tailscale's native TLS provisioning, which handles certs for MagicDNS names automatically.

The tailnet suffix `taile0585b.ts.net` was discovered via `tailscale dns status`. It should be configurable since different tailnets have different suffixes.

## Goals / Non-Goals

**Goals:**
- Services accessible via their Tailscale MagicDNS URLs over HTTPS
- No manual DNS or `/etc/hosts` configuration needed on clients
- Tailnet suffix configurable in one place

**Non-Goals:**
- Custom domain support (e.g., `gno.hbohlen.systems`) — this would require separate DNS infrastructure
- Changing Tailscale node names (keep `gno`, `opencode`)
- Changing the caddy-tailscale plugin version
- Exposing services outside the tailnet

## Decisions

**Use MagicDNS names as virtualHost hostnames**: The `bind tailscale/<name>` directive creates nodes at `<name>.<tailnet>.ts.net`. The virtualHost hostname must match this for TLS to work. Default hostnames become `gno.taile0585b.ts.net` and `opencode.taile0585b.ts.net`.

**Remove `tls internal`**: Without this directive, the caddy-tailscale plugin handles TLS natively using Tailscale's HTTPS certificate provisioning. Tailscale coordinates with Let's Encrypt (or its internal CA) to provide valid certs for `*.ts.net` names. Clients on the tailnet already trust Tailscale's CA.

**Tailnet suffix as NixOS option**: Add `services.caddy.tailnetSuffix` (default `"taile0585b.ts.net"`) to `caddy.nix`. Both modules reference this for building MagicDNS names. If the tailnet changes, only one option needs updating.

**Hostname options retain full override**: `services.gno-serve.hostname` and `services.caddy.opencodeHost` still accept any string. The defaults just change to MagicDNS names. Users who want custom domains can still set them (and handle DNS themselves).

## Risks / Trade-offs

- **Tailnet suffix coupling**: If Tailscale changes the tailnet name (e.g., re-creating the tailnet), the suffix must be updated. Mitigated by making it a single NixOS option.
- **`tls internal` removal**: If the caddy-tailscale plugin doesn't provision certs automatically without `tls internal`, HTTPS will fail. Tested behavior: Tailscale clients on the tailnet trust `*.ts.net` certs natively. If issues arise, `tls internal` can be re-added alongside the MagicDNS names (requires clients to install Caddy's root CA).
- **gno-daemon still failing**: The daemon service (`gno-daemon.service`) is crash-looping with exit code 1. This is a separate issue (likely missing collection initialization) and is NOT addressed by this change.
