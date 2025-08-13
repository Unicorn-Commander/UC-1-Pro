#!/bin/bash

# UC-1 Pro Google Workspace SSO Test Script
# Tests the Google Workspace authentication integration

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

echo -e "${BLUE}🧪 Testing Google Workspace SSO Integration...${NC}"
echo

# Test 1: Authentik accessibility
echo -e "${YELLOW}Test 1: Authentik Service${NC}"
if curl -s -f "${AUTHENTIK_URL}/-/health/live/" > /dev/null; then
    echo -e "${GREEN}✅ Authentik is running and accessible${NC}"
else
    echo -e "${RED}❌ Authentik is not accessible${NC}"
    echo "Start Authentik: make auth-start"
    exit 1
fi
echo

# Test 2: Check for Google provider
echo -e "${YELLOW}Test 2: Google Provider Configuration${NC}"
if curl -s "${AUTHENTIK_API_URL}/sources/" | grep -q "google"; then
    echo -e "${GREEN}✅ Google provider appears to be configured${NC}"
else
    echo -e "${RED}❌ Google provider not found${NC}"
    echo "Configure provider: ./scripts/configure-google-sso.sh"
fi
echo

# Test 3: OAuth endpoints
echo -e "${YELLOW}Test 3: OAuth Endpoints${NC}"

# Check login endpoint
if curl -s -I "${AUTHENTIK_URL}/source/oauth/login/google/" 2>/dev/null | grep -q "302\|200"; then
    echo -e "${GREEN}✅ Google OAuth login endpoint accessible${NC}"
else
    echo -e "${YELLOW}⚠️ Google OAuth login endpoint not configured${NC}"
fi

# Check callback endpoint
if curl -s -I "${AUTHENTIK_URL}/source/oauth/callback/google/" 2>/dev/null | grep -q "400\|405\|302"; then
    echo -e "${GREEN}✅ Google OAuth callback endpoint exists${NC}"
else
    echo -e "${YELLOW}⚠️ Google OAuth callback endpoint not found${NC}"
fi
echo

# Test 4: Configuration files
echo -e "${YELLOW}Test 4: Configuration Files${NC}"

CONFIG_FILE="/home/ucadmin/UC-1-Pro/services/authentik/google-workspace-config.env"
if [[ -f "$CONFIG_FILE" ]]; then
    echo -e "${GREEN}✅ Configuration file exists${NC}"
    
    # Show configuration summary (redacted)
    if grep -q "CLIENT_ID" "$CONFIG_FILE"; then
        CLIENT_ID=$(grep "CLIENT_ID=" "$CONFIG_FILE" | cut -d'=' -f2)
        echo -e "   Client ID: ${GREEN}${CLIENT_ID:0:20}...${NC}"
    fi
    
    if grep -q "GOOGLE_WORKSPACE_DOMAIN" "$CONFIG_FILE"; then
        DOMAIN=$(grep "GOOGLE_WORKSPACE_DOMAIN=" "$CONFIG_FILE" | cut -d'=' -f2)
        echo -e "   Domain: ${GREEN}${DOMAIN}${NC}"
    fi
    
    if grep -q "GROUP_SYNC_ENABLED=true" "$CONFIG_FILE"; then
        echo -e "   Group Sync: ${GREEN}Enabled${NC}"
    else
        echo -e "   Group Sync: ${YELLOW}Disabled${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Configuration file not found${NC}"
    echo "Run: ./scripts/configure-google-sso.sh"
fi
echo

# Test 5: Domain policy
POLICY_FILE="/home/ucadmin/UC-1-Pro/services/authentik/google-domain-policy.py"
if [[ -f "$POLICY_FILE" ]]; then
    echo -e "${GREEN}✅ Domain restriction policy exists${NC}"
    ALLOWED_DOMAINS=$(grep "allowed_domains" "$POLICY_FILE" | grep -o "'[^']*'" | tr '\n' ' ')
    echo -e "   Allowed domains: ${GREEN}${ALLOWED_DOMAINS}${NC}"
else
    echo -e "${YELLOW}⚠️ Domain policy not configured${NC}"
fi
echo

