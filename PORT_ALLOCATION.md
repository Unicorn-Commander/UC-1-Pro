# UC-1 Pro Port Allocation Map

This document maps all port allocations across the UC-1 Pro stack to prevent conflicts.

## Core Services (Main Stack)

| Port | Service | Container | Purpose |
|------|---------|-----------|---------|
| 5432 | PostgreSQL | unicorn-postgresql | Database |
| 6333 | Qdrant | unicorn-qdrant | Vector DB HTTP |
| 6334 | Qdrant | unicorn-qdrant | Vector DB gRPC |
| 6379 | Redis | unicorn-redis | Cache/Queue |
| 8000 | vLLM | unicorn-vllm | LLM Inference API |
| 8080 | Open-WebUI | unicorn-open-webui | Main Chat Interface |
| 8081 | Documentation | unicorn-docs | MkDocs |
| 8082 | Embeddings | unicorn-embeddings | Text Embedding API |
| 8083 | Reranker | unicorn-reranker | Document Reranking |
| 8084 | Ops Center | unicorn-ops-center | Admin Dashboard |
| 8888 | Center-Deep | unicorn-searxng | AI Search Platform |
| 8880 | Kokoro TTS | unicorn-kokoro | Text-to-Speech |
| 9000 | WhisperX | unicorn-whisperx | Speech-to-Text |
| 9090 | Prometheus | unicorn-prometheus | Metrics Collection |
| 9835 | GPU Exporter | unicorn-gpu-exporter | GPU Metrics |
| 9998 | Apache Tika | unicorn-tika | Document OCR |

## Extension Services

### Authentication (Authentik SSO)
| Port | Service | Container | Purpose |
|------|---------|-----------|---------|
| 9005 | Authentik Server | authentik-server | SSO Web Interface |
| 9445 | Authentik HTTPS | authentik-server | SSO HTTPS |
| 9876 | Authentik Proxy | authentik-proxy | ForwardAuth Proxy |

### Traefik Reverse Proxy
| Port | Service | Container | Purpose |
|------|---------|-----------|---------|
| 80 | Traefik HTTP | traefik | HTTP Traffic |
| 443 | Traefik HTTPS | traefik | HTTPS Traffic |
| 8090 | Traefik Dashboard | traefik | Web Management |

### Development Tools
| Port | Service | Container | Purpose |
|------|---------|-----------|---------|
| 8889 | Jupyter Lab | jupyter-lab | Development |
| 8890 | pgAdmin | pgadmin | Database Admin |
| 8891 | Nginx | nginx | Static Files |
| 8892 | Code Server | code-server | VS Code Web |

### Monitoring Stack
| Port | Service | Container | Purpose |
|------|---------|-----------|---------|
| 3000 | Grafana | grafana | Dashboard |
| 9091 | Prometheus | monitoring-prometheus | Extension Metrics |
| 9100 | Node Exporter | node-exporter | System Metrics |

### AI Extensions
| Port | Service | Container | Purpose |
|------|---------|-----------|---------|
| 8188 | ComfyUI | comfyui | Image Generation |
| 8189 | ComfyUI Manager | comfyui-manager | Extension Manager |
| 5173 | Bolt.DIY | bolt-diy | AI Coding Assistant |
| 5678 | n8n | n8n | Workflow Automation |

### Container Management
| Port | Service | Container | Purpose |
|------|---------|-----------|---------|
| 9444 | Portainer | portainer | Container Management |
| 9443 | Portainer HTTPS | portainer | Secure Management |
| 9001 | Portainer Edge | portainer-edge | Edge Agent |

## Port Range Allocation Strategy

| Range | Purpose | Status |
|-------|---------|--------|
| 80-99 | Standard HTTP/HTTPS | Used (80, 443) |
| 3000-3999 | Web Applications | Used (3000) |
| 5000-5999 | Development Tools | Used (5173, 5432, 5678) |
| 6000-6999 | Databases | Used (6333, 6334, 6379) |
| 8000-8999 | Main Services | Used (8000, 8080-8084, 8188-8189, 8880, 8888, 8890-8892) |
| 9000-9999 | Processing/Monitoring | Used (9000, 9005, 9090-9091, 9100, 9443-9445, 9835, 9876, 9998) |

## Conflict Resolution

### Known Fixed Conflicts:
1. **Portainer vs WhisperX**: Portainer moved from 9000→9444
2. **Traefik Dashboard vs Open-WebUI**: Traefik moved from 8080→8090
3. **Monitoring Prometheus vs Core**: Extension moved from 9090→9091
4. **Authentik vs WhisperX**: Authentik uses 9005, not 9000

### Port Conflict Prevention Rules:
1. **Core services** use 8000-8999 range
2. **Processing services** use 9000-9999 range  
3. **Extensions** use offset ports to avoid core conflicts
4. **Development tools** use 8890+ range
5. **Always check this document** before adding new services

## Quick Reference for New Services

### Next Available Ports:
- Core services: 8085, 8086, 8087
- Processing: 9002, 9003, 9004
- Web apps: 3001, 3002, 3003
- Development: 8893, 8894, 8895

### Reserved/Avoid:
- 22 (SSH)
- 25 (SMTP)
- 53 (DNS)
- 110, 143, 993, 995 (Email)
- 3306 (MySQL)
- 5672, 15672 (RabbitMQ)
- 11211 (Memcached)

## Commands to Check Port Usage

```bash
# Check what's listening on all ports
sudo netstat -tlnp

# Check specific port
sudo lsof -i :9000

# Check Docker port mappings
docker ps --format "table {{.Names}}\t{{.Ports}}"

# Check UC-1 Pro services
make status
```

## Update Procedure

When adding new services:
1. Check this document for available ports
2. Update this document with new allocation
3. Test for conflicts: `sudo lsof -i :PORT`
4. Commit changes to version control