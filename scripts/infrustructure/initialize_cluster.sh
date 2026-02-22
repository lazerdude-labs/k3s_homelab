#!/bin/bash
set -o errexit
set -o pipefail

initialize_cluster_main() {
    export VAULT_ADDR="http://127.0.0.1:8200"

    if ! VAULT_TOKEN=$(cat /etc/vault.d/agent-token-k3s 2>/dev/null); then
        whiptail --msgbox "ERROR: Cannot read Vault token.\n\nEnsure /etc/vault.d/agent-token-k3s exists and you're in the k3s-deployer group:\n  groups \$USER\n\nIf not listed, run:\n  sudo usermod -aG k3s-deployer \$USER\n  newgrp k3s-deployer" 12 70
        exit 1
    fi
    export VAULT_TOKEN

    if vault kv get -format=json k3s/initialize_backup >/dev/null 2>&1; then
        prev_proxmox_username=$(vault kv get -field=proxmox_username k3s/initialize_backup 2>/dev/null || echo "")
        prev_proxmox_api_token_id=$(vault kv get -field=proxmox_api_token_id k3s/initialize_backup 2>/dev/null || echo "")
        prev_proxmox_endpoint=$(vault kv get -field=proxmox_endpoint k3s/initialize_backup 2>/dev/null || echo "")
        prev_ssh_key_content=$(vault kv get -field=ssh_key_content k3s/initialize_backup 2>/dev/null || echo "")
        prev_iso_file_name=$(vault kv get -field=iso_file_name k3s/initialize_backup 2>/dev/null || echo "")
        prev_proxmox_node_name=$(vault kv get -field=proxmox_node_name k3s/initialize_backup 2>/dev/null || echo "")
        prev_bridge_name=$(vault kv get -field=bridge_name k3s/initialize_backup 2>/dev/null || echo "")
        prev_fqdn=$(vault kv get -field=fqdn k3s/initialize_backup 2>/dev/null || echo "")
        prev_vlan_id=$(vault kv get -field=vlan_id k3s/initialize_backup 2>/dev/null || echo "")
        prev_ip_master=$(vault kv get -field=ip_master k3s/initialize_backup 2>/dev/null || echo "")
        prev_ip_worker1=$(vault kv get -field=ip_worker1 k3s/initialize_backup 2>/dev/null || echo "")
        prev_ip_worker2=$(vault kv get -field=ip_worker2 k3s/initialize_backup 2>/dev/null || echo "")
        prev_gateway_ip=$(vault kv get -field=gateway_ip k3s/initialize_backup 2>/dev/null || echo "")
        prev_local_dns=$(vault kv get -field=local_dns k3s/initialize_backup 2>/dev/null || echo "")
    fi

    proxmox_username=$(whiptail --inputbox "Proxmox Username:" 8 50 "${prev_proxmox_username:-}" 3>&1 1>&2 2>&3) || exit 1
    proxmox_password=$(whiptail --passwordbox "Proxmox Password:" 8 50 3>&1 1>&2 2>&3) || exit 1
    proxmox_api_token_id=$(whiptail --inputbox "Proxmox API Token ID:" 8 50 "${prev_proxmox_api_token_id:-}" 3>&1 1>&2 2>&3) || exit 1
    proxmox_endpoint=$(whiptail --inputbox "Proxmox Endpoint (IP):" 8 50 "${prev_proxmox_endpoint:-}" 3>&1 1>&2 2>&3) || exit 1
    ssh_key_content=$(whiptail --inputbox "SSH Public Key (paste content):" 10 70 "${prev_ssh_key_content:-}" 3>&1 1>&2 2>&3) || exit 1
    iso_file_name=$(whiptail --inputbox "ISO File Name: Ex. local:iso/Rocky9Cloud.img" 8 50 "${prev_iso_file_name:-}" 3>&1 1>&2 2>&3) || exit 1
    proxmox_node_name=$(whiptail --inputbox "Proxmox Node Name:" 8 50 "${prev_proxmox_node_name:-}" 3>&1 1>&2 2>&3) || exit 1
    bridge_name=$(whiptail --inputbox "Proxmox Bridge Name:" 8 50 "${prev_bridge_name:-vmbr0}" 3>&1 1>&2 2>&3) || exit 1
    fqdn=$(whiptail --inputbox "FQDN: Ex. rplab.lan" 8 50 "${prev_fqdn:-}" 3>&1 1>&2 2>&3) || exit 1
    vlan_id=$(whiptail --inputbox "Proxmox VLAN ID:" 8 50 "${prev_vlan_id:-0}" 3>&1 1>&2 2>&3) || exit 1
    ip_master=$(whiptail --inputbox "IP Master: X.X.X.X/24" 8 50 "${prev_ip_master:-}" 3>&1 1>&2 2>&3) || exit 1
    ip_worker1=$(whiptail --inputbox "IP Worker1: X.X.X.X/24" 8 50 "${prev_ip_worker1:-}" 3>&1 1>&2 2>&3) || exit 1
    ip_worker2=$(whiptail --inputbox "IP Worker2: X.X.X.X/24" 8 50 "${prev_ip_worker2:-}" 3>&1 1>&2 2>&3) || exit 1
    gateway_ip=$(whiptail --inputbox "Gateway IP:" 8 50 "${prev_gateway_ip:-}" 3>&1 1>&2 2>&3) || exit 1
    local_dns=$(whiptail --inputbox "Local DNS:" 8 50 "${prev_local_dns:-}" 3>&1 1>&2 2>&3) || exit 1

    for field in "$proxmox_username" "$proxmox_password" "$proxmox_api_token_id" "$proxmox_endpoint" "$ssh_key_content" "$iso_file_name" "$proxmox_node_name" "$bridge_name" "$fqdn" "$vlan_id" "$ip_master" "$ip_worker1" "$ip_worker2" "$gateway_ip" "$local_dns"; do
        if [[ -z "$field" ]]; then
            whiptail --msgbox "All fields are required. Please try again." 10 60
            exit 1
        fi
    done

    vault kv put k3s/initialize_backup \
        proxmox_username="$proxmox_username" \
        proxmox_api_token_id="$proxmox_api_token_id" \
        proxmox_endpoint="$proxmox_endpoint" \
        ssh_key_content="$ssh_key_content" \
        iso_file_name="$iso_file_name" \
        proxmox_node_name="$proxmox_node_name" \
        bridge_name="$bridge_name" \
        fqdn="$fqdn" \
        vlan_id="$vlan_id" \
        ip_master="$ip_master" \
        ip_worker1="$ip_worker1" \
        ip_worker2="$ip_worker2" \
        gateway_ip="$gateway_ip" \
        local_dns="$local_dns" >/dev/null

    vault kv put k3s/proxmox \
        username="$proxmox_username" \
        password="$proxmox_password" \
        endpoint="$proxmox_endpoint" \
        api_token_id="$proxmox_api_token_id" \
        node="$proxmox_node_name" \
        iso_file_name="$iso_file_name"

    vault kv put k3s/network \
        bridge_name="$bridge_name" \
        vlan_id="$vlan_id" \
        ip_address_master="$ip_master" \
        ip_address_worker1="$ip_worker1" \
        ip_address_worker2="$ip_worker2" \
        gateway_ip="$gateway_ip" \
        local_dns="$local_dns" \
        fqdn="$fqdn"

    vault kv put k3s/ssh \
        public_key="$ssh_key_content"

    whiptail --msgbox "Configuration saved securely to Vault." 10 60
    return 0
}

initialize_cluster_main "$@"
