#!/bin/bash

# UC-1 Pro Microsoft 365 SSO Test Script
# This script tests the Microsoft 365 authentication integration

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

echo -e "${BLUE}🧪 Testing Microsoft 365 SSO Integration...${NC}"
echo

# Test 1: Check if Authentik is accessible
echo -e "${YELLOW}Test 1: Authentik Accessibility${NC}"
if curl -s -f "${AUTHENTIK_URL}/-/health/live/" > /dev/null; then
    echo -e "${GREEN}✅ Authentik is accessible${NC}"
else
    echo -e "${RED}❌ Authentik is not accessible${NC}"
    echo "Please ensure Authentik is running: cd services/authentik && docker-compose up -d"
    exit 1
fi
echo

# Test 2: Check Microsoft provider configuration
echo -e "${YELLOW}Test 2: Microsoft Provider Configuration${NC}"
if curl -s "${AUTHENTIK_API_URL}/sources/" | grep -q "microsoft"; then
    echo -e "${GREEN}✅ Microsoft provider appears to be configured${NC}"
    
    # Get provider details
    PROVIDER_INFO=$(curl -s "${AUTHENTIK_API_URL}/sources/" | grep -A 10 -B 10 "microsoft" || echo "Could not fetch provider details")
    echo -e "${BLUE}Provider info: ${PROVIDER_INFO:0:100}...${NC}"
else
    echo -e "${RED}❌ Microsoft provider not found${NC}"
    echo "Please configure the Microsoft provider in Authentik admin interface"
fi
echo

# Test 3: Check OAuth endpoints
echo -e "${YELLOW}Test 3: OAuth Endpoint Accessibility${NC}"

# Check authorization endpoint (should redirect to Microsoft)
if curl -s -I "${AUTHENTIK_URL}/source/oauth/login/microsoft/" | grep -q "302\|200"; then
    echo -e "${GREEN}✅ Microsoft OAuth login endpoint is accessible${NC}"
else
    echo -e "${RED}❌ Microsoft OAuth login endpoint not accessible${NC}"
    echo "This might indicate the provider is not properly configured"
fi
echo

# Test 4: Check callback endpoint
echo -e "${YELLOW}Test 4: OAuth Callback Endpoint${NC}"
if curl -s -I "${AUTHENTIK_URL}/source/oauth/callback/microsoft/" | grep -q "400\|405"; then
    echo -e "${GREEN}✅ Microsoft OAuth callback endpoint exists (expected 400/405 without auth)${NC}"
else
    echo -e "${YELLOW}⚠️ Microsoft OAuth callback endpoint response unexpected${NC}"
    echo "This might be normal - endpoint expects OAuth callback data"
fi
echo

# Test 5: Manual login test
echo -e "${YELLOW}Test 5: Manual Login Test${NC}"
echo -e "${BLUE}Manual testing required:${NC}"
echo
echo -e "1. Open browser to: ${GREEN}${AUTHENTIK_URL}${NC}"
echo -e "2. Look for '${GREEN}Sign in with Microsoft${NC}' button"
echo -e "3. Click the button and verify redirect to Microsoft login"
echo -e "4. Complete Microsoft login and verify redirect back to Authentik"
echo
echo -e "${BLUE}Expected flow:${NC}"
echo -e "   ${AUTHENTIK_URL} → login.microsoftonline.com → ${AUTHENTIK_URL}"
echo

# Test 6: Configuration file check
CONFIG_FILE="/home/ucadmin/UC-1-Pro/services/authentik/microsoft365-config.env"
echo -e "${YELLOW}Test 6: Configuration File${NC}"
if [[ -f "$CONFIG_FILE" ]]; then
    echo -e "${GREEN}✅ Configuration file exists: ${CONFIG_FILE}${NC}"
    
    # Show redacted configuration
    echo -e "${BLUE}Configuration summary:${NC}"
    if grep -q "TENANT_ID" "$CONFIG_FILE"; then
        TENANT_ID=$(grep "TENANT_ID=" "$CONFIG_FILE" | cut -d'=' -f2)
        echo -e "   Tenant ID: ${GREEN}${TENANT_ID:0:8}...${NC}"
    fi
    
    if grep -q "CLIENT_ID" "$CONFIG_FILE"; then
        CLIENT_ID=$(grep "CLIENT_ID=" "$CONFIG_FILE" | cut -d'=' -f2)
        echo -e "   Client ID: ${GREEN}${CLIENT_ID:0:8}...${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Configuration file not found${NC}"
    echo "Run: ./scripts/configure-microsoft365-sso.sh"
fi
echo

# Test 7: Azure AD redirect URI validation
echo -e "${YELLOW}Test 7: Azure AD Configuration Check${NC}"
echo -e "${BLUE}Verify in Azure AD app registration:${NC}"
echo -e "   Redirect URI: ${GREEN}${AUTHENTIK_URL}/source/oauth/callback/microsoft/${NC}"
echo -e "   Supported account types: ${GREEN}This organization only${NC}"
echo -e "   API permissions granted and consented: ${GREEN}openid, profile, email, User.Read${NC}"
echo

# Summary and next steps
echo -e "${BLUE}📋 Test Summary${NC}"
echo -e "${BLUE}═══════════════${NC}"
echo
echo -e "${GREEN}✅ Completed Tests:${NC}"
echo -e "   • Authentik accessibility"
echo -e "   • Provider configuration check"
echo -e "   • OAuth endpoint validation"
echo

echo -e "${YELLOW}📋 Manual Verification Required:${NC}"
echo -e "   • Azure AD app registration complete"
echo -e "   • Microsoft provider configured in Authentik"
echo -e "   • End-to-end login flow test"
echo

echo -e "${BLUE}🔧 Troubleshooting Commands:${NC}"
echo -e "   View Authentik logs:     ${GREEN}docker logs authentik-server -f${NC}"
echo -e "   Restart Authentik:       ${GREEN}cd services/authentik && docker-compose restart${NC}"
echo -e "   Reconfigure provider:     ${GREEN}./scripts/configure-microsoft365-sso.sh${NC}"
echo

echo -e "${BLUE}📚 Documentation:${NC}"
echo -e "   Setup guide: ${GREEN}/home/ucadmin/UC-1-Pro/services/authentik/setup-microsoft365.md${NC}"
echo

echo -e "${GREEN}🎉 Microsoft 365 SSO testing complete! 🦄${NC}"
echo -e "${YELLOW}Remember to test the actual login flow manually${NC}"