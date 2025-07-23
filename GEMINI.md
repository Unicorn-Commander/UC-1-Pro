# Gemini Agent Project Context for UC-1 Pro

This file contains specific context and preferences for the Gemini agent when working within the `UC-1 Pro` project.

## Project Details

- **Project Root**: `/Users/aaronstransky/Development/UC-1-Pro`
- **Operating System**: `darwin` (Mac Studio)
- **Primary Goal**: Develop and maintain a modular, production-ready AI infrastructure optimized for NVIDIA RTX 5090 GPUs.

## Key Directories

- `services/`: Core microservices (e.g., WhisperX, Kokoro TTS, Reranker).
- `scripts/`: Management and utility scripts (e.g., `start.sh`, `install-dependencies.sh`).
- `config/`: Shared configuration files (e.g., Prometheus).
- `Drivers/`: System drivers and related documentation.
- `documentation/`: MkDocs-based project documentation site.
- `extensions/`: Optional, standalone services that integrate with the core stack.

## Important Files

- `docker-compose.yml`: Main Docker orchestration file.
- `.env.template`: Template for environment variables.
- `.gitignore`: Git ignore rules for the repository.
- `setup-uc1-pro.sh`: Initial project setup script.
- `install-dependencies.sh`: Script for installing system-level dependencies.
- `README.md`: Main project overview and quick start guide.
- `uc1-pro-architecture-doc.md`: Detailed system architecture document.
- `This_System.md`: Specific hardware details of the target system.

## Network Configuration

- **Main Docker Network**: `unicorn-network` (external bridge network).

## Common Ports (Exposed to Host)

- `8080`: Open-WebUI (Main Interface)
- `8000`: vLLM API
- `8084`: Model Manager
- `9000`: WhisperX STT
- `8880`: Kokoro TTS
- `8083`: Reranker
- `8888`: SearXNG
- `9998`: Tika OCR
- `8081`: Documentation Site
- `6379`: Redis
- `5432`: PostgreSQL
- `6333/6334`: Qdrant
- `9835`: GPU Exporter
- `9090`: Prometheus
- `5173`: Bolt.DIY (Extension)
- `5678`: n8n (Extension)
- `80/443/8080`: Traefik (Extension - HTTP, HTTPS, Dashboard)

## Known Context / Issues

- **Web Search Quota**: Currently experiencing a quota issue with the web search tool, which is blocking research on "Flux Kontext".
- **Architectural Clarification**: The `uc1-pro-architecture-doc.md` has been updated to clarify that some services use pre-built Docker images rather than being built from source within the `services/` directory.

## Agent Preferences

- **Modularity**: Prefer creating new services/extensions in separate, self-contained folders with their own `docker-compose.yml` files.
- **Documentation**: Prioritize clear, comprehensive, and up-to-date documentation.
- **Safety**: Always explain commands that modify the file system before execution.
