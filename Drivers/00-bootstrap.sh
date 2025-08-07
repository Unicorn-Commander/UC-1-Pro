#!/bin/bash
# 00-bootstrap.sh - UC-1 Pro Complete Server Bootstrap
# Master script for fresh Ubuntu Server 24.04 installation

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${PURPLE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                                                        ║${NC}"
echo -e "${PURPLE}║    🦄 UC-1 Pro Complete Server Bootstrap 🦄            ║${NC}"
echo -e "${PURPLE}║                                                        ║${NC}"
echo -e "${PURPLE}║    Transform your Ubuntu Server 24.04 into an         ║${NC}"
echo -e "${PURPLE}║    enterprise-grade AI infrastructure platform        ║${NC}"
echo -e "${PURPLE}║                                                        ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# Check Ubuntu version
if ! grep -q "Ubuntu 24.04" /etc/os-release; then
    echo -e "${YELLOW}Warning: This bootstrap is optimized for Ubuntu Server 24.04${NC}"
    echo -e "${YELLOW}Continue anyway? (y/N)${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if this is a fresh system
echo -e "${CYAN}Checking system status...${NC}"
if command -v docker &> /dev/null && command -v nvidia-smi &> /dev/null; then
    echo -e "${YELLOW}Warning: Docker and NVIDIA drivers appear to already be installed.${NC}"
    echo -e "${YELLOW}This will update/reconfigure existing installations.${NC}"
    echo -e "${YELLOW}Continue? (y/N)${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    BOOTSTRAP PLAN                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}This bootstrap will install:${NC}"
echo "  🎯 Step 1: NVIDIA RTX 5090 drivers + Vulkan support"
echo "  🐳 Step 2: Docker + NVIDIA Container Toolkit"
echo "  🛠️  Step 3: System dependencies + AI optimizations"
echo "  ✅ Step 4: Complete system verification"
echo ""
echo -e "${YELLOW}Estimated time: 15-20 minutes${NC}"
echo -e "${YELLOW}Internet connection required for downloads${NC}"
echo ""
echo -e "${RED}IMPORTANT: System will require 2 reboots during this process${NC}"
echo ""
read -p "Press Enter to begin bootstrap or Ctrl+C to cancel..."
echo ""

# Step 1: NVIDIA Driver Installation
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    STEP 1/4: NVIDIA                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ -f "$SCRIPT_DIR/01-nvidia-driver.sh" ]; then
    bash "$SCRIPT_DIR/01-nvidia-driver.sh"
    
    echo ""
    echo -e "${RED}FIRST REBOOT REQUIRED${NC}"
    echo -e "${YELLOW}The system needs to reboot to load the NVIDIA driver.${NC}"
    echo -e "${YELLOW}After reboot, run this script again to continue with Step 2.${NC}"
    echo ""
    echo -e "${CYAN}To continue after reboot:${NC}"
    echo "  sudo $0 --continue-from-step2"
    echo ""
    read -p "Press Enter to reboot now or Ctrl+C to reboot manually later..."
    reboot
else
    echo -e "${RED}Error: 01-nvidia-driver.sh not found in $SCRIPT_DIR${NC}"
    exit 1
fi

# This function handles continuation after first reboot
continue_from_step2() {
    echo -e "${CYAN}Continuing bootstrap from Step 2...${NC}"
    
    # Verify NVIDIA installation
    if ! command -v nvidia-smi &> /dev/null; then
        echo -e "${RED}Error: NVIDIA driver not found. Please check Step 1 installation.${NC}"
        exit 1
    fi
    
    if ! nvidia-smi &> /dev/null; then
        echo -e "${RED}Error: NVIDIA driver not working. Please check Step 1 installation.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ NVIDIA driver verified${NC}"
    echo ""
    
    # Step 2: Docker Installation
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    STEP 2/4: DOCKER                    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ -f "$SCRIPT_DIR/02-docker.sh" ]; then
        bash "$SCRIPT_DIR/02-docker.sh"
    else
        echo -e "${RED}Error: 02-docker.sh not found in $SCRIPT_DIR${NC}"
        exit 1
    fi
    
    echo ""
    
    # Step 3: System Dependencies
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                STEP 3/4: SYSTEM DEPS                   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ -f "$SCRIPT_DIR/03-system-deps.sh" ]; then
        bash "$SCRIPT_DIR/03-system-deps.sh"
    else
        echo -e "${RED}Error: 03-system-deps.sh not found in $SCRIPT_DIR${NC}"
        exit 1
    fi
    
    echo ""
    
    # Step 4: Final Verification
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                STEP 4/4: VERIFICATION                  ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    run_final_verification
    
    echo ""
    echo -e "${RED}FINAL REBOOT RECOMMENDED${NC}"
    echo -e "${YELLOW}A final reboot is recommended to ensure all optimizations are active.${NC}"
    echo ""
    read -p "Reboot now to complete setup? (y/N): " reboot_choice
    if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Rebooting in 5 seconds...${NC}"
        sleep 5
        reboot
    else
        echo -e "${YELLOW}Remember to reboot manually to complete setup.${NC}"
    fi
}

# Final verification function
run_final_verification() {
    echo -e "${CYAN}Running comprehensive system verification...${NC}"
    echo ""
    
    # NVIDIA verification
    echo -e "${YELLOW}🎯 NVIDIA Driver:${NC}"
    if nvidia-smi &> /dev/null; then
        echo -e "${GREEN}✓ NVIDIA driver working${NC}"
        nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
    else
        echo -e "${RED}✗ NVIDIA driver failed${NC}"
    fi
    echo ""
    
    # Docker verification
    echo -e "${YELLOW}🐳 Docker:${NC}"
    if docker run --rm hello-world &> /dev/null; then
        echo -e "${GREEN}✓ Docker working${NC}"
        echo "  Version: $(docker --version)"
    else
        echo -e "${RED}✗ Docker failed${NC}"
    fi
    echo ""
    
    # NVIDIA Container Runtime verification
    echo -e "${YELLOW}🚀 NVIDIA Container Runtime:${NC}"
    if timeout 30 docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi &> /dev/null; then
        echo -e "${GREEN}✓ GPU containers working${NC}"
    else
        echo -e "${RED}✗ GPU containers failed${NC}"
    fi
    echo ""
    
    # Vulkan verification
    echo -e "${YELLOW}🎮 Vulkan:${NC}"
    if command -v vulkaninfo &> /dev/null; then
        echo -e "${GREEN}✓ Vulkan tools installed${NC}"
    else
        echo -e "${RED}✗ Vulkan tools missing${NC}"
    fi
    echo ""
    
    # System resources
    echo -e "${YELLOW}💾 System Resources:${NC}"
    echo "  RAM: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "  Disk: $(df -h / | awk 'NR==2 {print $4}') available"
    echo "  CPU: $(nproc) cores"
    if nvidia-smi &> /dev/null; then
        echo "  GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader)"
        echo "  VRAM: $(nvidia-smi --query-gpu=memory.total --format=csv,noheader,units=MiB)"
    fi
    echo ""
    
    echo -e "${GREEN}🎉 UC-1 Pro server bootstrap verification complete!${NC}"
}

# Handle command line arguments
case "${1:-}" in
    --continue-from-step2)
        continue_from_step2
        ;;
    --verify-only)
        run_final_verification
        ;;
    *)
        # Default behavior - start from beginning
        ;;
esac