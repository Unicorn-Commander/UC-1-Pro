#!/bin/bash
# install-nvidia-driver.sh - NVIDIA Driver 570.172.08 Installation Script for UC-1 Pro
# Enhanced for Ubuntu Server 24.04 with nouveau blacklisting, Vulkan support, and iGPU compatibility

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
echo -e "${BLUE}║      For UC-1 Pro (RTX 5090) - Ubuntu Server 24.04    ║${NC}"
echo -e "${BLUE}║   With Nouveau Blacklisting, Vulkan & iGPU Support    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# Function to check Secure Boot status
check_secure_boot() {
    if command -v mokutil &> /dev/null; then
        if mokutil --sb-state 2>/dev/null | grep -q "SecureBoot enabled"; then
            return 0  # Secure Boot is enabled
        fi
    fi
    return 1  # Secure Boot is disabled or status unknown
}

# Function to detect if system has multiple GPUs
detect_gpu_configuration() {
    local gpu_count=$(lspci | grep -i vga | wc -l)
    local has_nvidia=$(lspci | grep -i nvidia | grep -i vga | wc -l)
    local has_intel=$(lspci | grep -i intel | grep -i vga | wc -l)
    
    echo -e "${YELLOW}Detecting GPU configuration...${NC}"
    echo "  Total GPUs: $gpu_count"
    echo "  NVIDIA GPUs: $has_nvidia"
    echo "  Intel GPUs: $has_intel"
    
    if [ "$gpu_count" -gt 1 ] && [ "$has_intel" -gt 0 ] && [ "$has_nvidia" -gt 0 ]; then
        echo -e "${GREEN}✓ Detected multi-GPU system with Intel iGPU and NVIDIA GPU${NC}"
        echo -e "${YELLOW}  Will configure NVIDIA GPU for compute-only mode${NC}"
        return 0
    else
        return 1
    fi
}

# Function to clean existing NVIDIA installations
clean_existing_nvidia() {
    echo -e "${YELLOW}Checking for existing NVIDIA installations...${NC}"
    
    # Check if nvidia-uninstall exists and run it
    if [ -f /usr/bin/nvidia-uninstall ]; then
        echo "  Found nvidia-uninstall, running cleanup..."
        nvidia-uninstall --silent 2>/dev/null || true
    fi
    
    # Remove DKMS modules
    if dkms status | grep -q nvidia; then
        echo "  Removing DKMS modules..."
        for module in $(dkms status | grep nvidia | awk '{print $1}' | sort -u); do
            for version in $(dkms status | grep "$module" | awk -F, '{print $2}' | sed 's/^ *//'); do
                dkms remove "$module/$version" --all 2>/dev/null || true
            done
        done
    fi
    
    # Clean up kernel module source
    rm -rf /usr/src/nvidia-* 2>/dev/null || true
    
    # Remove any loaded nvidia modules
    for mod in nvidia_drm nvidia_modeset nvidia_uvm nvidia; do
        rmmod $mod 2>/dev/null || true
    done
    
    echo -e "${GREEN}✓ Cleanup completed${NC}"
}

# Detect GPU configuration
IS_MULTI_GPU=false
if detect_gpu_configuration; then
    IS_MULTI_GPU=true
fi

# Check Ubuntu version
if ! grep -q "Ubuntu 24.04" /etc/os-release; then
    echo -e "${YELLOW}Warning: This script is optimized for Ubuntu Server 24.04${NC}"
    echo -e "${YELLOW}Continue anyway? (y/N)${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 1: Clean existing NVIDIA installations
echo -e "${YELLOW}Step 1: Cleaning any existing NVIDIA installations...${NC}"
clean_existing_nvidia

# Step 2: Blacklist nouveau driver
echo -e "${YELLOW}Step 2: Blacklisting nouveau driver...${NC}"
cat > /etc/modprobe.d/blacklist-nouveau.conf << EOF
blacklist nouveau
options nouveau modeset=0
EOF

# Add to kernel command line if not present
if ! grep -q "nouveau.modeset=0" /etc/default/grub; then
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nouveau.modeset=0 rd.driver.blacklist=nouveau"/' /etc/default/grub
    update-grub
fi
echo -e "${GREEN}✓ Nouveau driver blacklisted${NC}"

# Step 3: Install build dependencies and Vulkan packages
echo -e "${YELLOW}Step 3: Installing build dependencies and Vulkan support...${NC}"
apt-get update
apt-get install -y \
    build-essential \
    dkms \
    linux-headers-$(uname -r) \
    pkg-config \
    libvulkan1 \
    mesa-vulkan-drivers \
    vulkan-tools \
    vulkan-utility-libraries-dev \
    libvulkan-dev \
    libglvnd-dev \
    libgl1-mesa-dev

