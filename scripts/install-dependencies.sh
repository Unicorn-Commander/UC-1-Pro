#!/bin/bash
#
# UC-1 Pro Dependency Installation Script
#
# This script installs all necessary dependencies to run the UC-1 Pro stack
# on a fresh Ubuntu 24.04 LTS server.
#
# It installs:
#   - Docker Engine
#   - Docker Compose (as a plugin)
#   - NVIDIA Container Toolkit
#
# USAGE:
#   1. Make the script executable: chmod +x install-dependencies.sh
#   2. Run with sudo: sudo ./install-dependencies.sh
#

set -e

echo "[INFO] Starting UC-1 Pro dependency installation..."

# --- 1. Install Docker Engine & Docker Compose ---
echo "[INFO] Step 1: Installing Docker Engine and Docker Compose..."

# Update package index and install prerequisites
sudo apt-get update
sudo apt-get install -y ca-certificates curl

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Set up the Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again with the new repository
sudo apt-get update

# Install Docker Engine, CLI, containerd, and Compose plugin
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[INFO] Docker installation complete."


# --- 2. Install NVIDIA Container Toolkit ---
echo "[INFO] Step 2: Installing NVIDIA Container Toolkit..."

# Add NVIDIA's GPG key and repository
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Update package index with the new repository
sudo apt-get update

# Install the toolkit
sudo apt-get install -y nvidia-container-toolkit

echo "[INFO] NVIDIA Container Toolkit installation complete."


# --- 3. Configure Docker and System ---
echo "[INFO] Step 3: Configuring Docker to use NVIDIA runtime..."

# Configure the Docker daemon to recognize the NVIDIA runtime
sudo nvidia-ctk runtime configure --runtime=docker

# Restart the Docker daemon to apply the changes
sudo systemctl restart docker

# Add current user to the docker group to run docker without sudo
# This is optional but highly recommended.
if [ -n "$SUDO_USER" ]; then
    sudo usermod -aG docker $SUDO_USER
    echo "[IMPORTANT] User $SUDO_USER has been added to the 'docker' group."
elif
    echo "[WARNING] Could not determine the original user. Please run 'sudo usermod -aG docker $USER' manually."
fi

echo ""
echo "--- Installation Summary ---"
echo "Docker Version:"
docker --version
echo ""
echo "Docker Compose Version:"
docker compose version
echo ""
echo "NVIDIA Container Toolkit configured."
echo "----------------------------"
echo ""
echo "[SUCCESS] All dependencies have been installed."
echo "[IMPORTANT] You must log out and log back in for the group changes to take effect."
echo "After logging back in, test the installation by running: docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi"
