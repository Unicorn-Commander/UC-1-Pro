# UC-1 Pro Server Bootstrap Scripts 🦄

Complete automation for transforming a fresh Ubuntu Server 24.04 into an enterprise-grade AI infrastructure platform.

## 🚀 Quick Start

For a completely fresh Ubuntu Server 24.04 installation:

```bash
sudo ./00-bootstrap.sh
```

This master script will automatically run all setup steps and handle the required reboots.

## 📋 Individual Scripts

If you prefer to run steps individually or need to troubleshoot:

### 01-nvidia-driver.sh
- **Purpose**: Install NVIDIA RTX 5090 drivers + Vulkan support
- **Features**: 
  - Blacklists nouveau driver (fixes conflicts)
  - Downloads and prepares NVIDIA driver 570.172.08
  - Installs Vulkan packages for headless servers
  - Updates initramfs
- **Requires**: Reboot after installation
- **Usage**: `sudo ./01-nvidia-driver.sh`

### 02-docker.sh  
- **Purpose**: Install Docker + NVIDIA Container Toolkit
- **Features**:
  - Installs latest Docker CE
  - Configures NVIDIA Container Runtime
  - Sets up proper daemon configuration
  - Tests GPU container access
- **Prerequisites**: NVIDIA driver must be installed
- **Usage**: `sudo ./02-docker.sh`

### 03-system-deps.sh
- **Purpose**: Install system dependencies + AI optimizations  
- **Features**:
  - Development tools (Python, Node.js, Git, etc.)
  - AI/ML libraries (FFmpeg, audio processing, etc.)
  - System monitoring tools (htop, nvtop, glances)
  - Kernel optimizations for AI workloads
  - Firewall configuration for UC-1 Pro ports
  - Useful shell aliases and improvements
- **Usage**: `sudo ./03-system-deps.sh`

### 99-verify-setup.sh
- **Purpose**: Comprehensive system verification
- **Features**:
  - Tests all installed components
  - Performance benchmarks
  - Detailed system information
  - Health check for UC-1 Pro readiness
- **Usage**: `sudo ./99-verify-setup.sh` (or as regular user)

## 🔄 Bootstrap Process Flow

```
Fresh Ubuntu Server 24.04
         ↓
    00-bootstrap.sh
         ↓
   01-nvidia-driver.sh
         ↓
    🔄 REBOOT #1
         ↓
    02-docker.sh
         ↓
   03-system-deps.sh  
         ↓
   99-verify-setup.sh
         ↓
    🔄 REBOOT #2 (optional)
         ↓
    Ready for UC-1 Pro! 🎉
```

## 🛠️ What Gets Installed

### NVIDIA Stack
- NVIDIA Driver 570.172.08
- CUDA 12.8 support
- Vulkan 1.3+ runtime
- NVIDIA Container Toolkit
- Nouveau driver blacklisting

### Docker Ecosystem  
- Docker CE (latest)
- Docker Compose V2
- NVIDIA Container Runtime
- Optimized daemon configuration
- Log rotation setup

### Development Tools
- Python 3.11+ ecosystem
- Node.js LTS + npm
- Git, curl, wget, build-essential
- Hugging Face CLI
- System monitoring tools

### AI/ML Libraries
- FFmpeg with GPU acceleration
- Audio processing libraries  
- OpenGL/Vulkan runtime
- Scientific computing dependencies

### System Optimizations
- 16GB shared memory for containers
- Kernel parameters tuned for ML
- Docker log rotation
- Firewall with UC-1 Pro ports
- Enhanced shell environment

## 🔧 Troubleshooting

### Common Issues

**GPU not detected after driver install:**
```bash
# Check if nouveau is still loaded
lsmod | grep nouveau

# If yes, ensure blacklist worked
sudo update-initramfs -u
sudo reboot
```

**Docker can't access GPU:**
```bash
# Verify NVIDIA Container Runtime
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi

# Check Docker daemon config
sudo cat /etc/docker/daemon.json
```

**Permission denied for docker:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in
```

### Verification Commands

```bash
# Quick system check
nvidia-smi
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
vulkaninfo --summary

# Full verification
sudo ./99-verify-setup.sh
```

## 📊 System Requirements

### Minimum Hardware
- NVIDIA RTX 5090 (32GB VRAM)
- 64GB RAM recommended  
- 1TB+ NVMe storage
- 8+ CPU cores

### Software Requirements
- Ubuntu Server 24.04 LTS
- Internet connection for downloads
- Root/sudo access

## 🔐 Security Features

- UFW firewall enabled with UC-1 Pro ports
- Docker containers run in isolated networks
- No unnecessary services installed
- Secure package sources (GPG verified)
- Log rotation to prevent disk filling

## 🦄 UC-1 Pro Integration

After bootstrap completion:

```bash
# Clone UC-1 Pro repository
git clone https://github.com/your-org/UC-1-Pro.git
cd UC-1-Pro

# Run UC-1 Pro installer  
./install.sh

# Start all services
./start.sh

# Access web interface
# http://your-server:8080
```

## 📝 Notes

- **Reboot Requirements**: Bootstrap requires 2 reboots (handled automatically)
- **Network Access**: Scripts download packages and containers
- **Time Estimate**: 15-20 minutes total (including downloads)
- **Disk Usage**: ~10GB for all tools and dependencies
- **Logging**: All operations logged to system journal

## 🆘 Support

If you encounter issues:

1. Run full verification: `sudo ./99-verify-setup.sh`
2. Check system logs: `sudo journalctl -xeu docker`
3. Verify GPU: `nvidia-smi`  
4. Test containers: `docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi`

For UC-1 Pro specific issues, see the main project documentation.

---

## Hardware Information

**Motherboard**: ASUS TUF GAMING Z790-PLUS WIFI  
**Latest BIOS**: Version 1820 (2025/05/21)  
**System BIOS**: Version 1604 (12/15/2023) - Update recommended

**File**: TUF-GAMING-Z790-PLUS-WIFI-ASUS-1820.CAP  
Store BIOS file in `Drivers/BIOS/` directory.

---

**Magic Unicorn Unconventional Technology & Stuff Inc** 🦄  
Transform your server into an AI powerhouse with UC-1 Pro!
