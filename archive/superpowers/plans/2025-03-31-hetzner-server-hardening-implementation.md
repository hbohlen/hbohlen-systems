# Hetzner Server Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Secure hbohlen-01 with Tailscale SSH, ACLs, setec secrets management, fail2ban, and hardened OpenSSH fallback

**Architecture:** Three-phase implementation (Foundation, Defense in Depth, Secrets) using NixOS modules in dendritic structure. Each phase deployable independently.

**Tech Stack:** NixOS, Tailscale, setec, fail2ban, OpenSSH with modern crypto

---

## File Structure

```
nix/cells/nixos/
├── default.nix                          # existing
├── hosts/
│   └── hbohlen-01/
│       ├── default.nix                  # existing
│       └── hardware-configuration.nix   # existing
└── modules/
    ├── base.nix                         # existing - MODIFY
    ├── disko.nix                        # existing
    ├── fail2ban.nix                     # NEW
    ├── ssh-hardening.nix                # NEW
    └── tailscale-enhanced.nix           # NEW (replaces basic tailscale config)

# Note: setec will be added as a custom module since it's not in nixpkgs yet
tailscale/
└── acl.hujson                           # NEW - Tailscale ACL policy
```

---

## Phase 1: Foundation (Tailscale SSH + OpenSSH Hardening)

### Task 1.1: Create ssh-hardening.nix module

**Files:**
- Create: `nix/cells/nixos/modules/ssh-hardening.nix`

- [ ] **Step 1: Write the module**

```nix
# nix/cells/nixos/modules/ssh-hardening.nix
{ config, pkgs, ... }:

{
  # Harden OpenSSH for emergency fallback only
  services.openssh = {
    enable = true;
    
    settings = {
      # Disable weak auth methods
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      
      # Modern crypto only
      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
      ];
      KexAlgorithms = [
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
      ];
      Macs = [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.org"
      ];
      
      # Rate limiting
      MaxAuthTries = 3;
      MaxSessions = 2;
      ClientAliveInterval = 60;
      ClientAliveCountMax = 3;
    };
    
    # Only listen on Tailscale interface (CGNAT range)
    # This prevents direct internet SSH while keeping fallback
    listenAddresses = [
      { addr = "100.64.0.0"; port = 22; }
    ];
  };
  
  # Ensure firewall allows SSH on Tailscale interface
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
}
```

- [ ] **Step 2: Commit**

```bash
git add nix/cells/nixos/modules/ssh-hardening.nix
git commit -m "feat: add ssh-hardening module for OpenSSH fallback"
```

---

### Task 1.2: Create tailscale-enhanced.nix module

**Files:**
- Create: `nix/cells/nixos/modules/tailscale-enhanced.nix`

- [ ] **Step 1: Write the module**

```nix
# nix/cells/nixos/modules/tailscale-enhanced.nix
{ config, pkgs, ... }:

let
  # Advertise tags for ACL policy
  tailscaleTags = "tag:server,tag:prod";
in
{
  # Enable Tailscale daemon
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "server";
    extraUpFlags = [
      "--ssh"                                    # Enable Tailscale SSH
      "--advertise-tags=${tailscaleTags}"        # Apply ACL tags
      "--reset"                                  # Ensure clean state
    ];
  };
  
  # Ensure Tailscale starts on boot
  systemd.services.tailscale.wantedBy = [ "multi-user.target" ];
  
  # Install tailscale CLI for debugging
  environment.systemPackages = [ pkgs.tailscale ];
}
```

- [ ] **Step 2: Update base.nix to remove conflicting tailscale config**

```nix
# nix/cells/nixos/modules/base.nix
# REMOVE the services.tailscale block entirely
# (lines 57-61 in current version)

# Keep everything else the same
```

- [ ] **Step 3: Commit**

```bash
git add nix/cells/nixos/modules/tailscale-enhanced.nix
git commit -m "feat: add tailscale-enhanced module with SSH and tags"
```

