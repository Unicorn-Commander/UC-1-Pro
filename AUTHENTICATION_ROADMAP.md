# UC-1 Pro Enterprise Authentication Roadmap

## 🎯 Executive Summary

UC-1 Pro will implement a comprehensive enterprise authentication system supporting Microsoft 365, Google Workspace, LDAP/AD, and local accounts with unified SSO across all services including Open-WebUI.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Users/Organizations                      │
└─────────────────┬───────────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────────┐
│              UC-1 Pro Authentication Gateway                 │
│                                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
│  │   M365   │ │  Google  │ │   LDAP   │ │    Local     │  │
│  │  Entra   │ │Workspace │ │    AD    │ │   Accounts   │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────┘  │
│                                                              │
│                    JWT Token Management                      │
│                    Session Orchestration                     │
│                         RBAC Engine                          │
└─────────────────┬───────────────────────────────────────────┘
                  │
    ┌─────────────┼─────────────┬────────────┬────────────┐
    │             │             │            │            │
┌───▼──┐  ┌──────▼──────┐  ┌───▼───┐  ┌────▼────┐  ┌─────▼────┐
│ Ops  │  │  Open-WebUI │  │ vLLM  │  │ Center  │  │ Other    │
│Center│  │   (Chat)    │  │  API  │  │  Deep   │  │ Services │
└──────┘  └─────────────┘  └───────┘  └─────────┘  └──────────┘
```

## 📋 Implementation Phases

### Phase 1: Authentication Foundation (Week 1-2)

#### 1.1 Core Authentication Service
```python
# /services/auth/server.py
- FastAPI authentication service
- JWT token generation/validation
- Session management
- Redis session store
- PostgreSQL user database
```

#### 1.2 Database Schema
```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE,
    display_name VARCHAR(255),
    auth_provider VARCHAR(50), -- local/microsoft/google/ldap
    provider_id VARCHAR(255),
    organization_id UUID,
    created_at TIMESTAMP,
    last_login TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    mfa_enabled BOOLEAN DEFAULT false
);

-- Organizations table
CREATE TABLE organizations (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    domain VARCHAR(255) UNIQUE,
    auth_provider VARCHAR(50),
    settings JSONB,
    created_at TIMESTAMP
);

-- Roles table
CREATE TABLE roles (
    id UUID PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    permissions JSONB,
    organization_id UUID,
    is_system BOOLEAN DEFAULT false
);

-- User roles mapping
CREATE TABLE user_roles (
    user_id UUID REFERENCES users(id),
    role_id UUID REFERENCES roles(id),
    granted_at TIMESTAMP,
    granted_by UUID,
    PRIMARY KEY (user_id, role_id)
);
```

### Phase 2: Microsoft 365/Entra ID Integration (Week 2-3)

#### 2.1 Azure AD App Registration
```yaml
# Required Permissions:
- User.Read
- User.ReadBasic.All
- Group.Read.All
- Directory.Read.All
- Mail.Send (optional for notifications)

# Redirect URIs:
- http://localhost:8084/auth/microsoft/callback
- https://your-domain.com/auth/microsoft/callback
```

#### 2.2 Implementation
```python
# Using MSAL Python
from msal import ConfidentialClientApplication

class MicrosoftAuthProvider:
    def __init__(self):
        self.app = ConfidentialClientApplication(
            client_id=AZURE_CLIENT_ID,
            client_credential=AZURE_CLIENT_SECRET,
            authority=f"https://login.microsoftonline.com/{TENANT_ID}"
        )
    
    async def authenticate(self, auth_code):
        # Exchange code for tokens
        result = self.app.acquire_token_by_authorization_code(
            auth_code,
            scopes=["User.Read", "Group.Read.All"],
            redirect_uri=REDIRECT_URI
        )
        
        # Get user info from Graph API
        user_info = await self.get_user_info(result["access_token"])
        
        # Map AD groups to roles
        groups = await self.get_user_groups(result["access_token"])
        roles = self.map_groups_to_roles(groups)
        
        return user_info, roles
```

### Phase 3: Google Workspace Integration (Week 3-4)

#### 3.1 Google Cloud Setup
```yaml
# OAuth 2.0 Client Configuration
- Application Type: Web Application
- Authorized JavaScript origins:
  - http://localhost:8084
  - https://your-domain.com
- Authorized redirect URIs:
  - http://localhost:8084/auth/google/callback
  - https://your-domain.com/auth/google/callback

