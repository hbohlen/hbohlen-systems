---
name: server-hardening-tailscale-safe
description: Safely harden a remote server with Tailscale without locking yourself out. Emphasizes verification steps and fallback access.
category: devops
---

# Safe Server Hardening with Tailscale

Use this when hardening a remote server that has Tailscale configured, to avoid lockout.

## Pre-Hardening Safety Checklist

1. **Verify Tailscale connectivity FIRST**
   ```bash
   # Check Tailscale IP
   tailscale ip -4
   # Or with custom socket:
   tailscale --socket=/path/to/tailscaled.sock ip -4
   ```

2. **Confirm current SSH connection path**
   ```bash
   echo "Connected from: $SSH_CONNECTION"
   # If it shows 100.x.x.x, you're on Tailscale
   ```

3. **Open SECOND SSH session via Tailscale**
   ```bash
   ssh user@<tailscale-ip>
   ```
   - Only proceed if this works! This is your fallback

4. **Backup SSH config**
   ```bash
   sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d-%H%M%S)
   ```

5. **Verify SSH keys are present**
   ```bash
   ls -la ~/.ssh/authorized_keys
   ```
   - If no keys: STOP and set up key-based auth first

## Hardening Steps

### Phase 1: SSH Hardening

Add to `/etc/ssh/sshd_config`:
```
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
AllowUsers <username>
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
```

Test and restart:
```bash
sudo sshd -t
sudo systemctl restart ssh  # or sshd on some systems
```

**CRITICAL**: Test SSH via Tailscale in a NEW terminal before proceeding!

### Phase 2: Firewall (UFW)

```bash
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw enable
```

### Phase 3: Fail2ban

```bash
sudo apt install fail2ban
sudo tee /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
EOF

sudo systemctl restart fail2ban
sudo systemctl enable fail2ban
```

## Verification

```bash
# Check services
sudo systemctl status ssh fail2ban

# Check firewall
sudo ufw status verbose

# Check fail2ban
sudo fail2ban-client status sshd

# Check SSH config
grep -E "^(PasswordAuthentication|PermitRootLogin|AllowUsers)" /etc/ssh/sshd_config
```

## Emergency Recovery

If locked out:
1. Use DigitalOcean console (web-based)
2. Or Tailscale SSH if that's what you used

## Special Cases

### Tailscale Userspace Mode
- Socket at: `~/.local/var/run/tailscale/tailscaled.sock`
- Check status: `tailscale --socket=/path/to/socket status`
- SSH still binds to 0.0.0.0:22 but Tailscale handles auth
- Cannot easily filter by interface in UFW

### Ubuntu vs Other Distros
- Ubuntu: service name is `ssh`, not `sshd`
- Config at `/etc/ssh/sshd_config` (same)

## Pitfalls

- **Never disable password auth before verifying SSH keys work**
- **Never restart SSH without testing config syntax**
- **Never enable firewall without allowing SSH first**
- **Always have a second terminal open before making changes**
