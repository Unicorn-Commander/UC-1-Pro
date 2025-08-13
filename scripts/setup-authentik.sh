#!/bin/bash

# UC-1 Pro Authentik SSO Setup Script
# This script adds enterprise authentication to UC-1 Pro

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# UC-1 Pro header
echo -e "${PURPLE}"
echo "🦄 =================================================="
echo "   UC-1 Pro Enterprise Authentication Setup"
echo "   Adding Authentik SSO to your AI stack"
echo "==================================================${NC}"
echo

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ Error: Please run this script from the UC-1 Pro root directory${NC}"
    exit 1
fi

# Function to generate secure random string
generate_secret() {
    openssl rand -base64 32 | tr -d "\n"
}

echo -e "${BLUE}🔧 Step 1: Generating secure secrets...${NC}"

# Generate secrets
AUTHENTIK_SECRET_KEY=$(generate_secret)
AUTHENTIK_POSTGRESQL_PASSWORD=$(generate_secret)
AUTHENTIK_BOOTSTRAP_TOKEN=$(generate_secret)

echo -e "${GREEN}✅ Generated Authentik secret key${NC}"
echo -e "${GREEN}✅ Generated PostgreSQL password${NC}"
echo -e "${GREEN}✅ Generated bootstrap token${NC}"

# Add secrets to .env file
echo -e "${BLUE}🔧 Step 2: Adding configuration to .env file...${NC}"

# Backup existing .env
if [ -f ".env" ]; then
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    echo -e "${YELLOW}📦 Backed up existing .env file${NC}"
fi

# Add Authentik configuration
cat >> .env << EOF

# Authentik SSO Configuration (added $(date))
AUTHENTIK_SECRET_KEY=${AUTHENTIK_SECRET_KEY}
AUTHENTIK_POSTGRESQL_PASSWORD=${AUTHENTIK_POSTGRESQL_PASSWORD}
AUTHENTIK_BOOTSTRAP_TOKEN=${AUTHENTIK_BOOTSTRAP_TOKEN}
AUTHENTIK_BOOTSTRAP_EMAIL=admin@magicunicorn.tech
AUTHENTIK_POSTGRESQL_USER=authentik
AUTHENTIK_POSTGRESQL_NAME=authentik
UC1_PRO_DOMAIN=localhost

# Default admin credentials (CHANGE THESE!)
AUTHENTIK_BOOTSTRAP_PASSWORD=MagicUnicorn!Auth
EOF

echo -e "${GREEN}✅ Added Authentik configuration to .env${NC}"

# Update main docker-compose.yml to include Authentik services
echo -e "${BLUE}🔧 Step 3: Integrating Authentik with UC-1 Pro services...${NC}"

# Check if Authentik is already in docker-compose.yml
if grep -q "authentik-server" docker-compose.yml; then
    echo -e "${YELLOW}⚠️  Authentik services already present in docker-compose.yml${NC}"
else
    # Add Authentik services to main docker-compose.yml
    cat >> docker-compose.yml << 'EOF'

  # Authentik SSO Services
  authentik-postgresql:
    image: docker.io/library/postgres:16-alpine
    container_name: authentik-postgresql
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -d $${POSTGRES_DB} -U $${POSTGRES_USER}"]
      start_period: 20s
      interval: 30s
      retries: 5
      timeout: 5s
    volumes:
      - ./volumes/authentik/database:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: ${AUTHENTIK_POSTGRESQL_PASSWORD}
      POSTGRES_USER: ${AUTHENTIK_POSTGRESQL_USER:-authentik}
      POSTGRES_DB: ${AUTHENTIK_POSTGRESQL_NAME:-authentik}
    networks:
      - unicorn-network

  authentik-redis:
    image: docker.io/library/redis:alpine
    container_name: authentik-redis
    command: --save 60 1 --loglevel warning
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "redis-cli ping | grep PONG"]
      start_period: 20s
      interval: 30s
      retries: 5
      timeout: 3s
    volumes:
      - ./volumes/authentik/redis:/data
    networks:
      - unicorn-network

  authentik-server:
    image: ghcr.io/goauthentik/server:2024.8.3
    container_name: authentik-server
    restart: unless-stopped
    command: server
    environment:
      AUTHENTIK_REDIS__HOST: authentik-redis
      AUTHENTIK_POSTGRESQL__HOST: authentik-postgresql
      AUTHENTIK_POSTGRESQL__USER: ${AUTHENTIK_POSTGRESQL_USER:-authentik}
      AUTHENTIK_POSTGRESQL__NAME: ${AUTHENTIK_POSTGRESQL_NAME:-authentik}
      AUTHENTIK_POSTGRESQL__PASSWORD: ${AUTHENTIK_POSTGRESQL_PASSWORD}
      AUTHENTIK_SECRET_KEY: ${AUTHENTIK_SECRET_KEY}
      AUTHENTIK_ERROR_REPORTING__ENABLED: false
      AUTHENTIK_BOOTSTRAP_PASSWORD: ${AUTHENTIK_BOOTSTRAP_PASSWORD:-MagicUnicorn!Auth}
      AUTHENTIK_BOOTSTRAP_TOKEN: ${AUTHENTIK_BOOTSTRAP_TOKEN}
      AUTHENTIK_BOOTSTRAP_EMAIL: ${AUTHENTIK_BOOTSTRAP_EMAIL:-admin@magicunicorn.tech}
      AUTHENTIK_COOKIE_DOMAIN: ${UC1_PRO_DOMAIN:-localhost}
      AUTHENTIK_DEFAULT_USER_CHANGE_NAME: true
      AUTHENTIK_DEFAULT_USER_CHANGE_EMAIL: true
      AUTHENTIK_DEFAULT_USER_CHANGE_USERNAME: true
    volumes:
      - ./volumes/authentik/media:/media
      - ./volumes/authentik/templates:/templates
    ports:
      - "0.0.0.0:9000:9000"
      - "0.0.0.0:9443:9443"
    depends_on:
      - authentik-postgresql
      - authentik-redis
    networks:
      - unicorn-network

  authentik-worker:
    image: ghcr.io/goauthentik/server:2024.8.3
    container_name: authentik-worker
    restart: unless-stopped
    command: worker
    environment:
      AUTHENTIK_REDIS__HOST: authentik-redis
      AUTHENTIK_POSTGRESQL__HOST: authentik-postgresql
      AUTHENTIK_POSTGRESQL__USER: ${AUTHENTIK_POSTGRESQL_USER:-authentik}
      AUTHENTIK_POSTGRESQL__NAME: ${AUTHENTIK_POSTGRESQL_NAME:-authentik}
      AUTHENTIK_POSTGRESQL__PASSWORD: ${AUTHENTIK_POSTGRESQL_PASSWORD}
      AUTHENTIK_SECRET_KEY: ${AUTHENTIK_SECRET_KEY}
      AUTHENTIK_ERROR_REPORTING__ENABLED: false
    user: root
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./volumes/authentik/media:/media
      - ./volumes/authentik/certs:/certs
      - ./volumes/authentik/templates:/templates
    depends_on:
      - authentik-postgresql
      - authentik-redis
    networks:
      - unicorn-network
