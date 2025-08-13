# Microsoft 365 / Entra ID Integration Guide

This guide walks through setting up Microsoft 365 (Azure AD / Entra ID) authentication with Authentik for UC-1 Pro.

## Prerequisites

1. **Azure AD/Entra ID Access**: You need admin access to your organization's Azure AD/Entra ID
2. **Authentik Running**: Ensure Authentik is running on `http://localhost:9005`
3. **Domain Configuration**: For production, you'll need a proper domain name

## Step 1: Create Azure AD Application

### 1.1 Access Azure Portal
1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Azure Active Directory** (or **Microsoft Entra ID**)
3. Click **App registrations** in the left menu
4. Click **New registration**

### 1.2 Register Application
Fill in the registration form:

- **Name**: `UC-1 Pro SSO`
- **Supported account types**: `Accounts in this organizational directory only`
- **Redirect URI**: 
  - Type: `Web`
  - URL: `http://localhost:9005/source/oauth/callback/microsoft/`

**Note**: For production, replace `localhost:9005` with your actual domain.

### 1.3 Configure Application
After creation, note down:
- **Application (client) ID** - You'll need this for Authentik
- **Directory (tenant) ID** - Also needed for Authentik

### 1.4 Create Client Secret
1. Go to **Certificates & secrets**
2. Click **New client secret**
3. Description: `UC-1 Pro Authentik Integration`
4. Expires: Choose appropriate duration (recommend 24 months)
5. Click **Add**
6. **Copy the secret value immediately** - you won't see it again!

### 1.5 Configure API Permissions
1. Go to **API permissions**
2. Click **Add a permission**
3. Select **Microsoft Graph**
4. Choose **Delegated permissions**
5. Add these permissions:
   - `openid`
   - `profile`
   - `email`
   - `User.Read`
   - `Group.Read.All` (optional, for group sync)
6. Click **Add permissions**
7. Click **Grant admin consent** (requires admin privileges)

## Step 2: Configure Authentik

### 2.1 Access Authentik Admin
1. Open browser to `http://localhost:9005`
2. Click **Sign in** 
3. Login with:
   - Email: `admin@magicunicorn.tech`
   - Password: `MagicUnicorn!Auth`

**IMPORTANT**: Change this password immediately after first login!

### 2.2 Create Microsoft Provider
1. Go to **Directory** → **Federation & Social login**
2. Click **Create** button
3. Select **Microsoft** from the provider types
4. Fill in the configuration:

**Basic Settings:**
- **Name**: `Microsoft 365`
- **Slug**: `microsoft365` (auto-generated)
- **Provider type**: `Microsoft`

**OAuth2 Settings:**
- **Client ID**: (Paste the Application ID from Azure)
- **Client Secret**: (Paste the secret you created)
- **Scopes**: `openid profile email`

**Advanced Settings:**
- **Authorization URL**: `https://login.microsoftonline.com/{tenant-id}/oauth2/v2.0/authorize`
- **Access token URL**: `https://login.microsoftonline.com/{tenant-id}/oauth2/v2.0/token`
- **Profile URL**: `https://graph.microsoft.com/v1.0/me`

Replace `{tenant-id}` with your actual tenant ID from Azure.

### 2.3 Configure User Matching
In the provider settings:
- **User matching mode**: `Link users on unique identifier`
- **User path**: `users`

### 2.4 Create Application for UC-1 Pro
1. Go to **Applications** → **Applications**
2. Click **Create**
3. Fill in:
   - **Name**: `UC-1 Pro Main`
   - **Slug**: `uc1-pro-main`
   - **Provider**: Select the Microsoft provider you just created
   - **Authorization flow**: `default-authorization-flow`

## Step 3: Group Mapping (Optional)

### 3.1 Create UC-1 Pro Groups
If not already created, set up these groups in Authentik:

