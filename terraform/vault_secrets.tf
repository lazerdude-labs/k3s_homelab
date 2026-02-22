###################################
# Fetch secrets from Vault
###################################

# Fetch Proxmox configuration from Vault
data "vault_kv_secret_v2" "proxmox" {
  mount = "k3s"
  name  = "proxmox"
}

data "vault_kv_secret_v2" "network" {
  mount = "k3s"
  name  = "network"
}

data "vault_kv_secret_v2" "ssh" {
  mount = "k3s"
  name  = "ssh"
}


# Create locals that pull from Vault data sources
locals {
  proxmox_data = tomap(data.vault_kv_secret_v2.proxmox.data)
  network_data = tomap(data.vault_kv_secret_v2.network.data)
  ssh_data     = tomap(data.vault_kv_secret_v2.ssh.data)

  proxmox_config = {
    username      = local.proxmox_data["username"]
    password      = local.proxmox_data["password"]
    endpoint      = local.proxmox_data["endpoint"]
    api_token_id  = local.proxmox_data["api_token_id"]
    node          = local.proxmox_data["node"]
    iso_file_name = local.proxmox_data["iso_file_name"]
  }

  network_config = {
    bridge_name        = local.network_data["bridge_name"]
    vlan_id            = tonumber(local.network_data["vlan_id"])
    ip_address_master  = local.network_data["ip_address_master"]
    ip_address_worker1 = local.network_data["ip_address_worker1"]
    ip_address_worker2 = local.network_data["ip_address_worker2"]
    gateway_ip         = local.network_data["gateway_ip"]
    local_dns          = split(",", local.network_data["local_dns"])
    fqdn               = local.network_data["fqdn"]
  }

  ssh_config = {
    public_key = local.ssh_data["public_key"]
  }
}




