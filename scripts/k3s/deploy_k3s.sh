#!/bin/bash

set -o errexit # script exits immediately on first error
set -o pipefail # script exits if any command in a pipeline fails

deploy_k3s_main() {
    whiptail --msgbox "Deploying K3S With Ansible..." 10 50
    cd ansible

    if ! ansible-playbook -i inventory.ini playbooks/setup.yml; then
        whiptail --msgbox "Ansible reported an error. Check logs." 10 60
    fi
    
    return 0
}

deploy_k3s_main "$@"