# Test 6: Group mapping (if configured)
MAPPING_FILE="/home/ucadmin/UC-1-Pro/services/authentik/google-group-mapping.py"
echo -e "${YELLOW}Test 5: Group Mapping${NC}"
if [[ -f "$MAPPING_FILE" ]]; then
    echo -e "${GREEN}✅ Group mapping script exists${NC}"
    # Count mappings
    MAPPING_COUNT=$(grep -c "@" "$MAPPING_FILE" || echo "0")
    echo -e "   Configured mappings: ${GREEN}${MAPPING_COUNT}${NC}"
else
    echo -e "${YELLOW}⚠️ Group mapping not configured${NC}"
fi
echo

# Test 7: Manual verification checklist
echo -e "${YELLOW}Test 6: Manual Verification Checklist${NC}"
echo -e "${BLUE}Google Cloud Console:${NC}"
echo -e "   □ OAuth 2.0 credentials created"
echo -e "   □ Redirect URI: ${GREEN}${AUTHENTIK_URL}/source/oauth/callback/google/${NC}"
echo -e "   □ OAuth consent screen configured"
echo -e "   □ APIs enabled (Identity Platform, Admin SDK)"
echo

echo -e "${BLUE}Google Workspace Admin:${NC}"
echo -e "   □ API access enabled"
echo -e "   □ Domain-wide delegation configured (if using group sync)"
echo -e "   □ Security policies reviewed"
echo

echo -e "${BLUE}Authentik Configuration:${NC}"
echo -e "   □ Google provider created"
echo -e "   □ Application configured"
echo -e "   □ Domain policy applied"
echo -e "   □ Group mappings configured (if applicable)"
echo

# Test 8: End-to-end test
echo -e "${YELLOW}Test 7: End-to-End Authentication Flow${NC}"
echo -e "${BLUE}Manual test required:${NC}"
echo
echo -e "1. Open browser to: ${GREEN}${AUTHENTIK_URL}${NC}"
echo -e "2. Look for '${GREEN}Sign in with Google${NC}' button"
echo -e "3. Click and authenticate with Google account"
echo -e "4. Verify successful redirect back to Authentik"
echo -e "5. Check user creation in Authentik admin"
echo

# Summary
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}📊 Test Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo

# Count successes
SUCCESS_COUNT=0
TOTAL_TESTS=5

if curl -s -f "${AUTHENTIK_URL}/-/health/live/" > /dev/null 2>&1; then
    ((SUCCESS_COUNT++))
fi

if curl -s "${AUTHENTIK_API_URL}/sources/" 2>/dev/null | grep -q "google"; then
    ((SUCCESS_COUNT++))
fi

if [[ -f "$CONFIG_FILE" ]]; then
    ((SUCCESS_COUNT++))
fi

if [[ -f "$POLICY_FILE" ]]; then
    ((SUCCESS_COUNT++))
fi

if [[ -f "$MAPPING_FILE" ]]; then
    ((SUCCESS_COUNT++))
fi

echo -e "Automated Tests: ${GREEN}${SUCCESS_COUNT}/${TOTAL_TESTS} passed${NC}"
echo

if [[ $SUCCESS_COUNT -eq $TOTAL_TESTS ]]; then
    echo -e "${GREEN}✅ All automated tests passed!${NC}"
    echo -e "${YELLOW}⚠️ Manual configuration and testing still required${NC}"
else
    echo -e "${YELLOW}⚠️ Some tests failed - configuration incomplete${NC}"
    echo -e "Run: ${GREEN}./scripts/configure-google-sso.sh${NC}"
fi
echo

# Troubleshooting
echo -e "${BLUE}🔧 Troubleshooting Commands:${NC}"
echo -e "   View logs:        ${GREEN}docker logs authentik-server -f${NC}"
echo -e "   Restart service:  ${GREEN}make auth-restart${NC}"
echo -e "   Reconfigure:      ${GREEN}./scripts/configure-google-sso.sh${NC}"
echo -e "   Documentation:    ${GREEN}services/authentik/setup-google-workspace.md${NC}"
echo

echo -e "${GREEN}🎉 Google Workspace SSO test complete! 🦄${NC}"