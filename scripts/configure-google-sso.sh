#!/bin/bash

# UC-1 Pro Google Workspace SSO Configuration Script
# This script helps configure Google Workspace authentication in Authentik

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

echo -e "${BLUE}🔐 UC-1 Pro Google Workspace SSO Configuration${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo

# Check if Authentik is running
if ! curl -s -f "${AUTHENTIK_URL}/-/health/live/" > /dev/null; then
    echo -e "${RED}❌ Authentik is not running or not accessible at ${AUTHENTIK_URL}${NC}"
    echo "Please ensure Authentik is running: make auth-start"
    exit 1
fi

echo -e "${GREEN}✅ Authentik is running${NC}"
echo

# Function to prompt for input
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

# Function to prompt for secret
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

echo -e "${BLUE}📋 Google Cloud Console Configuration${NC}"
echo "Please provide the following from your Google Cloud Console OAuth 2.0 credentials:"
echo

# Collect Google OAuth configuration
prompt_input "Client ID" CLIENT_ID true
prompt_secret "Client Secret" CLIENT_SECRET
prompt_input "Google Workspace domain (e.g., company.com)" DOMAIN true
prompt_input "Organization name (for display)" ORG_NAME true

# Ask about advanced features
echo
echo -e "${BLUE}📋 Advanced Configuration${NC}"
echo -n -e "${YELLOW}Enable Google Workspace group sync? (y/n): ${NC}"
read -r ENABLE_GROUP_SYNC

if [[ "$ENABLE_GROUP_SYNC" == "y" || "$ENABLE_GROUP_SYNC" == "Y" ]]; then
    GROUP_SYNC_ENABLED="true"
    echo -e "${GREEN}Group sync will be configured${NC}"
else
    GROUP_SYNC_ENABLED="false"
    echo -e "${YELLOW}Group sync disabled${NC}"
fi

echo
echo -e "${BLUE}🔧 Creating Google Workspace Provider Configuration...${NC}"

# Create configuration file
CONFIG_FILE="/home/ucadmin/UC-1-Pro/services/authentik/google-workspace-config.env"
cat > "$CONFIG_FILE" << EOF
# Google Workspace Configuration for UC-1 Pro
# Generated on $(date)

# OAuth 2.0 Credentials
CLIENT_ID=${CLIENT_ID}
CLIENT_SECRET=${CLIENT_SECRET}
GOOGLE_WORKSPACE_DOMAIN=${DOMAIN}
ORG_NAME=${ORG_NAME}

# OAuth2 URLs
AUTHORIZATION_URL=https://accounts.google.com/o/oauth2/v2/auth
ACCESS_TOKEN_URL=https://oauth2.googleapis.com/token
PROFILE_URL=https://www.googleapis.com/oauth2/v1/userinfo

# Redirect URIs
REDIRECT_URI_LOCAL=http://localhost:9005/source/oauth/callback/google/
REDIRECT_URI_PRODUCTION=https://${DOMAIN}/source/oauth/callback/google/

# Scopes
SCOPES=openid profile email
EOF

if [[ "$GROUP_SYNC_ENABLED" == "true" ]]; then
    cat >> "$CONFIG_FILE" << EOF

# Group Sync Configuration
GROUP_SYNC_ENABLED=true
GROUP_SYNC_SCOPE=https://www.googleapis.com/auth/admin.directory.group.readonly
EOF
fi

echo -e "${GREEN}✅ Configuration saved to: ${CONFIG_FILE}${NC}"
echo

# Display manual configuration steps
echo -e "${BLUE}📋 Manual Configuration Required${NC}"
echo
echo -e "${YELLOW}Step 1: Access Authentik Admin${NC}"
echo -e "   URL: ${GREEN}${AUTHENTIK_URL}${NC}"
echo -e "   Login: ${GREEN}admin@magicunicorn.tech / MagicUnicorn!Auth${NC}"
echo

echo -e "${YELLOW}Step 2: Create Google Provider${NC}"
echo -e "   • Go to: ${GREEN}Directory → Federation & Social login${NC}"
echo -e "   • Click: ${GREEN}Create${NC}"
echo -e "   • Select: ${GREEN}Google${NC}"
echo

echo -e "${YELLOW}Step 3: Configure Provider${NC}"
echo -e "   Name:          ${GREEN}${ORG_NAME} Google Workspace${NC}"
echo -e "   Slug:          ${GREEN}google-workspace${NC}"
echo -e "   Client ID:     ${GREEN}${CLIENT_ID}${NC}"
echo -e "   Client Secret: ${GREEN}[Use the secret you provided]${NC}"
echo

echo -e "${YELLOW}Step 4: OAuth2 Settings${NC}"
echo -e "   Scopes: ${GREEN}openid profile email${NC}"
if [[ "$GROUP_SYNC_ENABLED" == "true" ]]; then
    echo -e "           ${GREEN}https://www.googleapis.com/auth/admin.directory.group.readonly${NC}"
fi
echo