---

### Task 1.3: Update nixosConfigurations to use new modules

**Files:**
- Modify: `nix/cells/nixos/default.nix`

- [ ] **Step 1: Update the module imports**

```nix
# nix/cells/nixos/default.nix
{ inputs, ... }:
{
  flake.nixosConfigurations = {
    hbohlen-01 = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        inputs.disko.nixosModules.disko
        ./modules/disko.nix
        ./modules/base.nix
        ./modules/ssh-hardening.nix          # NEW
        ./modules/tailscale-enhanced.nix     # NEW (replaces basic tailscale)
        ./hosts/hbohlen-01/default.nix
      ];
    };
  };
}
```

- [ ] **Step 2: Commit**

```bash
git add nix/cells/nixos/default.nix
git commit -m "feat: integrate ssh-hardening and tailscale-enhanced modules"
```

---

### Task 1.4: Deploy Phase 1 to server

**Files:**
- None (deployment task)

- [ ] **Step 1: Build the configuration**

```bash
cd ~/dev/hbohlen-systems
nix build .#nixosConfigurations.hbohlen-01.config.system.build.toplevel --no-use-machine-substituters
```

Expected: Build succeeds, shows store path

- [ ] **Step 2: Deploy via nixos-rebuild**

```bash
nixos-rebuild switch \
  --flake .#hbohlen-01 \
  --target-host root@hbohlen-01 \
  --no-use-machine-substituters
```

Expected: Deploy succeeds, SSH connection remains open

- [ ] **Step 3: Verify Tailscale SSH works**

From your laptop:
```bash
tailscale ssh hbohlen@hbohlen-01
```

Expected: You get a shell without needing SSH keys

- [ ] **Step 4: Verify OpenSSH still works via Tailscale IP**

```bash
ssh hbohlen@100.x.x.x  # hbohlen-01's Tailscale IP
```

Expected: SSH succeeds with key auth

- [ ] **Step 5: Verify root login is disabled on OpenSSH**

```bash
ssh root@100.x.x.x
```

Expected: Permission denied

- [ ] **Step 6: Document and commit**

```bash
git add -A
git commit -m "deploy: phase 1 - tailscale ssh and hardened openssh"
```

---

## Phase 2: Defense in Depth (fail2ban + ACLs)

### Task 2.1: Create fail2ban.nix module

**Files:**
- Create: `nix/cells/nixos/modules/fail2ban.nix`

- [ ] **Step 1: Write the module**

```nix
# nix/cells/nixos/modules/fail2ban.nix
{ config, pkgs, ... }:

{
  services.fail2ban = {
    enable = true;
    
    # Global settings
    maxretry = 3;
    findtime = "10m";
    bantime = "1h";
    
    # Extra daemon config
    extraDaemonConfig = ''
      [DEFAULT]
      backend = systemd
      usedns = no
      logencoding = utf-8
    '';
    
    # SSH jail for brute force protection
    jails = {
      sshd = ''
        enabled = true
        filter = sshd
        action = iptables-multiport[name=SSH, port="ssh", protocol=tcp]
        logpath = /var/log/auth.log
        backend = %(sshd_backend)s
      '';
      
      # Additional protection for Tailscale SSH (logs to same auth.log)
      sshd-tailscale = ''
        enabled = true
        filter = sshd
        action = iptables-multiport[name=SSH-TAILSCALE, port="ssh", protocol=tcp]
        logpath = /var/log/auth.log
        maxretry = 5
        findtime = 15m
      '';
    };
  };
  
  # Ensure log directory exists
  systemd.tmpfiles.rules = [
    "d /var/log 0755 root root -"
  ];
}
```

- [ ] **Step 2: Commit**

```bash
git add nix/cells/nixos/modules/fail2ban.nix
git commit -m "feat: add fail2ban module for ssh protection"
```

---

### Task 2.2: Create Tailscale ACL policy

**Files:**
- Create: `tailscale/acl.hujson`

