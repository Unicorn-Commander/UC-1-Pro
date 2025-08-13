#!/bin/bash

# UC-1 Pro Traefik Auth Proxy Setup Script
# Configures Traefik reverse proxy with Authentik SSO integration

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔐 UC-1 Pro Traefik Auth Proxy Setup${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo

# Check if Authentik is running
AUTHENTIK_URL="http://localhost:9005"
if ! curl -s -f "${AUTHENTIK_URL}/-/health/live/" > /dev/null; then
    echo -e "${RED}❌ Authentik is not running${NC}"
    echo "Please start Authentik first: make auth-start"
    exit 1
fi
echo -e "${GREEN}✅ Authentik is running${NC}"

# Check if services are running
echo -e "${YELLOW}Checking UC-1 Pro services...${NC}"

SERVICES_RUNNING=true
if ! docker ps | grep -q "unicorn-open-webui"; then
    echo -e "${YELLOW}⚠️ Open-WebUI not running${NC}"
    SERVICES_RUNNING=false
fi

if ! docker ps | grep -q "unicorn-ops-center"; then
    echo -e "${YELLOW}⚠️ Ops Center not running${NC}"
    SERVICES_RUNNING=false
fi

if [ "$SERVICES_RUNNING" = false ]; then
    echo -e "${YELLOW}Some services are not running. Start them with: make start${NC}"
fi

echo

# Create Authentik Proxy Outpost token
echo -e "${BLUE}📋 Authentik Configuration Required${NC}"
echo
echo -e "${YELLOW}Step 1: Create Proxy Outpost in Authentik${NC}"
echo -e "1. Login to Authentik: ${GREEN}${AUTHENTIK_URL}${NC}"
echo -e "2. Go to: ${GREEN}Applications → Outposts${NC}"
echo -e "3. Click: ${GREEN}Create${NC}"
echo -e "4. Configure:"
echo -e "   - Name: ${GREEN}UC-1 Pro Proxy${NC}"
echo -e "   - Type: ${GREEN}Proxy${NC}"
echo -e "   - Integration: ${GREEN}Local Docker connection${NC}"
echo -e "5. After creation, copy the ${GREEN}Token ID${NC}"
echo

# Prompt for token
echo -n -e "${YELLOW}Enter Authentik Proxy Token (from step above): ${NC}"
read -r PROXY_TOKEN

if [[ -z "$PROXY_TOKEN" ]]; then
    echo -e "${RED}Token is required!${NC}"
    exit 1
fi

# Save token to .env
ENV_FILE="/home/ucadmin/UC-1-Pro/.env"
if grep -q "AUTHENTIK_PROXY_TOKEN" "$ENV_FILE"; then
    sed -i "s/AUTHENTIK_PROXY_TOKEN=.*/AUTHENTIK_PROXY_TOKEN=${PROXY_TOKEN}/" "$ENV_FILE"
else
    echo "" >> "$ENV_FILE"
    echo "# Authentik Proxy Configuration" >> "$ENV_FILE"
    echo "AUTHENTIK_PROXY_TOKEN=${PROXY_TOKEN}" >> "$ENV_FILE"
fi

echo -e "${GREEN}✅ Token saved to .env${NC}"
echo

# Create necessary directories
echo -e "${YELLOW}Creating configuration directories...${NC}"
mkdir -p /home/ucadmin/UC-1-Pro/services/traefik/certs
mkdir -p /home/ucadmin/UC-1-Pro/services/traefik/config

echo -e "${GREEN}✅ Directories created${NC}"
echo

# Generate self-signed certificates for development
if [[ ! -f "/home/ucadmin/UC-1-Pro/services/traefik/certs/localhost.crt" ]]; then
    echo -e "${YELLOW}Generating self-signed certificates for development...${NC}"
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /home/ucadmin/UC-1-Pro/services/traefik/certs/localhost.key \
        -out /home/ucadmin/UC-1-Pro/services/traefik/certs/localhost.crt \
        -subj "/C=US/ST=State/L=City/O=Magic Unicorn/CN=*.localhost"
    
    echo -e "${GREEN}✅ Certificates generated${NC}"
else
    echo -e "${GREEN}✅ Certificates already exist${NC}"
fi
echo

# Create hosts file entries
echo -e "${BLUE}📋 Host Configuration${NC}"
echo
echo -e "${YELLOW}Add these entries to /etc/hosts for local development:${NC}"
echo -e "${GREEN}"
cat << EOF
# UC-1 Pro Services
127.0.0.1    chat.localhost webui.localhost
127.0.0.1    admin.localhost ops.localhost
127.0.0.1    api.localhost
127.0.0.1    search.localhost
127.0.0.1    docs.localhost
127.0.0.1    auth.localhost sso.localhost
127.0.0.1    traefik.localhost
127.0.0.1    grafana.localhost monitoring.localhost
127.0.0.1    prometheus.localhost metrics.localhost
127.0.0.1    vectors.localhost qdrant.localhost
127.0.0.1    stt.localhost whisper.localhost
127.0.0.1    tts.localhost kokoro.localhost
127.0.0.1    embeddings.localhost
127.0.0.1    reranker.localhost
EOF
echo -e "${NC}"

echo -n -e "${YELLOW}Would you like to add these automatically? (requires sudo) (y/n): ${NC}"
read -r ADD_HOSTS

if [[ "$ADD_HOSTS" == "y" || "$ADD_HOSTS" == "Y" ]]; then
    # Backup hosts file
    sudo cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d%H%M%S)
    
    # Remove old entries if they exist
    sudo sed -i '/# UC-1 Pro Services/,/^$/d' /etc/hosts
    
    # Add new entries
    echo "" | sudo tee -a /etc/hosts > /dev/null
    echo "# UC-1 Pro Services" | sudo tee -a /etc/hosts > /dev/null
    echo "127.0.0.1    chat.localhost webui.localhost" | sudo tee -a /etc/hosts > /dev/null
    echo "127.0.0.1    admin.localhost ops.localhost" | sudo tee -a /etc/hosts > /dev/null
    echo "127.0.0.1    api.localhost" | sudo tee -a /etc/hosts > /dev/null
    echo "127.0.0.1    search.localhost" | sudo tee -a /etc/hosts > /dev/null
    echo "127.0.0.1    docs.localhost" | sudo tee -a /etc/hosts > /dev/null
    echo "127.0.0.1    auth.localhost sso.localhost" | sudo tee -a /etc/hosts > /dev/null
    echo "127.0.0.1    traefik.localhost" | sudo tee -a /etc/hosts > /dev/null
    echo "127.0.0.1    grafana.localhost monitoring.localhost" | sudo tee -a /etc/hosts > /dev/null
    echo "127.0.0.1    prometheus.localhost metrics.localhost" | sudo tee -a /etc/hosts > /dev/null
    echo "127.0.0.1    vectors.localhost qdrant.localhost" | sudo tee -a /etc/hosts > /dev/null
    echo "127.0.0.1    stt.localhost whisper.localhost" | sudo tee -a /etc/hosts > /dev/null
    echo "127.0.0.1    tts.localhost kokoro.localhost" | sudo tee -a /etc/hosts > /dev/null
    echo "127.0.0.1    embeddings.localhost" | sudo tee -a /etc/hosts > /dev/null
    echo "127.0.0.1    reranker.localhost" | sudo tee -a /etc/hosts > /dev/null
    
    echo -e "${GREEN}✅ Hosts file updated${NC}"
