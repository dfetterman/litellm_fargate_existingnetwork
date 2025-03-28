#!/bin/bash

# Exit on error
set -e

function check_prerequisites() {
  # Check if terraform is installed
  if ! command -v terraform &> /dev/null; then
      echo "Terraform is not installed. Please install Terraform and try again."
      exit 1
  fi

  # Check if AWS CLI is installed
  if ! command -v aws &> /dev/null; then
      echo "AWS CLI is not installed. Please install AWS CLI and try again."
      exit 1
  fi

  # Check if AWS credentials are configured
  if ! aws sts get-caller-identity &> /dev/null; then
      echo "AWS credentials are not configured. Please configure AWS CLI and try again."
      exit 1
  fi
}

function deploy() {
  echo "Deploying LiteLLM infrastructure..."
  
  # Check if terraform.tfvars exists
  if [ ! -f terraform.tfvars ]; then
      echo "terraform.tfvars file not found. Creating from example..."
      cp terraform.tfvars.example terraform.tfvars
      echo "Please edit terraform.tfvars with your configuration and run this script again."
      exit 0
  fi

  # Initialize Terraform
  echo "Initializing Terraform..."
  terraform init

  # Plan the deployment
  echo "Planning the deployment..."
  terraform plan -out=tfplan

  # Ask for confirmation
  read -p "Do you want to apply the changes? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Deployment cancelled."
      exit 0
  fi

  # Apply the changes
  echo "Applying the changes..."
  terraform apply tfplan

  # Show the outputs
  echo "Deployment complete. Here are the outputs:"
  terraform output

  echo "LiteLLM proxy is now deployed."
  echo "You can access it at: $(terraform output -raw litellm_endpoint)"
}

function destroy() {
  echo "WARNING: This will destroy all resources created by this Terraform project."
  read -p "Are you sure you want to destroy all resources? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Destroy cancelled."
      exit 0
  fi

  # Destroy the resources
  echo "Destroying resources..."
  terraform destroy -auto-approve

  echo "All resources have been destroyed."
}

function update() {
  echo "Updating LiteLLM infrastructure..."
  
  # Get the current state
  echo "Getting current state..."
  terraform refresh
  
  # Plan the update
  echo "Planning the update..."
  terraform plan -out=tfplan
  
  # Ask for confirmation
  read -p "Do you want to apply the changes? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Update cancelled."
      exit 0
  fi
  
  # Apply the changes
  echo "Applying the changes..."
  terraform apply tfplan
  
  echo "Update complete."
}

# Main script
check_prerequisites

if [ $# -eq 0 ]; then
  echo "Usage: $0 [deploy|destroy|update]"
  exit 1
fi

case "$1" in
  deploy)
    deploy
    ;;
  destroy)
    destroy
    ;;
  update)
    update
    ;;
  *)
    echo "Unknown command: $1"
    echo "Usage: $0 [deploy|destroy|update]"
    exit 1
    ;;
esac
