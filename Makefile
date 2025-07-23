# UC-1 Pro Makefile for common operations

.PHONY: help start stop restart status logs health gpu-status clean backup

help:
	@echo "UC-1 Pro Management Commands"
	@echo ""
	@echo "  make start       - Start all services"
	@echo "  make stop        - Stop all services"
	@echo "  make restart     - Restart all services"
	@echo "  make status      - Show service status"
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

start:
	@./scripts/start.sh

stop:
	@docker-compose down

restart:
	@docker-compose restart

status:
	@docker-compose ps

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