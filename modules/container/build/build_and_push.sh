#!/bin/bash

set -e

# Enable command logging
set -x

# Check if required environment variables are set
if [ -z "$AWS_REGION" ] || [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$REPOSITORY_NAME" ] || [ -z "$ECR_REPOSITORY_URL" ]; then
  echo "Error: Required environment variables are not set."
  echo "Required variables: AWS_REGION, AWS_ACCOUNT_ID, REPOSITORY_NAME, ECR_REPOSITORY_URL"
  exit 1
fi

echo "Starting build process..."

# Clean up any existing Docker processes
echo "Cleaning up existing Docker processes..."
if pgrep dockerd > /dev/null; then
  echo "Stopping existing Docker daemon..."
  sudo pkill -9 dockerd || true
  sudo pkill -9 docker || true
  sleep 5
fi

# Clean up Docker storage
echo "Cleaning up Docker storage..."
docker system prune -a -f || true
docker volume prune -f || true

# Create directory for Docker data
echo "Setting up Docker data directory..."
sudo rm -rf /tmp/docker || true
sudo mkdir -p /tmp/docker

# Start Docker daemon with custom data directory
echo "Starting Docker daemon..."
sudo dockerd --data-root=/tmp/docker > /tmp/docker.log 2>&1 &
DOCKER_PID=$!

# Wait for Docker to start
echo "Waiting for Docker to be ready..."
for i in {1..30}; do
  if docker info >/dev/null 2>&1; then
    echo "Docker is ready"
    break
  fi
  if ! ps -p $DOCKER_PID > /dev/null; then
    echo "Docker daemon failed to start. Logs:"
    cat /tmp/docker.log
    exit 1
  fi
  echo "Waiting for Docker to start... ($i/30)"
  sleep 2
done

if ! docker info >/dev/null 2>&1; then
  echo "Docker failed to start after 60 seconds. Logs:"
  cat /tmp/docker.log
  exit 1
fi

# Create a temporary build directory
echo "Setting up build directory..."
TEMP_BUILD_DIR="/tmp/litellm-build"
rm -rf $TEMP_BUILD_DIR || true
mkdir -p $TEMP_BUILD_DIR

# Copy all necessary files to the temporary directory
echo "Copying build files..."
cp -r $(dirname "$0")/../image/* $TEMP_BUILD_DIR/

# Navigate to the temporary build directory
cd $TEMP_BUILD_DIR

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Create the repository if it doesn't exist
echo "Ensuring ECR repository exists..."
aws ecr describe-repositories --repository-names $REPOSITORY_NAME --region $AWS_REGION || aws ecr create-repository --repository-name $REPOSITORY_NAME --region $AWS_REGION

# Build and push the Docker image
echo "Building Docker image..."
docker build -t $ECR_REPOSITORY_URL:latest .

echo "Pushing Docker image..."
docker push $ECR_REPOSITORY_URL:latest

# Clean up
echo "Cleaning up..."
cd - > /dev/null
rm -rf $TEMP_BUILD_DIR || true
docker system prune -a -f || true
docker volume prune -f || true

# Stop Docker daemon
echo "Stopping Docker daemon..."
if ps -p $DOCKER_PID > /dev/null; then
  sudo kill $DOCKER_PID
  sleep 5
  sudo pkill -9 dockerd || true
fi

echo "Build and push completed successfully!"
