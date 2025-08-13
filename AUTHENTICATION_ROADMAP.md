# UC-1 Pro Authentication & SSO Implementation Guide

## 🚀 Current Implementation Status

UC-1 Pro now features enterprise-grade SSO authentication using **Authentik** with support for:
- ✅ Microsoft 365 / Entra ID
- ✅ Google Workspace
- ✅ LDAP / Active Directory
- ✅ Local accounts
- ✅ Traefik reverse proxy with ForwardAuth

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Users                                │
└─────────────┬───────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Traefik Reverse Proxy                     │
│                  (ForwardAuth Middleware)                    │
└─────────────┬───────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Authentik SSO (Port 9005)                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │Microsoft │  │  Google  │  │LDAP/AD   │  │  Local   │   │
│  │   365    │  │Workspace │  │          │  │ Accounts │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────┬───────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────┐
│                    UC-1 Pro Services                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │Open-WebUI│  │Ops Center│  │  vLLM    │  │Center-Deep│  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Start Authentication Services

```bash
# Start Authentik SSO
make auth-start

# Setup Traefik proxy (optional)
./scripts/setup-traefik-auth.sh

# Check status
make auth-status
```

### 2. Configure Identity Providers

#### Microsoft 365 / Entra ID
```bash
# Interactive configuration
make auth-setup-m365

# Test configuration
make auth-test-m365
```

#### Google Workspace
```bash
# Interactive configuration
make auth-setup-google

# Test configuration
make auth-test-google
```

### 3. Access Services

| Service | URL | Default Access |
|---------|-----|----------------|
| Authentik Admin | http://localhost:9005 | admin@magicunicorn.tech / MagicUnicorn!Auth |
| Chat Interface | http://chat.localhost | Authenticated Users |
| Admin Dashboard | http://admin.localhost | Administrators |
| API Gateway | http://api.localhost | Developers |
| Search Engine | http://search.localhost | Authenticated Users |

## Identity Provider Setup

### Microsoft 365 / Entra ID

1. **Azure Portal Configuration**
   - Register application in Azure AD
   - Add redirect URI: `http://localhost:9005/source/oauth/callback/microsoft/`
   - Grant permissions: openid, profile, email, User.Read
   - Create client secret

2. **Run Configuration Script**
   ```bash
   make auth-setup-m365
   # Enter: Tenant ID, Client ID, Client Secret
   ```

3. **Complete in Authentik Admin**
   - Login to http://localhost:9005
   - Create Microsoft provider with provided details
   - Test authentication flow

**Full Guide**: `/services/authentik/setup-microsoft365.md`

### Google Workspace

1. **Google Cloud Console**
   - Create OAuth 2.0 credentials
   - Configure consent screen
   - Add redirect URI: `http://localhost:9005/source/oauth/callback/google/`
   - Enable required APIs

2. **Run Configuration Script**
   ```bash
   make auth-setup-google
   # Enter: Client ID, Client Secret, Domain
   ```

3. **Complete in Authentik Admin**
   - Create Google provider
   - Configure domain restrictions
   - Test authentication

**Full Guide**: `/services/authentik/setup-google-workspace.md`

### LDAP / Active Directory

1. **Prerequisites**
   - LDAP server accessible from UC-1 Pro
   - Service account with read permissions
   - Base DN and search filters

2. **Configuration in Authentik**
   ```yaml
   Server URI: ldap://your-domain-controller
   Bind DN: CN=Service,CN=Users,DC=company,DC=com
   Base DN: CN=Users,DC=company,DC=com
   ```

## Group-Based Access Control

### Default Groups

| Group | Description | Permissions |
|-------|-------------|-------------|
| `uc1-admins` | Administrators | Full system access |
| `uc1-developers` | Development team | API, tools, logs |
| `uc1-users` | Standard users | Chat, search |
| `uc1-viewers` | Read-only | Dashboards, reports |

### Service Access Matrix

| Service | Admins | Developers | Users | Viewers | Public |
|---------|:------:|:----------:|:-----:|:-------:|:------:|
| Open-WebUI | ✅ | ✅ | ✅ | ✅ | ❌ |
| Ops Center | ✅ | ❌ | ❌ | ❌ | ❌ |
| vLLM API | ✅ | ✅ | ❌ | ❌ | ❌ |
| Center-Deep | ✅ | ✅ | ✅ | ✅ | ❌ |
| Qdrant | ✅ | ✅ | ❌ | ❌ | ❌ |
| Monitoring | ✅ | ✅ | ❌ | ✅ | ❌ |
| Documentation | ✅ | ✅ | ✅ | ✅ | ✅ |

## Traefik Integration (Optional)

