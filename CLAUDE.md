# UC-1 Pro Project Context for Claude

## Project Overview

UC-1 Pro is an enterprise-grade AI infrastructure stack designed for NVIDIA RTX 5090 GPUs. It provides a complete AI platform with LLM inference, speech processing, document intelligence, and search capabilities through a modular microservices architecture.

**Company**: Magic Unicorn Unconventional Technology & Stuff Inc  
**Website**: https://unicorncommander.com  
**License**: MIT

## Key Features

- **vLLM Engine**: High-performance LLM inference optimized for RTX 5090 (32GB VRAM)
- **Speech Processing**: WhisperX for STT with speaker diarization
- **Voice Synthesis**: Kokoro TTS with multiple voice options
- **Document Intelligence**: OCR and document processing with Apache Tika
- **Vector Search**: Qdrant vector database for RAG applications
- **Private Search**: Center-Deep - Advanced AI-powered search platform with tool servers (custom SearXNG fork)
- **Web Interface**: Open-WebUI as the main chat interface
- **Admin Dashboard**: Enhanced admin panel with Center-Deep branding and theme switching
- **Monitoring**: Built-in Prometheus & Grafana support

## Technical Stack

### Core Technologies
- **Container Platform**: Docker & Docker Compose
- **GPU Framework**: NVIDIA CUDA 12.0+ with Container Toolkit
- **Primary Language**: Python 3.11+
- **LLM Model**: Qwen/Qwen2.5-32B-Instruct-AWQ (default)
- **Embedding Model**: BAAI/bge-base-en-v1.5
- **Reranker Model**: BAAI/bge-reranker-v2-m3

### Databases
- **PostgreSQL 16**: Relational data and metadata
- **Redis 7.4**: High-speed caching and message queuing
- **Qdrant 1.15**: Vector database for embeddings

## Project Structure

```
UC-1-Pro/
├── docker-compose.yml       # Main orchestration file
├── .env                    # Environment configuration
├── Makefile               # Common management commands
├── install.sh             # Automated installer
├── start.sh              # Startup script
├── scripts/              # Management utilities
├── services/             # Microservices modules
├── extensions/           # Optional add-ons
├── documentation/        # Project documentation
└── volumes/             # Docker volume mount points
```

## Service Ports

| Service | Port | Description |
|---------|------|-------------|
| Open-WebUI | 8080 | Main chat interface |
| vLLM | 8000 | LLM inference API |
| Documentation | 8081 | MkDocs documentation |
| Embeddings | 8082 | Text embedding service |
| Reranker | 8083 | Document reranking |
| Ops Center | 8084 | Enhanced operations center with themes |
| Center-Deep | 8888 | AI-powered search platform |
| WhisperX | 9000 | Speech-to-text |
| Kokoro TTS | 8880 | Text-to-speech |
| Tika OCR | 9998 | Document processing |
| PostgreSQL | 5432 | Database |
| Redis | 6379 | Cache/Queue |
| Qdrant | 6333/6334 | Vector database |
| Prometheus | 9090 | Metrics |
| GPU Exporter | 9835 | GPU metrics |

## Common Commands

### Service Management
```bash
# Start all services
./start.sh
# or
make start

# Stop all services
docker-compose down
# or
make stop

# Check service status
make status

# View logs
make logs
make logs-vllm    # vLLM specific
make logs-ui      # Open-WebUI specific

# Health check
make health
./scripts/health-check-detailed.sh
```

### Model Management
```bash
# Download models before startup (optional)
./scripts/download-models.sh

# Switch between LLM models
./scripts/switch-model.sh

# Access model manager UI
# http://localhost:8084
```

### GPU Management
```bash
# Check GPU status
make gpu-status
./scripts/gpu-memory-manager.sh status

# Optimize GPU allocation
./scripts/gpu-memory-manager.sh balanced
./scripts/gpu-memory-manager.sh full-llm
```

### Testing
```bash
# Test LLM inference
./scripts/test-inference.sh

# Validate environment
./scripts/validate-env.sh
```

### Backup & Maintenance
```bash
# Manual backup
make backup
./scripts/backup.sh

# Clean Docker resources
make clean
```

### Extensions
```bash
# List available extensions
make ext-list

# Start monitoring (Grafana)
make monitoring

# Start ComfyUI for image generation
make comfyui

# Start Portainer
make portainer
```

## Environment Variables

Key configuration in `.env`:

```env
# Model Configuration
DEFAULT_LLM_MODEL=Qwen/Qwen2.5-32B-Instruct-AWQ
GPU_MEMORY_UTIL=0.95
MAX_MODEL_LEN=16384
TENSOR_PARALLEL=1

# Service Models
EMBEDDING_MODEL=BAAI/bge-base-en-v1.5
RERANKER_MODEL=BAAI/bge-reranker-v2-m3
WHISPER_MODEL=base
KOKORO_VOICE=af

# Database Credentials
POSTGRES_USER=unicorn
POSTGRES_PASSWORD=<generated>
POSTGRES_DB=unicorn_db

# API Keys
VLLM_API_KEY=<generated>
WEBUI_SECRET_KEY=<generated>
HF_TOKEN=<optional>

# Backup Settings
BACKUP_SCHEDULE=0 2 * * *
BACKUP_RETENTION_DAYS=7

# Admin Credentials
ADMIN_USERNAME=ucadmin
ADMIN_PASSWORD=MagicUnicorn!8-)
```

## Center-Deep Integration

Center-Deep is our custom fork of SearXNG that provides advanced AI-powered search capabilities:

### Features
- **AI Tool Servers**: Integrated OpenAI API v1 compatible tool servers
- **Admin Dashboard**: Web-based control panel for search configuration
- **Tool Server Ports**:
  - Search Tool: Port 8001
  - Deep Search: Port 8002  
  - Report Generator: Port 8003
  - Academic Research: Port 8004

### Configuration
- **Repository**: Located in `/home/ucadmin/UC-1-Pro/Center-Deep`
- **Docker Service**: `unicorn-searxng` (maintains naming for compatibility)
- **Access URL**: http://localhost:8888
- **Admin Credentials**: ucadmin / MagicUnicorn!8-)

### Integration with UC-1 Pro
- Open-WebUI configured to use Center-Deep for web searches
- Shares Redis instance for caching
- Uses vLLM for AI tool processing
- Branded with Magic Unicorn logo on public landing page

## Ops Center Features (Enhanced Multi-System Management)

The enhanced Ops Center now includes advanced multisystem management capabilities:

### Core Management Features
- **Dynamic Deployment Detection**: Automatically detects enterprise vs appliance deployment types
- **Enhanced Resource Monitoring**: Real-time GPU, CPU, memory, disk, and network metrics
- **Universal Hardware Support**: Compatible with NVIDIA RTX, AMD, and Intel GPUs
- **Multi-Platform Management**: Single interface for UC-1-Pro, UC-1, and Meeting-Ops variants

### Advanced Monitoring & APIs
- **Resource Monitor**: Enhanced system metrics with detailed GPU monitoring via nvidia-smi
- **Deployment Configuration API**: `/api/v1/deployment/config` endpoint for dynamic UI adaptation
- **Enhanced System Status**: Improved `/api/v1/system/status` with fallback capabilities
- **Hardware Detection**: Universal hardware detector supporting multiple GPU architectures

### Theme System
- **Magic Unicorn Theme**: Purple gradient with gold accents
- **Dark Mode**: Clean dark theme with blue accents  
- **Light Mode**: Clean light theme with blue accents
- **Dynamic Branding**: Context-aware branding based on deployment type
- Theme selection persists across sessions

