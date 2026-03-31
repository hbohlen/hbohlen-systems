# Hetzner Server Hardening with Tailscale + setec Design

**Date:** 2025-03-31  
**Status:** Draft - Pending Review  
**Approach:** Defense in Depth (Approach B)

---

## 1. Goals

- Secure hbohlen-01 (Hetzner NixOS server) with defense-in-depth strategy
- Enable Tailscale SSH as primary access method
- Implement Tailscale ACLs for network segmentation
- Deploy setec for runtime secrets management
- Add fail2ban for brute-force protection
- Keep OpenSSH as emergency fallback with hardening

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Hetzner Cloud                          │
│                    (hbohlen-01)                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              NixOS System                           │   │
│  │  ┌─────────────────────────────────────────────┐   │   │
│  │  │  Network Layer                              │   │   │
│  │  │  • Firewall: Deny all inbound except TS     │   │   │
│  │  │  • OpenSSH: Port 22, key-only, hardened     │   │   │
│  │  │  • Tailscale: Userspace, subnet routes      │   │   │
│  │  └─────────────────────────────────────────────┘   │   │
│  │  ┌─────────────────────────────────────────────┐   │   │
│  │  │  Access Control                             │   │   │
│  │  │  • Tailscale ACLs: tag-based policies       │   │   │
│  │  │  • Tailscale SSH: Primary access method     │   │   │
│  │  │  • OpenSSH: Fallback for emergencies        │   │   │
│  │  └─────────────────────────────────────────────┘   │   │
│  │  ┌─────────────────────────────────────────────┐   │   │
│  │  │  Secrets Management                         │   │   │
│  │  │  • setec daemon: Tailscale identity auth    │   │   │
│  │  │  • setec CLI: Secret CRUD operations        │   │   │
│  │  │  • SDK: Go/Node/Python runtime access       │   │   │
│  │  └─────────────────────────────────────────────┘   │   │
│  │  ┌─────────────────────────────────────────────┐   │   │
│  │  │  Monitoring & Defense                       │   │   │
│  │  │  • fail2ban: SSH brute-force protection     │   │   │
│  │  └─────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  Tailscale      │
                    │  Control Plane  │
                    │  (ACL policies) │
                    └─────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  Your Devices   │
                    │  (laptop, etc)  │
                    └─────────────────┘
```

---

## 3. Design Decisions

### 3.1 Tailscale SSH as Primary Access

**Rationale:**
- Eliminates SSH key management
- Uses existing Tailscale identity authentication
- Automatic device posture checks
- Works across network changes

**Configuration:**
- Enable `tailscale ssh` on server
- Configure ACL to allow `group:admin` SSH access
- Keep OpenSSH for emergency fallback only

### 3.2 Tailscale ACL Policy

**Groups:**
- `group:admin`: hbohlen's Tailscale identity

**Tags:**
- `tag:server`: Applied to hbohlen-01
- `tag:prod`: Future production servers

**Access Rules:**
- Admin can access all ports on all devices
- Servers can communicate on necessary ports (443)

**SSH Rules:**
- Check mode for admin -> server access
- Allows both root and non-root users

### 3.3 OpenSSH Hardening (Fallback)

**Changes from current config:**
- Disable root login (use Tailscale SSH for root)
- Restrict to modern crypto only (ChaCha20-Poly1305, Curve25519)
- Only listen on Tailscale interface (100.64.0.0/10 CGNAT range)
- Max 3 auth attempts, 2 concurrent sessions

**Why keep it:**
- Emergency access if Tailscale control plane issues
- Can still access via Hetzner console if needed

### 3.4 setec Secrets Management

**Architecture:**
- `setecd` runs as systemd service
- Unix socket at `/run/setec/setec.sock`
- Authenticates via Tailscale identity
- Secrets encrypted at rest with NaCl

**Usage Patterns:**
1. CLI: `setec put/get/list/delete`
2. SDK: `setec.Client` with `Get()` method
3. Config files: Reference secrets by name, resolve at runtime

**Security Properties:**
- Secrets never in git, nix store, or env vars
- Access controlled by Tailscale identity
- In-memory caching with TTL
- Audit logging of secret access

### 3.5 fail2ban

**Configuration:**
- Max 3 retries within 10 minutes
- Ban duration: 1 hour
- Monitor SSH auth logs
- iptables-based blocking

---

## 4. File Structure

```
nix/cells/nixos/
├── default.nix                    # existing - exports nixosConfigurations
├── hosts/
│   └── hbohlen-01/
│       ├── default.nix            # existing - host config
│       └── hardware-configuration.nix
└── modules/
    ├── base.nix                   # existing - basic NixOS config
    ├── disko.nix                  # existing - disk partitioning
    ├── fail2ban.nix               # NEW - intrusion protection
    ├── ssh-hardening.nix          # NEW - OpenSSH hardening
    ├── tailscale-acl.nix          # NEW - Tailscale ACL config
    └── setec.nix                  # NEW - setec secrets daemon