1. Go to **Directory** → **Groups**
2. Create these groups:
   - `uc1-admins` - Full system access
   - `uc1-developers` - Development access  
   - `uc1-users` - Standard user access
   - `uc1-viewers` - Read-only access

### 3.2 Map Azure Groups
If you want to sync Azure AD groups:

1. In the Microsoft provider settings
2. Go to **Property mappings**
3. Create custom property mapping for groups:

```python
# Group mapping expression
import requests

# Get user's groups from Microsoft Graph
groups_response = requests.get(
    "https://graph.microsoft.com/v1.0/me/memberOf",
    headers={"Authorization": f"Bearer {access_token}"}
)

azure_groups = []
if groups_response.status_code == 200:
    groups_data = groups_response.json()
    azure_groups = [group["displayName"] for group in groups_data.get("value", [])]

# Map Azure groups to UC-1 Pro groups
group_mapping = {
    "UC1-Admins": "uc1-admins",
    "UC1-Developers": "uc1-developers", 
    "UC1-Users": "uc1-users",
    "UC1-Viewers": "uc1-viewers"
}

uc1_groups = []
for azure_group in azure_groups:
    if azure_group in group_mapping:
        uc1_groups.append(group_mapping[azure_group])

# Default to users group if no specific mapping
if not uc1_groups:
    uc1_groups = ["uc1-users"]

return uc1_groups
```

## Step 4: Test Authentication

### 4.1 Test Login Flow
1. Open new incognito/private browser window
2. Go to `http://localhost:9005`
3. Click **Sign in with Microsoft**
4. You should be redirected to Microsoft login
5. Enter your Microsoft 365 credentials
6. Grant permissions when prompted
7. You should be redirected back to Authentik and logged in

### 4.2 Verify User Creation
1. In Authentik admin, go to **Directory** → **Users**
2. You should see your Microsoft user listed
3. Check the user's groups to ensure mapping worked

## Step 5: Production Considerations

### 5.1 Domain Configuration
For production deployment:

1. **Update Azure AD Redirect URI**:
   - Change from `http://localhost:9005/...`
   - To `https://yourdomain.com/source/oauth/callback/microsoft/`

2. **Update Authentik Cookie Domain**:
   - Set `UC1_PRO_DOMAIN=yourdomain.com` in `.env`

### 5.2 Security Hardening
1. **Use HTTPS**: Configure SSL certificates
2. **Rotate Secrets**: Regularly rotate client secrets
3. **Monitor Access**: Set up logging and alerting
4. **Backup Configuration**: Export Authentik configuration regularly

## Troubleshooting

### Common Issues

1. **"Invalid Redirect URI"**:
   - Ensure redirect URI in Azure exactly matches Authentik configuration
   - Check for typos in the URL

2. **"Insufficient Privileges"**:
   - Ensure admin granted consent to API permissions
   - Check user has required permissions in Azure AD

3. **User Not Created**:
   - Check Authentik logs: `docker logs authentik-server`
   - Verify user matching mode settings

4. **Group Mapping Issues**:
   - Test group mapping expression in Authentik
   - Check Azure AD group membership

### Debug Commands

```bash
# Check Authentik logs
docker logs authentik-server -f

# Test authentication flow
curl -v "http://localhost:9005/source/oauth/login/microsoft/"

# Verify API endpoint
curl "http://localhost:9005/api/v3/sources/"
```

## Next Steps

After successful Microsoft 365 integration:

1. **Configure other services** to use Authentik for authentication
2. **Set up Traefik auth middleware** for automatic SSO
3. **Add Google Workspace** as additional provider
4. **Configure LDAP/AD** for hybrid environments
5. **Set up user provisioning** for Open-WebUI and other services

## Support

For issues with this integration:

1. Check Authentik documentation: https://docs.goauthentik.io/
2. Microsoft identity platform docs: https://docs.microsoft.com/en-us/azure/active-directory/
3. UC-1 Pro project issues: https://github.com/magicunicorn/uc1-pro/issues