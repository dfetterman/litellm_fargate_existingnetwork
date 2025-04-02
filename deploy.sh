#!/bin/bash

# Exit on error
set -e

echo "Deploying LiteLLM infrastructure..."

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Plan the deployment
echo "Planning the deployment..."
terraform plan

# Apply the changes
echo "Applying the changes..."
terraform apply --auto-approve

echo "Deployment complete."
