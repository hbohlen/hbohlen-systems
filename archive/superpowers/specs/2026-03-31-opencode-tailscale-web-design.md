# Design: Serve opencode Web UI over Tailscale-only

**Date:** 2026-03-31  
**Status:** Approved

## Overview

Serve the opencode web UI at `opencode.hbohlen.systems.ts.net` accessible only to Tailscale tailnet devices using Caddy with the caddy-tailscale plugin.

## Architecture

- **opencode** runs as systemd service on port 8080 (localhost only)
- **Caddy** with caddy-tailscale plugin listens on Tailscale-only interface
- Creates unique Tailscale node at `opencode.hbohlen.systems.ts.net`
- Open to anyone on tailnet without additional auth

## Components

### 1. opencode systemd service

- Binary from `llm-agents` flake input
- Runs `opencode web --port 8080` bound to 127.0.0.1
- No public interface exposure
- Auto-restart on failure

### 2. Caddy with caddy-tailscale plugin

- Custom Caddy package with tailscale plugin included
- Auth key managed via opnix (1Password reference)
- VirtualHost binds to Tailscale interface

### 3. Tailscale auth key management

- Migrate existing hardcoded auth key to opnix-managed secret
- 1Password reference: `op://hbohlen-systems/tailscale/authKey`

## Data Flow

```
Tailnet Device → opencode.hbohlen.systems.ts.net → Caddy (tailscale) → localhost:8080 → opencode web
```

## Known Constraints

- Each caddy-tailscale service creates a new device in Tailnet dashboard
- Watch device limit on Tailscale account

## Implementation Scope

1. Build Caddy with caddy-tailscale plugin via overlay/custom package
2. Configure Caddy virtualHost for opencode service
3. Add opencode systemd service
4. Migrate Tailscale auth key to opnix