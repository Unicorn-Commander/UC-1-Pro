# Google Workspace OAuth Integration Guide

This guide walks through setting up Google Workspace authentication with Authentik for UC-1 Pro.

## Prerequisites

1. **Google Workspace Admin Access**: You need admin access to your organization's Google Workspace
2. **Google Cloud Console Access**: Access to create OAuth 2.0 credentials
3. **Authentik Running**: Ensure Authentik is running on `http://localhost:9005`
4. **Domain Verification**: For production, you'll need a verified domain

## Step 1: Configure Google Cloud Console

### 1.1 Access Google Cloud Console
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select or create a project for UC-1 Pro
3. Enable necessary APIs:
   - Google Identity Platform API
   - Admin SDK API (for group sync)

### 1.2 Configure OAuth Consent Screen
1. Navigate to **APIs & Services** → **OAuth consent screen**
2. Choose user type:
   - **Internal**: For Google Workspace users only (recommended)
   - **External**: For any Google account (requires verification)
3. Fill in application information:
   - **App name**: `UC-1 Pro`
   - **User support email**: Your support email
   - **Developer contact**: Your admin email
4. Add scopes:
   - `openid`
   - `profile`
   - `email`
   - `https://www.googleapis.com/auth/admin.directory.group.readonly` (optional, for group sync)
5. Save and continue

### 1.3 Create OAuth 2.0 Credentials
1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth client ID**
3. Application type: **Web application**
4. Name: `UC-1 Pro Authentik`
5. Add authorized redirect URIs:
   ```
   http://localhost:9005/source/oauth/callback/google/
   ```
   For production, also add:
   ```
   https://yourdomain.com/source/oauth/callback/google/
   ```
6. Click **Create**
7. **Save the Client ID and Client Secret** - you'll need these for Authentik

### 1.4 Configure Domain-Wide Delegation (Optional)
For automatic group synchronization:

1. Go to **IAM & Admin** → **Service Accounts**
2. Create a service account if needed
3. Enable domain-wide delegation
4. Note the Client ID for admin console configuration

## Step 2: Configure Google Workspace Admin