echo -e "${GREEN}✓ Dependencies and Vulkan packages installed${NC}"

# Step 4: Download NVIDIA driver
echo -e "${YELLOW}Step 4: Downloading NVIDIA driver ${DRIVER_VERSION}...${NC}"
if [ ! -f "${DRIVER_FILE}" ]; then
    wget -O "${DRIVER_FILE}" "${DRIVER_URL}"
    chmod +x "${DRIVER_FILE}"
    echo -e "${GREEN}✓ Driver downloaded${NC}"
else
    echo -e "${GREEN}✓ Driver already exists${NC}"
fi

# Step 5: Update initramfs
echo -e "${YELLOW}Step 5: Updating initramfs...${NC}"
update-initramfs -u
echo -e "${GREEN}✓ Initramfs updated${NC}"

# Step 6: Check for Secure Boot
echo -e "${YELLOW}Step 6: Checking Secure Boot status...${NC}"
SECURE_BOOT_ENABLED=false
if check_secure_boot; then
    SECURE_BOOT_ENABLED=true
    echo -e "${YELLOW}⚠ Secure Boot is ENABLED${NC}"
    
    # Check if MOK keys already exist
    if [ -f /var/lib/shim-signed/mok/MOK.priv ] && [ -f /var/lib/shim-signed/mok/MOK.der ]; then
        echo -e "${GREEN}✓ MOK keys already exist${NC}"
        
        # Check if key is already enrolled
        if mokutil --test-key /var/lib/shim-signed/mok/MOK.der 2>&1 | grep -q "is already enrolled"; then
            echo -e "${GREEN}✓ MOK key is already enrolled${NC}"
        else
            echo -e "${YELLOW}MOK key exists but not enrolled yet${NC}"
            echo -e "${YELLOW}You'll need to enroll it on next reboot${NC}"
        fi
    else
        echo -e "${YELLOW}Setting up MOK (Machine Owner Key) for module signing...${NC}"
        
        # Create MOK directory
        mkdir -p /var/lib/shim-signed/mok/
        
        # Generate MOK key pair
        openssl req -new -x509 -newkey rsa:2048 -keyout /var/lib/shim-signed/mok/MOK.priv \
            -outform DER -out /var/lib/shim-signed/mok/MOK.der -days 36500 \
            -subj "/CN=UC-1-Pro-NVIDIA-Driver/" -nodes
        
        # Set proper permissions
        chmod 600 /var/lib/shim-signed/mok/MOK.priv
        chmod 644 /var/lib/shim-signed/mok/MOK.der
        
        echo -e "${GREEN}✓ MOK keys generated${NC}"
        
        # Request MOK enrollment
        echo -e "${YELLOW}Requesting MOK enrollment...${NC}"
        echo -e "${YELLOW}You'll need to create a password for MOK enrollment:${NC}"
        mokutil --import /var/lib/shim-signed/mok/MOK.der
        
        echo ""
        echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║              MOK ENROLLMENT INSTRUCTIONS               ║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
        echo -e "${GREEN}On next reboot:${NC}"
        echo -e "${GREEN}1. You'll see a blue screen saying 'Perform MOK management'${NC}"
        echo -e "${GREEN}2. Select 'Enroll MOK'${NC}"
        echo -e "${GREEN}3. Select 'Continue'${NC}"
        echo -e "${GREEN}4. Select 'Yes' to enroll the key${NC}"
        echo -e "${GREEN}5. Enter the password you just created${NC}"
        echo -e "${GREEN}6. Select 'Reboot'${NC}"
        echo ""
    fi
    
    echo -e "${YELLOW}The driver will be installed and signed automatically.${NC}"
    echo -e "${YELLOW}Module loading will work after MOK enrollment on reboot.${NC}"
else
    echo -e "${GREEN}✓ Secure Boot is disabled or not supported${NC}"
fi

# Step 7: Install NVIDIA driver
echo -e "${YELLOW}Step 7: Installing NVIDIA driver...${NC}"

# Base installation flags
INSTALL_FLAGS="--dkms --no-x-check --no-cc-version-check"

