#!/bin/bash

#Handles Apt or Yum based Vault installation, initialization, and unsealing. Also creates the necessary configuration file for our deployment.
if command -v apt >/dev/null 2>&1; then
    echo "APT available (Debian/Ubuntu)"
    wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt install vault
    wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt install terraform
    sudo apt install ansible
elif command -v yum >/dev/null 2>&1; then
    echo "YUM available (older RHEL/CentOS)"
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
    sudo yum -y install vault
    sudo dnf install -y epel-release
    sudo dnf install -y ansible
    sudo dnf install -y terraform
else
    echo "No known package manager found"
fi



sudo systemctl enable --now vault 
# Create Vault configuration file (made http)

sudo bash -c "cat >/etc/vault.d/vault.hcl <<'EOF'
# Copyright IBM Corp. 2016, 2025
# SPDX-License-Identifier: BUSL-1.1

# Full configuration options can be found at https://developer.hashicorp.com/vault/docs/configuration

ui = true

#mlock = true
#disable_mlock = true

storage \"file\" {
  path = \"/opt/vault/data\"
}

#storage \"consul\" {
#  address = \"127.0.0.1:8500\"
#  path    = \"vault\"
#}

# HTTP listener
listener \"tcp\" {
  address = \"127.0.0.1:8200\"
  tls_disable = 1
}

# HTTPS listener
#listener \"tcp\" {
#  address       = \"127.0.0.1:8200\"
#  tls_cert_file = \"/opt/vault/tls/tls.crt\"
#  tls_key_file  = \"/opt/vault/tls/tls.key\"
#}

# Enterprise license_path
# This will be required for enterprise as of v1.8
#license_path = \"/etc/vault.d/vault.hclic\"

# Example AWS KMS auto unseal
#seal \"awskms\" {
#  region = \"us-east-1\"
#  kms_key_id = \"REPLACE-ME\"
#}

# Example HSM auto unseal
#seal \"pkcs11\" {
#  lib            = \"/usr/vault/lib/libCryptoki2_64.so\"
#  slot           = \"0\"
#  pin            = \"AAAA-BBBB-CCCC-DDDD\"
#  key_label      = \"vault-hsm-key\"
#  hmac_key_label = \"vault-hsm-hmac-key\"
#}
EOF"


sudo systemctl restart vault


export VAULT_ADDR="http://127.0.0.1:8200"

# 1. Initialize Vault and capture JSON output
INIT_OUTPUT=$(vault operator init -format=json)

# 2. Extract unseal keys and root token
UNSEAL_KEY_1=$(echo "$INIT_OUTPUT" | jq -r '.unseal_keys_b64[0]')
UNSEAL_KEY_2=$(echo "$INIT_OUTPUT" | jq -r '.unseal_keys_b64[1]')
UNSEAL_KEY_3=$(echo "$INIT_OUTPUT" | jq -r '.unseal_keys_b64[2]')
ROOT_TOKEN=$(echo "$INIT_OUTPUT" | jq -r '.root_token')

# 3. Save root token somewhere safe for your installer
echo "$ROOT_TOKEN" | sudo tee /etc/vault.d/root_token >/dev/null
sudo chmod 600 /etc/vault.d/root_token

# 4. Unseal Vault automatically
sudo VAULT_ADDR="http://127.0.0.1:8200" vault operator unseal "$UNSEAL_KEY_1"
sudo VAULT_ADDR="http://127.0.0.1:8200" vault operator unseal "$UNSEAL_KEY_2"
sudo VAULT_ADDR="http://127.0.0.1:8200" vault operator unseal "$UNSEAL_KEY_3"


echo "Vault initialized and unsealed."
