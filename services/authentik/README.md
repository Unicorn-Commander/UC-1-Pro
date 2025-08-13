# Authentik SSO for UC-1 Pro

## Overview

Authentik provides enterprise-grade authentication and authorization for UC-1 Pro, supporting Microsoft 365, Google Workspace, LDAP/AD, and local accounts with unified SSO across all services.

## Quick Start

### 1. Generate Required Secrets

```bash
# Generate Authentik secret key
export AUTHENTIK_SECRET_KEY=$(openssl rand -base64 32)

# Generate PostgreSQL password
export AUTHENTIK_POSTGRESQL_PASSWORD=$(openssl rand -base64 24)

# Generate bootstrap token
export AUTHENTIK_BOOTSTRAP_TOKEN=$(openssl rand -base64 32)

# Add to main .env file
echo "AUTHENTIK_SECRET_KEY=${AUTHENTIK_SECRET_KEY}" >> ../../.env
echo "AUTHENTIK_POSTGRESQL_PASSWORD=${AUTHENTIK_POSTGRESQL_PASSWORD}" >> ../../.env
echo "AUTHENTIK_BOOTSTRAP_TOKEN=${AUTHENTIK_BOOTSTRAP_TOKEN}" >> ../../.env
echo "AUTHENTIK_BOOTSTRAP_EMAIL=admin@magicunicorn.tech" >> ../../.env
```

### 2. Deploy Authentik

```bash
# Start Authentik services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f authentik-server
```

### 3. Initial Setup

1. **Access Authentik**: http://localhost:9005/if/flow/initial-setup/
2. **Admin Login**: http://localhost:9005/if/flow/default-authentication-flow/
   - Email: `admin@magicunicorn.tech`
   - Password: `MagicUnicorn!Auth` (change immediately)

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AUTHENTIK_SECRET_KEY` | Encryption key for sessions | Generated |
| `AUTHENTIK_POSTGRESQL_PASSWORD` | Database password | Generated |
| `AUTHENTIK_BOOTSTRAP_PASSWORD` | Initial admin password | `MagicUnicorn!Auth` |
| `AUTHENTIK_BOOTSTRAP_EMAIL` | Initial admin email | `admin@magicunicorn.tech` |
| `UC1_PRO_DOMAIN` | Domain for cookies | `localhost` |

### Ports

| Port | Service | Description |
|------|---------|-------------|
| 9005 | HTTP | Authentik web interface |
| 9445 | HTTPS | Authentik secure interface |

## Identity Providers

### Microsoft 365/Entra ID

1. **Register Azure AD Application**:
   - Go to [Azure Portal](https://portal.azure.com) → App registrations
   - Create new registration:
     - Name: `UC-1 Pro SSO`
     - Redirect URI: `http://localhost:9005/source/oauth/callback/microsoft/`
   - Note `Application (client) ID` and create `Client secret`

2. **Configure in Authentik**:
   - Admin Interface → Directory → Federation & Social login
   - Create Microsoft provider with Azure credentials

### Google Workspace

1. **Google Cloud Console Setup**:
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Enable Google Identity Platform API
   - Create OAuth 2.0 credentials:
     - Authorized redirect URI: `http://localhost:9005/source/oauth/callback/google/`

2. **Configure in Authentik**:
   - Create Google OAuth provider
   - Map Google Groups to Authentik Groups

### LDAP/Active Directory

1. **Configure LDAP Source**:
   - Server URI: `ldap://your-domain-controller`
   - Bind DN: `CN=Service Account,CN=Users,DC=company,DC=com`
   - Base DN: `CN=Users,DC=company,DC=com`

## Groups and Roles

### Default Groups

| Group | Description | Permissions |
|-------|-------------|-------------|
| `uc1-admins` | Full system access | All UC-1 Pro services |
| `uc1-developers` | Development access | Models, services, logs |
| `uc1-users` | Standard users | AI services only |
| `uc1-viewers` | Read-only access | Dashboards, reports |

### Role Mapping

```json
{
  "uc1-admins": {
    "services": ["*"],
    "operations": ["*"]
  },
  "uc1-developers": {
    "services": ["vllm", "ollama", "ops-center"],
    "operations": ["read", "deploy", "restart"]
  },
  "uc1-users": {
    "services": ["open-webui", "center-deep"],
    "operations": ["read", "use"]
  }
}
```

