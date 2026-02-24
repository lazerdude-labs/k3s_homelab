#!/bin/bash


set -e # script exits immediately on first error
#First we need to navigate to the terraform directory
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="$(cat /etc/vault.d/agent-token-k3s)"
cd terraform
terraform init
terraform destroy -auto-approve