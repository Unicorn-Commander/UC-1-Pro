#!/bin/bash

# Script to sign NVIDIA driver for Secure Boot systems

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}      NVIDIA Driver Signing for Secure Boot               ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
   echo "Please run as root: sudo $0"
   exit 1
fi

# Create signing keys
echo -e "\n${YELLOW}Creating MOK (Machine Owner Key) for signing...${NC}"

mkdir -p /var/lib/shim-signed/mok
cd /var/lib/shim-signed/mok

# Generate key if it doesn't exist
if [ ! -f MOK.priv ]; then
    openssl req -new -x509 -newkey rsa:2048 -keyout MOK.priv -outform DER -out MOK.der -nodes -days 36500 -subj "/CN=UC1 Pro NVIDIA Driver Signing Key/"
    echo -e "${GREEN}✓ MOK key generated${NC}"
else
    echo -e "${GREEN}✓ MOK key already exists${NC}"
fi

# Install mokutil if not present
if ! command -v mokutil &> /dev/null; then
    apt-get update
    apt-get install -y mokutil
fi

# Check if key is already enrolled
if [ -f MOK.der ]; then
    if mokutil --test-key MOK.der 2>&1 | grep -q "is already enrolled"; then
        echo -e "${GREEN}✓ MOK key already enrolled${NC}"
        MOK_ENROLLED=1
    else
        echo -e "${YELLOW}MOK key exists but not enrolled yet${NC}"
    fi
fi

# Import key if not enrolled
if [ -z "$MOK_ENROLLED" ]; then
    echo -e "\n${YELLOW}Enrolling MOK key...${NC}"
    echo -e "${RED}IMPORTANT: You must create a password for MOK enrollment${NC}"
    echo "Remember this password - you'll need it after reboot!"
    echo ""
    
    mokutil --import MOK.der
    
    echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}     ACTION REQUIRED: Reboot to Enroll MOK Key           ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}STEP 1: Reboot your system now${NC}"
    echo -e "Command: ${GREEN}sudo reboot${NC}"
    echo ""
    echo -e "${YELLOW}STEP 2: At the blue MOK management screen:${NC}"
    echo "  1. Select 'Enroll MOK'"
    echo "  2. Select 'Continue'"
    echo "  3. Select 'Yes'"
    echo "  4. Enter the password you just created"
    echo "  5. Select 'Reboot'"
    echo ""
    echo -e "${YELLOW}STEP 3: After enrollment is complete:${NC}"
    echo -e "Run this script again: ${GREEN}sudo ./scripts/sign-nvidia-driver.sh${NC}"
    echo ""
    echo -e "${BLUE}Next command to run:${NC}"
    echo -e "${GREEN}sudo reboot${NC}"
    echo ""
    exit 0
fi

# Find NVIDIA driver installer
DRIVER_FILE=$(ls /home/*/UC-1-Pro/NVIDIA-Linux-x86_64-*.run 2>/dev/null | head -1)
if [ -z "$DRIVER_FILE" ]; then
    DRIVER_FILE=$(ls NVIDIA-Linux-x86_64-*.run 2>/dev/null | head -1)
fi

if [ -z "$DRIVER_FILE" ]; then
    echo -e "${RED}NVIDIA driver installer not found!${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Installing NVIDIA driver with module signing...${NC}"

# Install with module signing
$DRIVER_FILE \
    --silent \
    --dkms \
    --module-signing-secret-key=/var/lib/shim-signed/mok/MOK.priv \
    --module-signing-public-key=/var/lib/shim-signed/mok/MOK.der

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ NVIDIA driver installed and signed!${NC}"
    
    if [ -n "$NEEDS_REBOOT" ]; then
        echo -e "\n${YELLOW}You need to reboot to enroll the MOK key${NC}"
        echo "After reboot, follow the MOK enrollment steps above"
    else
        echo -e "\n${GREEN}Installation complete! The driver should work after a reboot.${NC}"
    fi
else
    echo -e "${RED}Driver installation failed. Check /var/log/nvidia-installer.log${NC}"
    exit 1
fi

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}                    Next Steps                            ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}1. Reboot your system:${NC}"
echo -e "   ${GREEN}sudo reboot${NC}"
echo ""
if [ -n "$NEEDS_REBOOT" ]; then
    echo -e "${YELLOW}2. Complete MOK enrollment at the blue screen${NC}"
    echo ""
    echo -e "${YELLOW}3. Verify GPU after boot:${NC}"
    echo -e "   ${GREEN}nvidia-smi${NC}"
else
    echo -e "${YELLOW}2. Verify GPU after boot:${NC}"
    echo -e "   ${GREEN}nvidia-smi${NC}"
fi
echo ""
echo -e "${YELLOW}3. Continue UC-1 Pro installation:${NC}"
echo -e "   ${GREEN}cd ~/UC-1-Pro && ./install.sh${NC}"
echo ""