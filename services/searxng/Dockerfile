FROM searxng/searxng:latest

# The base image already includes all necessary dependencies
# We just need to copy our configuration

USER root

# Create directory for configuration files if needed
RUN mkdir -p /etc/searxng

# Copy our own uwsgi.ini (optional)
COPY uwsgi.ini /etc/searxng/uwsgi.ini

# Return to non-root user
USER searxng

# Health check using wget (already available in Alpine)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/healthz || exit 1

# Default command
CMD ["/usr/local/searxng/dockerfiles/docker-entrypoint.sh"]
