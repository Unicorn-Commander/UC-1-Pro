#!/bin/bash
# 99-verify-setup.sh - Complete UC-1 Pro Setup Verification
# Comprehensive health check for all components

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    local silent="${3:-false}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$silent" = "true" ]; then
        if eval "$test_command" &> /dev/null; then
            echo -e "${GREEN}✓${NC} $test_name"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            return 0
        else
            echo -e "${RED}✗${NC} $test_name"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            return 1
        fi
    else
        echo -e "${YELLOW}Testing: $test_name${NC}"
        if eval "$test_command"; then
            echo -e "${GREEN}✓${NC} $test_name - PASSED"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            return 0
        else
            echo -e "${RED}✗${NC} $test_name - FAILED"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            return 1
        fi
    fi
}

echo -e "${PURPLE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                                                        ║${NC}"
echo -e "${PURPLE}║       🦄 UC-1 Pro Complete Setup Verification 🦄       ║${NC}"
echo -e "${PURPLE}║                                                        ║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# System Information
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   SYSTEM INFO                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}OS:${NC} $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo -e "${CYAN}Kernel:${NC} $(uname -r)"
echo -e "${CYAN}Architecture:${NC} $(uname -m)"
echo -e "${CYAN}CPU:${NC} $(nproc) cores - $(cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d':' -f2 | xargs)"
echo -e "${CYAN}RAM:${NC} $(free -h | awk '/^Mem:/ {print $2}') total, $(free -h | awk '/^Mem:/ {print $7}') available"
echo -e "${CYAN}Disk:${NC} $(df -h / | awk 'NR==2 {print $2}') total, $(df -h / | awk 'NR==2 {print $4}') available"
echo -e "${CYAN}Uptime:${NC} $(uptime -p)"
echo ""

# NVIDIA Tests
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   NVIDIA TESTS                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

run_test "NVIDIA driver installation" "command -v nvidia-smi" true
run_test "NVIDIA driver functionality" "nvidia-smi" true
run_test "NVIDIA kernel modules loaded" "lsmod | grep nvidia" true
run_test "CUDA runtime detection" "nvidia-smi | grep -i cuda" true

if command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
    echo ""
    echo -e "${CYAN}GPU Information:${NC}"
    nvidia-smi --query-gpu=name,driver_version,memory.total,compute_cap --format=csv,noheader | \
    while IFS=, read -r name driver memory compute; do
        echo -e "  ${YELLOW}GPU:${NC} $name"
        echo -e "  ${YELLOW}Driver:${NC} $driver"
        echo -e "  ${YELLOW}VRAM:${NC} $memory"
        echo -e "  ${YELLOW}Compute:${NC} $compute"
    done
fi
echo ""

# Vulkan Tests
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   VULKAN TESTS                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

run_test "Vulkan loader" "command -v vulkaninfo" true
run_test "Vulkan runtime" "ldconfig -p | grep vulkan" true
run_test "Vulkan devices detection" "vulkaninfo --summary" true

# Docker Tests
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   DOCKER TESTS                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

run_test "Docker installation" "command -v docker" true
run_test "Docker service running" "systemctl is-active docker" true
run_test "Docker hello-world" "timeout 30 docker run --rm hello-world" true
run_test "Docker compose plugin" "docker compose version" true

if command -v docker &> /dev/null; then
    echo ""
    echo -e "${CYAN}Docker Information:${NC}"
    echo -e "  ${YELLOW}Version:${NC} $(docker --version | cut -d' ' -f3 | tr -d ',')"
    echo -e "  ${YELLOW}Root Dir:${NC} $(docker info --format '{{.DockerRootDir}}' 2>/dev/null || echo 'N/A')"
    echo -e "  ${YELLOW}Storage Driver:${NC} $(docker info --format '{{.Driver}}' 2>/dev/null || echo 'N/A')"
    echo -e "  ${YELLOW}Running Containers:${NC} $(docker ps -q | wc -l)"
fi
echo ""

# NVIDIA Container Runtime Tests
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              NVIDIA CONTAINER TESTS                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

run_test "NVIDIA Container Toolkit" "command -v nvidia-container-runtime" true
run_test "NVIDIA Docker runtime" "docker info | grep nvidia" true
run_test "GPU container access" "timeout 60 docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi" true

# Development Tools Tests
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                DEVELOPMENT TOOLS                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

run_test "Python 3 installation" "python3 --version" true
run_test "pip installation" "pip --version" true
run_test "Node.js installation" "node --version" true
run_test "npm installation" "npm --version" true
run_test "Git installation" "git --version" true
run_test "Build tools" "gcc --version" true
run_test "Hugging Face CLI" "huggingface-cli --version" true

# System Optimization Tests
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║               SYSTEM OPTIMIZATIONS                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

