FROM ghcr.io/berriai/litellm:litellm_stable_release_branch-v1.65.0-stable

# Install jq and curl for secret parsing and health checks
RUN apk add --no-cache curl

# Pre-install AWS CLI and other dependencies
# RUN pip install --no-cache-dir awscli

# Set environment variables
# ENV LITELLM_LOG=DEBUG

# Expose the port
EXPOSE 4000

# Copy the litellm config
RUN mkdir -p /app/config
COPY ./litellm_config.yaml /app/config/

# Copy the AWS CLI config
RUN mkdir -p /root/.aws
COPY ./config /root/.aws

# Create a startup script
COPY ./entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Set the entrypoint to our startup script
ENTRYPOINT ["/app/entrypoint.sh"]