#!/bin/bash

# Remove Terraform configuration files
find . -type f \( -name "*.tf" -o -name "*.tfstate" -o -name "*.tfvars" \) -exec rm -f {} +

# Remove Terraform-related directories
find . -type d -name ".terraform" -exec rm -rf {} +

# Remove Terraform lock files
find . -type f -name ".terraform.lock.hcl" -exec rm -f {} +

echo "Terraform dependencies removed."
