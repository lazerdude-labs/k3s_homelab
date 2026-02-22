# K3S HomeLab Installation Guide


## Introduction
Purpose of this guide is to ensure the successful execution of this project! Since I am but a simple sheep, I mean human being, I am still learning alot and might have made an error. This guide will walk you through step by step to ensure you can get this up and running yourself!

The whole installation will ultimately download terraform, ansible, & vault and set up vault to secure your secrets so that after entering it into the whiptail gui they are secure in the vault. The whole installation might take up to 30 minutes and that is due to to the download of k3s binary. I have DSL though so hopefully yours is quicker than my slow internet.

Right now it supports RHEL and Debian/Ubuntu (should?). But if you run into Debian/Ubuntu errors please let me know.


## Prerequisites
Hardware requirements: (All hardware requirements can beadjusted in terraform/main.tf and adjusted there for the time being)
    Ram: 16 GB RAM (total)
    Disk: 360 GB (total)    
    Cores: 6 (total)
    Sockets 6 (total)

* **Notes** - If you have a different name for you datastore_id (mine is local-lvm) please change it in the main.tf. Please have uploaded your Rocky or Ubuntu (I'd ask you use rocky for first time but alas) into your proxmox. You will provide the location in the initialize cluster portion of setup.

The network vlan, ip addresses, dns, gateway for all devices you will set when you initialize the cluster after vault has been initialized.

## Repository Setup

This repository first needs to be cloned and brought down to your local host for execution.

'''
git clone <your-gitlab-url>
cd <repo>
'''
Repository Structure Overview:
'''
/scripts/ # This is where all the scripts will be pulled from. You do not need anything from this folder
/terraform/ # Where all the terraform infrustructure code is
/ansible/ # Where the deployment for the infrustructure is
'''
## Being Installation

Inside of the repository run
'''
./k3s_deployment.sh
'''

When you run this it will check to see if you have a vault initialized. I have not accounted for if you already have one for other use cases. So for the is setup I'd say use a system that hasn't used vault. If you had vault but dont care about it feel free to run the ./scripts/reset_vault.sh script to reset your vault for a clean slate.

From here it will begin its entire installation of all the needed dependencies. Once done it will load up the main screen with the sheep! Baaaaahhhhhh.

The next step is to go down in the deployment gui to initialize cluster. This initializes your vault variables. When doing the variables I will provide a list of what my inputs were so you don't mess up syntax because it will save whatever you put into it. If you do happen to do it wrong or question yourself (I have done it many times) go ahead and just exit and rerun it.

Sample Inputs:
'''
    proxmox_username = root (if you do something other than root make sure permissions are good on that user)
    proxmox_password = SuperSecurePassword123
    proxmox_endpoint = https://192.168.1.5:8006/
    proxmox_api_token_id = terraform@pam!terraform=ca.....
    proxmox_node_name = rplab
    iso_file_name = local:iso/Rocky9Cloud.img
    bridge_name = vmbr1
    vlan_id_proxmox = 30
    ip_address_master = 10.10.30.31/24
    ip_address_worker1 = 10.10.30.32/24
    ip_address_worker2 = 10.10.30.33/24
    gateway_ip = 10.10.30.1
    local_dns = 10.10.20.5
    ssh_public_key = (copied and pasted my literal public key into this)
    fqdn = rplab.lan
'''

## Deploying the Cluster

Once complete go ahead and click on Deploy K3S Cluster. The system will:
* Provision infrastructure via Terraform
* Deploy Services via Ansible
* Secure secrets via Vault
* Launch your k3s cluster

