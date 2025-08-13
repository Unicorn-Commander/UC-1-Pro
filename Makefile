# UC-1 Pro Makefile for common operations

.PHONY: help start stop restart status ports logs health gpu-status clean backup update build test-services

help:
	@echo "UC-1 Pro Management Commands"
	@echo ""
	@echo "  make start       - Start all services"
	@echo "  make stop        - Stop all services"
	@echo "  make restart     - Restart all services"
	@echo "  make status      - Show service status"
	@echo "  make ports       - Show port allocations"
	@echo "  make logs        - Follow logs (all services)"
	@echo "  make health      - Run health check"
	@echo "  make gpu-status  - Show GPU usage"
	@echo "  make clean       - Remove unused Docker resources"
	@echo "  make backup      - Backup databases"
	@echo ""
	@echo "Service-specific logs:"
	@echo "  make logs-vllm   - vLLM logs"
	@echo "  make logs-ui     - Open-WebUI logs"
	@echo ""
	@echo "Extensions:"
	@echo "  make ext-list    - List available extensions"
	@echo "  make monitoring  - Start monitoring extension"
	@echo "  make comfyui     - Start ComfyUI extension"
	@echo ""
	@echo "Authentication (SSO):"
	@echo "  make auth-start         - Start Authentik SSO"
	@echo "  make auth-stop          - Stop Authentik SSO"
	@echo "  make auth-logs          - View Authentik logs"
	@echo "  make auth-test          - Test Authentik integration"
	@echo "  make auth-configure-apps - Configure apps in Authentik"
	@echo "  make auth-enable-oauth  - Enable OAuth for Open-WebUI"
	@echo "  make auth-setup-m365    - Configure Microsoft 365"
	@echo "  make auth-setup-google  - Configure Google Workspace"
	@echo ""
	@echo "Traefik Proxy:"
	@echo "  make traefik-start      - Start Traefik proxy"
	@echo "  make traefik-stop       - Stop Traefik proxy"
	@echo "  make traefik-logs       - View Traefik logs"

start:
	@./start.sh

stop:
	@docker-compose down

restart:
	@docker-compose restart

status:
	@docker-compose ps

ports:
	@echo "🔌 UC-1 Pro Port Allocations:"
	@echo ""
	@docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -E "unicorn-|authentik-|traefik" | head -20
	@echo ""
	@echo "📋 For complete port map: cat PORT_ALLOCATION.md"
	@echo "🔍 Check specific port: sudo lsof -i :PORT"

logs:
	@docker-compose logs -f

logs-vllm:
	@docker-compose logs -f vllm

logs-ui:
	@docker-compose logs -f open-webui

health:
	@./scripts/health-check-detailed.sh

gpu-status:
	@./scripts/gpu-memory-manager.sh status

clean:
	@echo "Cleaning unused Docker resources..."
	@docker system prune -f
	@docker volume prune -f

backup:
	@./scripts/backup.sh

ext-list:
	@echo "Available extensions:"
	@ls -1 extensions/

monitoring:
	@cd extensions/monitoring && docker-compose up -d
	@echo "Monitoring started: Grafana at http://localhost:3000"

comfyui:
	@cd extensions/comfyui && docker-compose up -d
	@echo "ComfyUI started at http://localhost:8188"

portainer:
	@cd extensions/portainer && docker-compose up -d
	@echo "Portainer started at https://localhost:9443"

# Additional service management
logs-embed:
	@docker-compose logs -f embeddings

logs-rerank:
	@docker-compose logs -f reranker

logs-whisper:
	@docker-compose logs -f whisperx

logs-tts:
	@docker-compose logs -f kokoro-tts

# Build and update commands
build:
	@echo "Building custom services..."
	@docker-compose build embeddings reranker whisperx kokoro-tts

update:
	@echo "Pulling latest images..."
	@docker-compose pull
	@echo "Rebuilding custom services..."
	@docker-compose build
	@echo "Restarting services..."
	@docker-compose up -d

# Testing commands
test-services:
	@echo "Testing service endpoints..."
	@./scripts/test-inference.sh 2>/dev/null || echo "vLLM test completed"
	@curl -s http://localhost:8082/health | jq -r '.status' | xargs -I {} echo "Embeddings: {}"
	@curl -s http://localhost:8083/health | jq -r '.status' | xargs -I {} echo "Reranker: {}"
	@curl -s http://localhost:9000/health | jq -r '.status' | xargs -I {} echo "WhisperX: {}"
	@curl -s http://localhost:8880/health | jq -r '.status' | xargs -I {} echo "Kokoro TTS: {}"

