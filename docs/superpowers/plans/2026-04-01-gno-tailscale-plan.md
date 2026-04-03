# GNO Knowledge Base with Tailscale Serve - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install GNO knowledge engine from `github:numtide/llm-agents.nix` and expose its web UI via Tailscale serve at `gno.hbohlen.systems.ts.net`.

**Architecture:** 
- GNO daemon runs as systemd service, continuously indexing `~/mnemosyne`
- GNO serve runs on localhost:8081 (port 8080 is occupied by opencode)
- Tailscale serve proxies `gno.hbohlen.systems.ts.net` → `localhost:8081`
- Service accessible to all authenticated Tailscale users on the tailnet

**Tech Stack:** NixOS, systemd, Tailscale, GNO (from llm-agents.nix)

---

## File Structure

```
nix/cells/nixos/modules/gno-daemon.nix    # NEW - systemd service for gno daemon
nix/cells/nixos/modules/gno-serve.nix      # NEW - systemd service for gno serve + tailscale serve
nix/cells/nixos/hosts/hbohlen-01/default.nix  # MODIFY - enable gno modules
flake.nix                                   # NO CHANGE - llm-agents.nix already added
```

---

## Task 1: Create GNO Daemon Module

Create systemd service for running `gno daemon` which continuously indexes `~/mnemosyne`.

**Files:**
- Create: `nix/cells/nixos/modules/gno-daemon.nix`

- [ ] **Step 1: Create the module file**

```nix
# nix/cells/nixos/modules/gno-daemon.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.gno-daemon;
in
{
  options.services.gno-daemon = {
    enable = lib.mkEnableOption "GNO knowledge engine daemon";
    user = lib.mkOption {
      type = lib.types.str;
      default = "hbohlen";
      description = "User to run gno daemon as";
    };
    homeDir = lib.mkOption {
      type = lib.types.path;
      default = "/home/hbohlen";
      description = "Home directory for gno configuration and data";
    };
    collectionPath = lib.mkOption {
      type = lib.types.path;
      default = "/home/hbohlen/mnemosyne";
      description = "Path to the directory to index";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure the collection directory exists
    systemd.tmpfiles.rules = [
      "d ${cfg.collectionPath} 0755 ${cfg.user} ${cfg.user} -"
    ];

    systemd.services.gno-daemon = {
      description = "GNO knowledge engine daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "tailscaled.service" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.user;
        Restart = "on-failure";
        RestartSec = "5s";
        TimeoutStartSec = "30s";
        Environment = [
          "HOME=${cfg.homeDir}"
        ];
        ExecStart = "${lib.getExe pkgs.gno} daemon";
        WorkingDirectory = cfg.homeDir;
      };
    };

    environment.systemPackages = [ pkgs.gno ];
  };
}
```

- [ ] **Step 2: Commit the daemon module**

```bash
git add nix/cells/nixos/modules/gno-daemon.nix
git commit -m "nix: add gno-daemon module for GNO knowledge engine"
```

---

## Task 2: Create GNO Serve + Tailscale Serve Module

Create systemd service for running `gno serve` and configure Tailscale serve.

**Files:**
- Create: `nix/cells/nixos/modules/gno-serve.nix`

- [ ] **Step 1: Create the module file**

```nix
# nix/cells/nixos/modules/gno-serve.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.gno-serve;
in
{
  options.services.gno-serve = {
    enable = lib.mkEnableOption "GNO web UI served via Tailscale";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8081;
      description = "Port for gno serve to listen on (8080 is used by opencode)";
    };
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "gno.hbohlen.systems.ts.net";
      description = "Tailscale Magic DNS hostname";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.gno-serve = {
      description = "GNO web UI server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "tailscaled.service" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = "5s";
        Environment = [
          "HOME=/home/hbohlen"
        ];
        ExecStart = "${lib.getExe pkgs.gno} serve --port ${toString cfg.port} --hostname 127.0.0.1";
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };

    # Tailscale serve configuration
    systemd.services.tailscale-serve-gno = {
      description = "Configure Tailscale serve for GNO";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "tailscaled.service" "gno-serve.service" ];
      wants = [ "gno-serve.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
ExecStart = "${lib.getExe pkgs.tailscale} serve --bg ${toString cfg.port}";
        ExecStop = "${lib.getExe pkgs.tailscale} serve reset";
      };
    };
  };
}
```

- [ ] **Step 2: Commit the serve module**

```bash
git add nix/cells/nixos/modules/gno-serve.nix
git commit -m "nix: add gno-serve module with Tailscale serve integration"
```

---

HH:## Task 3: Update Host Configuration

Import the new GNO modules and enable the services in the hbohlen-01 host configuration.

**Files:**
- Modify: `nix/cells/nixos/hosts/hbohlen-01/default.nix`

TR:- [ ] **Step 1: Read current file**