# Required APIs:
- Google Identity Platform
- Admin SDK API
- Directory API
```

#### 3.2 Implementation
```python
from google.auth.transport import requests
from google.oauth2 import id_token
import google_auth_oauthlib.flow

class GoogleAuthProvider:
    def __init__(self):
        self.flow = google_auth_oauthlib.flow.Flow.from_client_config(
            GOOGLE_CLIENT_CONFIG,
            scopes=['openid', 'email', 'profile', 
                   'https://www.googleapis.com/auth/admin.directory.user.readonly']
        )
    
    async def authenticate(self, auth_code):
        # Exchange code for tokens
        self.flow.fetch_token(code=auth_code)
        
        # Verify and decode ID token
        idinfo = id_token.verify_oauth2_token(
            self.flow.credentials.id_token,
            requests.Request(),
            GOOGLE_CLIENT_ID
        )
        
        # Check if user belongs to organization
        if idinfo['hd'] != ALLOWED_DOMAIN:
            raise UnauthorizedError("Invalid organization domain")
        
        # Get user groups from Directory API
        groups = await self.get_user_groups(idinfo['email'])
        roles = self.map_groups_to_roles(groups)
        
        return idinfo, roles
```

### Phase 4: LDAP/Active Directory Integration (Week 4-5)

#### 4.1 LDAP Configuration
```python
import ldap3
from ldap3 import Server, Connection, ALL

class LDAPAuthProvider:
    def __init__(self):
        self.server = Server(
            LDAP_SERVER,
            port=LDAP_PORT,
            use_ssl=LDAP_USE_SSL,
            get_info=ALL
        )
    
    async def authenticate(self, username, password):
        # Bind with user credentials
        user_dn = f"{LDAP_USER_RDN_ATTR}={username},{LDAP_USER_BASE_DN}"
        
        try:
            conn = Connection(
                self.server,
                user=user_dn,
                password=password,
                auto_bind=True
            )
            
            # Get user attributes
            conn.search(
                user_dn,
                '(objectClass=person)',
                attributes=['*']
            )
            user_info = conn.entries[0]
            
            # Get user groups
            groups = await self.get_user_groups(user_dn)
            roles = self.map_groups_to_roles(groups)
            
            return user_info, roles
            
        except ldap3.core.exceptions.LDAPBindError:
            raise AuthenticationError("Invalid credentials")
```

### Phase 5: Unified Authentication Gateway (Week 5-6)

#### 5.1 Auth Middleware
```python
from fastapi import Request, HTTPException
from fastapi.security import HTTPBearer

class AuthMiddleware:
    async def __call__(self, request: Request, call_next):
        # Skip auth for public endpoints
        if request.url.path in PUBLIC_ENDPOINTS:
            return await call_next(request)
        
        # Extract token
        token = self.extract_token(request)
        if not token:
            raise HTTPException(401, "Authentication required")
        
        # Validate token
        payload = self.validate_jwt(token)
        
        # Check permissions
        if not self.check_permissions(payload, request):
            raise HTTPException(403, "Insufficient permissions")
        
        # Add user context to request
        request.state.user = payload
        
        return await call_next(request)
```

#### 5.2 Open-WebUI Integration
```yaml
# docker-compose.yml modification
services:
  auth-proxy:
    image: uc1-pro-auth-proxy
    environment:
      - UPSTREAM_URL=http://unicorn-open-webui:8080
      - AUTH_SERVICE_URL=http://unicorn-auth:8085
      - JWT_SECRET=${JWT_SECRET}
    ports:
      - "8080:8080"
    depends_on:
      - auth-service
      - open-webui
```

### Phase 6: User Registration & Self-Service (Week 6-7)

#### 6.1 Registration Flow
```python
class RegistrationService:
    async def register_user(self, registration_data):
        # Validate email domain
        domain = registration_data.email.split('@')[1]
        org = await self.get_organization_by_domain(domain)
        
        if org and org.auth_provider != 'local':
            raise ValidationError(
                f"Please use {org.auth_provider} SSO to sign in"
            )
        
        # Create user account
        user = await self.create_user(registration_data)
        
        # Send verification email
        await self.send_verification_email(user)
        
        # Assign default role based on organization
        if org:
            default_role = org.settings.get('default_role', 'user')
            await self.assign_role(user, default_role)
        
        return user
