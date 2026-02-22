#!/bin/bash
set -euo pipefail

echo "=== Resetting Vault to a clean state ==="

# 1. Stop Vault
echo "[1/5] Stopping Vault service..."
sudo systemctl stop vault || true
sudo yum remove vault -y
# 2. Remove Vault data (Shamir keys, root token, all secrets)
echo "[2/5] Removing Vault data directory..."
sudo rm -rf /opt/vault/data

# 3. Remove Vault configuration (policies, agent configs, root_token, etc.)
echo "[3/5] Removing Vault config directory..."
sudo rm -rf /etc/vault.d/*

# 4. Recreate empty directories with correct ownership
echo "[4/5] Recreating directories..."
sudo mkdir -p /opt/vault/data
sudo chown vault:vault /opt/vault/data

sudo mkdir -p /etc/vault.d
sudo chown root:root /etc/vault.d
sudo gpasswd -d $(whoami) k3s-deployer
sudo groupdel k3s-deployer
