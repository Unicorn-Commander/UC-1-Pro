#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Installing NVIDIA Container Toolkit...${NC}"

# Method 1: Try the official repository first
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)

# For Ubuntu 24.04, use ubuntu22.04 repository as fallback
if [ "$distribution" = "ubuntu24.04" ]; then
    echo -e "${YELLOW}Ubuntu 24.04 detected, using Ubuntu 22.04 repository...${NC}"
    distribution="ubuntu22.04"
fi

# Configure repository
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Update and install
echo "Updating package lists..."
sudo apt-get update

echo "Installing NVIDIA Container Toolkit..."
sudo apt-get install -y nvidia-container-toolkit || {
    echo -e "${YELLOW}Failed to install from repository, trying alternative method...${NC}"
    
    # Method 2: Direct .deb download for Ubuntu 24.04
    wget https://nvidia.github.io/libnvidia-container/stable/deb/amd64/nvidia-container-toolkit-base_1.14.3-1_amd64.deb
    wget https://nvidia.github.io/libnvidia-container/stable/deb/amd64/nvidia-container-toolkit_1.14.3-1_amd64.deb
    
    sudo apt-get install -y ./nvidia-container-toolkit-base_*.deb
    sudo apt-get install -y ./nvidia-container-toolkit_*.deb
    
    rm -f nvidia-container-toolkit*.deb
}

# Configure Docker
echo -e "${YELLOW}Configuring Docker for NVIDIA runtime...${NC}"
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Verify installation
if command -v nvidia-ctk &> /dev/null; then
    echo -e "${GREEN}NVIDIA Container Toolkit installed successfully!${NC}"
    nvidia-ctk --version
else
    echo -e "${RED}Installation may have failed. Please check the output above.${NC}"
    exit 1
fi

# Optional: Test with CUDA container (only if GPU is available)
if nvidia-smi &> /dev/null; then
    echo -e "${YELLOW}Testing NVIDIA Container Toolkit with CUDA container...${NC}"
    docker run --rm --runtime=nvidia --gpus all nvidia/cuda:12.0-base nvidia-smi
else
    echo -e "${YELLOW}No NVIDIA GPU detected, skipping container test.${NC}"
fi

echo -e "${GREEN}NVIDIA Container Toolkit setup complete!${NC}"