```

#### 6.2 Frontend Components
```jsx
// LoginPage.jsx
function LoginPage() {
  const [authMethod, setAuthMethod] = useState('detect');
  
  const handleEmailChange = (email) => {
    // Auto-detect organization from email
    const domain = email.split('@')[1];
    detectAuthMethod(domain).then(method => {
      setAuthMethod(method);
      
      if (method === 'microsoft') {
        // Redirect to Microsoft login
        window.location.href = '/auth/microsoft/login';
      } else if (method === 'google') {
        // Redirect to Google login
        window.location.href = '/auth/google/login';
      }
    });
  };
  
  return (
    <div className="login-container">
      <input 
        type="email" 
        placeholder="Enter your email"
        onChange={(e) => handleEmailChange(e.target.value)}
      />
      
      {authMethod === 'local' && (
        <>
          <input type="password" placeholder="Password" />
          <button>Sign In</button>
          <a href="/register">Register new account</a>
        </>
      )}
      
      <div className="sso-options">
        <button onClick={() => loginWithMicrosoft()}>
          Sign in with Microsoft
        </button>
        <button onClick={() => loginWithGoogle()}>
          Sign in with Google  
        </button>
        <button onClick={() => setAuthMethod('ldap')}>
          Sign in with LDAP
        </button>
      </div>
    </div>
  );
}
```

## 🔒 Security Considerations

### Token Management
- JWT tokens with 15-minute expiry
- Refresh tokens with 7-day expiry
- Secure httpOnly cookies for web
- Token rotation on refresh
- Blacklist for revoked tokens

### Session Security
- Redis session store with TTL
- Device fingerprinting
- IP address validation
- Concurrent session limits
- Automatic logout on suspicious activity

### MFA Support
- TOTP (Google Authenticator, Authy)
- WebAuthn/FIDO2 for hardware keys
- SMS backup codes (optional)
- App-specific passwords for API access

## 📊 Role Definitions

### Default System Roles

| Role | Description | Key Permissions |
|------|-------------|-----------------|
| **Admin** | Full system access | All permissions |
| **Developer** | Development access | Deploy models, manage services, view logs |
| **User** | Standard user | Use AI services, manage own resources |
| **Viewer** | Read-only access | View dashboards, reports |

### Permission Examples
```json
{
  "admin": {
    "system": ["*"],
    "models": ["*"],
    "users": ["*"],
    "services": ["*"]
  },
  "developer": {
    "system": ["read", "monitor"],
    "models": ["read", "deploy", "delete"],
    "users": ["read:self", "update:self"],
    "services": ["read", "restart", "logs"]
  },
  "user": {
    "system": ["read:basic"],
    "models": ["read", "use"],
    "users": ["read:self", "update:self"],
    "services": ["read:status"]
  }
}
```

## 🚀 Quick Start Guide

### 1. Enable Microsoft 365 Authentication
```bash
# Set environment variables
export AZURE_CLIENT_ID="your-client-id"
export AZURE_CLIENT_SECRET="your-client-secret"
export AZURE_TENANT_ID="your-tenant-id"

# Enable in config
./scripts/configure-auth.sh --provider microsoft
```

### 2. Enable Google Workspace
```bash
# Set environment variables
export GOOGLE_CLIENT_ID="your-client-id"
export GOOGLE_CLIENT_SECRET="your-client-secret"
export GOOGLE_ALLOWED_DOMAIN="your-company.com"

# Enable in config
./scripts/configure-auth.sh --provider google
```

### 3. Enable LDAP
```bash
# Configure LDAP settings
export LDAP_SERVER="ldap://your-domain.com"
export LDAP_BASE_DN="dc=your-domain,dc=com"
export LDAP_USER_RDN_ATTR="uid"

# Enable in config
./scripts/configure-auth.sh --provider ldap
```

## 📈 Success Metrics

- **Authentication Success Rate**: > 99.9%
- **SSO Login Time**: < 2 seconds
- **Token Validation Time**: < 50ms
- **Session Sync Latency**: < 100ms
- **MFA Adoption Rate**: > 80% for admins

## 🔄 Migration Path

1. **Phase 1**: Deploy auth service alongside existing basic auth
2. **Phase 2**: Migrate admin users to new auth system
3. **Phase 3**: Enable SSO for pilot organizations
4. **Phase 4**: Full migration with backwards compatibility
5. **Phase 5**: Deprecate old auth system

## 📝 Compliance & Standards

- **OAuth 2.0 / OpenID Connect**: Industry standard protocols
- **SAML 2.0**: Enterprise SSO compatibility
- **GDPR**: User data protection and right to deletion
- **SOC 2**: Audit logging and access controls
- **HIPAA**: Healthcare data protection (optional module)

---

**Next Steps**: Begin with Phase 1 authentication foundation, then progressively add identity providers based on customer requirements.