## Integration with UC-1 Pro Services

### Traefik Auth Middleware

Add to main `docker-compose.yml`:

```yaml
services:
  traefik:
    image: traefik:v3.0
    command:
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--api.dashboard=true"
    labels:
      - "traefik.http.middlewares.auth.forwardauth.address=http://authentik-server:9005/outpost.goauthentik.io/auth/traefik"
      - "traefik.http.middlewares.auth.forwardauth.trustForwardHeader=true"
      - "traefik.http.middlewares.auth.forwardauth.authResponseHeaders=X-authentik-username,X-authentik-groups,X-authentik-email,X-authentik-name,X-authentik-uid"

  ops-center:
    labels:
      - "traefik.http.routers.ops-center.middlewares=auth"
      - "traefik.http.routers.ops-center.rule=Host(`admin.localhost`)"
```

### Open-WebUI User Sync

Authentik will automatically provision users in Open-WebUI when they first log in through SSO.

## API Integration

### REST API Access

```python
import requests

# Get API token from Authentik admin interface
headers = {
    "Authorization": f"Bearer {authentik_api_token}",
    "Content-Type": "application/json"
}

# Create user programmatically
user_data = {
    "username": "newuser",
    "email": "newuser@company.com",
    "name": "New User",
    "groups": ["uc1-users"]
}

response = requests.post(
    "http://localhost:9005/api/v3/core/users/",
    json=user_data,
    headers=headers
)
```

### WebSocket Events

Monitor authentication events:

```python
import websocket

def on_message(ws, message):
    print(f"Auth event: {message}")

ws = websocket.WebSocketApp(
    "ws://localhost:9005/ws/outpost/",
    on_message=on_message
)
ws.run_forever()
```

## Monitoring

### Health Checks

```bash
# Check Authentik health
curl http://localhost:9005/-/health/live/

# Check database connection
docker exec authentik-server ak check_db

# Check Redis connection
docker exec authentik-redis redis-cli ping
```

### Logs

```bash
# View authentication logs
docker-compose logs -f authentik-server | grep "authentik.core"

# View worker logs
docker-compose logs -f authentik-worker

# Database logs
docker-compose logs -f authentik-postgresql
```

## Troubleshooting

### Common Issues

1. **CSRF Token Error**:
   - Ensure `AUTHENTIK_COOKIE_DOMAIN` matches your domain
   - Check browser cookies are enabled

2. **Database Connection Issues**:
   - Verify PostgreSQL is healthy: `docker-compose ps`
   - Check credentials in environment variables

3. **Provider Configuration**:
   - Verify redirect URIs match exactly
   - Check client secrets are correctly set

### Debug Mode

Enable debug logging:

```bash
# Add to docker-compose.yml environment
AUTHENTIK_LOG_LEVEL: debug
AUTHENTIK_LOG_FILE: /tmp/authentik.log
```

## Security

### Production Hardening

1. **Change Default Passwords**:
   ```bash
   # Change admin password immediately
   # Use strong, unique passwords for all accounts
   ```

2. **Use HTTPS**:
   ```yaml
   # Configure SSL certificates
   AUTHENTIK_LISTEN__HTTPS: 0.0.0.0:9443
   ```

3. **Secure Secrets**:
   ```bash
   # Use Docker secrets or external secret management
   # Rotate secrets regularly
   ```

### Backup

```bash
# Backup database
docker exec authentik-postgresql pg_dump -U authentik authentik > authentik_backup.sql

# Backup configuration
docker exec authentik-server ak export > authentik_config.json
```

## Next Steps

1. **Complete Initial Setup**: Access admin interface and change default password
2. **Configure Identity Providers**: Add Microsoft 365, Google Workspace, or LDAP
3. **Set Up Groups**: Create organizational groups and role mappings
4. **Test Authentication**: Verify SSO flows work end-to-end
5. **Integrate Services**: Add auth middleware to UC-1 Pro services

For detailed configuration guides, see the [UC-1 Pro Authentication Roadmap](../../AUTHENTICATION_ROADMAP.md).