# Add module signing if Secure Boot is enabled
if [ "$SECURE_BOOT_ENABLED" = true ]; then
    INSTALL_FLAGS="$INSTALL_FLAGS --module-signing-secret-key=/var/lib/shim-signed/mok/MOK.priv --module-signing-public-key=/var/lib/shim-signed/mok/MOK.der"
    echo -e "${YELLOW}Using MOK keys for module signing${NC}"
fi

# Determine installation mode based on GPU configuration
if [ "$IS_MULTI_GPU" = true ]; then
    echo -e "${YELLOW}Installing in compute-only mode (iGPU handles display)...${NC}"
    INSTALL_FLAGS="$INSTALL_FLAGS --no-opengl-files --install-libglvnd"
else
    echo -e "${YELLOW}Installing in standard mode...${NC}"
fi

# Always use silent installation
echo -e "${YELLOW}Running NVIDIA installer with flags: $INSTALL_FLAGS${NC}"
./"${DRIVER_FILE}" --silent $INSTALL_FLAGS

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ NVIDIA driver installed successfully${NC}"
    
    if [ "$SECURE_BOOT_ENABLED" = true ]; then
        echo ""
        echo -e "${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║         IMPORTANT: Secure Boot Next Steps              ║${NC}"
        echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
        echo -e "${YELLOW}The driver is installed but won't load until you:${NC}"
        echo -e "${YELLOW}1. Reboot your system${NC}"
        echo -e "${YELLOW}2. Enroll the MOK key when prompted (blue screen)${NC}"
        echo -e "${YELLOW}3. The driver will then load automatically${NC}"
        echo ""
        echo -e "${GREEN}The kernel modules have been signed with your MOK key.${NC}"
    fi
else
    echo -e "${RED}✗ NVIDIA driver installation failed${NC}"
    
    # Check the log for specific errors
    if [ -f /var/log/nvidia-installer.log ]; then
        if grep -q "The kernel module failed to load" /var/log/nvidia-installer.log; then
            echo -e "${YELLOW}The installation completed but the module couldn't load.${NC}"
            echo -e "${YELLOW}This is expected with Secure Boot enabled.${NC}"
            echo -e "${YELLOW}After rebooting and enrolling the MOK key, the driver will work.${NC}"
        else
            echo -e "${RED}Check /var/log/nvidia-installer.log for details${NC}"
        fi
    fi
    
    if [ "$SECURE_BOOT_ENABLED" = true ]; then
        echo ""
        echo -e "${YELLOW}Alternative options:${NC}"
        echo "  1. Disable Secure Boot in BIOS/UEFI settings"
        echo "  2. Use Ubuntu's pre-signed drivers: sudo ubuntu-drivers install"
    fi
    exit 1
fi

# Step 8: Configure NVIDIA settings
echo -e "${YELLOW}Step 8: Configuring NVIDIA settings...${NC}"

# Set persistence mode
nvidia-smi -pm 1 2>/dev/null || true

# Create udev rules for GPU permissions
cat > /etc/udev/rules.d/99-nvidia.rules << EOF
# NVIDIA GPU compute permissions
KERNEL=="nvidia*", MODE="0666"
KERNEL=="nvidia-uvm*", MODE="0666"
KERNEL=="nvidia-modeset", MODE="0666"
KERNEL=="nvidia-drm", MODE="0666"
EOF

udevadm control --reload-rules
udevadm trigger

echo -e "${GREEN}✓ NVIDIA settings configured${NC}"

# Step 9: Verify installation
echo -e "${YELLOW}Step 9: Verifying installation...${NC}"
if nvidia-smi; then
    echo -e "${GREEN}✓ NVIDIA driver is working!${NC}"
    
    # Show GPU info
    echo ""
    echo -e "${BLUE}GPU Information:${NC}"
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
else
    echo -e "${RED}✗ NVIDIA driver verification failed${NC}"
    echo -e "${YELLOW}The driver may work after a reboot${NC}"
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Installation Complete!                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$IS_MULTI_GPU" = true ]; then
    echo -e "${GREEN}NVIDIA driver installed in compute-only mode.${NC}"
    echo -e "${GREEN}Your Intel iGPU will handle display output.${NC}"
    echo -e "${GREEN}The RTX 5090 is configured for compute tasks only.${NC}"
else
    echo -e "${GREEN}NVIDIA driver installed in standard mode.${NC}"
fi

echo ""
echo -e "${YELLOW}Recommended: Reboot your system to ensure all changes take effect${NC}"
echo ""
echo -e "${YELLOW}After reboot, verify with:${NC}"
echo "  nvidia-smi"
echo "  nvidia-smi -q | grep 'Driver Version'"
echo "  vulkaninfo --summary"
