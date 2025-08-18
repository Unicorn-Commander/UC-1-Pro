# Center-Deep Pro - Build from local synchronized repository
# This is the recommended approach for UC-1 Pro integration

FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# Copy the local Center-Deep repository
# This assumes you have Center-Deep cloned/synced locally
COPY ./Center-Deep/ /app/

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