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
- 8090 - Dashboard (changed from 8080)

### Monitoring
- 9091 - Prometheus (changed from 9090)
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

## No More Conflicts! 🎉

All port conflicts have been resolved:

- **Portainer**: Changed from 9000 → 9444 (WhisperX uses 9000)
- **Traefik Dashboard**: Changed from 8080 → 8090 (Open-WebUI uses 8080)
- **Monitoring Prometheus**: Changed from 9090 → 9091 (Core Prometheus uses 9090)

All services can now run simultaneously without port conflicts.

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