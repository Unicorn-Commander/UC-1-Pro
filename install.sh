#!/bin/bash

# UC-1 Pro Complete Installation Script
# This script handles the entire installation process on Ubuntu 24.04 LTS
# It tracks progress and can resume after reboots

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Installation state file
STATE_FILE=".install_state"

# Function to save state
save_state() {
    echo "$1" > "$STATE_FILE"
}

# Function to get state
get_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "fresh"
    fi
}

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          UC-1 Pro Complete Installer                   ║${NC}"
echo -e "${BLUE}║       Enterprise AI Stack for RTX 5090                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check installation state
INSTALL_STATE=$(get_state)

if [ "$INSTALL_STATE" != "fresh" ]; then
    echo -e "${GREEN}Resuming installation from: $INSTALL_STATE${NC}"
    echo ""
fi

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
            
            # Check GPU device permissions
            if [ -e /dev/nvidia0 ]; then
                echo -e "${GREEN}✓ GPU device accessible${NC}"
            else
                echo -e "${YELLOW}⚠ GPU device not accessible - may need to install drivers${NC}"
            fi
            
            # Check group permissions
            if [ "$EUID" -ne 0 ]; then
                local missing_groups=""
                groups | grep -q render || missing_groups="render "
                groups | grep -q video || missing_groups="${missing_groups}video"
                
                if [ -n "$missing_groups" ]; then
                    echo -e "${YELLOW}Note: Consider adding user to groups: ${missing_groups}${NC}"
                fi
            fi
            
            return 0
        fi
    fi
    return 1
}

# Function to generate secure passwords
generate_password() {
    local length=${1:-32}
    # Generate alphanumeric password without problematic characters
    openssl rand -base64 48 | tr -d "=+/\n" | cut -c1-$length
}

# Function to generate API keys
generate_api_key() {
    local prefix=${1:-"uc1"}
    echo "${prefix}-$(openssl rand -hex 16)"
}

