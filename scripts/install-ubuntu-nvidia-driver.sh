#!/bin/bash

# Install Ubuntu's pre-signed NVIDIA driver (works with Secure Boot)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Installing Ubuntu's Pre-signed NVIDIA Driver${NC}"
echo "==========================================="
echo ""
echo "This method works with Secure Boot enabled!"
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
echo -e "${YELLOW}IMPORTANT: A reboot is required${NC}"
echo ""
echo "Next steps:"
echo "1. Reboot: ${GREEN}sudo reboot${NC}"
echo "2. Verify GPU: ${GREEN}nvidia-smi${NC}"
echo "3. Continue installation: ${GREEN}cd ~/UC-1-Pro && ./install.sh${NC}"