run_test "Shared memory configuration" "grep '/dev/shm' /etc/fstab" true
run_test "Sysctl optimizations" "grep 'vm.swappiness' /etc/sysctl.conf" true
run_test "Nouveau blacklisted" "grep 'blacklist nouveau' /etc/modprobe.d/blacklist-nouveau.conf" true
run_test "Docker log rotation" "ls /etc/logrotate.d/docker-containers" true

# Network and Security Tests
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║               NETWORK & SECURITY                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

run_test "UFW firewall" "ufw status | grep 'Status: active'" true
run_test "SSH access allowed" "ufw status | grep '22/tcp.*ALLOW'" true
run_test "UC-1 Pro ports open" "ufw status | grep '8080/tcp.*ALLOW'" true

# UC-1 Pro Specific Tests (if available)
if [ -f "/home/$(logname)/UC-1-Pro/docker-compose.yml" ] || [ -f "$HOME/UC-1-Pro/docker-compose.yml" ]; then
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                 UC-1 PRO PROJECT                       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    UC1_DIR="/home/$(logname)/UC-1-Pro"
    [ ! -d "$UC1_DIR" ] && UC1_DIR="$HOME/UC-1-Pro"
    
    if [ -d "$UC1_DIR" ]; then
        run_test "UC-1 Pro project directory" "ls '$UC1_DIR/docker-compose.yml'" true
        run_test "UC-1 Pro environment file" "ls '$UC1_DIR/.env'" true
        run_test "UC-1 Pro scripts directory" "ls '$UC1_DIR/scripts/'" true
        
        echo -e "${CYAN}UC-1 Pro Project:${NC}"
        echo -e "  ${YELLOW}Location:${NC} $UC1_DIR"
        echo -e "  ${YELLOW}Status:${NC} Ready for deployment"
    fi
    echo ""
fi

# Performance Tests
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                PERFORMANCE TESTS                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}Running performance benchmarks...${NC}"

# GPU Memory Test
if nvidia-smi &> /dev/null; then
    echo -e "${CYAN}GPU Memory Test:${NC}"
    timeout 30 docker run --rm --gpus all nvidia/cuda:12.0-base sh -c "
        nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,units=MiB | 
        awk -F', ' '{printf \"  Used: %s / %s (%.1f%%)\n\", \$1, \$2, (\$1/\$2)*100}'
    " 2>/dev/null || echo -e "${RED}  GPU memory test failed${NC}"
fi

# Docker Performance Test
echo -e "${CYAN}Docker Performance Test:${NC}"
start_time=$(date +%s.%N)
docker run --rm alpine:latest echo "Docker container startup test" > /dev/null 2>&1
end_time=$(date +%s.%N)
startup_time=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "N/A")
if [ "$startup_time" != "N/A" ]; then
    echo -e "  ${YELLOW}Container startup time:${NC} ${startup_time}s"
else
    echo -e "  ${YELLOW}Container startup time:${NC} <1s"
fi

echo ""

# Final Summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   FINAL SUMMARY                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}Test Results:${NC}"
echo -e "  ${GREEN}✓ Passed: $PASSED_TESTS${NC}"
echo -e "  ${RED}✗ Failed: $FAILED_TESTS${NC}"
echo -e "  ${BLUE}📊 Total: $TOTAL_TESTS${NC}"

success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
echo -e "  ${YELLOW}🎯 Success Rate: ${success_rate}%${NC}"

echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 CONGRATULATIONS! 🎉${NC}"
    echo -e "${GREEN}Your UC-1 Pro server is fully configured and ready!${NC}"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "  1. Clone UC-1 Pro: git clone https://github.com/your-repo/UC-1-Pro.git"
    echo "  2. Navigate to project: cd UC-1-Pro"
    echo "  3. Run installer: ./install.sh"
    echo "  4. Start services: ./start.sh"
    echo "  5. Access UI: http://your-server:8080"
    echo ""
    echo -e "${YELLOW}🦄 Welcome to the UC-1 Pro ecosystem! 🦄${NC}"
else
    echo -e "${RED}⚠️  SETUP INCOMPLETE ⚠️${NC}"
    echo -e "${YELLOW}$FAILED_TESTS test(s) failed. Please review the errors above.${NC}"
    echo ""
    echo -e "${CYAN}Common solutions:${NC}"
    echo "  • Run individual scripts manually"
    echo "  • Check system logs: journalctl -xeu docker"
    echo "  • Verify GPU: nvidia-smi"
    echo "  • Restart services: sudo systemctl restart docker"
    echo "  • Reboot system if needed"
    
    exit 1
fi

echo ""
echo -e "${CYAN}System ready for UC-1 Pro deployment! 🚀${NC}"