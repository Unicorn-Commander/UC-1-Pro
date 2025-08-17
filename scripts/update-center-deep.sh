#!/bin/bash

# Update Center-Deep to use the new Unicorn-Commander repository
# This script updates the local Center-Deep installation to pull from the new repository location

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}     Center-Deep Repository Update Script       ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Navigate to UC-1 Pro directory
cd /home/ucadmin/UC-1-Pro

# Check if Center-Deep directory exists
if [ -d "Center-Deep" ]; then
    echo -e "${YELLOW}⚠️  Updating existing Center-Deep installation...${NC}"
    cd Center-Deep
    
    # Get current remote URL
    CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "none")
    echo -e "${BLUE}Current remote: ${CURRENT_REMOTE}${NC}"
    
    # Update to new repository URL
    echo -e "${BLUE}🔄 Updating repository remote...${NC}"
    git remote set-url origin https://github.com/Unicorn-Commander/Center-Deep.git
    
    # Fetch latest changes
    echo -e "${BLUE}📥 Fetching latest changes...${NC}"
    git fetch origin
    
    # Pull latest changes
    echo -e "${BLUE}📦 Pulling latest updates...${NC}"
    git pull origin main
    
    echo -e "${GREEN}✅ Center-Deep repository updated successfully!${NC}"
    
else
    echo -e "${YELLOW}⚠️  Center-Deep directory not found. Cloning from new repository...${NC}"
    
    # Clone from new repository
    git clone https://github.com/Unicorn-Commander/Center-Deep.git Center-Deep
    
    echo -e "${GREEN}✅ Center-Deep cloned successfully!${NC}"
fi

cd /home/ucadmin/UC-1-Pro

# Check docker-compose configuration
echo ""
echo -e "${BLUE}🐳 Docker Compose Configuration Options:${NC}"
echo ""
echo -e "${GREEN}Option 1: Local Development (Current)${NC}"
echo "  Uses: ./Center-Deep directory"
echo "  Command: docker-compose up -d unicorn-searxng"
echo ""
echo -e "${GREEN}Option 2: Repository Build${NC}"
echo "  Uses: GitHub repository directly"
echo "  Command: docker-compose --profile production -f docker-compose.center-deep.yml up -d"
echo ""
echo -e "${GREEN}Option 3: Update Existing Service${NC}"
echo "  Rebuild with latest code:"
echo "  Command: docker-compose build unicorn-searxng && docker-compose up -d unicorn-searxng"
echo ""

# Ask if user wants to rebuild now
read -p "Would you like to rebuild Center-Deep container now? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}🔨 Rebuilding Center-Deep container...${NC}"
    docker-compose build unicorn-searxng
    
    echo -e "${BLUE}🚀 Restarting Center-Deep service...${NC}"
    docker-compose up -d unicorn-searxng
    
    echo -e "${GREEN}✅ Center-Deep container rebuilt and restarted!${NC}"
else
    echo -e "${YELLOW}ℹ️  Skipping container rebuild. Run the following when ready:${NC}"
    echo "  docker-compose build unicorn-searxng"
    echo "  docker-compose up -d unicorn-searxng"
fi

echo ""
echo -e "${GREEN}✅ Update complete!${NC}"
echo ""
echo -e "${BLUE}Center-Deep Pro is now pulling from:${NC}"
echo -e "${GREEN}https://github.com/Unicorn-Commander/Center-Deep${NC}"
echo ""
echo -e "${BLUE}Access Center-Deep at:${NC}"
echo -e "${GREEN}http://localhost:8888${NC}"