# ============================================================================
# STAGE 1: System Dependencies and Docker
# ============================================================================
if [ "$INSTALL_STATE" = "fresh" ] || [ "$INSTALL_STATE" = "stage1" ]; then
    save_state "stage1"
    
    echo -e "\n${BLUE}=== Stage 1: System Dependencies ===${NC}"
    
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
    
    echo -e "\n${BLUE}=== Installing Docker ===${NC}"
    
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
    fi
    
    # Install Docker Compose standalone
    if ! command_exists docker-compose; then
        echo "Installing Docker Compose standalone..."
        $SUDO curl -L "https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        $SUDO chmod +x /usr/local/bin/docker-compose
    fi
    
    # Add current user to necessary groups
    if [ "$EUID" -ne 0 ]; then
        echo -e "\n${YELLOW}Adding $USER to necessary groups...${NC}"
        
        # Add to docker group
        $SUDO usermod -aG docker $USER
        echo -e "${GREEN}✓ Added to docker group${NC}"
        
        # Add to render and video groups for GPU access
        if getent group render >/dev/null 2>&1; then
            $SUDO usermod -aG render $USER
            echo -e "${GREEN}✓ Added to render group${NC}"
        fi
        
        if getent group video >/dev/null 2>&1; then
            $SUDO usermod -aG video $USER
            echo -e "${GREEN}✓ Added to video group${NC}"
        fi
    fi
    
    save_state "stage2"
    
    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}IMPORTANT: Group permissions have been updated!${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "You need to either:"
    echo "  1. Log out and log back in, OR"
    echo "  2. Reboot your system"
    echo ""
    echo "Then run this installer again to continue with Stage 2."
    echo ""
    echo -e "${GREEN}Command to continue after reboot:${NC}"
    echo "  cd $(pwd) && ./install.sh"
    echo ""
    exit 0
fi

# ============================================================================
# STAGE 2: NVIDIA Drivers and Container Toolkit
# ============================================================================
if [ "$INSTALL_STATE" = "stage2" ]; then
    echo -e "\n${BLUE}=== Stage 2: NVIDIA Components ===${NC}"
    
    # Verify group permissions are active
    if [ "$EUID" -ne 0 ]; then
        if ! groups | grep -q docker; then
            echo -e "${RED}Docker group not active yet!${NC}"
            echo "Please log out and log back in, then run the installer again."
            exit 1
        else
            echo -e "${GREEN}✓ Docker group permissions active${NC}"
        fi
    fi
    
    # NVIDIA Driver Installation
    if check_gpu; then
        echo -e "${GREEN}✓ NVIDIA GPU already configured${NC}"
    else
        echo -e "${YELLOW}NVIDIA GPU not detected. Checking for drivers...${NC}"
        
        # Check if driver installer exists
        if ls NVIDIA-Linux-x86_64-*.run 1> /dev/null 2>&1; then
            DRIVER_FILE=$(ls NVIDIA-Linux-x86_64-*.run | head -1)
            echo -e "${GREEN}Found driver installer: $DRIVER_FILE${NC}"
            
            read -p "Install NVIDIA driver now? (Y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                echo "Installing NVIDIA driver..."
                $SUDO ./$DRIVER_FILE --silent --dkms
                
                save_state "stage3_reboot_required"
                
                echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "${YELLOW}NVIDIA driver installed - REBOOT REQUIRED!${NC}"
                echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo ""
                echo "Please reboot your system for the driver to take effect."
                echo ""
                echo -e "${GREEN}Command to continue after reboot:${NC}"
                echo "  cd $(pwd) && ./install.sh"
                echo ""
                exit 0
            fi
        else
            echo -e "${YELLOW}No NVIDIA driver installer found.${NC}"
            echo "Download driver from: https://www.nvidia.com/drivers"
            echo "Or run: ./Drivers/install-nvidia-driver.sh"
        fi
    fi
    
    # NVIDIA Container Toolkit
    echo -e "\n${BLUE}=== Installing NVIDIA Container Toolkit ===${NC}"
    
    if docker info 2>/dev/null | grep -q nvidia; then
        echo -e "${GREEN}✓ NVIDIA Container Toolkit already installed${NC}"
    else
        echo "Installing NVIDIA Container Toolkit..."
        
        if [ -f "./Drivers/install-nvidia-container-toolkit.sh" ]; then
            bash ./Drivers/install-nvidia-container-toolkit.sh
        else
            echo -e "${RED}NVIDIA Container Toolkit installer not found${NC}"
            echo "Please install manually"
        fi
    fi
    
    save_state "stage3"
fi

# ============================================================================
# STAGE 3: UC-1 Pro Configuration
# ============================================================================
if [ "$INSTALL_STATE" = "stage3" ] || [ "$INSTALL_STATE" = "stage3_reboot_required" ]; then
    if [ "$INSTALL_STATE" = "stage3_reboot_required" ]; then
        echo -e "${GREEN}✓ Continuing after NVIDIA driver installation${NC}"
        save_state "stage3"
    fi
    
    echo -e "\n${BLUE}=== Stage 3: UC-1 Pro Configuration ===${NC}"
    
    # Create necessary directories
    echo "Creating required directories..."
    mkdir -p backups
    mkdir -p volumes
    
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
                # Use the fix script
                if [ -f "./scripts/fix-env-passwords.sh" ]; then
                    ./scripts/fix-env-passwords.sh
                else
                    echo -e "${YELLOW}Password fix script not found, generating manually...${NC}"
                    # Generate passwords
                    POSTGRES_PASS=$(generate_password 24)
                    WEBUI_SECRET=$(generate_password 64)
                    VLLM_KEY=$(generate_api_key "vllm")
                    SEARXNG_SECRET=$(generate_password 32)
                    
                    # Update .env
                    cp .env .env.backup
                    # Use python for safer replacement
                    python3 -c "
import re
with open('.env', 'r') as f:
    content = f.read()
content = re.sub(r'POSTGRES_PASSWORD=.*changeme.*', 'POSTGRES_PASSWORD=$POSTGRES_PASS', content)
content = re.sub(r'WEBUI_SECRET_KEY=.*changeme.*', 'WEBUI_SECRET_KEY=$WEBUI_SECRET', content)
content = re.sub(r'VLLM_API_KEY=.*changeme.*', 'VLLM_API_KEY=$VLLM_KEY', content)
content = re.sub(r'SEARXNG_SECRET=.*changeme.*', 'SEARXNG_SECRET=$SEARXNG_SECRET', content)
with open('.env', 'w') as f:
    f.write(content)
"
                fi
                
                echo -e "${GREEN}✓ Passwords updated with secure values${NC}"
                echo "Original .env backed up to .env.backup"
            fi
        fi
    fi
    
    # Run pre-flight check
    echo -e "\n${BLUE}=== Pre-flight Check ===${NC}"
    if [ -f "./pre-flight-check.sh" ]; then
        ./pre-flight-check.sh || true
    fi
    
    # Clean up state file
    rm -f "$STATE_FILE"
    
    echo -e "\n${BLUE}=== Installation Complete! ===${NC}"
    echo ""
    echo -e "${GREEN}✨ UC-1 Pro is ready to start! ✨${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Start the stack: ${GREEN}./start.sh${NC}"
    echo "2. Monitor logs: ${GREEN}docker-compose logs -f${NC}"
    echo ""
    echo "Services will be available at:"
    echo "  - Open-WebUI: ${BLUE}http://localhost:8080${NC}"
    echo "  - vLLM API: ${BLUE}http://localhost:8000${NC}"
    echo "  - Documentation: ${BLUE}http://localhost:8081${NC}"
    echo ""
    
    # Final GPU check
    if check_gpu; then
        echo -e "${GREEN}✓ GPU is ready for AI workloads!${NC}"
    else
        echo -e "${YELLOW}⚠ No GPU detected - CPU mode will be used${NC}"
    fi
fi