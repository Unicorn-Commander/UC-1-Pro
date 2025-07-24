#\!/bin/bash

# Force recreate Model Manager with proper network config

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Recreating Model Manager with proper network configuration${NC}"

# Stop and remove the container completely
echo -e "${YELLOW}Stopping and removing old container...${NC}"
docker compose stop model-manager
docker compose rm -f model-manager

# Rebuild the image to ensure latest code
echo -e "${YELLOW}Rebuilding Model Manager image...${NC}"
docker compose build model-manager

# Recreate with proper config
echo -e "${YELLOW}Starting Model Manager with correct network settings...${NC}"
docker compose up -d model-manager

# Wait a moment for startup
sleep 5

# Check status
echo -e "\n${BLUE}Checking container status:${NC}"
docker compose ps model-manager

echo -e "\n${BLUE}Checking network connectivity:${NC}"
docker inspect unicorn-model-manager  < /dev/null |  grep -A 10 "Networks"

echo -e "\n${BLUE}Checking port mapping:${NC}"
docker port unicorn-model-manager

echo -e "\n${GREEN}Model Manager should now be accessible at:${NC}"
echo "- External: http://localhost:8084"
echo "- Internal: http://unicorn-model-manager:8080"
