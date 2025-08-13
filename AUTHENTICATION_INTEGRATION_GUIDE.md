# UC-1 Pro Authentication Integration Guide

## Overview

This guide walks you through integrating Authentik SSO with all UC-1 Pro services. After completing these steps, all services will use unified authentication.

## Prerequisites

✅ Authentik is running (`make auth-start`)  
✅ You can access Authentik at http://localhost:9005  
✅ You have admin credentials (admin@magicunicorn.tech / MagicUnicorn!Auth)

## Integration Steps

### Step 1: Run Configuration Script

```bash
# This interactive script guides you through Authentik setup
./scripts/configure-authentik-apps.sh
```

The script will help you:
1. Create OAuth providers for each service
2. Configure applications in Authentik
3. Set up proxy providers
4. Create an outpost for ForwardAuth

### Step 2: Manual Configuration in Authentik Admin

#### A. Create OAuth Provider for Open-WebUI

1. Login to Authentik: http://localhost:9005
2. Navigate to **Applications** → **Providers** → **Create**
3. Select **OAuth2/OpenID Provider**
4. Configure:
   ```yaml
   Name: Open-WebUI OAuth
   Client type: Confidential
   Client ID: open-webui
   Client Secret: [Generated - copy this!]
   Redirect URIs:
     - http://localhost:8080/oauth/oidc/callback
     - http://chat.localhost/oauth/oidc/callback
   Scopes: openid, email, profile, groups
   ```
5. Save and copy the Client Secret

#### B. Create Proxy Providers for Other Services

For each service (Ops Center, vLLM, Center-Deep), create a proxy provider:

1. **Applications** → **Providers** → **Create** → **Proxy Provider**

2. **Ops Center:**
   ```yaml
   Name: Ops Center Proxy
   External host: http://admin.localhost
   Internal host: http://unicorn-ops-center:8084
   ```

3. **vLLM API:**
   ```yaml
   Name: vLLM API Proxy
   External host: http://api.localhost
   Internal host: http://unicorn-vllm:8000
   ```

4. **Center-Deep Search:**
   ```yaml
   Name: Center-Deep Proxy
   External host: http://search.localhost
   Internal host: http://unicorn-searxng:8890
   ```

#### C. Create Applications

For each provider, create an application:

1. **Applications** → **Applications** → **Create**
2. Link each application to its provider
3. Set access policies (which groups can access)

#### D. Create Outpost

1. **Applications** → **Outposts** → **Create**
2. Configure:
   ```yaml
   Name: UC-1 Pro Proxy
   Type: Proxy
   Integration: Local Docker connection
   Applications: [Select all created applications]
   ```
3. Copy the generated token

### Step 3: Update Docker Compose

Add OAuth environment variables to your main docker-compose.yml:

```yaml
services:
  open-webui:
    environment:
      # Add these OAuth settings
      ENABLE_OAUTH_SIGNUP: "true"
      OPENID_PROVIDER_URL: "http://authentik-server:9000/application/o/open-webui/"
      OPENID_CLIENT_ID: "open-webui"
      OPENID_CLIENT_SECRET: "${OPENWEBUI_OAUTH_CLIENT_SECRET}"
      OPENID_REDIRECT_URI: "http://localhost:8080/oauth/oidc/callback"
      OPENID_SCOPE: "openid profile email groups"
      OPENID_PROVIDER_DISPLAY_NAME: "UC-1 Pro SSO"
```

### Step 4: Update Environment Variables

Add to your `.env` file:

```bash
# Authentik OAuth Configuration
OPENWEBUI_OAUTH_CLIENT_ID=open-webui
OPENWEBUI_OAUTH_CLIENT_SECRET=your-secret-here
AUTHENTIK_OUTPOST_TOKEN=your-outpost-token-here
```

### Step 5: Configure Service-Specific Authentication

#### Open-WebUI

Open-WebUI will automatically show "Login with UC-1 Pro SSO" button after restart.

```bash
# Restart to apply OAuth
docker-compose restart open-webui
```

#### Ops Center

The Ops Center already reads auth headers. No additional configuration needed if using Traefik.

#### vLLM API

For API authentication, users need to get tokens from Authentik:

```python
# Example: Using Authentik token with vLLM
import requests

# Get token from Authentik
token = "your-authentik-api-token"

# Use with vLLM API
response = requests.post(
    "http://localhost:8000/v1/completions",
    headers={"Authorization": f"Bearer {token}"},
    json={"model": "Qwen/Qwen2.5-32B-Instruct-AWQ", "prompt": "Hello"}
)
```

### Step 6: Enable Traefik Proxy (Optional but Recommended)

Traefik provides automatic authentication for all services:

```bash
# Setup and start Traefik
./scripts/setup-traefik-auth.sh

# Add to /etc/hosts
127.0.0.1    chat.localhost admin.localhost api.localhost search.localhost
```

With Traefik enabled, access services via subdomains:
- http://chat.localhost - Open-WebUI
- http://admin.localhost - Ops Center  
- http://api.localhost - vLLM API
- http://search.localhost - Center-Deep

### Step 7: Test Authentication

#### Test Checklist

- [ ] **Open-WebUI**: Visit http://localhost:8080
  - Should show "Login with UC-1 Pro SSO" button
  - Clicking redirects to Authentik
  - After login, returns to Open-WebUI

- [ ] **With Traefik**: Visit http://admin.localhost
  - Should redirect to Authentik login
  - After login, shows Ops Center

- [ ] **API Access**: Test with curl
  ```bash
  # Should get 401 without auth
  curl http://localhost:8000/v1/models
  
  # Should work with token
  curl http://localhost:8000/v1/models \
    -H "Authorization: Bearer YOUR_TOKEN"
  ```

### Step 8: Configure User Groups

In Authentik, assign users to groups:

1. **Directory** → **Groups**
2. Create/verify groups exist:
   - `uc1-admins` - Full access
   - `uc1-developers` - API and development tools
   - `uc1-users` - Chat and search
   - `uc1-viewers` - Read-only

3. **Directory** → **Users**
4. Edit user → Groups → Add to appropriate groups

## Service Integration Status

| Service | OAuth Support | Proxy Support | Status |
|---------|--------------|---------------|--------|
| Open-WebUI | ✅ Native OIDC | ✅ Traefik | Ready |
| Ops Center | ❌ Header auth | ✅ Traefik | Ready with proxy |
| vLLM API | ❌ Token auth | ✅ Traefik | Ready with proxy |
| Center-Deep | ❌ Basic auth | ✅ Traefik | Ready with proxy |
| Qdrant | ❌ API key | ✅ Traefik | Ready with proxy |
| WhisperX | ❌ No auth | ✅ Traefik | Ready with proxy |
| Kokoro TTS | ❌ No auth | ✅ Traefik | Ready with proxy |

## Troubleshooting

### "Login with SSO" button not appearing

1. Check Open-WebUI environment variables:
   ```bash
   docker exec unicorn-open-webui env | grep OPENID
   ```

2. Restart Open-WebUI:
   ```bash
   docker-compose restart open-webui
   ```

### Authentication loop

1. Clear browser cookies
2. Check Authentik logs:
   ```bash
   docker logs authentik-server -f
   ```

### "Invalid redirect URI" error

1. Verify redirect URIs in Authentik match exactly
2. Check for trailing slashes
3. Ensure ports are correct

### Services not accessible via Traefik

1. Check hosts file entries
2. Verify Traefik is running:
   ```bash
   docker ps | grep traefik
   ```
3. Check Traefik logs:
   ```bash
   docker logs unicorn-traefik -f
   ```

## Quick Commands

```bash
# Start everything
make auth-start
docker-compose up -d

# Configure applications
./scripts/configure-authentik-apps.sh

# Test authentication
make auth-test

# View logs
make auth-logs
docker logs unicorn-open-webui -f

# Restart services
docker-compose restart open-webui
docker-compose restart authentik-server
```

## Next Steps

After completing integration:

1. **Configure identity providers** (Microsoft 365, Google Workspace)
2. **Set up user groups** and permissions
3. **Enable MFA** for admin accounts
4. **Configure backup** for Authentik database
5. **Set up monitoring** for authentication events

## Support

- Check logs: `make auth-logs`
- Authentik Admin: http://localhost:9005
- Documentation: `/services/authentik/README.md`
- Test scripts: `make auth-test`