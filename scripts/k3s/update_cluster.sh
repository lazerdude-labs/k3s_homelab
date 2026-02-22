#!/bin/bash
set -o errexit # script exits immediately on first error
set -o pipefail # script exits if any command in a pipeline fails

cd ansible 

ansible-playbook playbooks/upgrade.yml