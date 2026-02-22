# Vault Agent Setup for K3S

This script automates the setup of HashiCorp Vault Agent for automatic authentication in K3S deployments, eliminating the need to manage Vault tokens manually.

## Overview

The `vault_agent_setup.sh` script configures a complete Vault authentication pipeline using AppRole authentication method. It:

- Validates Vault connectivity
- Creates a K3S-specific policy
- Configures AppRole authentication
- Generates role credentials
- Sets up Vault Agent as a systemd service
- Creates a group for controlled token access
- Automatically generates and maintains authentication tokens

## Prerequisites

Before running this script, ensure:

- **Vault Server**: Vault is installed and running at `http://127.0.0.1:8200` (configurable via `VAULT_ADDR`)
- **Root Access**: Script must be run with `sudo` to create systemd services and manage groups
- **Vault CLI**: The `vault` command-line tool is installed and in your `$PATH`
- **Systemd**: Your system uses systemd for service management
- **Linux**: Script is designed for Linux systems

## Installation

1. Copy the script to your scripts directory:
   ```bash
   cp vault_agent_setup.sh /path/to/k3s/scripts/
   chmod +x /path/to/k3s/scripts/vault_agent_setup.sh
   ```

2. (Optional) Customize the Vault address if needed by editing the script:
   ```bash
   export VAULT_ADDR="http://your-vault-server:8200"
   ```

## Usage

Run the script with sudo:

```bash
sudo ./vault_agent_setup.sh
```

The script will:
1. Check that Vault is reachable
2. Create the `k3s-policy` policy file
3. Enable AppRole authentication
4. Create the `k3s-role` AppRole
5. Generate and store `role_id` and `secret_id`
6. Create the `k3s-deployer` group
7. Install Vault Agent configuration
8. Register and start the `vault-agent-k3s` systemd service
9. Verify token generation

## What Gets Created

### Files

- `/etc/vault.d/k3s-policy.hcl` - Vault policy for K3S access
- `/etc/vault.d/role_id` - AppRole role ID (mode 600)
- `/etc/vault.d/secret_id` - AppRole secret ID (mode 600)
- `/etc/vault.d/agent-k3s.hcl` - Vault Agent configuration (mode 600)
- `/etc/vault.d/agent-token-k3s` - Generated authentication token (mode 640)

### Groups & Permissions

- **k3s-deployer** group is created
- The invoking user (via `$SUDO_USER`) is added to this group
- Token sink is configured with `k3s-deployer` group ownership for shared access

### Systemd Service

- **Service Name**: `vault-agent-k3s`
- **Status**: Enabled for auto-start on boot
- **Configuration**: Runs Vault Agent with auto-auth enabled
- **Restart Policy**: Automatically restarts on failure

## Vault Policy

The script creates a policy that grants K3S processes permission to:

```hcl
path "k3s/*" {
  capabilities = ["create", "update", "read", "list"]
}
```

This allows read/write access to any secrets under the `k3s/*` path in Vault.

## AppRole Configuration

- **Auth Method**: AppRole
- **Token TTL**: 24 hours
- **Token Max TTL**: 72 hours
- **Policies**: `k3s-policy`

The AppRole credentials are stored securely in the filesystem with restricted permissions.

## Vault Agent Configuration

The agent uses the following settings:

- **Exit After Auth**: `false` - Agent continues running to refresh tokens
- **Authentication**: AppRole with stored role_id and secret_id
- **Token Sink**: File-based sink at `/etc/vault.d/agent-token-k3s`
- **Vault Address**: `http://127.0.0.1:8200`

## Accessing the Token

Once setup is complete, your K3S deployment scripts can access the token:

```bash
# Direct token access
export VAULT_TOKEN=$(cat /etc/vault.d/agent-token-k3s)

# Or use it with Vault CLI
vault secrets list -address=http://127.0.0.1:8200 \
  -header-value="X-Vault-Token=$(cat /etc/vault.d/agent-token-k3s)"
```

## Troubleshooting

### Vault Not Reachable

If you get an error that Vault is unreachable:

```
ERROR: Vault is not reachable at http://127.0.0.1:8200
```

**Solutions:**
- Verify Vault is running: `vault status`
- Check the Vault address is correct
- Ensure firewall allows access to port 8200
- Update `VAULT_ADDR` in the script if using a different address

### Token Not Generated

If the token file is not created after setup:

```bash
# Check Vault Agent logs
journalctl -u vault-agent-k3s -f

# Check service status
systemctl status vault-agent-k3s

# Verify Vault Agent process is running
ps aux | grep "vault agent"
```

### Permission Denied Errors

If users in the `k3s-deployer` group cannot access the token:

```bash
# Verify file permissions
ls -la /etc/vault.d/agent-token-k3s

# Verify user is in the group (may require logout/login)
groups $USER

# Add user manually if needed
sudo usermod -aG k3s-deployer <username>
```

### AppRole Already Exists

If the script fails because `k3s-role` already exists:

```bash
# Remove the existing role
vault delete auth/approle/role/k3s-role

# Rerun the script
sudo ./vault_agent_setup.sh
```

## Security Considerations

⚠️ **Important Security Notes:**

1. **role_id and secret_id**: These files are stored with mode `600` (root-only readable). Protect these carefully.
2. **Token Rotation**: The Vault Agent automatically refreshes tokens before expiration.
3. **AppRole Access**: Only authenticated users should have access to this system.
4. **Network**: Use TLS in production (`https://` instead of `http://`)
5. **Audit Logging**: Enable Vault audit logging to track all authentication events

## Integration with K3S Deployment Scripts

To use this in your K3S deployment:

```bash
#!/bin/bash

# Source the token from Vault Agent
export VAULT_TOKEN=$(cat /etc/vault.d/agent-token-k3s)
export VAULT_ADDR="http://127.0.0.1:8200"

# Now you can authenticate to Vault without manual token management
vault kv get k3s/some-secret
```

## Cleanup

To remove Vault Agent setup:

```bash
# Stop and disable the service
sudo systemctl stop vault-agent-k3s
sudo systemctl disable vault-agent-k3s

# Remove service file
sudo rm /etc/systemd/system/vault-agent-k3s.service
sudo systemctl daemon-reload

# Remove configuration files (optional)
sudo rm -rf /etc/vault.d/

# Remove group (optional)
sudo groupdel k3s-deployer
```

## Support

For issues or questions:

1. Check the troubleshooting section above
2. Review Vault Agent logs: `journalctl -u vault-agent-k3s -f`
3. Consult [HashiCorp Vault documentation](https://www.vaultproject.io/docs)