### 2.1 Access Admin Console
1. Go to [Google Admin Console](https://admin.google.com)
2. Navigate to **Security** → **API controls**
3. Click **Manage Domain Wide Delegation**

### 2.2 Add Client ID (If using domain-wide delegation)
1. Click **Add new**
2. Client ID: (Service account client ID from Step 1.4)
3. OAuth scopes:
   ```
   https://www.googleapis.com/auth/admin.directory.group.readonly
   https://www.googleapis.com/auth/admin.directory.user.readonly
   ```
4. Click **Authorize**

## Step 3: Configure Authentik

### 3.1 Access Authentik Admin
1. Open browser to `http://localhost:9005`
2. Login with admin credentials

### 3.2 Create Google Provider
1. Go to **Directory** → **Federation & Social login**
2. Click **Create**
3. Select **Google** from provider types
4. Configure the provider:

**Basic Settings:**
- **Name**: `Google Workspace`
- **Slug**: `google-workspace` (auto-generated)
- **Provider type**: `Google`

**OAuth2 Settings:**
- **Client ID**: (Paste from Google Cloud Console)
- **Client Secret**: (Paste from Google Cloud Console)
- **Scopes**: `openid profile email`

**Advanced Settings (Optional):**
- **Access type**: `offline` (for refresh tokens)
- **Prompt**: `consent` (to ensure permissions)

### 3.3 Configure User Matching
- **User matching mode**: `Link users on unique identifier`
- **User path template**: `google-%(user_id)s`

### 3.4 Create Application
1. Go to **Applications** → **Applications**
2. Click **Create**
3. Configure:
   - **Name**: `UC-1 Pro Google`
   - **Slug**: `uc1-pro-google`
   - **Provider**: Select the Google provider
   - **Authorization flow**: `default-authorization-flow`

## Step 4: Group Mapping Configuration

### 4.1 Create Group Mapping Expression
In Authentik, create a property mapping for Google groups:

1. Go to **Customization** → **Property Mappings**
2. Click **Create** → **SAML Property Mapping**
3. Name: `Google Workspace Group Mapping`
4. Expression:

```python
# Google Workspace Group Mapping
import requests
from authentik.sources.oauth.models import OAuthSource

# Get Google groups if domain-wide delegation is configured
google_groups = []
if hasattr(request.user, 'oauth_sources'):
    for source in request.user.oauth_sources.all():
        if source.provider_type == 'google':
            # Fetch groups from Google Admin API
            try:
                token = source.access_token
                headers = {'Authorization': f'Bearer {token}'}
                response = requests.get(
                    f'https://admin.googleapis.com/admin/directory/v1/groups?userKey={request.user.email}',
                    headers=headers
                )
                if response.status_code == 200:
                    groups_data = response.json()
                    google_groups = [g['name'] for g in groups_data.get('groups', [])]
            except:
                pass

# Map Google groups to UC-1 Pro groups
group_mapping = {
    'uc1-admins@yourdomain.com': 'uc1-admins',
    'uc1-developers@yourdomain.com': 'uc1-developers',
    'uc1-users@yourdomain.com': 'uc1-users',
    'uc1-viewers@yourdomain.com': 'uc1-viewers',
}

uc1_groups = []
for google_group in google_groups:
    if google_group in group_mapping:
        uc1_groups.append(group_mapping[google_group])

# Default to users group if no mapping
if not uc1_groups:
    uc1_groups = ['uc1-users']

return uc1_groups
```

### 4.2 Apply Mapping to Provider
1. Edit the Google provider
2. Under **Property mappings**, add the created mapping
3. Save the provider

## Step 5: Configure Organizational Units (Optional)

For organizations using Google Workspace organizational units:

### 5.1 Create OU-Based Access Rules
1. In Authentik, go to **Policies** → **Policies**
2. Create expression policy for OU-based access:

```python
# Check user's organizational unit
user_email = request.user.email
domain = user_email.split('@')[1]

# Define OU access rules
ou_rules = {
    'engineering': ['uc1-developers', 'uc1-users'],
    'management': ['uc1-admins', 'uc1-viewers'],
    'support': ['uc1-users', 'uc1-viewers'],
}

# Get user's OU from attributes (if synced)
user_ou = request.user.attributes.get('ou', 'default')

# Apply appropriate groups
if user_ou in ou_rules:
    for group_name in ou_rules[user_ou]:
        # Add user to group
        pass

return True
```

## Step 6: Test Authentication

### 6.1 Test Login Flow
1. Open incognito browser window
2. Navigate to `http://localhost:9005`
3. Click **Sign in with Google**
4. Select or enter Google account
5. Grant permissions when prompted
6. Verify successful redirect and login

### 6.2 Verify User Creation
1. In Authentik admin, go to **Directory** → **Users**
2. Find the Google user
3. Check groups and attributes

### 6.3 Test Group Sync (if configured)
1. Check if user's Google groups are mapped
2. Verify UC-1 Pro group membership

## Step 7: Production Configuration

### 7.1 Update Redirect URIs
1. In Google Cloud Console, add production redirect URI:
   ```
   https://yourdomain.com/source/oauth/callback/google/
   ```

### 7.2 Configure SSL/TLS
1. Set up proper certificates
2. Update Authentik to use HTTPS
3. Update all redirect URIs

### 7.3 Set Up Domain Restrictions
For Google Workspace organizations:

1. In the Google provider settings
2. Add domain restriction expression:

```python
# Only allow users from specific domains
allowed_domains = ['yourdomain.com', 'subsidiary.com']
user_email = request.user.email
user_domain = user_email.split('@')[1]

if user_domain not in allowed_domains:
    ak_message("Access denied: Invalid domain")
    return False

return True
```

## Step 8: Advanced Features

### 8.1 Google Workspace Directory Sync
Set up automatic user provisioning:

1. Create scheduled task in Authentik
2. Sync users from Google Workspace directory
3. Map organizational structure

### 8.2 Two-Factor Authentication
Leverage Google's 2FA:

1. Configure Authentik to trust Google's MFA
2. Disable Authentik's built-in MFA for Google users
3. Enforce 2FA in Google Workspace admin

### 8.3 Session Management
Configure session policies:

1. Set session timeout
2. Configure concurrent session limits
3. Set up device trust policies

## Troubleshooting

### Common Issues

1. **"Access blocked: This app's request is invalid"**
   - Check redirect URI matches exactly
   - Verify OAuth consent screen configuration
   - Ensure scopes are authorized

2. **"403: access_denied"**
   - Check if user is in allowed domain
   - Verify Google Workspace allows OAuth apps
   - Check organizational policies

3. **Groups not syncing**
   - Verify Admin SDK API is enabled
   - Check service account has proper delegation
   - Ensure correct scopes are configured

4. **"Invalid client"**
   - Verify Client ID and Secret are correct
   - Check credentials haven't expired
   - Ensure provider configuration matches

### Debug Commands

```bash
# Check Authentik logs
docker logs authentik-server -f | grep google

# Test OAuth endpoint
curl -v "http://localhost:9005/source/oauth/login/google/"

# Verify provider configuration
curl "http://localhost:9005/api/v3/sources/oauth/" \
  -H "Authorization: Bearer YOUR_API_TOKEN"
```

### Log Analysis
Check these log locations:

```bash
# Authentik server logs
docker logs authentik-server

# Authentik worker logs
docker logs authentik-worker

# Check for OAuth errors
docker logs authentik-server | grep -i "oauth\|google"
```

## Security Best Practices

1. **Limit Scopes**: Only request necessary permissions
2. **Domain Restrictions**: Limit to organization domains
3. **Regular Audits**: Review connected accounts regularly
4. **Token Rotation**: Enable refresh token rotation
5. **Monitor Access**: Set up alerts for suspicious activity

## Integration with UC-1 Pro Services

After successful Google Workspace integration:

1. **Open-WebUI**: Users can SSO directly
2. **Ops Center**: Admin access based on groups
3. **API Access**: Use Google identity for API authentication
4. **Service Mesh**: Automatic authentication via Traefik

## Next Steps

1. **Test with real users** from your organization
2. **Configure group mappings** for your team structure
3. **Set up automated provisioning** for new employees
4. **Enable audit logging** for compliance
5. **Configure other providers** (LDAP, SAML)

## Support Resources

- Authentik Documentation: https://docs.goauthentik.io/
- Google Identity Platform: https://developers.google.com/identity
- Google Workspace Admin: https://support.google.com/a
- UC-1 Pro Issues: https://github.com/magicunicorn/uc1-pro/issues