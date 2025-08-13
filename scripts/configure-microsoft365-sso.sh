#!/bin/bash

# UC-1 Pro Microsoft 365 SSO Configuration Script
# This script helps configure Microsoft 365 authentication in Authentik

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
AUTHENTIK_URL="http://localhost:9005"
AUTHENTIK_API_URL="${AUTHENTIK_URL}/api/v3"

echo -e "${BLUE}🔐 UC-1 Pro Microsoft 365 SSO Configuration${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo

# Check if Authentik is running
if ! curl -s -f "${AUTHENTIK_URL}/-/health/live/" > /dev/null; then
    echo -e "${RED}❌ Authentik is not running or not accessible at ${AUTHENTIK_URL}${NC}"
    echo "Please ensure Authentik is running: cd services/authentik && docker-compose up -d"
    exit 1
fi

echo -e "${GREEN}✅ Authentik is running${NC}"
echo

# Function to prompt for input with validation
prompt_input() {
    local prompt="$1"
    local var_name="$2"
    local required="$3"
    local value=""
    
    while [[ -z "$value" || ("$required" == "true" && -z "$value") ]]; do
        echo -n -e "${YELLOW}${prompt}: ${NC}"
        read -r value
        if [[ "$required" == "true" && -z "$value" ]]; then
            echo -e "${RED}This field is required!${NC}"
        fi
    done
    
    eval "$var_name='$value'"
}

# Function to prompt for password/secret
prompt_secret() {
    local prompt="$1"
    local var_name="$2"
    local value=""
    
    while [[ -z "$value" ]]; do
        echo -n -e "${YELLOW}${prompt}: ${NC}"
        read -r -s value
        echo
        if [[ -z "$value" ]]; then
            echo -e "${RED}This field is required!${NC}"
        fi
    done
    
    eval "$var_name='$value'"
}

echo -e "${BLUE}📋 Azure AD/Entra ID Configuration${NC}"
echo "Please provide the following information from your Azure AD app registration:"
echo

# Collect Azure AD configuration
prompt_input "Tenant ID (Directory ID)" TENANT_ID true
prompt_input "Client ID (Application ID)" CLIENT_ID true
prompt_secret "Client Secret" CLIENT_SECRET
prompt_input "Organization name (for display)" ORG_NAME true

echo
echo -e "${BLUE}🔧 Creating Microsoft 365 Provider in Authentik...${NC}"

# Get API token (this would typically be done via admin login)
echo -e "${YELLOW}ℹ️  Manual Configuration Required${NC}"
echo "Due to API authentication requirements, please complete the setup manually:"
echo

echo -e "${BLUE}1. Open Authentik Admin Interface:${NC}"
echo -e "   ${GREEN}${AUTHENTIK_URL}${NC}"
echo

echo -e "${BLUE}2. Login with:${NC}"
echo -e "   Email:    ${GREEN}admin@magicunicorn.tech${NC}"
echo -e "   Password: ${GREEN}MagicUnicorn!Auth${NC}"
echo -e "   ${RED}(Change this password immediately!)${NC}"
echo

echo -e "${BLUE}3. Create Microsoft Provider:${NC}"
echo -e "   • Go to: ${GREEN}Directory → Federation & Social login${NC}"
echo -e "   • Click: ${GREEN}Create${NC}"
echo -e "   • Select: ${GREEN}Microsoft${NC}"
echo

echo -e "${BLUE}4. Configuration Details:${NC}"
echo -e "   Name:                 ${GREEN}${ORG_NAME} Microsoft 365${NC}"
echo -e "   Slug:                 ${GREEN}microsoft365${NC}"
echo -e "   Client ID:            ${GREEN}${CLIENT_ID}${NC}"
echo -e "   Client Secret:        ${GREEN}${CLIENT_SECRET}${NC}"
echo -e "   Tenant ID:            ${GREEN}${TENANT_ID}${NC}"
echo

echo -e "${BLUE}5. OAuth2 URLs:${NC}"
echo -e "   Authorization URL:    ${GREEN}https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/authorize${NC}"
echo -e "   Access Token URL:     ${GREEN}https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token${NC}"
echo -e "   Profile URL:          ${GREEN}https://graph.microsoft.com/v1.0/me${NC}"
echo

echo -e "${BLUE}6. Scopes:${NC}"
echo -e "   ${GREEN}openid profile email${NC}"
echo

echo -e "${BLUE}7. Create Application:${NC}"
echo -e "   • Go to: ${GREEN}Applications → Applications${NC}"
echo -e "   • Click: ${GREEN}Create${NC}"
echo -e "   • Name: ${GREEN}UC-1 Pro${NC}"
echo -e "   • Slug: ${GREEN}uc1-pro${NC}"
echo -e "   • Provider: ${GREEN}Select the Microsoft provider${NC}"
echo

# Create configuration file for reference
CONFIG_FILE="/home/ucadmin/UC-1-Pro/services/authentik/microsoft365-config.env"
cat > "$CONFIG_FILE" << EOF
# Microsoft 365 Configuration for UC-1 Pro
# Generated on $(date)

TENANT_ID=${TENANT_ID}
CLIENT_ID=${CLIENT_ID}
CLIENT_SECRET=${CLIENT_SECRET}
ORG_NAME=${ORG_NAME}

# OAuth2 URLs
AUTHORIZATION_URL=https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/authorize
ACCESS_TOKEN_URL=https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token
PROFILE_URL=https://graph.microsoft.com/v1.0/me

# Azure AD Redirect URI (configure this in Azure)
REDIRECT_URI=http://localhost:9005/source/oauth/callback/microsoft/

# Scopes
SCOPES=openid profile email

# For production, update this to your domain
# REDIRECT_URI=https://yourdomain.com/source/oauth/callback/microsoft/
EOF

echo -e "${GREEN}✅ Configuration saved to: ${CONFIG_FILE}${NC}"
echo

echo -e "${BLUE}📋 Azure AD App Registration Checklist:${NC}"
echo -e "   ${GREEN}□${NC} App registered with name: ${GREEN}UC-1 Pro SSO${NC}"
echo -e "   ${GREEN}□${NC} Redirect URI configured: ${GREEN}http://localhost:9005/source/oauth/callback/microsoft/${NC}"
echo -e "   ${GREEN}□${NC} Client secret created and copied"
echo -e "   ${GREEN}□${NC} API permissions granted:"
echo -e "      ${GREEN}□${NC} openid"
echo -e "      ${GREEN}□${NC} profile" 
echo -e "      ${GREEN}□${NC} email"
echo -e "      ${GREEN}□${NC} User.Read"
echo -e "      ${GREEN}□${NC} Group.Read.All (optional)"
echo -e "   ${GREEN}□${NC} Admin consent granted"
echo

echo -e "${BLUE}🧪 Testing Instructions:${NC}"
echo -e "   1. Complete the manual configuration above"
echo -e "   2. Run: ${GREEN}./scripts/test-microsoft365-sso.sh${NC}"
echo -e "   3. Or manually test at: ${GREEN}${AUTHENTIK_URL}${NC}"
echo

echo -e "${YELLOW}📚 For detailed setup instructions, see:${NC}"
echo -e "   ${GREEN}/home/ucadmin/UC-1-Pro/services/authentik/setup-microsoft365.md${NC}"
echo

echo -e "${GREEN}🎉 Microsoft 365 SSO configuration started! 🦄${NC}"