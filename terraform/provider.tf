terraform {
  required_providers { 
    proxmox = { # Pulls in proxmox bgp provider
      source = "bpg/proxmox"
      version = "0.90.0"
    }
    vault = {
      source = "hashicorp/vault"
      version = "~> 4.0"
    }
  }

}



provider "proxmox" {

  endpoint  = local.proxmox_config.endpoint
  api_token = local.proxmox_config.api_token_id
  insecure = true

  ssh {
    agent = true
    username = local.proxmox_config.username
    password = local.proxmox_config.password
  }

}

provider "vault" {
  address = "http://127.0.0.1:8200"
  skip_child_token = true
  token = null # Will be set via environment variable from vault agent token file
}


