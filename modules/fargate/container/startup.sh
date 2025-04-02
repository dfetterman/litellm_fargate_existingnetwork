#!/bin/bash
set -e

# Copy the local config file
cp /app/config/litellm_config.yaml /app/config/litellm_config_final.yaml

# Use the master key directly from the environment variable
# The task definition is already configured to fetch it from Secrets Manager
MASTER_KEY=${LITELLM_MASTER_KEY}

# Install additional dependencies for health check
pip install --no-cache-dir fastapi uvicorn psycopg2-binary

# Start health check service in background
python /app/health_check.py &

# Start LiteLLM with the local config
exec litellm --config /app/config/litellm_config_final.yaml --port ${PORT:-4000} --host 0.0.0.0
