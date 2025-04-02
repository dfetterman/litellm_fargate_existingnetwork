#!/bin/bash

# Exit on error
set -e

# Check if required environment variables are set
if [ -z "$AWS_REGION" ] || [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$REPOSITORY_NAME" ] || [ -z "$ECR_IMAGE" ]; then
  echo "Error: Required environment variables are not set."
  echo "Required variables: AWS_REGION, AWS_ACCOUNT_ID, REPOSITORY_NAME, ECR_IMAGE"
  exit 1
fi

# Login to ECR 
echo "Logging in to ECR..."
aws --region ${AWS_REGION} ecr get-login-password | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build and push image for amd64 architecture (Fargate uses x86_64/amd64)
echo "Building Docker image for amd64 architecture..."
docker buildx create --use
docker buildx build --platform linux/amd64 -t "${REPOSITORY_NAME}" -f Dockerfile . ${BUILD_ARGS} --load
docker tag "${REPOSITORY_NAME}" "${ECR_IMAGE}"

echo "Pushing image to ECR: ${ECR_IMAGE}"
docker push "${ECR_IMAGE}"

echo "Image successfully pushed to ECR"
