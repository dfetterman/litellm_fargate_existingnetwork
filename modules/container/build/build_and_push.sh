#!/bin/bash

set -e

# Check if required environment variables are set
if [ -z "$AWS_REGION" ] || [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$ECR_REPOSITORY" ]; then
  echo "Error: AWS_REGION, AWS_ACCOUNT_ID, and ECR_REPOSITORY must be set"
  exit 1
fi

# Clean up Docker storage
docker system prune -a -f
docker volume prune -f

# Stop Docker daemon if running
if pgrep dockerd > /dev/null; then
  echo "Stopping Docker daemon..."
  sudo pkill dockerd
  sleep 3
fi

# Create directory for Docker data
sudo mkdir -p /tmp/docker

# Start Docker daemon with custom data directory
echo "Starting Docker daemon with data-root in /tmp..."
sudo dockerd --data-root=/tmp/docker &
sleep 5  # Wait for Docker to start

# Create a temporary build directory
TEMP_BUILD_DIR="/tmp/litellm-build"
mkdir -p $TEMP_BUILD_DIR

# Copy all necessary files to the temporary directory
cp -r $(dirname "$0")/../image/* $TEMP_BUILD_DIR/

# Navigate to the temporary build directory
cd $TEMP_BUILD_DIR

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Create the repository if it doesn't exist
aws ecr describe-repositories --repository-names $ECR_REPOSITORY --region $AWS_REGION || aws ecr create-repository --repository-name $ECR_REPOSITORY --region $AWS_REGION

# Build the Docker image
docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest .

# Push the Docker image to ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:latest

# Clean up the temporary directory
cd - > /dev/null
rm -rf $TEMP_BUILD_DIR

# Clean up Docker storage again
docker system prune -a -f
docker volume prune -f

# Stop custom Docker daemon
echo "Stopping Docker daemon..."
sudo pkill dockerd

echo "Build and push completed successfully!"
