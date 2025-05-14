#!/bin/bash

set -e

# Check if required environment variables are set
if [ -z "$AWS_REGION" ] || [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$REPOSITORY_NAME" ] || [ -z "$ECR_IMAGE" ]; then
  echo "Error: Required environment variables are not set."
  echo "Required variables: AWS_REGION, AWS_ACCOUNT_ID, REPOSITORY_NAME, ECR_IMAGE"
  exit 1
fi

# Create a temporary build directory with more space
BUILD_DIR="/tmp/litellm-build"
mkdir -p $BUILD_DIR
cp -r * $BUILD_DIR/
cd $BUILD_DIR

# Login to ECR 
echo "Logging in to ECR..."
aws --region ${AWS_REGION} ecr get-login-password | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build and push image for amd64 architecture (Fargate uses x86_64/amd64)
echo "Building Docker image for amd64 architecture..."
# Use --platform to ensure we build for linux/amd64 even when building on Mac with Apple Silicon
docker buildx build --platform linux/amd64 -t "${ECR_IMAGE}" -f Dockerfile . ${BUILD_ARGS} --load
docker push "${ECR_IMAGE}"

echo "Image successfully built and pushed to ECR"

# Clean up
cd -
rm -rf $BUILD_DIR