- [ ] **Step 1: Create directory and file**

```bash
mkdir -p tailscale
```

- [ ] **Step 2: Write the ACL policy**

```json
// tailscale/acl.hujson
// Tailscale ACL policy for hbohlen infrastructure
// Apply via: tailscale login --advertise-tags=tag:server

{
  // Define user groups
  "groups": {
    "group:admin": ["hbohlen@github"],
  },

  // Define device tags and their owners
  "tagOwners": {
    "tag:server": ["group:admin"],
    "tag:prod": ["group:admin"],
    "tag:dev": ["group:admin"],
  },

  // Access control rules
  "acls": [
    // Admin can access all devices and all ports
    {
      "action": "accept",
      "src": ["group:admin"],
      "dst": ["*:*"]
    },

    // Servers can communicate with each other on HTTPS
    {
      "action": "accept",
      "src": ["tag:server"],
      "dst": ["tag:server:443"]
    },

    // Dev servers can access prod monitoring
    {
      "action": "accept",
      "src": ["tag:dev"],
      "dst": ["tag:prod:9100"]  // Prometheus node exporter
    },
  ],

  // SSH access policy (Tailscale SSH)
  "ssh": [
    // Admin can SSH to any server as any user (with check)
    {
      "action": "check",
      "src": ["group:admin"],
      "dst": ["tag:server"],
      "users": ["autogroup:nonroot", "root"]
    },
    
    // Admin can SSH to prod as non-root only
    {
      "action": "check",
      "src": ["group:admin"],
      "dst": ["tag:prod"],
      "users": ["autogroup:nonroot"]
    },
  ],

  // Device posture / attributes (for future expansion)
  "nodeAttrs": [
    {
      "target": ["tag:server"],
      "attr": ["funnel"]
    },
  ],
}
```

- [ ] **Step 3: Commit**

```bash
git add tailscale/acl.hujson
git commit -m "feat: add tailscale ACL policy"
```

---

### Task 2.3: Integrate fail2ban into configuration

**Files:**
- Modify: `nix/cells/nixos/default.nix`

- [ ] **Step 1: Add fail2ban to module imports**

```nix
# nix/cells/nixos/default.nix
{ inputs, ... }:
{
  flake.nixosConfigurations = {
    hbohlen-01 = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        inputs.disko.nixosModules.disko
        ./modules/disko.nix
        ./modules/base.nix
        ./modules/ssh-hardening.nix
        ./modules/tailscale-enhanced.nix
        ./modules/fail2ban.nix           # NEW
        ./hosts/hbohlen-01/default.nix
      ];
    };
  };
}
```

- [ ] **Step 2: Commit**

```bash
git add nix/cells/nixos/default.nix
git commit -m "feat: integrate fail2ban module"
```

---

### Task 2.4: Apply tags to server and deploy

**Files:**
- None (remote commands)

- [ ] **Step 1: Rebuild and deploy**

```bash
cd ~/dev/hbohlen-systems
nixos-rebuild switch \
  --flake .#hbohlen-01 \
  --target-host root@hbohlen-01 \
  --no-use-machine-substituters
```

Expected: Deploy succeeds

- [ ] **Step 2: Verify fail2ban is running**

```bash
tailscale ssh hbohlen@hbohlen-01
sudo systemctl status fail2ban
```

Expected: Active (running)

- [ ] **Step 3: Check fail2ban status**

