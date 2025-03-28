FROM ghcr.io/berriai/litellm:main-stable

# Copy the config file
COPY config/litellm_config.yaml /app/config.yaml

# Expose the port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:4000/health/liveliness || exit 1

# Run the LiteLLM proxy server
CMD ["--config", "/app/config.yaml", "--port", "4000", "--host", "0.0.0.0"]
