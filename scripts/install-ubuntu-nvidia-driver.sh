#!/bin/bash

# Install Ubuntu's pre-signed NVIDIA driver (works with Secure Boot)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}    Installing Ubuntu's Pre-signed NVIDIA Driver          ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}✓ This method works with Secure Boot enabled!${NC}"
echo ""

# Update package lists
sudo apt update

# Install ubuntu-drivers-common if not present
if ! command -v ubuntu-drivers &> /dev/null; then
    sudo apt install -y ubuntu-drivers-common
fi

# Show available drivers
echo -e "\n${YELLOW}Available NVIDIA drivers:${NC}"
ubuntu-drivers devices

# Install recommended driver
echo -e "\n${YELLOW}Installing recommended NVIDIA driver...${NC}"
sudo ubuntu-drivers autoinstall

# Alternative: Install specific driver version
# sudo apt install -y nvidia-driver-545

echo -e "\n${GREEN}✓ Driver installation complete!${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}                    Next Steps                            ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}1. Reboot your system (REQUIRED):${NC}"
echo -e "   ${GREEN}sudo reboot${NC}"
echo ""
echo -e "${YELLOW}2. Verify GPU after boot:${NC}"
echo -e "   ${GREEN}nvidia-smi${NC}"
echo ""
echo -e "${YELLOW}3. Continue UC-1 Pro installation:${NC}"
echo -e "   ${GREEN}cd ~/UC-1-Pro && ./install.sh${NC}"
echo ""