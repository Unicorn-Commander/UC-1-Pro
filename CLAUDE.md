# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

UC-1 Pro is a modular, enterprise-grade AI infrastructure stack optimized for NVIDIA RTX 5090 GPUs. It implements a microservices architecture using Docker Compose for orchestration.

## Common Development Commands

### Stack Management
```bash
# Initial setup (creates .env file)
./setup-uc1-pro.sh

# Start the entire stack
./scripts/start.sh

# View logs for specific service
docker-compose logs -f <service-name>  # e.g., vllm, open-webui

# Stop all services
docker-compose down

# Restart a specific service
docker-compose restart <service-name>
```

### Testing & Debugging
```bash
# Test vLLM inference
./scripts/test-inference.sh

# Check service health
./scripts/health-check.sh

# Monitor system resources
./scripts/monitor.sh

# View service logs
./scripts/logs.sh
```

### Model Management
```bash
# Switch LLM model
./scripts/switch-model.sh
```

## High-Level Architecture

The system follows a microservices pattern with these key design principles:

1. **Hardware Optimization**: Services are distributed across RTX 5090 (vLLM), Intel iGPU (Kokoro TTS via OpenVINO), and CPU (WhisperX, embeddings, reranker).

2. **Service Communication**: All services communicate through a dedicated Docker network (`unicorn-network: 172.20.0.0/16`) using service aliases for internal DNS resolution.

3. **Data Persistence**: Three data stores handle different concerns:
   - PostgreSQL: Metadata and relational data
   - Redis: Caching, queuing, and session management
   - Qdrant: Vector embeddings for RAG

4. **API Gateway Pattern**: Open-WebUI (port 8080) serves as the main interface, orchestrating calls to backend services.

## Core Services & Ports

- **8080**: Open-WebUI (Main UI & API Gateway)
- **8000**: vLLM (LLM inference on RTX 5090)
- **8082**: Embeddings (CPU-based text embeddings)
- **9000**: WhisperX (Speech-to-text)
- **8880**: Kokoro TTS (Text-to-speech on Intel iGPU)
- **8083**: Reranker (Document reranking)
- **9998**: Tika OCR (Document processing)
- **8888**: SearXNG (Web search)
- **8084**: Model Manager (Model configuration UI)

## Service Development

Each service in `/services/` is self-contained with:
- `Dockerfile`: Container definition
- `docker-compose.yml`: Standalone testing configuration
- `server.py`: FastAPI-based service implementation
- `requirements.txt`: Python dependencies
- `README.md`: Service-specific documentation

When modifying services:
1. Test locally using the service's own `docker-compose.yml`
2. Integrate changes into the main `docker-compose.yml`
3. Ensure health checks pass before committing

## Environment Configuration

The `.env` file (created from `.env.template`) contains critical configuration:
- Database credentials (POSTGRES_*, QDRANT_*)
- API keys (VLLM_API_KEY, HF_TOKEN)
- Model selections (DEFAULT_LLM_MODEL, EMBEDDING_MODEL)
- Resource limits (MAX_MODEL_LEN, GPU_MEMORY_UTIL)

## Python Service Patterns

All Python services follow a consistent FastAPI pattern:
- Health endpoint at `/health`
- OpenAI-compatible APIs where applicable
- Environment-based configuration
- Graceful startup with model preloading