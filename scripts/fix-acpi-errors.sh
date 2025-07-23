#!/bin/bash

# Fix ACPI BIOS errors on Ubuntu 24.04
# These errors are related to NVIDIA GPU power management

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          ACPI Error Fix for UC-1 Pro                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}This fixes ACPI BIOS errors related to NVIDIA GPU${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root (sudo)${NC}"
    exit 1
fi

echo -e "${BLUE}=== Current Boot Parameters ===${NC}"
cat /proc/cmdline
echo ""

echo -e "${BLUE}=== Applying ACPI Fixes ===${NC}"

# Backup current GRUB config
cp /etc/default/grub /etc/default/grub.backup.$(date +%Y%m%d_%H%M%S)

# Check if GRUB_CMDLINE_LINUX_DEFAULT exists
if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub; then
    # Update existing line
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 acpi_enforce_resources=lax pci=realloc=off"/g' /etc/default/grub
    
    # Remove duplicates if any
    sed -i 's/acpi_enforce_resources=lax acpi_enforce_resources=lax/acpi_enforce_resources=lax/g' /etc/default/grub
    sed -i 's/pci=realloc=off pci=realloc=off/pci=realloc=off/g' /etc/default/grub
else
    # Add new line
    echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash acpi_enforce_resources=lax pci=realloc=off"' >> /etc/default/grub
fi

echo -e "${GREEN}✓ Updated GRUB configuration${NC}"

# Update GRUB
echo -e "${YELLOW}Updating GRUB...${NC}"
update-grub

echo -e "\n${BLUE}=== Additional Fixes ===${NC}"

# Create ACPI override if needed
mkdir -p /etc/acpi/events

# Disable ACPI debug messages in kernel log
if ! grep -q "loglevel=3" /proc/cmdline; then
    echo -e "${YELLOW}To reduce kernel log spam, you can also add 'loglevel=3' to GRUB_CMDLINE_LINUX_DEFAULT${NC}"
fi

# Create modprobe config for NVIDIA
cat > /etc/modprobe.d/nvidia-power.conf << EOF
# Disable runtime power management for NVIDIA
options nvidia NVreg_DynamicPowerManagement=0
options nvidia-drm modeset=1
EOF

echo -e "${GREEN}✓ Created NVIDIA power management config${NC}"

# Check for BIOS updates
echo -e "\n${BLUE}=== System Information ===${NC}"
echo "Motherboard: $(dmidecode -s baseboard-manufacturer 2>/dev/null || echo 'Unknown') $(dmidecode -s baseboard-product-name 2>/dev/null || echo 'Unknown')"
echo "BIOS Version: $(dmidecode -s bios-version 2>/dev/null || echo 'Unknown')"
echo "BIOS Date: $(dmidecode -s bios-release-date 2>/dev/null || echo 'Unknown')"

echo -e "\n${YELLOW}Consider checking for BIOS updates from your motherboard manufacturer${NC}"
echo "These ACPI errors often indicate outdated BIOS ACPI tables"

echo -e "\n${BLUE}=== Summary ===${NC}"
echo "Applied the following fixes:"
echo "1. Added 'acpi_enforce_resources=lax' - Relaxes ACPI resource conflict checking"
echo "2. Added 'pci=realloc=off' - Prevents PCI BAR reallocation issues"
echo "3. Disabled NVIDIA dynamic power management"
echo ""
echo -e "${YELLOW}IMPORTANT: A reboot is required for changes to take effect${NC}"
echo ""
echo -e "Run: ${GREEN}sudo reboot${NC}"
echo ""
echo "Note: These errors are cosmetic and don't affect Docker or UC-1 Pro operation."
echo "The errors occur because the BIOS ACPI tables have duplicate entries for GPU power management."