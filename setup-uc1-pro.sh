#!/bin/bash
#
# UC-1 Pro Initial Setup Script
#
# This script performs initial checks and setup tasks required before
# running the main stack for the first time.
#
# It ensures that:
#   1. The .env configuration file exists.
#   2. The necessary (but empty) volumes directory is created to match documentation.
#

set -e

echo "[INFO] Starting UC-1 Pro initial setup..."

# --- 1. Check for .env file ---
echo "[INFO] Checking for .env file..."
if [ ! -f ".env" ]; then
    echo "[ERROR] .env file not found!"
    echo "Please copy the .env.template file to .env and configure it before running this script."
    echo "  cp .env.template .env"
    exit 1
fi
echo "[SUCCESS] .env file found."

# --- 2. Create volumes directory ---
# Although we use named volumes, the documentation shows a `volumes` directory.
# We create it here to prevent confusion and align with the docs.
echo "[INFO] Creating 'volumes' directory to align with documentation..."
mkdir -p volumes
echo "[SUCCESS] 'volumes' directory created."


echo ""
echo "[COMPLETE] Initial setup is complete."
echo "You can now start the full application stack by running: ./scripts/start.sh"
