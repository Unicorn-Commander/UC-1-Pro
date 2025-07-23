#!/bin/bash

# Fix Docker pull issues with registry timeouts

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Docker Registry Connection Fix${NC}"
echo "================================"

# Function to retry docker pull
retry_pull() {
    local image=$1
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo -e "${YELLOW}Pulling $image (attempt $attempt/$max_attempts)...${NC}"
        if docker pull "$image"; then
            echo -e "${GREEN}✓ Successfully pulled $image${NC}"
            return 0
        else
            echo -e "${RED}Failed to pull $image${NC}"
            if [ $attempt -lt $max_attempts ]; then
                echo "Waiting 10 seconds before retry..."
                sleep 10
            fi
        fi
        ((attempt++))
    done
    
    return 1
}

# Option 1: Try different registry mirrors
echo -e "\n${BLUE}Option 1: Trying with registry mirrors...${NC}"
echo "You can configure Docker to use a mirror by adding to /etc/docker/daemon.json:"
echo '{'
echo '  "registry-mirrors": ['
echo '    "https://mirror.gcr.io",'
echo '    "https://docker.mirrors.ustc.edu.cn"'
echo '  ]'
echo '}'

# Option 2: Increase timeout settings
echo -e "\n${BLUE}Option 2: Increasing Docker timeout...${NC}"
export DOCKER_CLIENT_TIMEOUT=120
export COMPOSE_HTTP_TIMEOUT=120

# Option 3: Pull images one by one with retries
echo -e "\n${BLUE}Option 3: Pulling critical images with retry logic...${NC}"

# List of critical images
IMAGES=(
    "redis:7.4.5-alpine"
    "postgres:16.9-alpine"
    "qdrant/qdrant:v1.15.0"
    "vllm/vllm-openai:v0.9.2"
    "ghcr.io/open-webui/open-webui:main"
)

failed_images=""

for image in "${IMAGES[@]}"; do
    if ! retry_pull "$image"; then
        failed_images="$failed_images\n- $image"
    fi
done

if [ -n "$failed_images" ]; then
    echo -e "\n${RED}Failed to pull some images:${NC}"
    echo -e "$failed_images"
    echo -e "\n${YELLOW}Troubleshooting steps:${NC}"
    echo "1. Check your internet connection"
    echo "2. Try using a VPN if Docker Hub is blocked"
    echo "3. Configure a Docker registry mirror"
    echo "4. Try again later (Docker Hub might be having issues)"
else
    echo -e "\n${GREEN}All critical images pulled successfully!${NC}"
    echo "You can now run ./start.sh"
fi

# Option 4: Use alternative registries
echo -e "\n${BLUE}Alternative: Pull from mirror registries${NC}"
echo "For Qdrant specifically, you can try:"
echo "docker pull docker.mirrors.ustc.edu.cn/qdrant/qdrant:v1.15.0"
echo "docker tag docker.mirrors.ustc.edu.cn/qdrant/qdrant:v1.15.0 qdrant/qdrant:v1.15.0"