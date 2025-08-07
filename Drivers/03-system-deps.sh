#!/bin/bash
# 03-system-deps.sh - System Dependencies Installation Script
# For UC-1 Pro - Ubuntu Server 24.04

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              System Dependencies Installation           ║${NC}"
echo -e "${BLUE}║               For UC-1 Pro AI Server                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# Step 1: Update system packages
echo -e "${YELLOW}Step 1: Updating system packages...${NC}"
apt-get update && apt-get upgrade -y
echo -e "${GREEN}✓ System packages updated${NC}"

# Step 2: Install essential development tools
echo -e "${YELLOW}Step 2: Installing development tools...${NC}"
apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    htop \
    tree \
    jq \
    vim \
    nano \
    tmux \
    screen \
    rsync \
    zip \
    unrar
echo -e "${GREEN}✓ Development tools installed${NC}"

# Step 3: Install Python ecosystem
echo -e "${YELLOW}Step 3: Installing Python ecosystem...${NC}"
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python-is-python3
    
# Update pip to latest version
python3 -m pip install --upgrade pip setuptools wheel
echo -e "${GREEN}✓ Python ecosystem installed${NC}"

# Step 4: Install Node.js (for web interfaces)
echo -e "${YELLOW}Step 4: Installing Node.js...${NC}"
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    apt-get install -y nodejs
    echo -e "${GREEN}✓ Node.js installed${NC}"
else
    echo -e "${GREEN}✓ Node.js already installed${NC}"
fi

# Step 5: Install system monitoring tools
echo -e "${YELLOW}Step 5: Installing monitoring tools...${NC}"
apt-get install -y \
    iotop \
    iftop \
    nethogs \
    glances \
    lm-sensors \
    smartmontools \
    nvtop
echo -e "${GREEN}✓ Monitoring tools installed${NC}"

# Step 6: Install network tools
echo -e "${YELLOW}Step 6: Installing network tools...${NC}"
apt-get install -y \
    net-tools \
    iputils-ping \
    traceroute \
    nmap \
    telnet \
    netcat-openbsd \
    ufw
echo -e "${GREEN}✓ Network tools installed${NC}"

# Step 7: Install media and AI libraries
echo -e "${YELLOW}Step 7: Installing media and AI libraries...${NC}"
apt-get install -y \
    ffmpeg \
    libsm6 \
    libxext6 \
    libfontconfig1 \
    libxrender1 \
    libgl1-mesa-glx \
    libasound2-dev \
    portaudio19-dev \
    libportaudio2 \
    libsndfile1-dev \
    espeak-ng \
    espeak-ng-data
echo -e "${GREEN}✓ Media and AI libraries installed${NC}"

# Step 8: Configure firewall basics
echo -e "${YELLOW}Step 8: Configuring basic firewall...${NC}"
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 8080/tcp  # Open-WebUI
ufw allow 8000/tcp  # vLLM
ufw allow 8888/tcp  # SearXNG
echo -e "${GREEN}✓ Basic firewall configured${NC}"

# Step 9: Set up useful aliases and bash improvements
echo -e "${YELLOW}Step 9: Setting up shell improvements...${NC}"
cat >> /etc/bash.bashrc << 'EOF'

# UC-1 Pro custom aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias gpu='nvidia-smi'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dlog='docker-compose logs -f'
alias dcup='docker-compose up -d'
alias dcdown='docker-compose down'
alias dcrestart='docker-compose restart'
alias ucstatus='cd ~/UC-1-Pro && make status'
alias uclogs='cd ~/UC-1-Pro && make logs'
alias uchealth='cd ~/UC-1-Pro && ./scripts/health-check-detailed.sh'

# Enhanced prompt with git branch
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOF
echo -e "${GREEN}✓ Shell improvements added${NC}"

# Step 10: Create useful directories
echo -e "${YELLOW}Step 10: Creating project directories...${NC}"
mkdir -p /opt/uc1-pro/{models,data,logs,backups}
chown -R $SUDO_USER:$SUDO_USER /opt/uc1-pro/ 2>/dev/null || true
mkdir -p /home/$SUDO_USER/{projects,scripts,downloads} 2>/dev/null || true
chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/{projects,scripts,downloads} 2>/dev/null || true
echo -e "${GREEN}✓ Project directories created${NC}"

# Step 11: Install Hugging Face CLI (for model downloads)
echo -e "${YELLOW}Step 11: Installing Hugging Face CLI...${NC}"
python3 -m pip install huggingface_hub[cli]
echo -e "${GREEN}✓ Hugging Face CLI installed${NC}"

# Step 12: System optimizations for AI workloads
echo -e "${YELLOW}Step 12: Applying AI workload optimizations...${NC}"

# Increase shared memory for AI containers
echo 'tmpfs /dev/shm tmpfs defaults,size=16G 0 0' >> /etc/fstab

# Optimize kernel parameters for AI/ML
cat >> /etc/sysctl.conf << 'EOF'

# UC-1 Pro AI optimizations
vm.swappiness=10
vm.dirty_ratio=15
vm.dirty_background_ratio=5
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 32768 134217728
net.ipv4.tcp_wmem=4096 32768 134217728
EOF

sysctl -p
echo -e "${GREEN}✓ AI workload optimizations applied${NC}"

# Step 13: Set up log rotation for Docker
echo -e "${YELLOW}Step 13: Configuring log rotation...${NC}"
cat > /etc/logrotate.d/docker-containers << 'EOF'
/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    size=100M
    missingok
    delaycompress
    copytruncate
}
EOF
echo -e "${GREEN}✓ Log rotation configured${NC}"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    VERIFICATION                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verify installations
echo -e "${YELLOW}Verifying installations...${NC}"
echo -e "Python: $(python3 --version 2>&1)"
echo -e "Node.js: $(node --version 2>&1)"
echo -e "Docker: $(docker --version 2>&1)"
echo -e "Git: $(git --version 2>&1)"
echo -e "FFmpeg: $(ffmpeg -version 2>&1 | head -1)"

echo ""
echo -e "${GREEN}System dependencies installation complete! 🛠️${NC}"
echo ""
echo -e "${YELLOW}System optimizations applied:${NC}"
echo "  • 16GB shared memory for AI containers"
echo "  • Kernel parameters tuned for ML workloads"
echo "  • Docker log rotation configured"
echo "  • Firewall with UC-1 Pro ports open"
echo "  • Useful aliases and shell improvements"
echo ""
echo -e "${YELLOW}Reboot recommended to apply all optimizations${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Reboot the system: sudo reboot"
echo "  2. Clone UC-1 Pro repository"
echo "  3. Run: cd UC-1-Pro && ./install.sh"