```

---

## 5. Implementation Phases

### Phase 1: Foundation (30-60 mins)

1. Enable Tailscale SSH on hbohlen-01
2. Test: `tailscale ssh hbohlen@hbohlen-01`
3. Create `ssh-hardening.nix` module
4. Deploy and verify access works

**Success Criteria:**
- Can SSH via Tailscale
- OpenSSH still works as fallback
- Root login disabled on OpenSSH

### Phase 2: Defense in Depth (30-45 mins)

1. Create `fail2ban.nix` module
2. Create Tailscale ACL policy file
3. Apply tags to server: `tailscale up --advertise-tags=tag:server`
4. Deploy and verify SSH still works

**Success Criteria:**
- fail2ban running and monitoring logs
- ACL policy applied in Tailscale admin panel
- SSH access still functional

### Phase 3: Secrets Management (45-90 mins)

1. Create `setec.nix` NixOS module
2. Deploy setec server
3. Store test secret: `setec put --name=test --value=hello`
4. Test retrieval: `setec get --name=test`
5. Create example app using setec SDK
6. Update Hermes agent config to reference setec secrets

**Success Criteria:**
- setec daemon running
- Can store/retrieve secrets via CLI
- SDK can access secrets from code
- Hermes agents can read API keys from setec

---

## 6. Secrets Migration Plan

**Current State:**
- No secrets management (everything in config files or env vars)

**Target State:**
- API keys in setec
- Config files reference secret names, not values
- No secrets in git or nix store

**Migration Steps:**
1. List all secrets needed (Anthropic API key, etc.)
2. Store each in setec via CLI
3. Update application configs to use setec paths
4. Remove secrets from old locations

---

## 7. Rollback Plan

**If Tailscale SSH fails:**
1. Use Hetzner console to access server
2. Edit config to re-enable OpenSSH root login
3. Deploy with `nixos-rebuild switch`
4. Debug Tailscale SSH issue

**If setec causes issues:**
1. Stop setec service
2. Temporarily put secrets in agenix/sops as fallback
3. Debug setec configuration

---

## 8. Future Considerations

**Out of scope for this design:**
- Auditd system call logging
- Intrusion detection (AIDE, etc.)
- Automated security scanning
- Backup encryption keys in setec

**Potential future additions:**
- Device posture requirements in ACLs
- Secret rotation automation
- Monitoring/alerting on secret access

---

## 9. Open Questions

1. Should we use setec's experimental features or stick to stable API?
2. Do we need secrets that change at runtime (rotating tokens)?
3. Should we restrict OpenSSH to specific source IPs as well?

---

## 10. References

- [Tailscale setec Documentation](https://tailscale.com/kb/1486/setec)
- [Tailscale ACL Documentation](https://tailscale.com/kb/1018/acls)
- [Tailscale SSH Documentation](https://tailscale.com/kb/1193/tailscale-ssh)
- [NixOS fail2ban Module](https://search.nixos.org/options?query=services.fail2ban)
