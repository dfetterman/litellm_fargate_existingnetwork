FROM ghcr.io/berriai/litellm:main-stable

# Pre-install AWS CLI instead of installing at runtime
RUN pip install --no-cache-dir awscli

# Set environment variables
ENV STORE_MODEL_IN_DB="True"

# Create necessary directories
RUN mkdir -p /app/config

# Copy the config file
COPY ./config/litellm_config.yaml /app/config/

# Copy health check script
COPY ./health_check.py /app/health_check.py

# Expose the ports
EXPOSE 4000
EXPOSE 8080

# Create a startup script
COPY ./startup.sh /app/startup.sh
RUN chmod +x /app/startup.sh

# Set the entrypoint to our startup script
ENTRYPOINT ["/app/startup.sh"]
