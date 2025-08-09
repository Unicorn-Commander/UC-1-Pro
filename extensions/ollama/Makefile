# Ollama Extension Makefile

.PHONY: help start stop restart status logs pull clean models install-model

help:
	@echo "Ollama Extension Management Commands:"
	@echo "  make start        - Start Ollama service"
	@echo "  make stop         - Stop Ollama service"
	@echo "  make restart      - Restart Ollama service"
	@echo "  make status       - Check service status"
	@echo "  make logs         - View service logs"
	@echo "  make pull         - Pull latest Ollama image"
	@echo "  make clean        - Remove containers and volumes"
	@echo "  make models       - List installed models"
	@echo "  make install-model MODEL=<name> - Install a model"

start:
	docker-compose up -d
	@echo "Ollama service started on http://localhost:11434"

stop:
	docker-compose down

restart:
	docker-compose restart

status:
	@docker ps --filter "name=unicorn-ollama" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

logs:
	docker-compose logs -f

pull:
	docker-compose pull

clean:
	docker-compose down -v
	@echo "Cleaned up Ollama containers and volumes"

models:
	@echo "Installed Ollama models:"
	@docker exec unicorn-ollama ollama list 2>/dev/null || echo "Ollama container not running"

install-model:
	@if [ -z "$(MODEL)" ]; then \
		echo "Usage: make install-model MODEL=<model-name>"; \
		echo "Example: make install-model MODEL=llama2"; \
		exit 1; \
	fi
	docker exec unicorn-ollama ollama pull $(MODEL)