#!/bin/bash
# Server Hardening Checklist - Run this before hardening any remote server
# Usage: ./hardening-checklist.sh

set -e

echo "=== SERVER HARDENING PRE-FLIGHT CHECKLIST ==="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# 1. Check if connected via Tailscale
echo "1. Checking connection path..."
SSH_FROM=$(echo $SSH_CONNECTION | awk '{print $1}')
if [[ "$SSH_FROM" =~ ^100\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    check_pass "Connected via Tailscale (IP: $SSH_FROM)"
    TAILSCALE_CONNECTED=true
else
    check_warn "NOT connected via Tailscale (IP: $SSH_FROM)"
    TAILSCALE_CONNECTED=false
fi

# 2. Check Tailscale status
echo ""
echo "2. Checking Tailscale status..."
if command -v tailscale &> /dev/null; then
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "")
    if [ -n "$TAILSCALE_IP" ]; then
        check_pass "Tailscale IP: $TAILSCALE_IP"
    else
        check_warn "Tailscale installed but IP not available"
    fi
else
    check_warn "Tailscale not installed"
fi

# 3. Check for SSH keys
echo ""
echo "3. Checking SSH keys..."
if [ -f ~/.ssh/authorized_keys ]; then
    KEY_COUNT=$(wc -l < ~/.ssh/authorized_keys)
    if [ "$KEY_COUNT" -gt 0 ]; then
        check_pass "SSH keys found: $KEY_COUNT key(s)"
    else
        check_fail "authorized_keys exists but is empty!"
    fi
else
    check_fail "No ~/.ssh/authorized_keys file!"
fi

# 4. Backup SSH config
echo ""
echo "4. Backing up SSH config..."
if [ -f /etc/ssh/sshd_config ]; then
    BACKUP_FILE="/etc/ssh/sshd_config.bak.$(date +%Y%m%d-%H%M%S)"
    sudo cp /etc/ssh/sshd_config "$BACKUP_FILE"
    check_pass "SSH config backed up to: $BACKUP_FILE"
else
    check_fail "SSH config not found at /etc/ssh/sshd_config"
fi

# 5. Check sudo access
echo ""
echo "5. Checking sudo access..."
if sudo -n true 2>/dev/null; then
    check_pass "Sudo access confirmed"
else
    check_fail "No passwordless sudo - you'll need to enter password during hardening"
fi

echo ""
echo "=============================================="
if [ "$TAILSCALE_CONNECTED" = true ]; then
    check_pass "READY TO HARDEN - All checks passed"
    echo ""
    echo "REMINDER: Open a second terminal and connect via:"
    echo "  ssh $(whoami)@$(tailscale ip -4 2>/dev/null || echo '<tailscale-ip>')"
    echo ""
    echo "Then run the hardening commands."
else
    echo -e "${YELLOW}⚠ WARNING: Not connected via Tailscale${NC}"
    echo ""
    echo "Without Tailscale fallback, you risk lockout if SSH breaks."
    echo "Consider:"
    echo "  1. Connecting via Tailscale first, OR"
    echo "  2. Having console access ready (DigitalOcean console, etc.)"
fi