echo -e "${YELLOW}Step 5: Create Application${NC}"
echo -e "   • Go to: ${GREEN}Applications → Applications${NC}"
echo -e "   • Click: ${GREEN}Create${NC}"
echo -e "   • Name: ${GREEN}UC-1 Pro Google${NC}"
echo -e "   • Provider: ${GREEN}Select the Google provider${NC}"
echo

# Create group mapping script if enabled
if [[ "$GROUP_SYNC_ENABLED" == "true" ]]; then
    MAPPING_FILE="/home/ucadmin/UC-1-Pro/services/authentik/google-group-mapping.py"
    cat > "$MAPPING_FILE" << 'EOF'
# Google Workspace Group Mapping for UC-1 Pro
# This expression maps Google groups to UC-1 Pro groups

# Define your Google group to UC-1 Pro group mappings
group_mapping = {
EOF
    cat >> "$MAPPING_FILE" << EOF
    'uc1-admins@${DOMAIN}': 'uc1-admins',
    'uc1-developers@${DOMAIN}': 'uc1-developers',
    'uc1-users@${DOMAIN}': 'uc1-users',
    'uc1-viewers@${DOMAIN}': 'uc1-viewers',
    'engineering@${DOMAIN}': 'uc1-developers',
    'support@${DOMAIN}': 'uc1-users',
    'management@${DOMAIN}': 'uc1-admins',
EOF
    cat >> "$MAPPING_FILE" << 'EOF'
}

# Get user's Google groups from request context
google_groups = request.user.attributes.get('groups', [])

# Map to UC-1 Pro groups
uc1_groups = []
for google_group in google_groups:
    if google_group in group_mapping:
        uc1_groups.append(group_mapping[google_group])

# Default to users group if no specific mapping
if not uc1_groups:
    uc1_groups = ['uc1-users']

# Return the mapped groups
return uc1_groups
EOF
    
    echo -e "${GREEN}✅ Group mapping script saved to: ${MAPPING_FILE}${NC}"
    echo
    echo -e "${YELLOW}Step 6: Configure Group Mapping${NC}"
    echo -e "   • Go to: ${GREEN}Customization → Property Mappings${NC}"
    echo -e "   • Create new mapping with the script from: ${GREEN}${MAPPING_FILE}${NC}"
    echo -e "   • Apply to Google provider${NC}"
    echo
fi

# Create domain restriction policy
POLICY_FILE="/home/ucadmin/UC-1-Pro/services/authentik/google-domain-policy.py"
cat > "$POLICY_FILE" << EOF
# Domain Restriction Policy for Google Workspace
# Only allow users from your organization's domain

allowed_domains = ['${DOMAIN}']

# Get user email from request
user_email = request.user.email if hasattr(request.user, 'email') else ''

# Check domain
if user_email:
    user_domain = user_email.split('@')[1] if '@' in user_email else ''
    if user_domain in allowed_domains:
        return True

# Deny access for non-organization users
ak_message(f"Access denied: Only {', '.join(allowed_domains)} users are allowed")
return False
EOF

echo -e "${GREEN}✅ Domain policy saved to: ${POLICY_FILE}${NC}"
echo

# Display Google Cloud Console checklist
echo -e "${BLUE}📋 Google Cloud Console Checklist${NC}"
echo -e "   ${GREEN}□${NC} OAuth 2.0 credentials created"
echo -e "   ${GREEN}□${NC} Redirect URI added: ${GREEN}http://localhost:9005/source/oauth/callback/google/${NC}"
echo -e "   ${GREEN}□${NC} OAuth consent screen configured"
echo -e "   ${GREEN}□${NC} Required APIs enabled:"
echo -e "      ${GREEN}□${NC} Google Identity Platform API"
if [[ "$GROUP_SYNC_ENABLED" == "true" ]]; then
    echo -e "      ${GREEN}□${NC} Admin SDK API (for group sync)"
fi
echo -e "   ${GREEN}□${NC} Scopes configured:"
echo -e "      ${GREEN}□${NC} openid"
echo -e "      ${GREEN}□${NC} profile"
echo -e "      ${GREEN}□${NC} email"
if [[ "$GROUP_SYNC_ENABLED" == "true" ]]; then
    echo -e "      ${GREEN}□${NC} https://www.googleapis.com/auth/admin.directory.group.readonly"
fi
echo

# Display testing instructions
echo -e "${BLUE}🧪 Testing Instructions${NC}"
echo -e "   1. Complete the manual configuration above"
echo -e "   2. Run: ${GREEN}./scripts/test-google-sso.sh${NC}"
echo -e "   3. Test login at: ${GREEN}${AUTHENTIK_URL}${NC}"
echo -e "   4. Click '${GREEN}Sign in with Google${NC}'"
echo

echo -e "${YELLOW}📚 For detailed instructions, see:${NC}"
echo -e "   ${GREEN}/home/ucadmin/UC-1-Pro/services/authentik/setup-google-workspace.md${NC}"
echo

echo -e "${GREEN}🎉 Google Workspace SSO configuration prepared! 🦄${NC}"
echo -e "${YELLOW}Complete the manual steps above to activate Google login${NC}"