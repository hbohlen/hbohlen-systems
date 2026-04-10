# opencode Tailscale Web Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Serve opencode web UI at `opencode.hbohlen.systems.ts.net` accessible only to Tailscale tailnet devices

**Architecture:** Use caddy-tailscale plugin to create Tailscale-only endpoint. opencode runs on localhost:8080, Caddy proxies requests from Tailscale interface.

**Tech Stack:** NixOS, Caddy with caddy-tailscale plugin, opnix for secrets, llm-agents for opencode

---

## Task 1: Create caddy-tailscale module

**Files:**
- Create: `nix/cells/nixos/modules/caddy-tailscale.nix`

- [ ] **Step 1: Create caddy-tailscale module**

```nix
# nix/cells/nixos/modules/caddy-tailscale.nix
{ pkgs, lib, config, ... }:

let
  tailscalePlugin = "github.com/tailscale/caddy-tailscale@v0.0.0-20250207163903-69a970c84556";
in
{
  options = with lib.types; {
    services.caddy.tailscaleEnable = lib.mkEnableOption "Enable caddy tailscale integration";
    services.caddy.opencodeHost = lib.mkOption {
      type = lib.types.str;
      default = "opencode.hbohlen.systems";
      description = "Tailscale hostname for opencode";
    };
  };

  config = lib.mkIf config.services.caddy.tailscaleEnable {
    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ tailscalePlugin ];
      };
      
      virtualHosts = {
        "${config.services.caddy.opencodeHost}" = {
          extraConfig = ''
            bind tailscale/opencode
            reverse_proxy 127.0.0.1:8080
          '';
        };
      };
    };
  };
}
```

Note: The first build will fail with a hash error - copy the hash from the error message and add it to the plugin definition.

- [ ] **Step 2: Test module evaluates**

Run: `nix eval .#nixosConfigurations.hbohlen-01.options.services.caddy.tailscaleEnable.definitions`
Expected: Valid Nix expression (no errors)

---

## Task 2: Add opencode systemd service

**Files:**
- Create: `nix/cells/nixos/modules/opencode.nix`

- [ ] **Step 1: Check opencode web command options**

Run: `nix run github:numtide/llm-agents.nix#opencode -- web --help`
Expected: Help output showing available flags for --host binding

- [ ] **Step 2: Create module with correct ExecStart**

```nix
# nix/cells/nixos/modules/opencode.nix
{ config, lib, pkgs, inputs, ... }:

let
  opencodePkg = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
in
{
  options.services.opencode = {
    enable = lib.mkEnableOption "opencode web UI";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port for opencode web UI";
    };
  };

  config = lib.mkIf config.services.opencode.enable {
    systemd.services.opencode-web = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe opencodePkg} web --port ${toString config.services.opencode.port} --host 127.0.0.1";
        Restart = "on-failure";
        RestartSec = "5s";
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };
  };
}
```

---

## Task 3: Configure Tailscale auth key for caddy-tailscale plugin

The caddy-tailscale plugin requires TS_AUTHKEY environment variable.

- [ ] **Step 1: Add environmentFile to caddy config**

Update `caddy-tailscale.nix` to include environment file:

```nix
config = lib.mkIf config.services.caddy.tailscaleEnable {
  services.caddy = {
    enable = true;
    environmentFile = config.sops.secrets.caddy-tailscale-env.path;
    # ... rest
  };
};
```

- [ ] **Step 2: Add secret to opnix module**

Create item in 1Password vault `hbohlen-systems`:
- Title: `tailscale/caddy-authKey`  
- Content should be: `TS_AUTHKEY=tskey-auth-...`

Reference: `op://hbohlen-systems/tailscale/caddy-authKey`

---

## Task 4: Wire everything in host config

**Files:**
- Modify: `nix/cells/nixos/hosts/hbohlen-01/default.nix`

- [ ] **Step 1: Add imports and enable services**

```nix
imports = [
  # ... existing imports
  ../../modules/opencode.nix
  ../../modules/caddy-tailscale.nix
];

services.opencode = {
  enable = true;
  port = 8080;
};

services.caddy.tailscaleEnable = true;
```

---

## Verification

After deploying, verify:

1. `systemctl status opencode-web` shows running
2. From a Tailscale-connected machine: `curl -k https://opencode.hbohlen.systems.ts.net`
3. Caddy logs: `journalctl -u caddy -f`

---

**Plan complete and saved to `docs/superpowers/plans/2026-03-31-opencode-tailscale-web-implementation.md`**

Two execution options:

1. **Subagent-Driven (recommended)** - Dispatch a fresh subagent per task, review between tasks
2. **Inline Execution** - Execute tasks in this session using executing-plans

Which approach?