#!/bin/bash
# 02-docker.sh - Docker & NVIDIA Container Toolkit Installation Script
# For UC-1 Pro - Ubuntu Server 24.04

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Docker & NVIDIA Container Toolkit         ║${NC}"
echo -e "${BLUE}║            Installation for UC-1 Pro Server            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# Check if NVIDIA driver is installed
if ! command -v nvidia-smi &> /dev/null; then
    echo -e "${RED}Error: NVIDIA driver not found. Please run 01-nvidia-driver.sh first${NC}"
    exit 1
fi

# Step 1: Install Docker
echo -e "${YELLOW}Step 1: Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    # Remove old Docker packages
    apt-get remove -y docker docker-engine docker.io containerd runc || true
    
    # Update and install prerequisites
    apt-get update
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Add Docker GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    echo \
        "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi

# Step 2: Configure Docker daemon for GPU support
echo -e "${YELLOW}Step 2: Configuring Docker daemon...${NC}"
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    },
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "storage-driver": "overlay2"
}
EOF
echo -e "${GREEN}✓ Docker daemon configured${NC}"

# Step 3: Install NVIDIA Container Toolkit
echo -e "${YELLOW}Step 3: Installing NVIDIA Container Toolkit...${NC}"
if ! command -v nvidia-container-runtime &> /dev/null; then
    # Add NVIDIA Container Toolkit repository
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    # Install NVIDIA Container Toolkit
    apt-get update
    apt-get install -y nvidia-container-toolkit
    
    echo -e "${GREEN}✓ NVIDIA Container Toolkit installed${NC}"
else
    echo -e "${GREEN}✓ NVIDIA Container Toolkit already installed${NC}"
fi

# Step 4: Configure NVIDIA Container Toolkit
echo -e "${YELLOW}Step 4: Configuring NVIDIA Container Toolkit...${NC}"
nvidia-ctk runtime configure --runtime=docker
echo -e "${GREEN}✓ NVIDIA Container Toolkit configured${NC}"

# Step 5: Enable and start Docker
echo -e "${YELLOW}Step 5: Starting Docker service...${NC}"
systemctl enable docker
systemctl start docker
echo -e "${GREEN}✓ Docker service started${NC}"

# Step 6: Add user to docker group (if not root)
if [ -n "$SUDO_USER" ]; then
    echo -e "${YELLOW}Step 6: Adding $SUDO_USER to docker group...${NC}"
    usermod -aG docker "$SUDO_USER"
    echo -e "${GREEN}✓ User added to docker group${NC}"
    echo -e "${YELLOW}Note: Log out and back in for group changes to take effect${NC}"
fi

# Step 7: Restart Docker to apply NVIDIA runtime
echo -e "${YELLOW}Step 7: Restarting Docker with NVIDIA runtime...${NC}"
systemctl restart docker
sleep 3
echo -e "${GREEN}✓ Docker restarted${NC}"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    VERIFICATION                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Test Docker
echo -e "${YELLOW}Testing Docker installation...${NC}"
if docker run --rm hello-world &> /dev/null; then
    echo -e "${GREEN}✓ Docker working correctly${NC}"
else
    echo -e "${RED}✗ Docker test failed${NC}"
fi

# Test NVIDIA Container Runtime
echo -e "${YELLOW}Testing NVIDIA Container Runtime...${NC}"
if docker run --rm --runtime=nvidia --gpus all nvidia/cuda:12.0-base nvidia-smi &> /dev/null; then
    echo -e "${GREEN}✓ NVIDIA Container Runtime working correctly${NC}"
else
    echo -e "${RED}✗ NVIDIA Container Runtime test failed${NC}"
fi

echo ""
echo -e "${GREEN}Docker and NVIDIA Container Toolkit installation complete! 🐳${NC}"
echo ""
echo -e "${YELLOW}Verify GPU access in containers:${NC}"
echo "  docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi"
echo ""
echo -e "${YELLOW}Next: Run 03-system-deps.sh for additional system dependencies${NC}"