#!/bin/bash
# install-nvidia-driver.sh - NVIDIA Driver 570.172.08 Installation Script for UC-1 Pro

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Driver configuration
DRIVER_VERSION="570.172.08"
DRIVER_URL="https://us.download.nvidia.com/XFree86/Linux-x86_64/${DRIVER_VERSION}/NVIDIA-Linux-x86_64-${DRIVER_VERSION}.run"
DRIVER_FILE="NVIDIA-Linux-x86_64-${DRIVER_VERSION}.run"

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        NVIDIA Driver ${DRIVER_VERSION} Installer             ║${NC}"
echo -e "${BLUE}║           For UC-1 Pro (RTX 5090)                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${YELLOW}Downloading NVIDIA driver ${DRIVER_VERSION}...${NC}"
wget -O "${DRIVER_FILE}" "${DRIVER_URL}"
chmod +x "${DRIVER_FILE}"

echo -e "${GREEN}Download complete!${NC}"
echo ""
echo "To install the driver, run:"
echo "  sudo ./${DRIVER_FILE}"
echo ""
echo "For silent installation, use:"
echo "  sudo ./${DRIVER_FILE} --silent --dkms"