BV:```bash
NS:cat nix/cells/nixos/hosts/hbohlen-01/default.nix
NS:```
KM:
PN:- [ ] **Step 2: Add module imports**
QX:
VH:Add the gno modules to the imports array (before the host-specific config):

```nix
  # Enable GNO knowledge engine
  services.gno-daemon = {
    enable = true;
    collectionPath = "/home/hbohlen/mnemosyne";
  };

  services.gno-serve = {
    enable = true;
    port = 8081;
    hostname = "gno.hbohlen.systems.ts.net";
  };
```

- [ ] **Step 3: Verify NixOS configuration evaluates**

```bash
sudo nix eval .#nixosConfigurations.hbohlen-01.config.system.build.toplevel --apply 'x: x' 2>&1 | head -50
```

Expected: No errors, outputs the NixOS configuration attribute set.

- [ ] **Step 4: Commit the host configuration changes**

```bash
git add nix/cells/nixos/hosts/hbohlen-01/default.nix
git commit -m "hbohlen-01: enable GNO knowledge engine with Tailscale serve"
```

---

## Task 4: Build and Deploy

Build the NixOS configuration and deploy to the server.

**Files:**
- Build: All modified/new NixOS module files

- [ ] **Step 1: Dry run to check for errors**

```bash
sudo nixos-rebuild dry-activate --flake .#hbohlen-01 2>&1
```

Expected: "building the system configuration..." followed by "these are the differences..."

If errors occur, fix them before proceeding.

- [ ] **Step 2: Build and switch**

```bash
sudo nixos-rebuild switch --flake .#hbohlen-01 2>&1
```

Expected: "building the system configuration..." followed by "activation finished successfully"

- [ ] **Step 3: Verify services are running**

```bash
# Check gno-daemon is running
sudo systemctl status gno-daemon

# Check gno-serve is running  
sudo systemctl status gno-serve

# Check tailscale-serve-gno is configured
sudo systemctl status tailscale-serve-gno
```

- [ ] **Step 4: Verify Tailscale serve is active**

```bash
tailscale serve status
```

Expected: Should show `https://gno.hbohlen.systems.ts.net` proxied to localhost:8081

---

## Task 5: Initialize GNO Collection

Initialize the `~/mnemosyne` directory and verify indexing works.

**Files:**
- Directory: `/home/hbohlen/mnemosyne`

- [ ] **Step 1: Create the mnemosyne directory**

```bash
sudo -u hbohlen mkdir -p /home/hbohlen/mnemosyne
sudo -u hbohlen chmod 755 /home/hbohlen/mnemosyne
```

- [ ] **Step 2: Initialize the collection (first run only)**

```bash
# Check if already initialized
sudo -u hbohlen HOME=/home/hbohlen gno status 2>&1 || echo "Not initialized yet"

# Initialize if needed
sudo -u hbohlen HOME=/home/hbohlen gno init /home/hbohlen/mnemosyne --name mnemosyne 2>&1
```

- [ ] **Step 3: Verify indexing**

```bash
# Check daemon logs
sudo journalctl -u gno-daemon -n 50 --no-pager

# Run a test query to verify index
sudo -u hbohlen HOME=/home/hbohlen gno query "test" 2>&1 | head -20
```

Expected: Query should return (possibly empty) results, not an error.

---

## Task 6: Verify End-to-End

Access the GNO web UI via Tailscale and verify everything works.

**Files:**
- None (verification only)

- [ ] **Step 1: Access the web UI**

From a machine on the Tailscale tailnet, open a browser and navigate to:
```
https://gno.hbohlen.systems.ts.net
```

Expected: GNO web UI loads (may show empty state if no documents indexed yet)

- [ ] **Step 2: Add a test document**

```bash
cat << 'EOF' | sudo -u hbohlen tee /home/hbohlen/mnemosyne/test.md
# Test Document

This is a test document for GNO indexing.

## Key Points

- GNO is a knowledge engine
- It indexes documents
- Provides AI-powered search
EOF
```

- [ ] **Step 3: Wait for indexing and verify**

```bash
# Wait a few seconds for daemon to pick up changes
sleep 5

# Check that the document is indexed
sudo -u hbohlen HOME=/home/hbohlen gno query "knowledge engine" 2>&1
```

Expected: Should return the test document in results.

- [ ] **Step 4: Verify via web UI**

Refresh the browser at `https://gno.hbohlen.systems.ts.net` and search for "knowledge engine"

Expected: Test document appears in search results.

---

## Rollback Instructions

If something goes wrong:

```bash
# Edit nix/cells/nixos/hosts/hbohlen-01/default.nix and remove:
#   - services.gno-daemon enable block
#   - services.gno-serve enable block

# Rebuild
sudo nixos-rebuild switch --flake .#hbohlen-01

# Services will stop automatically
sudo systemctl stop gno-daemon gno-serve tailscale-serve-gno
```

---

## Dependencies

- `github:numtide/llm-agents.nix` (already in flake.nix) - provides gno package
- `services.tailscaled` running (from tailscale-enhanced.nix)
