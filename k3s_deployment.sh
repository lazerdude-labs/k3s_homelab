#!/bin/bash

set -o errexit # script exits immediately on first error
set -o pipefail # script exits if any command in a pipeline fails
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # Makes script work regardless of current working directory

function main () {


    # FIRST RUN CHECK
    if ! dependencies_present; then
    whiptail --title "Missing Dependencies" --msgbox \
     "\n\nWe will now run the install dependencies." \
        12 60

        install_dependencies
    fi

    if ! vault_is_initialized; then
    whiptail --title "First-Time Setup" --msgbox \
     "Vault is not initialized yet.\n\nWe will now run the initial setup process." \
        12 60

        first_run_setup
        
    fi
    welcome
    
    options
}

function dependencies_present() {
    "$SCRIPT_DIR/scripts/prep/dependencies_present.sh"
}
function install_dependencies() {
    "$SCRIPT_DIR/scripts/prep/install_dependencies.sh"

}


function first_run_setup() {
    whiptail --msgbox "It looks like this is your first time running the K3S Deployment Script. Let's set up the necessary Vault policies and AppRole for secure credential management." 15 60
    $SCRIPT_DIR/scripts/prep/vault_setup.sh
    sudo $SCRIPT_DIR/scripts/prep/vault_agent_setup.sh
    whiptail --msgbox "Initial setup complete!" 10 50
}

function welcome() {
    whiptail --msgbox "$(cat <<'EOF'
Welcome to the Simple K3S Automatic Deployment Script! This script will guide you through the process of deploying a K3S cluster on your infrastructure. Please follow the prompts to set up your cluster.

      .-""""-. 
    /(  (oo)  )\   < baa… guarding the cluster
   /  \  __  /  \
   \__/'----'\__/
EOF
)" 15 60
}


function options() {
    OPTION=$(whiptail --title "K3S Deployment Options" --menu "Choose an option:

          .-\"\"\"-. 
        /(  (oo)  )\\   
       /  \\  __  /  \\
       \\__/\`----'\\__/" 20 60 4 \
    "1" "Deploy K3S Cluster" \
    "2" "Update Cluster" \
    "3" "Initialize Cluster" \
    "4" "Destroy Cluster" \
    "5" "Exit" 3>&1 1>&2 2>&3)

    case $OPTION in
        1)
            deploy_cluster || options
            ;;
        2)
            update_cluster || options
            ;;
        3) 
            initialize_cluster || options
            ;;
        4) 
            destroy_cluster || options
            ;;
        5)
            exit 0
            ;;
        *)
            whiptail --msgbox "Invalid option. Please try again." 10 50
            options
            ;;
    esac
}

function update_cluster() {
    whiptail --msgbox "Updating K3S Cluster..." 10 50
    # Call your update script here
    $SCRIPT_DIR/scripts/k3s/update_cluster.sh
}

function destroy_cluster() {
    whiptail --msgbox "Destroying K3S Cluster..." 10 50
    $SCRIPT_DIR/scripts/infrustructure/destroy_infrustructure.sh
    options # Brings you back to main menu after destruction
}

function deploy_cluster() {
    whiptail --msgbox "Deploying K3S Cluster..." 10 50
    $SCRIPT_DIR/scripts/infrustructure/deploy_infrustructure.sh
    $SCRIPT_DIR/scripts/k3s/deploy_k3s.sh
    $SCRIPT_DIR/scripts/k3s/controller_dependencies.sh
    options # Brings you back to main menu after deployment
}

function initialize_cluster() {
    $SCRIPT_DIR/scripts/infrustructure/initialize_cluster.sh
    options # Brings you back to main menu after initialization
}


function vault_is_initialized() {
    $SCRIPT_DIR/scripts/prep/is_vault_initialized.sh

}



main "$@"
