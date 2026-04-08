---
name: server-security-hardening
description: Safely harden Ubuntu/Debian servers with SSH, firewall, and fail2ban - prioritizing access verification to prevent lockout.
tags: [security, ssh, firewall, hardening, tailscale]
category: devops
metadata:
  author: hbohlen-systems implementation experience
  version: "1.0.0"
---

# Server Security Hardening

Harden Ubuntu/Debian servers while maintaining safe access. **Never lock yourself out.**

## Pre-Flight Safety Check (MANDATORY)

Before ANY hardening:

1. **Identify all access paths:**
   ```bash
   # Check current connection
   echo "SSH connection: $SSH_CONNECTION"
   who am i
   
   # Check network interfaces
   ip addr show
   
   # Check if Tailscale/other VPN is active
   ip route | grep 100
   ```

2. **Verify SSH key-based access:**
   ```bash
   # Confirm authorized_keys exists and has content
   ls -la ~/.ssh/authorized_keys
   cat ~/.ssh/authorized_keys | wc -l  # Should be > 0
   ```

3. **Establish backup connection:**
   - Open a second SSH session via alternate path (Tailscale IP, different interface)
   - Confirm it works before proceeding
   - Keep both sessions open during hardening

4. **Check Tailscale status (if installed):**
   ```bash
   # System install
   tailscale status
   tailscale ip -4
   
   # Userspace mode (common for non-root installs)
   # Binary may be at ~/.local/bin/tailscale
   # Socket may be at ~/.local/var/run/tailscale/tailscaled.sock
   export PATH="$HOME/.local/bin:$PATH"
   tailscale --socket=/home/$USER/.local/var/run/tailscale/tailscaled.sock status
   ```

## SSH Hardening

1. **Backup current config:**
   ```bash
   sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d-%H%M%S)
   ```

2. **Apply security settings:**
   ```bash
   sudo tee -a /etc/ssh/sshd_config << 'EOF'
   
   # Security hardening
   PasswordAuthentication no
   PubkeyAuthentication yes
   PermitRootLogin no
   AllowUsers YOUR_USERNAME
   MaxAuthTries 3
   ClientAliveInterval 300
   ClientAliveCountMax 2
   EOF
   ```

3. **Test and restart:**
   ```bash
   sudo sshd -t          # Test syntax
   sudo systemctl restart sshd
   ```

4. **Verify access in NEW terminal** before closing existing sessions.

## Firewall (UFW)

```bash
# Install UFW
sudo apt update && sudo apt install -y ufw

# Default deny incoming
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (if still needed on public interface)
# Or skip if only using Tailscale/VPN
sudo ufw allow 22/tcp

# Enable with caution - ensure you have working access first
sudo ufw enable
```

## Fail2ban

```bash
# Install
sudo apt install -y fail2ban

# Basic config
sudo tee /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
EOF

sudo systemctl restart fail2ban
```

## Critical Pitfalls

- **Never disable password auth without verifying SSH keys work**
- **Never restrict AllowUsers without confirming your username is included**
- **Always test in a NEW terminal/session before closing existing ones**
- **Userspace Tailscale uses different socket paths** - check `~/.local/var/run/tailscale/`
- **Sudo password piping may not work** through some terminal tools - have user run commands directly

## Verification Checklist

- [ ] Backup SSH config created
- [ ] Second SSH session confirmed working before changes
- [ ] SSH keys verified present in authorized_keys
- [ ] Config syntax tested (`sshd -t`)
- [ ] New SSH connection tested after each change
- [ ] All original sessions still responsive