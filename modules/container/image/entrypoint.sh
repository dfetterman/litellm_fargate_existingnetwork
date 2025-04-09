#!/bin/bash
set -e

# Start LiteLLM with the local config
exec litellm --config /app/config/litellm_config.yaml \
  --port ${PORT:-4000} \
  --host 0.0.0.0
