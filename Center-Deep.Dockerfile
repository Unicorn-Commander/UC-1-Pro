# Center-Deep Pro - Enterprise Search Intelligence Platform
# Pulls from the official Unicorn-Commander repository

FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    gcc \
    g++ \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# Clone Center-Deep from the official repository
# Note: If the repository is private, you'll need to pass a GitHub token
ARG GITHUB_TOKEN=""
RUN if [ -n "$GITHUB_TOKEN" ]; then \
        git clone https://${GITHUB_TOKEN}@github.com/Unicorn-Commander/Center-Deep.git /tmp/center-deep; \
    else \
        git clone https://github.com/Unicorn-Commander/Center-Deep.git /tmp/center-deep; \
    fi && \
    cp -r /tmp/center-deep/* /app/ && \
    rm -rf /tmp/center-deep

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Create instance directory for database
RUN mkdir -p instance

# Expose port
EXPOSE 8890

# Environment variables
ENV FLASK_APP=app.py
ENV PYTHONUNBUFFERED=1

# Run the application
CMD ["python", "app.py"]