### Navigation & UI
- Fixed routing for all admin pages (/admin/*)
- **Deployment Context**: Frontend adapts based on deployment configuration
- **Quick Actions**: Streamlined actions for common tasks
- **Service Status Cards**: Enhanced with Center-Deep branding and real-time metrics

### Backend Enhancements
- **FastAPI Backend**: Enhanced with new monitoring and configuration endpoints
- **Graceful Fallbacks**: New features degrade gracefully if dependencies unavailable
- **Docker Integration**: Enhanced service management and health monitoring
- **Network Management**: Advanced network configuration and monitoring capabilities

### Integration Capabilities
- **Center-Deep Integration**: Seamless search platform integration
- **vLLM Management**: Advanced model management and GPU monitoring
- **Extension Ecosystem**: Support for hardware-specific extensions
- **Multi-tenant Support**: Ready for enterprise and appliance deployments

## Architecture Notes

### Hardware Allocation
- **RTX 5090**: Exclusive use by vLLM for LLM inference
- **Intel iGPU**: Kokoro TTS via OpenVINO optimization
- **CPU**: WhisperX, Embeddings, Reranker, and support services

### Network Architecture
- Docker network: `unicorn-network` (172.20.0.0/16)
- Services communicate via internal DNS names
- All services have multiple network aliases for flexibility

### Service Dependencies
- Open-WebUI depends on: PostgreSQL, Redis, Qdrant, vLLM
- SearXNG depends on: Redis
- All services are independently deployable

## Development Workflow

### Running Individual Services
```bash
# Test a service independently
cd services/[service-name]
docker-compose up
```

### Adding New Services
1. Create directory: `services/new-service/`
2. Add Dockerfile, requirements.txt, server.py
3. Create standalone docker-compose.yml for testing
4. Test independently
5. Integrate into main docker-compose.yml

### Debugging
```bash
# Service logs
docker-compose logs -f [service-name]

# Interactive shell
docker-compose exec [service-name] /bin/bash

# Resource monitoring
docker stats
nvidia-smi -l 1
```

## Security Considerations

- All services run in isolated Docker containers
- API authentication via environment variables
- Network isolation through Docker bridge network
- Automated daily backups with configurable retention
- SSL/TLS support via Traefik extension

## Performance Tips

1. **Model Selection**: AWQ quantization provides best speed/quality balance
2. **Context Length**: Adjust MAX_MODEL_LEN based on needs (default 16384)
3. **GPU Memory**: 95% utilization maximizes performance
4. **Caching**: Redis cache improves response times
5. **Batch Processing**: Enable for WhisperX and Embeddings

## Troubleshooting

### Common Issues

1. **GPU not detected**:
   ```bash
   nvidia-smi
   docker run --rm --runtime=nvidia nvidia/cuda:12.0-base nvidia-smi
   ```

2. **Service won't start**:
   ```bash
   docker-compose logs [service-name]
   ./scripts/health-check-detailed.sh
   ```

3. **Out of memory**:
   ```bash
   ./scripts/gpu-memory-manager.sh status
   docker stats
   ```

4. **Model download issues**:
   ```bash
   # Pre-download models
   ./scripts/download-models.sh
   ```

5. **Admin dashboard "Not Found" error**:
   - Clear browser cache (Ctrl+F5)
   - Ensure accessing via /admin/* routes
   - Check container logs: `docker logs unicorn-ops-center`

6. **Center-Deep integration**:
   - Service runs on port 8888
   - Access admin at http://localhost:8888/admin
   - Tool servers on ports 8001-8004

## Important Files

- `docker-compose.yml`: Main service orchestration
- `.env`: Environment configuration (sensitive)
- `Makefile`: Quick command reference
- `scripts/health-check-detailed.sh`: Comprehensive health check
- `scripts/switch-model.sh`: Model switching utility
- `services/*/README.md`: Individual service documentation

## Testing Commands

When testing changes:
```bash
# Lint and typecheck commands (if available)
# Python services typically use:
# - ruff check .
# - mypy .
# - pytest

# Check service health
./scripts/health-check-detailed.sh

# Test inference
./scripts/test-inference.sh
```

## Recent Updates (August 2025)

### Center-Deep Integration
- Replaced standard SearXNG with Center-Deep custom fork
- Added AI-powered tool servers for enhanced search
- Integrated with vLLM for AI processing
- Updated Open-WebUI to use Center-Deep for searches

### Ops Center Enhancements (Multi-System Management)
- **Enhanced Monitoring**: Added real-time resource monitoring with GPU support
- **Dynamic Configuration**: Auto-detects deployment type and adapts features
- **Universal Hardware**: Support for NVIDIA RTX, AMD, and Intel GPU detection
- **Advanced APIs**: New endpoints for deployment config and enhanced system status
- **Theme System**: Magic Unicorn, Dark, Light themes with dynamic branding
- **UI Improvements**: Fixed /admin routing, enhanced service status cards
- **Deployment Context**: Frontend adapts based on enterprise vs appliance mode

### Ops Center Landing Page (Current Development)
- **Modern UI Design**: Custom landing page with gradient backgrounds and service cards
- **Service Quick Access**: Direct links to Open-WebUI, Center-Deep, Unicorn Orator, Bolt.DIY
- **Center-Deep Search Integration**: Integrated search bar that redirects to Center-Deep
- **Real-time Status Monitoring**: Live service status indicators for all integrated services
- **Responsive Design**: Mobile-friendly layout with modern styling
- **Custom Branding**: Unicorn Commander PRO branding with Magic Unicorn theme
- **Landing Pages**: Multiple landing page templates (landing-unicorn.html, landing-modern.html, landing-dynamic.html)

### New API Endpoints
- `/api/v1/deployment/config`: Get deployment configuration and feature flags
- `/api/v1/system/status`: Enhanced system metrics with GPU monitoring
- `/api/v1/landing/config`: Landing page configuration endpoint
- Enhanced monitoring capabilities with graceful fallbacks

### GPU Configuration
- RTX 5090 detected and configured (32GB VRAM)
- vLLM using 95% GPU memory (~31GB)
- Qwen2.5-32B-Instruct-AWQ model loaded by default

### Additional Services & Extensions
- **Unicorn Orator**: Voice synthesis and speech processing (Port 8085)
- **Bolt.DIY**: AI-powered development environment (Port 5173)
- **Grafana Monitoring**: System metrics visualization
- **Portainer**: Docker container management interface

## Notes for Development

- Services are designed to be modular and independently testable
- Each service has its own Dockerfile and can run standalone
- Use the Ops Center (port 8084) for model management
- Monitor GPU usage to prevent OOM errors
- Check logs frequently when debugging issues
- Center-Deep repository located at `/home/ucadmin/UC-1-Pro/Center-Deep`