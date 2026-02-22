    #!/bin/bash

    export VAULT_ADDR="http://127.0.0.1:8200"
    export VAULT_TOKEN="$(cat /etc/vault.d/agent-token-k3s)"

    if [[ -s /etc/vault.d/agent-token-k3s ]]; then
        return 0 # initialized
    else
        echo "[ERROR] Token file /etc/vault.d/agent-token-k3s is missing or empty"
        return 1 # not initialized
    fi
