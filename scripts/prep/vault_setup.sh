#!/bin/bash

set -o errexit
set -o pipefail

setup_vault_main() {

    # Write Vault configuration BEFORE starting the service
    sudo tee /etc/vault.d/vault.hcl >/dev/null <<'EOF'
# Copyright IBM Corp. 2016, 2025
# SPDX-License-Identifier: BUSL-1.1

# Full configuration options can be found at https://developer.hashicorp.com/vault/docs/configuration

ui = true

#mlock = true
#disable_mlock = true

storage "file" {
  path = "/opt/vault/data"
}

#storage "consul" {
#  address = "127.0.0.1:8500"
#  path    = "vault"
#}

# HTTP listener
listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = 1
}

# HTTPS listener
#listener "tcp" {
#  address       = "127.0.0.1:8200"
#  tls_cert_file = "/opt/vault/tls/tls.crt"
#  tls_key_file  = "/opt/vault/tls/tls.key"
#}

# Enterprise license_path
#license_path = "/etc/vault.d/vault.hclic"

# Example AWS KMS auto unseal
#seal "awskms" {
#  region     = "us-east-1"
#  kms_key_id = "REPLACE-ME"
#}

# Example HSM auto unseal
#seal "pkcs11" {
#  lib            = "/usr/vault/lib/libCryptoki2_64.so"
#  slot           = "0"
#  pin            = "AAAA-BBBB-CCCC-DDDD"
#  key_label      = "vault-hsm-key"
#  hmac_key_label = "vault-hsm-hmac-key"
#}
EOF

    # Now start Vault
    sudo systemctl enable --now vault
    sudo systemctl restart vault

    export VAULT_ADDR="http://127.0.0.1:8200"

    # Initialize Vault
    INIT_OUTPUT=$(vault operator init -format=json)

    UNSEAL_KEY_1=$(echo "$INIT_OUTPUT" | jq -r '.unseal_keys_b64[0]')
    UNSEAL_KEY_2=$(echo "$INIT_OUTPUT" | jq -r '.unseal_keys_b64[1]')
    UNSEAL_KEY_3=$(echo "$INIT_OUTPUT" | jq -r '.unseal_keys_b64[2]')
    ROOT_TOKEN=$(echo "$INIT_OUTPUT" | jq -r '.root_token')

    echo "$ROOT_TOKEN" | sudo tee /etc/vault.d/root_token >/dev/null
    sudo chmod 600 /etc/vault.d/root_token

    sudo VAULT_ADDR="http://127.0.0.1:8200" vault operator unseal "$UNSEAL_KEY_1"
    sudo VAULT_ADDR="http://127.0.0.1:8200" vault operator unseal "$UNSEAL_KEY_2"
    sudo VAULT_ADDR="http://127.0.0.1:8200" vault operator unseal "$UNSEAL_KEY_3"

    echo "Vault initialized and unsealed."
}

setup_vault_main "$@"
