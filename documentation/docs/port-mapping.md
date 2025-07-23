# Port Mapping Reference

This document lists all ports used by UC-1 Pro services and extensions to help avoid conflicts.

## Core Services

| Service | Port | Description |
|---------|------|-------------|
| PostgreSQL | 5432 | Database |
| Redis | 6379 | Cache & message broker |
| Qdrant | 6333 | Vector DB HTTP |
| Qdrant | 6334 | Vector DB gRPC |
| vLLM | 8000 | LLM API |
| Open-WebUI | 8080 | Main web interface |
| Documentation | 8081 | This documentation |
| Embeddings | 8082 | Text embeddings API |
| Reranker | 8083 | Reranking API |
| Model Manager | 8084 | Model management UI |
| Kokoro TTS | 8880 | Text-to-speech API |
| SearXNG | 8888 | Search engine |
| WhisperX | 9000 | Speech-to-text API |
| Prometheus | 9090 | Metrics database |
| GPU Exporter | 9835 | NVIDIA GPU metrics |
| Tika OCR | 9998 | Document processing |

## Extensions

### Portainer
- 9444 - Web UI (HTTP)
- 9443 - Web UI (HTTPS)
- 9001 - Agent

### Traefik
- 80 - HTTP
- 443 - HTTPS
- 8080 - Dashboard ⚠️ **Conflicts with Open-WebUI**

### Monitoring
- 9090 - Prometheus ⚠️ **Conflicts with main Prometheus**
- 3000 - Grafana
- 9100 - Node Exporter

### Dev Tools
- 8889 - Jupyter Lab
- 8890 - VS Code Server
- 8891 - phpMyAdmin
- 8892 - RedisInsight

### ComfyUI
- 8188 - ComfyUI web interface
- 8189 - ComfyUI API

### Other Extensions
- 5173 - Bolt.DIY
- 5678 - n8n

## Handling Conflicts

⚠️ **Important**: Some extensions conflict with core services:

1. **Traefik Dashboard (8080)** conflicts with **Open-WebUI (8080)**
   - Solution: Either disable Traefik dashboard or change Open-WebUI port in `.env`

2. **Monitoring Prometheus (9090)** conflicts with **Core Prometheus (9090)**
   - Solution: Use either the core Prometheus or the monitoring extension, not both

## Changing Ports

To change a service port, modify the `ports` section in `docker-compose.yml`:

```yaml
services:
  service-name:
    ports:
      - "NEW_PORT:INTERNAL_PORT"
```

Then restart the service:
```bash
docker compose restart service-name
```

## Reserved System Ports

Avoid using these commonly reserved ports:
- 22 - SSH
- 53 - DNS
- 111 - RPC
- 631 - CUPS printing
- 3306 - MySQL (if installed)
- 5900 - VNC