```bash
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

Expected: Shows jail status, currently 0 banned

- [ ] **Step 4: Verify Tailscale tags applied**

```bash
sudo tailscale status
```

Expected: Shows tags: [tag:server tag:prod]

- [ ] **Step 5: Commit deployment**

```bash
git add -A
git commit -m "deploy: phase 2 - fail2ban and tailscale ACLs"
```

---

## Phase 3: Secrets Management (setec)

### Task 3.1: Research setec availability

**Files:**
- None (research task)

- [ ] **Step 1: Check if setec is in nixpkgs**

```bash
nix search nixpkgs setec 2>/dev/null || echo "Not found in nixpkgs"
```

- [ ] **Step 2: Check Tailscale repo for packaging**

Search for existing Nix packaging or build from source instructions.

**Decision point:**
- If setec available: Use nixpkgs version
- If not available: Create custom derivation or use pre-built binary

(Note: setec is relatively new, may need custom packaging)

---

### Task 3.2: Create setec module (if packaging needed)

**Files:**
- Create: `nix/cells/nixos/modules/setec.nix`

- [ ] **Step 1: Write setec derivation and module**

```nix
# nix/cells/nixos/modules/setec.nix
{ config, pkgs, lib, ... }:

let
  # setec derivation - may need to build from source or fetch pre-built
  setec = pkgs.buildGoModule rec {
    pname = "setec";
    version = "0.1.0";  # Update to latest
    
    src = pkgs.fetchFromGitHub {
      owner = "tailscale";
      repo = "setec";
      rev = "v${version}";
      sha256 = lib.fakeSha256;  # Replace with actual hash after first build attempt
    };
    
    vendorSha256 = lib.fakeSha256;  # Replace with actual hash
    
    subPackages = [ "cmd/setec" "cmd/setecd" ];
    
    meta = with lib; {
      description = "Tailscale's secrets management service";
      homepage = "https://tailscale.com/kb/1486/setec";
      license = licenses.bsd3;
    };
  };
in
{
  # setec daemon service
  systemd.services.setecd = {
    description = "Tailscale setec secrets daemon";
    after = [ "network.target" "tailscaled.service" ];
    requires = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "simple";
      ExecStart = "${setec}/bin/setecd --socket=/run/setec/setec.sock";
      Restart = "always";
      RestartSec = 5;
      
      # Security hardening
      DynamicUser = true;
      RuntimeDirectory = "setec";
      StateDirectory = "setec";
      
      # Capabilities
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
      CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
      
      # Restrictions
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
    };
  };
  
  # Create setec group for access control
  users.groups.setec = {};
  
  # Add hbohlen to setec group for CLI access
  users.users.hbohlen.extraGroups = [ "setec" ];
  
  # Install setec CLI
  environment.systemPackages = [ setec ];
  
  # Socket directory permissions
  systemd.tmpfiles.rules = [
    "d /run/setec 0750 root setec -"
  ];
}
```

**Alternative if building fails:** Use pre-built binary

```nix
setec = pkgs.stdenv.mkDerivation rec {
  pname = "setec";
  version = "0.1.0";
  
  src = pkgs.fetchurl {
    url = "https://github.com/tailscale/setec/releases/download/v${version}/setec_${version}_linux_amd64.tar.gz";
    sha256 = lib.fakeSha256;
  };
  
  sourceRoot = ".";
  
  installPhase = ''
    mkdir -p $out/bin
    cp setec $out/bin/
    cp setecd $out/bin/
  '';
};
```

- [ ] **Step 2: Commit**

```bash
git add nix/cells/nixos/modules/setec.nix
git commit -m "feat: add setec secrets management module"
```

---

### Task 3.3: Integrate setec into configuration

**Files:**
- Modify: `nix/cells/nixos/default.nix`

- [ ] **Step 1: Add setec module**

```nix
# nix/cells/nixos/default.nix
{ inputs, ... }:
{
  flake.nixosConfigurations = {
    hbohlen-01 = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        inputs.disko.nixosModules.disko
        ./modules/disko.nix
        ./modules/base.nix
        ./modules/ssh-hardening.nix
        ./modules/tailscale-enhanced.nix
        ./modules/fail2ban.nix
        ./modules/setec.nix              # NEW
        ./hosts/hbohlen-01/default.nix
      ];
    };
  };
}
```

- [ ] **Step 2: Commit**

```bash
git add nix/cells/nixos/default.nix
git commit -m "feat: integrate setec module"
```

---

### Task 3.4: Deploy setec and test

**Files:**
- None (deployment and testing)

- [ ] **Step 1: Build and deploy**

```bash
cd ~/dev/hbohlen-systems
nixos-rebuild switch \
  --flake .#hbohlen-01 \
  --target-host root@hbohlen-01 \
  --no-use-machine-substituters
