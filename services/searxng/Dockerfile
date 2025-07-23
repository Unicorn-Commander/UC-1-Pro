FROM searxng/searxng:latest

# Install additional packages if needed
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3-pip \
    python3-jinja2 \
    python3-dotenv \
    curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create directory for configuration files
RUN mkdir -p /etc/searxng

# Copy our own uwsgi.ini (optional)
COPY uwsgi.ini /etc/searxng/uwsgi.ini

# The settings.yml will be mounted at runtime

# Return to non-root user
USER searxng

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8888/healthz || exit 1

# Default command
CMD ["/usr/local/searxng/dockerfiles/docker-entrypoint.sh"]