# Model management
switch-model:
	@./scripts/switch-model.sh

download-models:
	@./scripts/download-models.sh

# Development commands
shell-vllm:
	@docker-compose exec vllm /bin/bash

shell-ui:
	@docker-compose exec open-webui /bin/bash

# System information
info:
	@echo "UC-1 Pro System Information"
	@echo "==========================="
	@nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader
	@echo ""
	@echo "Docker version: $$(docker --version)"
	@echo "Compose version: $$(docker-compose --version)"
	@echo ""
	@echo "Service URLs:"
	@echo "  Open-WebUI: http://localhost:8080"
	@echo "  vLLM API: http://localhost:8000"
	@echo "  Embeddings: http://localhost:8082"
	@echo "  Reranker: http://localhost:8083"
	@echo "  Search: http://localhost:8888"
	@echo "  Ops Center: http://localhost:8084"
	@cd extensions/portainer && docker-compose up -d
	@echo "Portainer started at http://localhost:9000"
	@echo "Username: admin"
	@echo "Password: $$(cat extensions/portainer/portainer_password.txt)"
# Authentik SSO Commands
.PHONY: auth-start auth-stop auth-restart auth-logs auth-status auth-test auth-setup-m365

auth-start:
	@echo "🔐 Starting Authentik SSO services..."
	@cd services/authentik && docker-compose --env-file ../../.env up -d

auth-stop:
	@echo "🔐 Stopping Authentik SSO services..."
	@cd services/authentik && docker-compose stop

auth-restart:
	@echo "🔐 Restarting Authentik SSO services..."
	@cd services/authentik && docker-compose restart

auth-logs:
	@echo "🔐 Showing Authentik SSO logs..."
	@cd services/authentik && docker-compose logs -f

auth-status:
	@echo "🔐 Authentik SSO service status:"
	@cd services/authentik && docker-compose ps

auth-test:
	@echo "🔐 Testing Authentik SSO integration..."
	@./scripts/test-authentik.sh

auth-setup-m365:
	@echo "🔐 Configuring Microsoft 365 SSO..."
	@./scripts/configure-microsoft365-sso.sh

auth-setup-google:
	@echo "🔐 Configuring Google Workspace SSO..."
	@./scripts/configure-google-sso.sh

auth-test-google:
	@echo "🔐 Testing Google Workspace SSO..."
	@./scripts/test-google-sso.sh

auth-test-m365:
	@echo "🔐 Testing Microsoft 365 SSO..."
	@./scripts/test-microsoft365-sso.sh

auth-configure-apps:
	@echo "🔐 Configuring Authentik applications..."
	@./scripts/configure-authentik-apps.sh

auth-enable-oauth:
	@echo "🔐 Enabling OAuth for Open-WebUI..."
	@sed -i 's/# ENABLE_OAUTH_SIGNUP:/ENABLE_OAUTH_SIGNUP:/g' docker-compose.yml
	@sed -i 's/# OAUTH_MERGE_ACCOUNTS_BY_EMAIL:/OAUTH_MERGE_ACCOUNTS_BY_EMAIL:/g' docker-compose.yml
	@sed -i 's/# OPENID_PROVIDER_URL:/OPENID_PROVIDER_URL:/g' docker-compose.yml
	@sed -i 's/# OPENID_CLIENT_ID:/OPENID_CLIENT_ID:/g' docker-compose.yml
	@sed -i 's/# OPENID_CLIENT_SECRET:/OPENID_CLIENT_SECRET:/g' docker-compose.yml
	@sed -i 's/# OPENID_REDIRECT_URI:/OPENID_REDIRECT_URI:/g' docker-compose.yml
	@sed -i 's/# OPENID_SCOPE:/OPENID_SCOPE:/g' docker-compose.yml
	@sed -i 's/# OPENID_PROVIDER_DISPLAY_NAME:/OPENID_PROVIDER_DISPLAY_NAME:/g' docker-compose.yml
	@echo "✅ OAuth enabled - restart Open-WebUI: docker-compose restart open-webui"

traefik-start:
	@echo "🔐 Starting Traefik reverse proxy..."
	@cd services/traefik && docker-compose --env-file ../../.env up -d

traefik-stop:
	@echo "🔐 Stopping Traefik..."
	@cd services/traefik && docker-compose stop

traefik-logs:
	@echo "🔐 Viewing Traefik logs..."
	@cd services/traefik && docker-compose logs -f

# Legacy aliases
authentik-start: auth-start
authentik-stop: auth-stop
authentik-logs: auth-logs
sso: auth-start
