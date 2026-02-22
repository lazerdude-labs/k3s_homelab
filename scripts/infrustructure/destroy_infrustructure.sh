#!/bin/bash


set -e # script exits immediately on first error
#First we need to navigate to the terraform directory
cd terraform
terraform init
terraform destroy -auto-approve