```

Expected: Build may take time if compiling Go. If pre-built binary, should be fast.

- [ ] **Step 2: Verify setec daemon is running**

```bash
tailscale ssh hbohlen@hbohlen-01
sudo systemctl status setecd
```

Expected: Active (running)

- [ ] **Step 3: Test setec CLI**

```bash
# Check if CLI works
setec --version || setec version

# Store a test secret
setec put --name=test-secret --value="hello-from-setec"

# Retrieve the secret
setec get --name=test-secret
```

Expected: Returns "hello-from-setec"

- [ ] **Step 4: Test SDK access (optional)**

Create a test program that uses the setec SDK (Go example):

```bash
cat > /tmp/test-setec.go << 'EOF'
package main

import (
    "context"
    "fmt"
    "tailscale.com/setec"
)

func main() {
    client, err := setec.NewClient("/run/setec/setec.sock")
    if err != nil {
        panic(err)
    }
    
    secret, err := client.Get(context.Background(), "test-secret")
    if err != nil {
        panic(err)
    }
    
    fmt.Println("Secret value:", secret)
}
EOF

# Would need Go and setec SDK installed to run this
```

For now, just verify the socket exists:
```bash
ls -la /run/setec/
```

Expected: Shows setec.sock with correct permissions

- [ ] **Step 5: Store real secrets**

Now store your actual secrets:

```bash
# Example: Anthropic API key
setec put --name=anthropic-api-key --value="sk-ant-api03-..."

# Example: OpenAI API key
setec put --name=openai-api-key --value="sk-..."

# List all secrets
setec list
```

- [ ] **Step 6: Commit deployment**

```bash
git add -A
git commit -m "deploy: phase 3 - setec secrets management"
```

---

## Phase 4: Integration with Hermes Agents (Optional)

### Task 4.1: Create agent config template using setec

**Files:**
- Create: `config/agents/config.template.json`

- [ ] **Step 1: Create config template**

```json
{
  "anthropic_api_key": "setec:anthropic-api-key",
  "openai_api_key": "setec:openai-api-key",
  "other_secret": "setec:other-secret-name"
}
```

The agent code would need to resolve `setec:` prefixed values by calling the setec SDK.

- [ ] **Step 2: Document the pattern**

Add README or comments explaining how agents should resolve setec secrets.

---

## Final Verification Checklist

After all phases complete, verify:

- [ ] Can SSH via Tailscale: `tailscale ssh hbohlen@hbohlen-01`
- [ ] OpenSSH only works via Tailscale IP, not public IP
- [ ] Root login disabled on OpenSSH
- [ ] fail2ban is running: `sudo systemctl status fail2ban`
- [ ] Tailscale tags applied: `sudo tailscale status` shows [tag:server]
- [ ] setec daemon running: `sudo systemctl status setecd`
- [ ] Can store/retrieve secrets via setec CLI
- [ ] ACL policy visible in Tailscale admin panel

---

## Rollback Procedures

**If Tailscale SSH fails:**
1. Access via Hetzner console
2. Edit `nix/cells/nixos/modules/ssh-hardening.nix`
3. Change `PermitRootLogin = "no"` to `PermitRootLogin = "prohibit-password"`
4. Rebuild and switch

**If setec causes issues:**
1. Stop setec service: `sudo systemctl stop setecd`
2. Disable in config temporarily
3. Consider fallback to agenix/sops-nix if needed

---

## Documentation Updates

After implementation, update:
- [ ] Main project README with new security features
- [ ] docs/ directory with setec usage examples
- [ ] Add troubleshooting section for common issues
