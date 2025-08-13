#!/bin/bash

# UC-1 Pro - Configure Authentik Applications
# This script guides you through setting up applications in Authentik

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}     UC-1 Pro - Authentik Application Configuration${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

echo -e "${YELLOW}This guide will help you configure applications in Authentik${NC}"
echo -e "${YELLOW}You'll need to complete these steps in the Authentik Admin UI${NC}"
echo

# Check if Authentik is running
if ! curl -s -f "http://localhost:9005/-/health/live/" > /dev/null; then
    echo -e "${RED}❌ Authentik is not running!${NC}"
    echo -e "Start it with: ${GREEN}make auth-start${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Authentik is running${NC}"
echo

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Step 1: Login to Authentik Admin${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo
echo -e "1. Open browser to: ${GREEN}http://localhost:9005${NC}"
echo -e "2. Login with:"
echo -e "   Email: ${GREEN}admin@magicunicorn.tech${NC}"
echo -e "   Password: ${GREEN}MagicUnicorn!Auth${NC}"
echo
read -p "Press Enter when logged in..."

echo
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Step 2: Create OAuth2 Provider for Open-WebUI${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo
echo -e "${YELLOW}Navigate to: Applications → Providers → Create${NC}"
echo
echo -e "Select: ${GREEN}OAuth2/OpenID Provider${NC}"
echo -e "Configure with these settings:"
echo
echo -e "${GREEN}Basic Settings:${NC}"
echo -e "  Name: ${BLUE}Open-WebUI OAuth${NC}"
echo -e "  Authentication flow: ${BLUE}default-authentication-flow${NC}"
echo -e "  Authorization flow: ${BLUE}default-provider-authorization-implicit-consent${NC}"
echo
echo -e "${GREEN}Protocol Settings:${NC}"
echo -e "  Client type: ${BLUE}Confidential${NC}"
echo -e "  Client ID: ${BLUE}open-webui${NC}"
echo -e "  Client Secret: ${BLUE}(Copy the generated secret!)${NC}"
echo -e "  Redirect URIs:"
echo -e "    ${BLUE}http://localhost:8080/oauth/oidc/callback${NC}"
echo -e "    ${BLUE}http://chat.localhost/oauth/oidc/callback${NC}"
echo
echo -e "${GREEN}Scopes:${NC}"
echo -e "  ✅ openid"
echo -e "  ✅ email"
echo -e "  ✅ profile"
echo -e "  ✅ groups"
echo
echo -e "${YELLOW}Save the provider and copy the Client Secret!${NC}"
echo
read -p "Enter the Client Secret: " OPENWEBUI_CLIENT_SECRET
echo

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Step 3: Create Application for Open-WebUI${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo
echo -e "${YELLOW}Navigate to: Applications → Applications → Create${NC}"
echo
echo -e "Configure:"
echo -e "  Name: ${BLUE}Open-WebUI${NC}"
echo -e "  Slug: ${BLUE}open-webui${NC}"
echo -e "  Provider: ${BLUE}Open-WebUI OAuth (select from dropdown)${NC}"
echo -e "  Policy engine mode: ${BLUE}any${NC}"
echo
echo -e "${GREEN}UI Settings:${NC}"
echo -e "  Launch URL: ${BLUE}http://localhost:8080${NC}"
echo -e "  Icon: ${BLUE}(optional - upload an icon)${NC}"
echo
read -p "Press Enter when application is created..."

echo
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Step 4: Create Proxy Provider for Ops Center${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo
echo -e "${YELLOW}Navigate to: Applications → Providers → Create${NC}"
echo
echo -e "Select: ${GREEN}Proxy Provider${NC}"
echo -e "Configure:"
echo -e "  Name: ${BLUE}Ops Center Proxy${NC}"
echo -e "  Authentication flow: ${BLUE}default-authentication-flow${NC}"
echo -e "  Authorization flow: ${BLUE}default-provider-authorization-implicit-consent${NC}"
echo
echo -e "${GREEN}Proxy Settings:${NC}"
echo -e "  External host: ${BLUE}http://admin.localhost${NC}"
echo -e "  Internal host: ${BLUE}http://unicorn-ops-center:8084${NC}"
echo -e "  Internal host SSL Validation: ${BLUE}Disabled${NC}"
echo
read -p "Press Enter when provider is created..."

echo
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Step 5: Create Applications for Other Services${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo
echo -e "Repeat the proxy provider process for:"
echo
echo -e "${GREEN}1. vLLM API:${NC}"
echo -e "   External: ${BLUE}http://api.localhost${NC}"
echo -e "   Internal: ${BLUE}http://unicorn-vllm:8000${NC}"
echo -e "   Groups: ${BLUE}uc1-admins, uc1-developers${NC}"
echo
echo -e "${GREEN}2. Center-Deep Search:${NC}"
echo -e "   External: ${BLUE}http://search.localhost${NC}"
echo -e "   Internal: ${BLUE}http://unicorn-searxng:8890${NC}"
echo -e "   Groups: ${BLUE}All authenticated users${NC}"
echo
echo -e "${GREEN}3. Qdrant Vector DB:${NC}"
echo -e "   External: ${BLUE}http://vectors.localhost${NC}"
echo -e "   Internal: ${BLUE}http://unicorn-qdrant:6333${NC}"
echo -e "   Groups: ${BLUE}uc1-admins, uc1-developers${NC}"
echo
read -p "Press Enter when all applications are created..."

echo
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Step 6: Create Outpost for ForwardAuth${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo
echo -e "${YELLOW}Navigate to: Applications → Outposts → Create${NC}"
echo
echo -e "Configure:"
echo -e "  Name: ${BLUE}UC-1 Pro Proxy${NC}"
echo -e "  Type: ${BLUE}Proxy${NC}"
echo -e "  Integration: ${BLUE}Local Docker connection${NC}"
echo -e "  Applications: ${BLUE}Select all created applications${NC}"
echo -e "  Configuration: ${BLUE}authentik Embedded Outpost${NC}"
echo
echo -e "${YELLOW}After creation, copy the token from the outpost details${NC}"
echo
read -p "Enter the Outpost Token: " OUTPOST_TOKEN
echo

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Step 7: Update Environment Configuration${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

# Update .env file
ENV_FILE="/home/ucadmin/UC-1-Pro/.env"

# Backup existing .env
cp "$ENV_FILE" "${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

# Add OAuth configuration
cat >> "$ENV_FILE" << EOF

# Authentik OAuth Configuration (added $(date))
OPENWEBUI_OAUTH_CLIENT_ID=open-webui
OPENWEBUI_OAUTH_CLIENT_SECRET=${OPENWEBUI_CLIENT_SECRET}
OPENWEBUI_OAUTH_PROVIDER_URL=http://localhost:9005/application/o/open-webui/
OPENWEBUI_OAUTH_REDIRECT_URI=http://localhost:8080/oauth/oidc/callback
AUTHENTIK_OUTPOST_TOKEN=${OUTPOST_TOKEN}
EOF

echo -e "${GREEN}✅ Configuration saved to .env${NC}"
echo

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Step 8: Configure Open-WebUI for OAuth${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo

# Create Open-WebUI OAuth configuration
cat > /home/ucadmin/UC-1-Pro/services/open-webui-oauth.env << EOF
# Open-WebUI OAuth Configuration
ENABLE_OAUTH_SIGNUP=true
OAUTH_MERGE_ACCOUNTS_BY_EMAIL=true

# OpenID Connect settings
OPENID_PROVIDER_URL=http://localhost:9005/application/o/open-webui/
OPENID_CLIENT_ID=open-webui
OPENID_CLIENT_SECRET=${OPENWEBUI_CLIENT_SECRET}
OPENID_REDIRECT_URI=http://localhost:8080/oauth/oidc/callback
OPENID_SCOPE="openid profile email groups"

# Optional: Map groups to Open-WebUI roles
OPENID_PROVIDER_DISPLAY_NAME="UC-1 Pro SSO"
OPENID_PROVIDER_LOGO_URL="http://localhost:9005/static/dist/assets/icons/icon.svg"
EOF

echo -e "${GREEN}✅ Open-WebUI OAuth configuration created${NC}"
echo

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Next Steps${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo
echo -e "1. ${YELLOW}Restart services to apply OAuth:${NC}"
echo -e "   ${GREEN}docker-compose restart open-webui${NC}"
echo
echo -e "2. ${YELLOW}Start Traefik proxy (optional):${NC}"
echo -e "   ${GREEN}./scripts/setup-traefik-auth.sh${NC}"
echo
echo -e "3. ${YELLOW}Test authentication:${NC}"
echo -e "   ${GREEN}http://localhost:8080${NC} - Should show 'Login with UC-1 Pro SSO'"
echo -e "   ${GREEN}http://admin.localhost${NC} - Should redirect to Authentik"
echo
echo -e "4. ${YELLOW}Configure group permissions in Authentik:${NC}"
echo -e "   - Assign users to groups (uc1-admins, uc1-developers, etc.)"
echo -e "   - Set policies for each application"
echo

echo -e "${GREEN}🎉 Authentik application configuration complete!${NC}"
echo -e "${YELLOW}Remember to test each service after configuration${NC}"