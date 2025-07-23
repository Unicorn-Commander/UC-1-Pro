# UC-1 Pro - Enterprise AI Stack for RTX 5090

A modular, production-ready AI infrastructure optimized for NVIDIA RTX 5090 GPUs.

## Quick Start

**1. Clone and Install**

```bash
git clone https://github.com/Unicorn-Commander/UC-1-Pro.git
cd UC-1-Pro
./install.sh
```

The installer will:
- Check and install system dependencies
- Install Docker and Docker Compose
- Set up NVIDIA drivers and container toolkit
- Create your `.env` configuration file
- Run pre-flight checks

**2. Start the Stack**

```bash
./scripts/start.sh
```

That's it! The install script handles everything for you.

## Architecture

- **vLLM** on RTX 5090 for primary LLM inference
- **WhisperX** for advanced speech-to-text
- **Kokoro TTS** for text-to-speech
- **Modular microservices** architecture
- **Docker-based** deployment

## Directory Structure

```
UC-1-Pro/
├── docker-compose.yml      # Main orchestration
├── .env.template           # Environment configuration template
├── .gitignore              # Git ignore file
├── setup-uc1-pro.sh        # Initial project setup script
├── services/               # Modular microservices
├── scripts/                # Management & installation scripts
├── config/                 # Shared configuration files
├── Drivers/                # System drivers & documentation
├── documentation/          # Project documentation site
└── extensions/             # Optional, standalone services
```

## Services

- **Port 8080**: Open-WebUI (Main Interface)
- **Port 8000**: vLLM API
- **Port 8084**: Model Manager
- **Port 9000**: WhisperX STT
- **Port 8880**: Kokoro TTS
- **Port 8083**: Reranker
- **Port 8888**: SearXNG
- **Port 9998**: Tika OCR
- **Port 8081**: Documentation

## Requirements

- Ubuntu Server 24.04 LTS
- NVIDIA RTX 5090 (32GB VRAM)
- 96GB RAM recommended

All other software dependencies (Docker, NVIDIA Container Toolkit) are installed by the `install-dependencies.sh` script.

For detailed architecture information, see `uc1-pro-architecture-doc.md`.

## Extensions

The `extensions/` directory contains optional services that can be run alongside the main UC-1 Pro stack. Each extension has its own `docker-compose.yml` and `README.md` with specific setup and usage instructions.

To run an extension, navigate to its directory and use `docker-compose up -d`.

- **Traefik**: A modern reverse proxy and load balancer. See `extensions/traefik/README.md`.
- **Bolt.DIY**: A development environment for building AI applications. See `extensions/bolt.diy/README.md`.
- **n8n**: A powerful workflow automation tool. See `extensions/n8n/README.md`.
