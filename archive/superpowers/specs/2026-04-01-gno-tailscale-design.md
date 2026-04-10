# GNO Knowledge Base with Tailscale Serve - Design Spec

**Date:** 2026-04-01
**Status:** Approved

## Overview

Install GNO (local knowledge engine) from `github:numtide/llm-agents.nix` and expose its web UI to the Tailscale tailnet via `tailscale serve` at `gno.hbohlen.systems.ts.net`.

## Context

- **GNO** (`@gmickel/gno`) is a local knowledge engine that indexes documents and provides AI-powered search, Q&A with citations, and knowledge graph visualization
- Packaged in `github:numtide/llm-agents.nix#gno` using Nix + Bun
- Web UI served via `gno serve` (default port 8080)
- Daemon mode (`gno daemon`) continuously watches for file changes and keeps search index updated

## Requirements

1. Install gno package from `github:numtide/llm-agents.nix#gno`
2. Create and manage `~/mnemosyne` as the indexed directory
3. Run gno daemon as systemd service (always on)
4. Expose web UI via Tailscale serve at `gno.hbohlen.systems.ts.net`
5. Access limited to Tailscale tailnet (no additional auth)
6. No MCP integration (web UI only)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Tailscale Tailnet                        │
│                                                              │
│  ┌──────────────┐      ┌──────────────────────────────────┐  │
│  │   Client     │      │      hbohlen-01 (NixOS Server)   │  │
│  │   Browser    │──────│  ┌────────────┐    ┌───────────┐ │  │
│  └──────────────┘      │  │  tailscale│    │    gno   │ │  │
│         │             │  │   serve   │────│  daemon  │ │  │
│         ▼             │  └─────┬─────┘    └─────┬─────┘ │  │
│  gno.hbohlen.         │        │                │       │  │
│  systems.ts.net       │   localhost:8080    ~/mnemosyne │  │
│                       └──────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. NixOS Module

**File:** `nix/cells/nixos/modules/gno.nix`

- Adds `github:numtide/llm-agents.nix` as flake input (or extends existing inputs)
- Adds gno package to `environment.systemPackages`
- Imports module configuration

### 2. Systemd Service

**File:** `nix/cells/nixos/modules/gno-daemon.nix`

- Service name: `gno-daemon.service`
- Command: `gno daemon`
- Environment:
  - `HOME=/home/hbohlen`
  - `GNODIR=/home/hbohlen/.config/gno` (or similar)
- Dependencies:
  - `After=network-online.target tailscaled.service`
  - `Wants=network-online.target`
- Restart: `on_failure` with 5-second delay and 5 retries
- User: `hbohlen`

### 3. Tailscale Serve Configuration

- Magic DNS name: `gno.hbohlen.systems.ts.net`
- Reverse proxy: `tailscale serve 8080` (proxies to localhost:8080)
- Or use NixOS `services.tailscale` options if available

### 4. Data Directory

- Path: `~/mnemosyne`
- Created by installer if not exists
- Initialized by gno via `gno init ~/mnemosyne --name mnemosyne` (first run)

## Data Flow

1. System boots → Tailscale connects to tailnet
2. Systemd starts `gno-daemon.service` after network is online
3. `gno daemon` watches `~/mnemosyne` for file changes
4. User accesses `https://gno.hbohlen.systems.ts.net` from any tailnet client
5. Tailscale serve proxies HTTPS request to localhost:8080
6. GNO web UI serves from memory

## Error Handling

| Failure Scenario | Behavior |
|------------------|---------|
| Tailscale not connected | Service starts but serve fails; logs warning |
| ~/mnemosyne missing | gno daemon may fail; create directory in activation |
| Port 8080 in use | Service fails; configurable port option |
| gno crashes | Systemd restarts with backoff; logs to journal |

## Testing

1. `sudo nixos-rebuild switch` - verify module loads without error
2. `systemctl status gno-daemon` - verify service is running
3. `tailscale serve status` - verify serve is configured
4. Access `https://gno.hbohlen.systems.ts.net` from browser on tailnet
5. `gno status` (via sudo -u hbohlen) - verify daemon healthy and indexing

## Security Considerations

- Service accessible only to authenticated Tailscale users
- No additional authentication on web UI (relies on Tailscale auth)
- Service runs as unprivileged user `hbohlen`
- Read-only access to indexed files only

## Implementation Notes

- Uses existing `tailscale-enhanced.nix` module as pattern
- Tailscale serve configuration via systemd unit that runs on tailscale up
- GNO package from `github:numtide/llm-agents.nix` - no local package definition needed
- Consider adding `tailscale serve` configuration to host-specific NixOS config or existing tailscale module

## Files to Create/Modify

1. `nix/cells/nixos/modules/gno-daemon.nix` (new) - systemd service module
2. `nix/cells/nixos/hosts/hbohlen-01/default.nix` (modify) - import gno-daemon module
3. `flake.nix` (modify) - add `github:numtide/llm-agents.nix` as input if not present

## Rollback Plan

- Remove gno-daemon module import from host config
- Run `nixos-rebuild switch`
- Uninstall gno from system packages
