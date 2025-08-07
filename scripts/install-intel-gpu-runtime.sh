#!/bin/bash
# Install Intel GPU Runtime for OpenVINO on Ubuntu

echo "Installing Intel GPU compute runtime packages..."

# Add Intel graphics repository
wget -qO - https://repositories.intel.com/graphics/intel-graphics.key | sudo apt-key add -
sudo apt-add-repository 'deb [arch=amd64] https://repositories.intel.com/graphics/ubuntu jammy main'

# Update package list
sudo apt update

# Install Intel GPU runtime packages
sudo apt install -y \
    intel-opencl-icd \
    intel-level-zero-gpu \
    level-zero \
    intel-media-va-driver-non-free \
    libmfx1 \
    libmfxgen1 \
    libvpl2 \
    libegl-mesa0 \
    libegl1-mesa \
    libegl1-mesa-dev \
    libgbm1 \
    libgl1-mesa-dev \
    libgl1-mesa-dri \
    libglapi-mesa \
    libgles2-mesa-dev \
    libglx-mesa0 \
    libigdgmm12 \
    libxatracker2 \
    mesa-va-drivers \
    mesa-vdpau-drivers \
    mesa-vulkan-drivers \
    va-driver-all

# Add current user to video and render groups
sudo usermod -a -G video $USER
sudo usermod -a -G render $USER

echo "Installation complete. Please reboot the system for changes to take effect."
echo "After reboot, check if /dev/dri exists and contains renderD128"