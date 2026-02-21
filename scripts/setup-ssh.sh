#!/bin/bash
# Setup SSH keys and config for NAS access

SSH_KEY="$HOME/.ssh/id_ed25519"
SSH_CONFIG="$HOME/.ssh/config"
NAS_IP="192.168.178.100"
NAS_ALIAS="nas"

set -e

echo "=== SSH Setup for NAS ==="

# Ensure .ssh directory exists
mkdir -p ~/.ssh && chmod 700 ~/.ssh

# Generate key if it doesn't exist
if [[ ! -f "$SSH_KEY" ]]; then
    echo "[*] Generating SSH key..."
    ssh-keygen -t ed25519 -C "$USER@$(hostname)" -f "$SSH_KEY" -N ""
    echo "[+] Key generated: $SSH_KEY.pub"
else
    echo "[✓] SSH key already exists: $SSH_KEY"
fi

# Add NAS to known_hosts (avoid "unknown host" prompt)
if ! grep -q "$NAS_IP" ~/.ssh/known_hosts 2>/dev/null; then
    echo "[*] Adding NAS to known_hosts..."
    ssh-keyscan -H "$NAS_IP" >> ~/.ssh/known_hosts 2>/dev/null
    echo "[+] NAS host key added"
else
    echo "[✓] NAS already in known_hosts"
fi

# Ensure NAS config entry exists
if ! grep -q "Host $NAS_ALIAS" "$SSH_CONFIG" 2>/dev/null; then
    echo "[*] Adding NAS alias to SSH config..."
    cat >> "$SSH_CONFIG" << EOF

# NAS Connection
Host $NAS_ALIAS
    HostName $NAS_IP
    User admin
    IdentityFile ~/.ssh/id_ed25519
EOF
    chmod 600 "$SSH_CONFIG"
    echo "[+] NAS alias added"
else
    echo "[✓] NAS alias already in SSH config"
fi

echo ""
echo "=== Setup Complete ==="
echo "Your public key:"
cat "$SSH_KEY.pub"
echo ""
echo "==> ACTION REQUIRED: Copy this key to your NAS:"
echo "    ssh-copy-id admin@$NAS_IP"
echo ""
echo "After copying the key, test with: ssh nas"
