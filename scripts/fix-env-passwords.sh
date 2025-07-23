#!/bin/bash

# Quick fix for .env password generation issues

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to generate secure passwords
generate_password() {
    local length=${1:-32}
    # Use only alphanumeric to avoid sed issues
    < /dev/urandom tr -dc 'A-Za-z0-9' | head -c$length
}

# Function to generate API keys
generate_api_key() {
    local prefix=${1:-"uc1"}
    echo "${prefix}-$(openssl rand -hex 16)"
}

echo -e "${YELLOW}Fixing .env passwords...${NC}"

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    exit 1
fi

# Backup
cp .env .env.backup.$(date +%s)

# Generate passwords
POSTGRES_PASS=$(generate_password 24)
WEBUI_SECRET=$(generate_password 64)
VLLM_KEY=$(generate_api_key "vllm")
SEARXNG_SECRET=$(generate_password 32)

echo -e "\n${GREEN}Generated credentials:${NC}"
echo "PostgreSQL: ${POSTGRES_PASS}"
echo "vLLM API Key: ${VLLM_KEY}"

# Create new .env with proper escaping
python3 << EOF
import re

with open('.env', 'r') as f:
    content = f.read()

# Replace passwords
replacements = {
    r'POSTGRES_PASSWORD=.*': f'POSTGRES_PASSWORD=${POSTGRES_PASS}',
    r'WEBUI_SECRET_KEY=.*': f'WEBUI_SECRET_KEY=${WEBUI_SECRET}',
    r'VLLM_API_KEY=.*': f'VLLM_API_KEY=${VLLM_KEY}',
    r'SEARXNG_SECRET=.*': f'SEARXNG_SECRET=${SEARXNG_SECRET}'
}

for pattern, replacement in replacements.items():
    content = re.sub(pattern, replacement, content, flags=re.MULTILINE)

with open('.env', 'w') as f:
    f.write(content)

print("✓ Passwords updated successfully!")
EOF