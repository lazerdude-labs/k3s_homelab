vault_kv_mount = "k3s"

vault_secrets = {
    proxmox_username = "k3s/proxmox/username"
    proxmox_password = "k3s/proxmox/password"
    proxmox_endpoint = "k3s/proxmox/endpoint"
    proxmox_api_token_id = "k3s/proxmox/api_token_id"
    proxmox_node_name = "k3s/proxmox/node"
    iso_file_name = "k3s/proxmox/iso_file_name"
    bridge_name = "k3s/network/bridge_name"
    vlan_id_proxmox = "k3s/network/vlan_id"
    ip_address_master = "k3s/network/ip_address_master"
    ip_address_worker1 = "k3s/network/ip_address_worker1"
    ip_address_worker2 = "k3s/network/ip_address_worker2"
    gateway_ip = "k3s/network/gateway_ip"
    local_dns = "k3s/network/local_dns"
    ssh_public_key = "k3s/ssh/public_key"
    fqdn = "k3s/network/fqdn"
}