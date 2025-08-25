#!/bin/bash

# UC-1 Pro Domain Configuration Script
# This script helps update the domain configuration for remote access

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          UC-1 Pro Domain Configuration                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo "Please run the installer first: ./install.sh"
    exit 1
fi

# Backup .env
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
echo -e "${GREEN}✓ Created backup of .env${NC}"

# Get current configuration
source .env
CURRENT_HOST="${EXTERNAL_HOST:-localhost}"
CURRENT_PROTOCOL="${EXTERNAL_PROTOCOL:-http}"

echo ""
echo "Current configuration:"
echo "  Host: ${BLUE}${CURRENT_HOST}${NC}"
echo "  Protocol: ${BLUE}${CURRENT_PROTOCOL}${NC}"
echo ""

# Ask for new configuration
echo "Enter new domain configuration (press Enter to keep current):"
read -p "Domain or IP address [${CURRENT_HOST}]: " NEW_HOST
NEW_HOST="${NEW_HOST:-$CURRENT_HOST}"

if [ "$NEW_HOST" != "localhost" ]; then
    read -p "Use HTTPS? (y/N) [current: ${CURRENT_PROTOCOL}]: " USE_HTTPS
    if [[ $USE_HTTPS =~ ^[Yy]$ ]]; then
        NEW_PROTOCOL="https"
    else
        NEW_PROTOCOL="http"
    fi
else
    NEW_PROTOCOL="http"
fi

# Update .env file
sed -i "s|^EXTERNAL_HOST=.*|EXTERNAL_HOST=${NEW_HOST}|" .env
sed -i "s|^EXTERNAL_PROTOCOL=.*|EXTERNAL_PROTOCOL=${NEW_PROTOCOL}|" .env

echo ""
echo -e "${GREEN}✓ Configuration updated!${NC}"
echo ""

# Show new URLs
echo "Services will be available at:"
if [ "$NEW_HOST" != "localhost" ]; then
    echo "  - Open-WebUI: ${BLUE}${NEW_PROTOCOL}://chat.${NEW_HOST}${NC}"
    echo "  - Center-Deep Search: ${BLUE}${NEW_PROTOCOL}://search.${NEW_HOST}${NC}"
    echo "  - Admin Dashboard: ${BLUE}${NEW_PROTOCOL}://${NEW_HOST}:8084${NC}"
    echo "  - vLLM API: ${BLUE}${NEW_PROTOCOL}://${NEW_HOST}:8000${NC}"
    echo ""
    echo -e "${YELLOW}Note: Configure these DNS records:${NC}"
    echo "  A    chat.${NEW_HOST}    -> Your server IP"
    echo "  A    search.${NEW_HOST}  -> Your server IP"
    echo ""
    echo "Or use a wildcard record:"
    echo "  A    *.${NEW_HOST}       -> Your server IP"
else
    echo "  - Open-WebUI: ${BLUE}http://localhost:8080${NC}"
    echo "  - Center-Deep Search: ${BLUE}http://localhost:8888${NC}"
    echo "  - Admin Dashboard: ${BLUE}http://localhost:8084${NC}"
    echo "  - vLLM API: ${BLUE}http://localhost:8000${NC}"
fi

echo ""
echo -e "${YELLOW}Important: Restart the Ops Center for changes to take effect:${NC}"
echo "  docker-compose restart ops-center"
echo ""
echo "Or restart all services:"
echo "  docker-compose down && ./start.sh"