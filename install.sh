#!/bin/bash

# UC-1 Pro Complete Installation Script
# This script handles the entire installation process on Ubuntu 24.04 LTS

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          UC-1 Pro Complete Installer                   ║${NC}"
echo -e "${BLUE}║       Enterprise AI Stack for RTX 5090                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    echo -e "${YELLOW}Warning: This installer is designed for Ubuntu 24.04 LTS${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if running as root for driver installation
if [ "$EUID" -eq 0 ]; then 
   echo -e "${GREEN}Running as root - can install all components${NC}"
   SUDO=""
else
   echo -e "${YELLOW}Not running as root - will use sudo for system packages${NC}"
   SUDO="sudo"
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check GPU
check_gpu() {
    if command_exists nvidia-smi; then
        if nvidia-smi >/dev/null 2>&1; then
            echo -e "${GREEN}✓ NVIDIA GPU detected${NC}"
            nvidia-smi --query-gpu=name --format=csv,noheader | head -1
            return 0
        fi
    fi
    return 1
}

echo -e "\n${BLUE}=== Phase 1: System Dependencies ===${NC}"

# Update system
echo "Updating package lists..."
$SUDO apt-get update

# Install basic dependencies
echo "Installing basic dependencies..."
$SUDO apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

echo -e "\n${BLUE}=== Phase 2: NVIDIA Drivers ===${NC}"

if check_gpu; then
    echo -e "${GREEN}NVIDIA GPU already configured${NC}"
else
    echo -e "${YELLOW}NVIDIA GPU not detected. Installing drivers...${NC}"
    
    # Check if we should install drivers
    read -p "Install NVIDIA drivers? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        # Run the NVIDIA driver installer
        if [ -f "./Drivers/install-nvidia-driver.sh" ]; then
            echo "Running NVIDIA driver installer..."
            $SUDO bash ./Drivers/install-nvidia-driver.sh
        else
            echo -e "${RED}NVIDIA driver installer not found${NC}"
            echo "Please install NVIDIA drivers manually"
        fi
    fi
fi

echo -e "\n${BLUE}=== Phase 3: Docker Installation ===${NC}"

if command_exists docker; then
    echo -e "${GREEN}✓ Docker is already installed${NC}"
    docker --version
else
    echo "Installing Docker..."
    
    # Add Docker's official GPG key
    $SUDO install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    $SUDO chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    $SUDO apt-get update
    $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add current user to docker group
    if [ "$EUID" -ne 0 ]; then
        $SUDO usermod -aG docker $USER
        echo -e "${YELLOW}Added $USER to docker group. You'll need to log out and back in.${NC}"
    fi
fi

# Install Docker Compose standalone (for docker-compose command)
if ! command_exists docker-compose; then
    echo "Installing Docker Compose standalone..."
    $SUDO curl -L "https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    $SUDO chmod +x /usr/local/bin/docker-compose
fi

echo -e "\n${BLUE}=== Phase 4: NVIDIA Container Toolkit ===${NC}"

if docker info 2>/dev/null | grep -q nvidia; then
    echo -e "${GREEN}✓ NVIDIA Container Toolkit already installed${NC}"
else
    echo "Installing NVIDIA Container Toolkit..."
    
    if [ -f "./Drivers/install-nvidia-container-toolkit.sh" ]; then
        bash ./Drivers/install-nvidia-container-toolkit.sh
    else
        echo -e "${RED}NVIDIA Container Toolkit installer not found${NC}"
        echo "Please install manually or check the repository"
    fi
fi

echo -e "\n${BLUE}=== Phase 5: UC-1 Pro Configuration ===${NC}"

# Create necessary directories
echo "Creating required directories..."
mkdir -p backups
mkdir -p volumes

# Function to generate secure passwords
generate_password() {
    local length=${1:-32}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

# Function to generate API keys
generate_api_key() {
    local prefix=${1:-"uc1"}
    echo "${prefix}-$(openssl rand -hex 16)"
}

# Handle .env file
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Creating .env file with secure auto-generated passwords...${NC}"
    cp .env.template .env
    
    # Generate secure passwords and keys
    POSTGRES_PASS=$(generate_password 24)
    WEBUI_SECRET=$(generate_password 64)
    VLLM_KEY=$(generate_api_key "vllm")
    SEARXNG_SECRET=$(generate_password 32)
    COMFYUI_KEY=$(generate_api_key "comfy")
    GRAFANA_PASS=$(generate_password 16)
    
    # Replace default values with generated ones
    sed -i.bak "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=${POSTGRES_PASS}/" .env
    sed -i.bak "s/WEBUI_SECRET_KEY=.*/WEBUI_SECRET_KEY=${WEBUI_SECRET}/" .env
    sed -i.bak "s/VLLM_API_KEY=.*/VLLM_API_KEY=${VLLM_KEY}/" .env
    sed -i.bak "s/SEARXNG_SECRET=.*/SEARXNG_SECRET=${SEARXNG_SECRET}/" .env
    sed -i.bak "s/COMFYUI_API_KEY=.*/COMFYUI_API_KEY=${COMFYUI_KEY}/" .env
    sed -i.bak "s/GRAFANA_PASSWORD=.*/GRAFANA_PASSWORD=${GRAFANA_PASS}/" .env
    
    # Clean up backup files
    rm -f .env.bak
    
    echo -e "${GREEN}✓ Secure passwords generated and saved to .env${NC}"
    echo ""
    echo "Generated credentials (save these!):"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "PostgreSQL Password: ${POSTGRES_PASS}"
    echo "vLLM API Key: ${VLLM_KEY}"
    echo "Grafana Password: admin / ${GRAFANA_PASS}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Optionally let user review/edit
    read -p "Would you like to review/edit the .env file? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ${EDITOR:-nano} .env
    fi
else
    echo -e "${GREEN}✓ .env file already exists${NC}"
    
    # Check for default passwords
    if grep -q "changeme\|CHANGE_ME" .env; then
        echo -e "${RED}WARNING: .env contains default passwords!${NC}"
        read -p "Generate new secure passwords? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            # Backup existing .env
            cp .env .env.backup
            
            # Generate and replace passwords
            sed -i "s/POSTGRES_PASSWORD=.*changeme.*/POSTGRES_PASSWORD=$(generate_password 24)/" .env
            sed -i "s/WEBUI_SECRET_KEY=.*changeme.*/WEBUI_SECRET_KEY=$(generate_password 64)/" .env
            sed -i "s/VLLM_API_KEY=.*changeme.*/VLLM_API_KEY=$(generate_api_key 'vllm')/" .env
            sed -i "s/SEARXNG_SECRET=.*changeme.*/SEARXNG_SECRET=$(generate_password 32)/" .env
            
            echo -e "${GREEN}✓ Passwords updated with secure values${NC}"
            echo "Original .env backed up to .env.backup"
        fi
    fi
fi

echo -e "\n${BLUE}=== Phase 6: Pre-flight Check ===${NC}"

# Run pre-flight check
if [ -f "./pre-flight-check.sh" ]; then
    ./pre-flight-check.sh || true
fi

echo -e "\n${BLUE}=== Installation Complete! ===${NC}"
echo ""
echo "Next steps:"
echo "1. Review and update passwords in .env file (if not already done)"
echo "2. Start the stack: ./scripts/start.sh"
echo "3. Monitor logs: docker-compose logs -f"
echo ""
echo "Services will be available at:"
echo "  - Open-WebUI: http://localhost:8080"
echo "  - vLLM API: http://localhost:8000"
echo "  - Documentation: http://localhost:8081"
echo ""

if [ "$EUID" -ne 0 ] && ! groups | grep -q docker; then
    echo -e "${YELLOW}NOTE: You need to log out and back in for docker group changes to take effect${NC}"
    echo "Or run: newgrp docker"
fi

echo -e "\n${GREEN}Ready to start UC-1 Pro!${NC}"