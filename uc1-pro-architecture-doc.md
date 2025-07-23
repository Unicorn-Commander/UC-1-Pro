# UC-1 Pro - System Architecture & Technical Documentation

## Table of Contents
1. [System Overview](#system-overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Directory Structure](#directory-structure)
4. [Microservices Architecture](#microservices-architecture)
5. [Service Descriptions](#service-descriptions)
6. [Network Architecture](#network-architecture)
7. [Data Flow](#data-flow)
8. [Hardware Resource Allocation](#hardware-resource-allocation)
9. [Deployment Guide](#deployment-guide)
10. [Service Communication Matrix](#service-communication-matrix)

## System Overview

UC-1 Pro is a modular, enterprise-grade AI infrastructure stack designed specifically for NVIDIA RTX 5090 GPUs. It implements a microservices architecture where each component is self-contained, independently deployable, and optimized for specific hardware resources.

### Key Design Principles
- **Hardware Optimization**: Services distributed across RTX 5090, Intel iGPU, and CPU
- **Modular Architecture**: Each service is a self-contained module with its own Dockerfile
- **Service Isolation**: Services can be developed, tested, and deployed independently
- **Network Flexibility**: All services accessible via multiple network paths
- **Resource Efficiency**: Workloads distributed based on computational requirements

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Client Applications                             │
│                        (Web Browser, API Clients, Mobile)                    │
└────────────────────────────────┬───────────────────────────────────────────┘
                                 │
┌────────────────────────────────┴───────────────────────────────────────────┐
│                           API Gateway / Load Balancer                       │
│                              (ports 8080, 8000)                            │
└────────────────────────────────┬───────────────────────────────────────────┘
                                 │
┌────────────────────────────────┴───────────────────────────────────────────┐
│                              Docker Network                                 │
│                           (unicorn-network: 172.20.0.0/16)                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────┐  ┌─────────────────────┐  ┌──────────────────┐   │
│  │   Open-WebUI (8080) │  │  Model Manager      │  │ Prometheus (9090)│   │
│  │   Main Interface    │  │  (8084)             │  │ Monitoring       │   │
│  └──────────┬──────────┘  └──────────┬──────────┘  └────────┬─────────┘   │
│             │                         │                       │             │
│  ┌──────────┴──────────────────────┴─────────────────────────┴──────────┐  │
│  │                         Service Communication Bus                     │  │
│  └──┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬──────┘  │
│     │         │         │         │         │         │         │          │
│  ┌──┴────┐ ┌─┴────┐ ┌─┴────┐ ┌─┴────┐ ┌─┴────┐ ┌─┴────┐ ┌─┴────┐      │
│  │ vLLM  │ │Embed │ │Whisper│ │Kokoro│ │Rerank│ │Tika  │ │SearX │      │
│  │(8000) │ │(8082)│ │(9000) │ │(8880)│ │(8083)│ │(9998)│ │(8888)│      │
│  └───┬───┘ └──┬───┘ └───┬───┘ └──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘      │
│      │        │          │        │        │        │        │           │
└──────┼────────┼──────────┼────────┼────────┼────────┼────────┼───────────┘
       │        │          │        │        │        │        │
┌──────┴────┐ ┌┴──────────┴────────┴────────┴────┐ ┌┴────────┴───────────┐
│ RTX 5090  │ │      Intel iGPU / CPU            │ │   CPU Only         │
│  (32GB)   │ │    (Shared System RAM)           │ │                    │
└───────────┘ └──────────────────────────────────┘ └────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                            Data Persistence Layer                           │
├─────────────────┬─────────────────────┬────────────────────────────────────┤
│  PostgreSQL     │     Redis           │        Qdrant                      │
│  (5432)         │     (6379)          │        (6333/6334)                 │
│  Metadata       │     Cache/Queue     │        Vector Store                │
└─────────────────┴─────────────────────┴────────────────────────────────────┘
```

## Directory Structure

```
UC-1-Pro/
├── docker-compose.yml              # Main orchestration file
├── .env.template                   # Environment configuration template
├── .env                           # Local environment configuration (git-ignored)
├── setup-uc1-pro.sh              # Initial setup script
│
├── scripts/                       # Management and utility scripts
│   ├── start.sh                  # Main deployment script
│   ├── stop.sh                   # Graceful shutdown script
│   ├── switch-model.sh           # Model switching utility
│   ├── monitor.sh                # Real-time system monitor
│   ├── logs.sh                   # Service log viewer
│   ├── health-check.sh           # Service health checker
│   ├── backup.sh                 # Data backup utility
│   └── test-inference.sh         # LLM inference tester
│
├── services/                      # Modular microservices
│   │
│   ├── model-manager/            # Model management UI
│   │   ├── Dockerfile
│   │   ├── docker-compose.yml    # Standalone testing
│   │   ├── requirements.txt
│   │   ├── server.py
│   │   └── README.md
│   │
│   ├── whisperx/                 # Speech-to-text service
│   │   ├── Dockerfile
│   │   ├── docker-compose.yml
│   │   ├── requirements.txt
│   │   ├── server.py
│   │   └── README.md
│   │
│   ├── kokoro-tts/               # Text-to-speech service
│   │   ├── Dockerfile
│   │   ├── docker-compose.yml
│   │   ├── requirements.txt
│   │   ├── server.py
│   │   ├── optimize_model.py
│   │   └── README.md
│   │
│   ├── reranker/                 # Document reranking service
│   │   ├── Dockerfile
│   │   ├── docker-compose.yml
│   │   ├── requirements.txt
│   │   ├── server.py
│   │   └── README.md
│   │
│   ├── tika-ocr/                 # Document OCR (from UC-1)
│   │   ├── Dockerfile
│   │   ├── docker-compose.yml
│   │   └── config/
│   │
│   └── searxng/                  # Search engine (from UC-1)
│       ├── Dockerfile
│       ├── docker-compose.yml
│       ├── settings.yml
│       └── uwsgi.ini
│
├── config/                        # Shared configuration files
│   └── prometheus/
│       └── prometheus.yml         # Metrics collection config
│
├── Drivers/                       # System drivers and BIOS
│   ├── README.md                 # Driver documentation
│   ├── install-nvidia-driver.sh  # NVIDIA driver installer
│   ├── install-nvidia-container-toolkit.sh
│   └── BIOS/                     # BIOS updates
│       └── TUF-GAMING-Z790-PLUS-WIFI-ASUS-1820.CAP
│
├── documentation/                 # Project documentation site
├── extensions/                    # Optional, standalone services
└── volumes/                       # Docker volume mount points (created at runtime)
    ├── postgres_data/
    ├── redis_data/
    ├── qdrant_data/
    ├── vllm_models/
    ├── embedding_models/
    └── ...
```

## Microservices Architecture

### Service Categories

#### 1. **Core AI Services (RTX 5090)**
- **vLLM**: Primary LLM inference engine
- **Model Manager**: Web UI for model management

#### 2. **Auxiliary AI Services (Intel iGPU/CPU)**
- **WhisperX**: Advanced speech recognition
- **Kokoro TTS**: Text-to-speech synthesis
- **Embeddings**: Text embedding generation
- **Reranker**: Document relevance scoring

#### 3. **Data Services**
- **PostgreSQL**: Relational database
- **Redis**: Cache and message broker
- **Qdrant**: Vector database

#### 4. **Supporting Services**
- **Open-WebUI**: Main user interface
- **Tika OCR**: Document processing
- **SearXNG**: Privacy-respecting search
- **Prometheus**: Metrics collection
- **GPU Exporter**: NVIDIA GPU metrics

## Service Descriptions

### vLLM (Port 8000)
**Purpose**: High-performance LLM inference  
**Hardware**: RTX 5090 (exclusive)  
**Key Features**:
- OpenAI-compatible API
- PagedAttention for memory efficiency
- Continuous batching
- AWQ quantization support
- 16K+ context window

**Configuration**:
```yaml
environment:
  DEFAULT_LLM_MODEL: Qwen/Qwen2.5-32B-Instruct-AWQ
  MAX_MODEL_LEN: 16384
  GPU_MEMORY_UTIL: 0.95
```

### WhisperX (Port 9000)
**Purpose**: Speech-to-text with advanced features  
**Hardware**: CPU (Intel optimized)  
**Key Features**:
- Word-level timestamps
- Speaker diarization
- Batch processing
- Multiple language support

**API Endpoints**:
- `POST /v1/audio/transcriptions`
- `GET /health`

### Kokoro TTS (Port 8880)
**Purpose**: Natural text-to-speech  
**Hardware**: Intel iGPU (OpenVINO)  
**Key Features**:
- Multiple voice options
- Speed control
- Streaming support
- Low latency

### Model Manager (Port 8084)
**Purpose**: Web UI for model management  
**Hardware**: Minimal (web server)  
**Key Features**:
- Model switching interface
- Status monitoring
- Pre-configured model list
- Simple web UI

### Embeddings Service (Port 8082)
**Purpose**: Generate text embeddings for RAG  
**Hardware**: CPU  
**Key Features**:
- High-throughput batch processing
- Multiple model support
- OpenAI-compatible API

### Reranker (Port 8083)
**Purpose**: Improve search relevance  
**Hardware**: CPU  
**Key Features**:
- Cross-encoder models
- Batch reranking
- Configurable models

### Open-WebUI (Port 8080)
**Purpose**: Main user interface  
**Hardware**: Minimal  
**Key Features**:
- Chat interface
- Document upload
- Model selection
- User management
- RAG integration

### Tika OCR (Port 9998)
**Purpose**: Document text extraction  
**Hardware**: CPU  
**Key Features**:
- Multiple format support
- OCR for images/PDFs
- Language detection
- Metadata extraction

### SearXNG (Port 8888)
**Purpose**: Metasearch engine  
**Hardware**: CPU  
**Key Features**:
- Privacy-respecting
- Multiple search engines
- Customizable
- No tracking

## Network Architecture

### Docker Network Configuration
```yaml
networks:
  unicorn-network:
    driver: bridge
    name: unicorn-network
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16
```

### Service Discovery
Each service has multiple network aliases for flexible access:

```yaml
networks:
  unicorn-network:
    aliases:
      - vllm          # Short name
      - llm           # Alternative
      - inference     # Functional name
```

### Access Patterns
1. **Internal**: `http://unicorn-vllm:8000`
2. **Container**: `http://vllm:8000`
3. **Host**: `http://localhost:8000`
4. **Network**: `http://172.20.0.x:8000`

## Data Flow

### 1. **Chat Completion Flow**
```
User → Open-WebUI → vLLM → Response
         ↓            ↓
      PostgreSQL   Redis Cache
```

### 2. **RAG (Retrieval Augmented Generation) Flow**
```
Document → Tika OCR → Text → Embeddings → Qdrant
                                ↓
User Query → Embeddings → Qdrant Search → Reranker → Context
                                              ↓
                                           vLLM → Response
```

### 3. **Speech Processing Flow**
```
Audio Input → WhisperX → Text → vLLM → Response → Kokoro TTS → Audio Output
```

### 4. **Search Integration Flow**
```
User Query → Open-WebUI → SearXNG → Search Results
                            ↓
                         Reranker → Relevant Results → vLLM Context
```

## Hardware Resource Allocation

### RTX 5090 (32GB VRAM)
- **Exclusive**: vLLM service
- **Usage**: 95% VRAM utilization
- **Models**: 70B parameter models with 4-bit quantization

### Intel iGPU
- **Shared**: Kokoro TTS (OpenVINO optimized)
- **Potential**: WhisperX (future OpenVINO support)

### CPU Resources
- **High Priority**: Embeddings, Reranker
- **Medium Priority**: WhisperX, Tika OCR
- **Low Priority**: Web services, databases

### Memory Allocation
- **Redis**: 16GB cache
- **PostgreSQL**: Dynamic
- **Service Containers**: ~2-4GB each

## Deployment Guide

### Prerequisites Check
```bash
# GPU Check
nvidia-smi

# Docker Check
docker --version
docker-compose --version

# NVIDIA Container Toolkit
docker run --rm --runtime=nvidia nvidia/cuda:12.0-base nvidia-smi
```

### Initial Setup
```bash
# 1. Clone repository
git clone <repository> UC-1-Pro
cd UC-1-Pro

# 2. Run setup script
chmod +x setup-uc1-pro.sh
./setup-uc1-pro.sh

# 3. Configure environment
cp .env.template .env
# Edit .env with your settings

# 4. Deploy
./scripts/start.sh
```

### Service Management
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart specific service
docker-compose restart vllm

# View logs
docker-compose logs -f vllm

# Scale service (if stateless)
docker-compose up -d --scale embeddings=2
```

## Service Communication Matrix

| Service | Communicates With | Protocol | Purpose |
|---------|------------------|----------|---------|
| Open-WebUI | vLLM, Embeddings, PostgreSQL, Redis, Qdrant, Tika, SearXNG | HTTP/REST | Central hub |
| vLLM | Redis | TCP | Cache |
| Model Manager | vLLM | HTTP | Status/Control |
| WhisperX | - | - | Standalone |
| Kokoro TTS | - | - | Standalone |
| Embeddings | - | - | Standalone |
| Reranker | - | - | Standalone |
| Tika OCR | - | - | Standalone |
| SearXNG | Redis | TCP | Cache |
| Prometheus | All services | HTTP | Metrics |

## Performance Considerations

### Expected Throughput
- **vLLM**: 500-600 tokens/sec (Qwen 32B AWQ)
- **WhisperX**: Real-time factor 0.1-0.3
- **Embeddings**: 1000+ embeddings/sec
- **Reranker**: 100+ documents/sec

### Optimization Tips
1. **Model Selection**: Use AWQ quantization for best speed/quality
2. **Batch Processing**: Enable for WhisperX and Embeddings
3. **Caching**: Redis cache for frequent queries
4. **Context Length**: Balance context size with speed

## Monitoring and Maintenance

### Health Checks
```bash
./scripts/health-check.sh
```

### Metrics Dashboard
- Prometheus: http://localhost:9090
- GPU Metrics: http://localhost:9835/metrics

### Backup Strategy
```bash
# Automated backup
./scripts/backup.sh

# Manual backup
docker-compose exec postgresql pg_dump -U unicorn unicorn_db > backup.sql
```

## Security Considerations

1. **Network Isolation**: Services communicate only through Docker network
2. **API Keys**: Configured in .env file
3. **Port Exposure**: Only necessary ports exposed to host
4. **Data Encryption**: Use HTTPS reverse proxy for production

## Troubleshooting

### Common Issues

1. **GPU Not Found**
   ```bash
   # Check NVIDIA runtime
   docker info | grep nvidia
   ```

2. **Service Won't Start**
   ```bash
   # Check logs
   docker-compose logs <service-name>
   ```

3. **Out of Memory**
   ```bash
   # Check resource usage
   docker stats
   nvidia-smi
   ```

## Development Workflow

### Adding New Service
1. Create service directory: `services/new-service/`
2. Add Dockerfile and requirements
3. Create standalone docker-compose.yml
4. Test independently
5. Integrate into main docker-compose.yml

### Testing Service
```bash
cd services/new-service
docker-compose up
# Test endpoints
docker-compose down
```

---

## Conclusion

UC-1 Pro implements a clean, modular architecture optimized for high-performance AI workloads on RTX 5090 hardware. The microservices design allows for independent scaling, development, and deployment while maintaining system cohesion through well-defined interfaces and a unified network architecture.