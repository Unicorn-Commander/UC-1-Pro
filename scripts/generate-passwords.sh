#!/bin/bash

# UC-1 Pro Password Generator
# Generates secure passwords for all services

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to generate secure passwords
generate_password() {
    local length=${1:-32}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

# Function to generate API keys
generate_api_key() {
    local prefix=${1:-"uc1"}
    echo "${prefix}-$(openssl rand -hex 16)"
}

echo -e "${BLUE}UC-1 Pro Password Generator${NC}"
echo "==========================="
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo "Run ./install.sh first to create the .env file"
    exit 1
fi

# Backup current .env
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
cp .env .env.backup.${TIMESTAMP}
echo -e "${GREEN}✓ Created backup: .env.backup.${TIMESTAMP}${NC}"

# Generate all passwords
echo -e "\n${YELLOW}Generating secure passwords...${NC}"

POSTGRES_PASS=$(generate_password 24)
WEBUI_SECRET=$(generate_password 64)
VLLM_KEY=$(generate_api_key "vllm")
SEARXNG_SECRET=$(generate_password 32)
COMFYUI_KEY=$(generate_api_key "comfy")
GRAFANA_PASS=$(generate_password 16)
PGADMIN_PASS=$(generate_password 16)
CODE_SERVER_PASS=$(generate_password 16)
JUPYTER_TOKEN=$(generate_password 32)

# Update .env file
echo -e "${YELLOW}Updating .env file...${NC}"

# Use different sed syntax for macOS vs Linux
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=${POSTGRES_PASS}/" .env
    sed -i '' "s/WEBUI_SECRET_KEY=.*/WEBUI_SECRET_KEY=${WEBUI_SECRET}/" .env
    sed -i '' "s/VLLM_API_KEY=.*/VLLM_API_KEY=${VLLM_KEY}/" .env
    sed -i '' "s/SEARXNG_SECRET=.*/SEARXNG_SECRET=${SEARXNG_SECRET}/" .env
    sed -i '' "s/COMFYUI_API_KEY=.*/COMFYUI_API_KEY=${COMFYUI_KEY}/" .env
    sed -i '' "s/GRAFANA_PASSWORD=.*/GRAFANA_PASSWORD=${GRAFANA_PASS}/" .env
    sed -i '' "s/PGADMIN_PASSWORD=.*/PGADMIN_PASSWORD=${PGADMIN_PASS}/" .env
    sed -i '' "s/CODE_SERVER_PASSWORD=.*/CODE_SERVER_PASSWORD=${CODE_SERVER_PASS}/" .env
    sed -i '' "s/JUPYTER_TOKEN=.*/JUPYTER_TOKEN=${JUPYTER_TOKEN}/" .env
else
    # Linux
    sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=${POSTGRES_PASS}/" .env
    sed -i "s/WEBUI_SECRET_KEY=.*/WEBUI_SECRET_KEY=${WEBUI_SECRET}/" .env
    sed -i "s/VLLM_API_KEY=.*/VLLM_API_KEY=${VLLM_KEY}/" .env
    sed -i "s/SEARXNG_SECRET=.*/SEARXNG_SECRET=${SEARXNG_SECRET}/" .env
    sed -i "s/COMFYUI_API_KEY=.*/COMFYUI_API_KEY=${COMFYUI_KEY}/" .env
    sed -i "s/GRAFANA_PASSWORD=.*/GRAFANA_PASSWORD=${GRAFANA_PASS}/" .env
    sed -i "s/PGADMIN_PASSWORD=.*/PGADMIN_PASSWORD=${PGADMIN_PASS}/" .env
    sed -i "s/CODE_SERVER_PASSWORD=.*/CODE_SERVER_PASSWORD=${CODE_SERVER_PASS}/" .env
    sed -i "s/JUPYTER_TOKEN=.*/JUPYTER_TOKEN=${JUPYTER_TOKEN}/" .env
fi

echo -e "${GREEN}✓ Passwords updated successfully!${NC}"

# Display credentials
echo ""
echo -e "${BLUE}Generated Credentials${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${YELLOW}Core Services:${NC}"
echo "  PostgreSQL:     unicorn / ${POSTGRES_PASS}"
echo "  vLLM API Key:   ${VLLM_KEY}"
echo ""
echo -e "${YELLOW}Extensions:${NC}"
echo "  Grafana:        admin / ${GRAFANA_PASS}"
echo "  pgAdmin:        admin@uc1.local / ${PGADMIN_PASS}"
echo "  Code-Server:    ${CODE_SERVER_PASS}"
echo "  Jupyter Token:  ${JUPYTER_TOKEN}"
echo "  ComfyUI Key:    ${COMFYUI_KEY}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Save credentials to secure file
CREDS_FILE="credentials-${TIMESTAMP}.txt"
cat > ${CREDS_FILE} << EOF
UC-1 Pro Credentials
Generated: $(date)
====================

Core Services:
  PostgreSQL:     unicorn / ${POSTGRES_PASS}
  vLLM API Key:   ${VLLM_KEY}

Extensions:
  Grafana:        admin / ${GRAFANA_PASS}
  pgAdmin:        admin@uc1.local / ${PGADMIN_PASS}
  Code-Server:    ${CODE_SERVER_PASS}
  Jupyter Token:  ${JUPYTER_TOKEN}
  ComfyUI Key:    ${COMFYUI_KEY}

Internal Keys (not shown to users):
  WebUI Secret:   ${WEBUI_SECRET}
  SearXNG Secret: ${SEARXNG_SECRET}
EOF

chmod 600 ${CREDS_FILE}
echo ""
echo -e "${GREEN}✓ Credentials saved to: ${CREDS_FILE}${NC}"
echo -e "${YELLOW}  Keep this file secure and delete after saving elsewhere!${NC}"

# Remind about restarting services
echo ""
echo -e "${YELLOW}Note: If services are running, restart them to use new passwords:${NC}"
echo "  docker-compose down && docker-compose up -d"