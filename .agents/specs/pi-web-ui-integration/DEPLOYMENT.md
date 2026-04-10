# pi-web-ui NixOS Deployment Guide

## Overview

This document describes the NixOS deployment configuration for pi-web-ui, a web-based chat interface for pi-authenticated LLM providers.

## Architecture

```
User (Tailnet)
    |
    | HTTPS (Tailscale MagicDNS)
    v
Caddy (port 443, Tailscale interface only)
    |
    | HTTP (localhost)
    v
pi-web-ui (port 3000, localhost only)
    |
    | File system
    v
~/.pi/agent/auth.json (pi credentials)
```

## Components

### 1. NixOS Module (`nixos/pi-web-ui.nix`)

**Features:**
- Systemd service with Node.js 20 runtime
- Runs on localhost:3000 (not exposed publicly)
- Security hardening enabled (PrivateTmp, ProtectSystem, etc.)
- Automatic restart on failure
- Runs as `hbohlen` user (not root)
- Reads auth.json from `/home/hbohlen/.pi/agent/auth.json`

**Service Configuration:**
```nix
services.pi-web-ui = {
  enable = true;
  port = 3000;
  user = "hbohlen";
  authFilePath = "/home/hbohlen/.pi/agent/auth.json";
};
```

### 2. Caddy Reverse Proxy (`nixos/caddy.nix`)

**Features:**
- Tailscale-only binding (no public internet access)
- Automatic HTTPS via Tailscale certificates
- Security headers (HSTS, X-Frame-Options, etc.)
- SSE streaming support for real-time chat
- Virtual host: `mnemosyne.hbohlen.systems`

**Caddy Configuration:**
```nix
services.caddy = {
  tailscaleEnable = true;
  enablePiWebUi = true;
  piWebUiHost = "mnemosyne.hbohlen.systems";
};
```

### 3. Tailscale ACLs (`tailscale/acl.hujson`)

**Access Control:**
- Only `group:admin` members can access all ports
- Service runs on Tailscale network only
- No public internet exposure (enforced by Caddy bind directive)

**Verification:**
```bash
# Check current ACLs
tailscale acl get

# Test from tailnet (should succeed)
curl https://mnemosyne.hbohlen.systems

# Test from external network (should fail/times out)
curl --connect-timeout 5 https://mnemosyne.hbohlen.systems
```

## Deployment Steps

### Prerequisites

1. Build the application:
```bash
npm install
npm run build
```

2. Verify auth.json exists:
```bash
ls -la ~/.pi/agent/auth.json
```

### Deploy to NixOS

1. **Build the NixOS configuration:**
```bash
nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel
```

2. **Deploy (if using deploy-rs or similar):**
```bash
deploy .#hbohlen-01
```

Or manually:
```bash
nixos-rebuild switch --flake .#hbohlen-01 --target-host root@hbohlen-01
```

3. **Verify services are running:**
```bash
ssh hbohlen-01
sudo systemctl status pi-web-ui
sudo systemctl status caddy
```

4. **Check logs:**
```bash
sudo journalctl -u pi-web-ui -f
sudo journalctl -u caddy -f
```

### Post-Deployment Verification

1. **Test Tailscale access:**
```bash
# From a device on the tailnet
curl https://mnemosyne.hbohlen.systems/api/config
```

2. **Verify HTTPS:**
```bash
curl -v https://mnemosyne.hbohlen.systems 2>&1 | grep "TLS handshake"
```

3. **Check service health:**
```bash
curl http://localhost:3000/api/health
```

## Security Considerations

### Network Isolation
- Service listens only on localhost (127.0.0.1:3000)
- Caddy binds only to Tailscale interface
- No direct public internet access

### Service Hardening
- PrivateTmp=true (isolated /tmp)
- ProtectSystem=strict (read-only system directories)
- NoNewPrivileges=true (cannot gain additional privileges)
- RestrictAddressFamilies (limited to AF_INET, AF_INET6, AF_UNIX)
- MemoryDenyWriteExecute (W^X protection)

### Secret Management
- Auth credentials stored in `~/.pi/agent/auth.json`
- File permissions should be 0600 (user read-only)
- Service runs as non-root user (`hbohlen`)

## Troubleshooting

### Service Won't Start

1. Check build artifacts exist:
```bash
ls -la backend/dist/
ls -la frontend/dist/
```

2. Verify Node.js version:
```bash
node --version  # Should be 18.x or 20.x
```

3. Check auth.json path:
```bash
ls -la /home/hbohlen/.pi/agent/auth.json
```

### Cannot Access via Browser

1. Verify Tailscale connection:
```bash
tailscale status
```

2. Check Caddy logs:
```bash
sudo journalctl -u caddy -n 50
```

3. Verify DNS resolution:
```bash
nslookup mnemosyne.hbohlen.systems
```

### Streaming Not Working

1. Check Caddy SSE configuration:
```bash
grep -A 5 "flush_interval" /etc/caddy/Caddyfile
```

2. Verify backend is responding:
```bash
curl -N http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"messages":[],"provider":"anthropic","model":"claude-sonnet-4"}'
```

## Maintenance

### Updating the Application

1. Pull latest code:
```bash
git pull origin main
```

2. Rebuild:
```bash
npm install
npm run build
```

3. Deploy:
```bash
nixos-rebuild switch --flake .#hbohlen-01
```

### Backup Considerations

- No persistent data stored (MVP has no conversation history)
- Only backup needed is `~/.pi/agent/auth.json` (pi credentials)

### Monitoring

Key metrics to monitor:
- Service uptime: `systemctl status pi-web-ui`
- Log errors: `journalctl -u pi-web-ui -p err`
- Memory usage: `systemctl status pi-web-ui` (shows memory consumption)
- Tailscale connectivity: `tailscale status`

## Rollback

If deployment fails:

```bash
# On the server
sudo nixos-rebuild switch --rollback

# Or switch to specific generation
sudo nixos-rebuild switch --flake .#hbohlen-01 --profile-name backup
```

## References

- [NixOS Module Source](../nixos/pi-web-ui.nix)
- [Caddy Configuration](../nixos/caddy.nix)
- [Host Configuration](../hosts/hbohlen-01.nix)
- [Tailscale ACLs](../../tailscale/acl.hujson)
- [Design Document](../design.md)