else
    echo -e "${YELLOW}Please add the entries manually to /etc/hosts${NC}"
fi
echo

# Start Traefik
echo -e "${BLUE}Starting Traefik with Authentik integration...${NC}"
cd /home/ucadmin/UC-1-Pro/services/traefik
docker-compose --env-file ../../.env up -d

# Wait for Traefik to start
echo -e "${YELLOW}Waiting for Traefik to start...${NC}"
sleep 5

# Check if Traefik is running
if docker ps | grep -q "unicorn-traefik"; then
    echo -e "${GREEN}✅ Traefik is running${NC}"
else
    echo -e "${RED}❌ Traefik failed to start${NC}"
    echo "Check logs: docker logs unicorn-traefik"
    exit 1
fi

if docker ps | grep -q "authentik-proxy"; then
    echo -e "${GREEN}✅ Authentik Proxy is running${NC}"
else
    echo -e "${RED}❌ Authentik Proxy failed to start${NC}"
    echo "Check logs: docker logs authentik-proxy"
    exit 1
fi
echo

# Display access URLs
echo -e "${BLUE}🌐 Service URLs with SSO${NC}"
echo -e "${BLUE}════════════════════════${NC}"
echo
echo -e "${GREEN}Public Access:${NC}"
echo -e "  Documentation:     ${BLUE}http://docs.localhost${NC}"
echo -e "  Authentik SSO:     ${BLUE}http://auth.localhost${NC}"
echo
echo -e "${GREEN}Authenticated Users:${NC}"
echo -e "  Chat Interface:    ${BLUE}http://chat.localhost${NC}"
echo -e "  Search Engine:     ${BLUE}http://search.localhost${NC}"
echo
echo -e "${GREEN}Developers Only:${NC}"
echo -e "  API Gateway:       ${BLUE}http://api.localhost/v1${NC}"
echo -e "  Vector Database:   ${BLUE}http://vectors.localhost${NC}"
echo -e "  Speech-to-Text:    ${BLUE}http://stt.localhost${NC}"
echo -e "  Text-to-Speech:    ${BLUE}http://tts.localhost${NC}"
echo -e "  Embeddings:        ${BLUE}http://embeddings.localhost${NC}"
echo -e "  Reranker:          ${BLUE}http://reranker.localhost${NC}"
echo
echo -e "${GREEN}Administrators Only:${NC}"
echo -e "  Ops Center:        ${BLUE}http://admin.localhost${NC}"
echo -e "  Traefik Dashboard: ${BLUE}http://traefik.localhost${NC}"
echo -e "  Monitoring:        ${BLUE}http://grafana.localhost${NC}"
echo -e "  Metrics:           ${BLUE}http://prometheus.localhost${NC}"
echo

# Next steps
echo -e "${BLUE}📋 Next Steps${NC}"
echo -e "${BLUE}═════════════${NC}"
echo
echo -e "1. ${YELLOW}Configure Applications in Authentik:${NC}"
echo -e "   - Create an application for each service"
echo -e "   - Assign appropriate provider (proxy)"
echo -e "   - Set authorization policies"
echo
echo -e "2. ${YELLOW}Test Authentication:${NC}"
echo -e "   - Visit ${GREEN}http://chat.localhost${NC}"
echo -e "   - You should be redirected to Authentik login"
echo -e "   - After login, redirected back to the service"
echo
echo -e "3. ${YELLOW}Configure Groups:${NC}"
echo -e "   - ${GREEN}uc1-admins${NC}: Access to all services"
echo -e "   - ${GREEN}uc1-developers${NC}: Access to APIs and tools"
echo -e "   - ${GREEN}uc1-users${NC}: Access to chat and search"
echo -e "   - ${GREEN}uc1-viewers${NC}: Read-only access"
echo

echo -e "${GREEN}🎉 Traefik Auth Proxy setup complete! 🦄${NC}"
echo -e "${YELLOW}Services are now protected with SSO authentication${NC}"