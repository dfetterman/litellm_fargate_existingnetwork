# FROM ghcr.io/berriai/litellm:litellm_stable_release_branch-v1.65.0-stable
FROM ghcr.io/berriai/litellm:litellm_stable_release_branch-v1.69.0-stable

# Install curl for health checks
RUN apk add --no-cache curl

# Enable detailed debugging
ENV LITELLM_LOG=DEBUG
ENV PRISMA_LOG_QUERIES=true
ENV PRISMA_LOG_LEVEL=debug
ENV DEBUG=true

# Expose the port
EXPOSE 4000

# Copy the litellm config
RUN mkdir -p /app/config
COPY ./litellm_config_load_balance.yaml /app/config/litellm_config.yaml

# Create AWS CLI config directory (but don't try to copy non-existent files)
RUN mkdir -p /root/.aws

# Create a startup script
COPY ./entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Set the entrypoint to our startup script
ENTRYPOINT ["/app/entrypoint.sh"]