EOF

    echo -e "${GREEN}✅ Added Authentik services to docker-compose.yml${NC}"
fi

# Create volume directories
echo -e "${BLUE}🔧 Step 4: Creating volume directories...${NC}"
mkdir -p ./volumes/authentik/{database,redis,media,templates,certs}
echo -e "${GREEN}✅ Created Authentik volume directories${NC}"

# Update Makefile with Authentik commands
echo -e "${BLUE}🔧 Step 5: Adding Authentik commands to Makefile...${NC}"

if ! grep -q "authentik-start" Makefile 2>/dev/null; then
    cat >> Makefile << 'EOF'

# Authentik SSO Commands
.PHONY: authentik-start authentik-stop authentik-restart authentik-logs authentik-status

authentik-start:
	@echo "🔐 Starting Authentik SSO services..."
	docker-compose up -d authentik-postgresql authentik-redis authentik-server authentik-worker

authentik-stop:
	@echo "🔐 Stopping Authentik SSO services..."
	docker-compose stop authentik-postgresql authentik-redis authentik-server authentik-worker

authentik-restart:
	@echo "🔐 Restarting Authentik SSO services..."
	docker-compose restart authentik-postgresql authentik-redis authentik-server authentik-worker

authentik-logs:
	@echo "🔐 Showing Authentik SSO logs..."
	docker-compose logs -f authentik-server authentik-worker

authentik-status:
	@echo "🔐 Authentik SSO service status:"
	@docker-compose ps authentik-postgresql authentik-redis authentik-server authentik-worker

sso: authentik-start
	@echo "🔐 Starting UC-1 Pro with SSO authentication..."
EOF
    echo -e "${GREEN}✅ Added Authentik commands to Makefile${NC}"
fi

echo
echo -e "${PURPLE}🎉 Authentik SSO Setup Complete!${NC}"
echo
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo -e "   1. Start Authentik:     ${GREEN}make authentik-start${NC}"
echo -e "   2. Access admin UI:     ${BLUE}http://localhost:9000${NC}"
echo -e "   3. Login credentials:"
echo -e "      Email:     ${GREEN}admin@magicunicorn.tech${NC}"
echo -e "      Password:  ${GREEN}MagicUnicorn!Auth${NC}"
echo -e "   4. ${RED}IMPORTANT: Change the default password immediately!${NC}"
echo
echo -e "${YELLOW}📚 Configuration Guide:${NC}"
echo -e "   • Microsoft 365: See services/authentik/README.md"
echo -e "   • Google Workspace: See AUTHENTICATION_ROADMAP.md"
echo -e "   • LDAP/AD: Configure in Authentik admin interface"
echo
echo -e "${BLUE}🔧 Quick Commands:${NC}"
echo -e "   • Check status:    ${GREEN}make authentik-status${NC}"
echo -e "   • View logs:       ${GREEN}make authentik-logs${NC}"
echo -e "   • Restart:         ${GREEN}make authentik-restart${NC}"
echo
echo -e "${GREEN}✨ Ready to add enterprise authentication to UC-1 Pro! 🦄${NC}"