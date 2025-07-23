#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Directory where this script is located (should be project root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${GREEN}UC-1 Pro Deployment Script${NC}"
echo "================================"

# Check for .env file
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env from template...${NC}"
    cp .env.template .env
    echo -e "${RED}Please edit .env file to set passwords!${NC}"
    exit 1
fi

# Load environment variables
set -a
[ -f .env ] && . ./.env
set +a

echo -e "\n${GREEN}Starting UC-1 Pro stack...${NC}"

# Pull images first
echo "Pulling Docker images..."
docker-compose pull

# Build custom services
echo "Building custom services..."
docker-compose build

# Start the stack
echo "Starting services..."
docker-compose up -d

echo -e "\n${GREEN}UC-1 Pro stack is starting!${NC}"
echo ""
echo "Services will be available at:"
echo "  - Open-WebUI: http://localhost:8080"
echo "  - vLLM API: http://localhost:8000/docs"
echo "  - Model Manager: http://localhost:8084"
echo "  - SearXNG: http://localhost:8888"
echo "  - GPU Metrics: http://localhost:9835/metrics"
echo "  - Prometheus: http://localhost:9090"
echo ""
echo "First-time model download may take 10-30 minutes."
echo "Check logs with: docker-compose logs -f vllm"