Enable subdomain-based routing with automatic SSO:

```bash
# Setup Traefik with Authentik
./scripts/setup-traefik-auth.sh

# Access services via subdomains
http://chat.localhost      # Open-WebUI
http://admin.localhost      # Ops Center
http://api.localhost        # vLLM API
http://search.localhost     # Center-Deep
```

## API Authentication

### Get API Token
```bash
# Via Authentik UI
1. Login to http://localhost:9005
2. Navigate to Directory → Tokens
3. Create new token with desired scope

# Via API
curl -X POST http://localhost:9005/api/v3/tokens/ \
  -H "Content-Type: application/json" \
  -d '{"identifier": "api-token", "user": "admin@magicunicorn.tech"}'
```

### Use Token
```bash
# Example API call
curl http://localhost:8000/v1/models \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Security Configuration

### Session Settings
- Session timeout: 8 hours
- Concurrent sessions: 3 per user
- Remember me: 30 days
- Idle timeout: 30 minutes

### Password Policy
- Minimum length: 12 characters
- Complexity: Upper, lower, number, special
- History: Last 5 passwords
- Lockout: 5 failed attempts

### Multi-Factor Authentication
- TOTP (Google Authenticator, Authy)
- WebAuthn (Hardware keys)
- SMS (optional)
- Email OTP

## Troubleshooting

### Common Issues

**"Port already in use" error**
```bash
# Check what's using port 9005
sudo lsof -i :9005
# Stop conflicting service or use different port
```

**"Access denied" after login**
- Check user group membership in Authentik
- Verify service access policies
- Review Traefik middleware logs

**SSO login loops**
- Clear browser cookies
- Check redirect URI configuration
- Verify provider settings match exactly

### Debug Commands
```bash
# Check Authentik logs
docker logs authentik-server -f

# Test authentication
make auth-test

# Check service status
docker-compose ps | grep authentik

# View user details
curl http://localhost:9005/api/v3/core/users/ \
  -H "Authorization: Bearer TOKEN"
```

## Production Deployment

### Prerequisites
- [ ] Valid SSL certificates
- [ ] Public domain name
- [ ] Firewall configuration
- [ ] Backup strategy

### Checklist
1. **Update redirect URIs** in all providers
2. **Configure SSL/TLS** in Traefik
3. **Set production secrets** in .env
4. **Enable audit logging**
5. **Configure backup schedule**
6. **Set up monitoring alerts**

### Environment Variables
```bash
# Production .env additions
UC1_PRO_DOMAIN=yourdomain.com
AUTHENTIK_COOKIE_DOMAIN=yourdomain.com
AUTHENTIK_ERROR_REPORTING__ENABLED=true
AUTHENTIK_LOG_LEVEL=info
```

## File Structure

```
/home/ucadmin/UC-1-Pro/
├── services/
│   ├── authentik/
│   │   ├── docker-compose.yml        # Authentik services
│   │   ├── README.md                 # Authentik documentation
│   │   ├── setup-microsoft365.md     # Microsoft 365 guide
│   │   ├── setup-google-workspace.md # Google Workspace guide
│   │   └── blueprints/               # Provider templates
│   └── traefik/
│       ├── docker-compose.yml        # Traefik proxy
│       └── config/                   # Routing rules
├── scripts/
│   ├── setup-authentik.sh            # Initial setup
│   ├── configure-microsoft365-sso.sh # Microsoft 365 config
│   ├── configure-google-sso.sh       # Google config
│   ├── test-authentik.sh             # Test integration
│   ├── test-microsoft365-sso.sh      # Test Microsoft
│   └── test-google-sso.sh            # Test Google
└── .env                              # Environment variables
```

## Support Resources

### Documentation
- **Setup Guides**: `/services/authentik/setup-*.md`
- **Authentik Docs**: https://docs.goauthentik.io/
- **Traefik Docs**: https://doc.traefik.io/traefik/

### Commands
```bash
# View all auth commands
make help | grep auth

# Common operations
make auth-start      # Start SSO
make auth-logs       # View logs
make auth-test       # Test setup
make auth-stop       # Stop SSO
```

## Roadmap

### ✅ Completed
- Authentik SSO deployment
- Microsoft 365 integration
- Google Workspace support
- Traefik proxy configuration
- Group-based access control
- Setup scripts and documentation

### 🔄 In Progress
- Open-WebUI user provisioning
- API token management
- Audit logging

### 📋 Planned
- SAML 2.0 support
- Advanced MFA policies
- User self-service portal
- Compliance reporting
- Zero-trust architecture

---

**Version**: 1.0.0  
**Last Updated**: August 2025  
**Maintainer**: UC-1 Pro Team