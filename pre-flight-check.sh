#!/bin/bash

# UC-1 Pro Pre-flight Check Script
# Run this before deployment to ensure everything is ready

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}UC-1 Pro Pre-flight Check${NC}"
echo "=========================="
echo ""

ERRORS=0
WARNINGS=0

# Function to check item
check() {
    local status=$1
    local message=$2
    
    if [ "$status" = "ok" ]; then
        echo -e "✅ ${GREEN}${message}${NC}"
    elif [ "$status" = "warning" ]; then
        echo -e "⚠️  ${YELLOW}${message}${NC}"
        ((WARNINGS++))
    else
        echo -e "❌ ${RED}${message}${NC}"
        ((ERRORS++))
    fi
}

# Check for .env file
if [ -f .env ]; then
    check "ok" ".env file exists"
    
    # Check for default passwords
    if grep -q "changeme\|CHANGE_ME" .env; then
        check "error" ".env contains default passwords - MUST be changed!"
    else
        check "ok" ".env passwords have been updated"
    fi
else
    check "error" ".env file missing - run ./setup-uc1-pro.sh first"
fi

# Check Docker installation
if command -v docker &> /dev/null; then
    check "ok" "Docker is installed"
else
    check "error" "Docker is not installed"
fi

# Check Docker Compose
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    check "ok" "Docker Compose is available"
else
    check "error" "Docker Compose is not installed"
fi

# Check NVIDIA Docker runtime
if docker info 2>/dev/null | grep -q nvidia; then
    check "ok" "NVIDIA Docker runtime is installed"
else
    check "warning" "NVIDIA Docker runtime not detected - GPU features won't work"
fi

# Check for required directories
for dir in scripts services config backups; do
    if [ -d "$dir" ]; then
        check "ok" "Directory $dir exists"
    else
        check "error" "Directory $dir is missing"
    fi
done

# Check script permissions
SCRIPTS=(
    "setup-uc1-pro.sh"
    "scripts/start.sh"
    "scripts/backup.sh"
    "scripts/health-check.sh"
    "scripts/install-dependencies.sh"
    "scripts/automated-backup.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        check "ok" "$script is executable"
    elif [ -f "$script" ]; then
        check "warning" "$script exists but is not executable - run: chmod +x $script"
    else
        check "error" "$script is missing"
    fi
done

# Check disk space
AVAILABLE_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -gt 100 ]; then
    check "ok" "Sufficient disk space available (${AVAILABLE_SPACE}GB)"
else
    check "warning" "Low disk space (${AVAILABLE_SPACE}GB) - recommend at least 100GB"
fi

# Check system resources
TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
if [ "$TOTAL_RAM" -ge 64 ]; then
    check "ok" "Sufficient RAM available (${TOTAL_RAM}GB)"
elif [ "$TOTAL_RAM" -ge 32 ]; then
    check "warning" "RAM is below recommended (${TOTAL_RAM}GB) - 96GB recommended"
else
    check "error" "Insufficient RAM (${TOTAL_RAM}GB) - minimum 32GB required"
fi

# Summary
echo ""
echo "=========================="
echo -e "${BLUE}Pre-flight Check Summary${NC}"
echo "=========================="

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}All checks passed! Ready for deployment.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run: ./scripts/start.sh"
    echo "2. Monitor startup: docker-compose logs -f"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}Checks passed with $WARNINGS warnings.${NC}"
    echo "Review warnings above before proceeding."
    exit 0
else
    echo -e "${RED}Found $ERRORS errors and $WARNINGS warnings.${NC}"
    echo "Please fix errors before deployment."
    exit 1
fi