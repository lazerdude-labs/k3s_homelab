#!/bin/bash
set -euo pipefail
export VAULT_ADDR="http://127.0.0.1:8200"

echo "=== K3S Vault Agent Setup ==="

# -----------------------------
# 0. Authenticate to Vault
# -----------------------------
if [[ -z "${VAULT_TOKEN:-}" ]]; then
    # Check if root token was saved from vault installation
    if [[ -f /etc/vault.d/root_token ]]; then
        echo "Found root token from Vault installation..."
        # Ensure file is readable
        if ! sudo test -r /etc/vault.d/root_token; then
            echo "ERROR: Cannot read /etc/vault.d/root_token"
            echo "Run this to fix permissions:"
            echo "  sudo chmod 640 /etc/vault.d/root_token"
            exit 1
        fi
        export VAULT_TOKEN=$(sudo cat /etc/vault.d/root_token)
        echo "[OK] Using root token from /etc/vault.d/root_token"
    else
        echo "No VAULT_TOKEN environment variable found."
        echo ""
        echo "You need to authenticate to Vault first. Choose one of:"
        echo "  1. vault login -method=userpass"
        echo "  2. vault login -method=ldap"
        echo "  3. vault login (interactive)"
        echo "  4. export VAULT_TOKEN=<your-root-or-admin-token>"
        echo ""
        echo "Then run this script again with the authenticated token."
        exit 1
    fi
fi

# Verify authentication
if ! vault token lookup >/dev/null 2>&1; then
    echo "ERROR: Failed to authenticate to Vault with the provided token."
    echo "The token may be invalid or expired."
    echo ""
    echo "Please re-authenticate:"
    echo "  unset VAULT_TOKEN"
    echo "  vault login <auth-method>"
    echo "  sudo ./scripts/vault_agent_setup.sh"
    exit 1
fi

echo "[OK] Authenticated to Vault"

# -----------------------------
# 1. Ensure Vault is reachable
# -----------------------------


if ! vault status >/dev/null 2>&1; then
    echo "WARNING: Vault is not reachable at $VAULT_ADDR"
    echo "Installing Vault..."
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    INSTALL_SCRIPT="$SCRIPT_DIR/install_vault.rhel.sh"
    
    if [[ ! -f "$INSTALL_SCRIPT" ]]; then
        echo "ERROR: $INSTALL_SCRIPT not found"
        exit 1
    fi
    
    bash "$INSTALL_SCRIPT"
    
    if ! vault status >/dev/null 2>&1; then
        echo "ERROR: Vault installation failed or Vault is still not reachable"
        exit 1
    fi
fi
vault secrets enable -path=k3s kv-v2
echo "[OK] Vault is reachable"

# -----------------------------
# 2. Create policy for K3S
# -----------------------------
echo "Creating Vault policy: k3s-policy"

sudo tee /etc/vault.d/k3s-policy.hcl >/dev/null <<EOF
path "k3s/*" {
  capabilities = ["create", "update", "read", "list"]
}
EOF

vault policy write k3s-policy /etc/vault.d/k3s-policy.hcl
echo "[OK] Policy created"

# -----------------------------
# 3. Enable AppRole auth
# -----------------------------
echo "Enabling AppRole auth method"
vault auth enable approle 2>/dev/null || true

# -----------------------------
# 4. Create AppRole
# -----------------------------
echo "Creating AppRole: k3s-role"

vault write auth/approle/role/k3s-role \
  token_policies="k3s-policy" \
  token_ttl="24h" \
  token_max_ttl="72h"

# -----------------------------
# 5. Fetch role_id and secret_id
# -----------------------------
echo "Fetching AppRole credentials"


vault read -field=role_id auth/approle/role/k3s-role/role-id \
  | sudo tee /etc/vault.d/role_id >/dev/null

vault write -field=secret_id -f auth/approle/role/k3s-role/secret-id \
  | sudo tee /etc/vault.d/secret_id >/dev/null


sudo chmod 600 /etc/vault.d/role_id /etc/vault.d/secret_id

echo "[OK] role_id and secret_id stored"

# -----------------------------
# 6. Create group for token access
# -----------------------------
echo "Creating group: k3s-deployer"

sudo groupadd -f k3s-deployer

# Add your normal user to the group
if [[ -n "${SUDO_USER:-}" ]]; then
    usermod -aG k3s-deployer "$SUDO_USER"
    echo "[OK] Added $SUDO_USER to k3s-deployer group"
else
    echo "WARNING: Could not detect invoking user. Add manually:"
    echo "  usermod -aG k3s-deployer <username>"
fi

# -----------------------------
# 7. Vault Agent config
# -----------------------------
echo "Writing Vault Agent config"

# Determine numeric UID/GID for sink ownership (Vault requires integers)
ROOT_UID=$(id -u root)
K3S_DEPLOYER_GID=$(getent group k3s-deployer | cut -d: -f3 || true)
if [[ -z "$K3S_DEPLOYER_GID" ]]; then
  # fallback to root group if k3s-deployer not found
  K3S_DEPLOYER_GID=0
fi

sudo tee /etc/vault.d/agent-k3s.hcl <<EOF
exit_after_auth = false
pid_file = "/run/vault-agent-k3s.pid"

auto_auth {
  method "approle" {
    mount_path = "auth/approle"
    config = {
      role_id_file_path   = "/etc/vault.d/role_id"
      secret_id_file_path = "/etc/vault.d/secret_id"
    }
  }

  sink "file" {
    config = {
      path = "/etc/vault.d/agent-token-k3s"
      mode = 0640
      user = ${ROOT_UID}
      group = ${K3S_DEPLOYER_GID}
    }
  }
}

vault {
  address = "http://127.0.0.1:8200"
}
EOF

chmod 600 /etc/vault.d/agent-k3s.hcl

echo "[OK] Vault Agent config installed"

# -----------------------------
# 8. systemd service
# -----------------------------
echo "Installing systemd service"

cat >/etc/systemd/system/vault-agent-k3s.service <<EOF
[Unit]
Description=Vault Agent for K3S Automation
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/vault agent -address=http://127.0.0.1:8200 -config=/etc/vault.d/agent-k3s.hcl
Restart=on-failure
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vault-agent-k3s.service

# First start (may race with file writes)
systemctl start vault-agent-k3s.service

# Guaranteed good start after files exist
sleep 1
systemctl restart vault-agent-k3s.service


echo "[OK] Vault Agent service started"

# -----------------------------
# 9. Verify token sink
# -----------------------------
echo "Waiting for Vault Agent to generate token..."

# Wait up to 30 seconds for a *non-empty* token file
for i in {1..10}; do
    if [[ -s /etc/vault.d/agent-token-k3s ]]; then
        echo "[OK] Token generated at /etc/vault.d/agent-token-k3s"
        break
    fi
    sleep 1
done

if [[ ! -s /etc/vault.d/agent-token-k3s ]]; then
    echo "ERROR: Token file not created. Check Vault Agent logs:"
    echo "  journalctl -u vault-agent-k3s -f"
    exit 1
fi

echo "=== Vault Agent Setup Complete ==="
echo "Your K3S deployment script can now authenticate automatically. \n You have been added to the k3s-deployer group.
\n Please log out and back in (or open a new shell) so group membership becomes active if you run into vault key errors.\n run id and ensure you see k3s-deployer in the groups list."

