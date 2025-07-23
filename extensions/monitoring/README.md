# Monitoring Extension for UC-1 Pro

This extension provides comprehensive monitoring for your UC-1 Pro stack using Prometheus and Grafana.

## Features

- **Prometheus**: Metrics collection and storage
- **Grafana**: Beautiful dashboards and visualizations
- **Node Exporter**: System-level metrics (CPU, memory, disk)
- **GPU Metrics**: Via the gpu-exporter from main stack
- **Service Health Monitoring**: Track all UC-1 Pro services

## Quick Start

```bash
cd extensions/monitoring
docker-compose up -d
```

Access:
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin by default)

## Configuration

### Change Grafana Password

Edit your `.env` file:
```env
GRAFANA_USER=admin
GRAFANA_PASSWORD=your-secure-password
```

### Retention Period

By default, Prometheus keeps 30 days of data. Modify in docker-compose.yml:
```yaml
command:
  - '--storage.tsdb.retention.time=90d'  # 90 days
```

## Available Metrics

### GPU Metrics (from gpu-exporter)
- GPU utilization
- Memory usage
- Temperature
- Power consumption

### System Metrics (from node-exporter)
- CPU usage
- Memory utilization
- Disk I/O
- Network traffic

### Service Metrics
- vLLM request latency
- Model loading times
- Queue depths
- Error rates

## Grafana Dashboards

Import these dashboard IDs for instant visualizations:

1. **NVIDIA GPU Dashboard**: 14574
2. **Node Exporter Full**: 1860
3. **Docker Container Dashboard**: 11600

### Import Instructions

1. Go to Grafana → Dashboards → Import
2. Enter the dashboard ID
3. Select Prometheus as data source
4. Click Import

## Adding Database Exporters

To monitor PostgreSQL and Redis, add these to the main docker-compose.yml:

```yaml
  redis-exporter:
    image: oliver006/redis_exporter:latest
    container_name: unicorn-redis-exporter
    environment:
      REDIS_ADDR: "redis://redis:6379"
    ports:
      - "9121:9121"
    networks:
      - unicorn-network

  postgres-exporter:
    image: prometheuscommunity/postgres-exporter:latest
    container_name: unicorn-postgres-exporter
    environment:
      DATA_SOURCE_NAME: "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgresql:5432/${POSTGRES_DB}?sslmode=disable"
    ports:
      - "9187:9187"
    networks:
      - unicorn-network
```

## Custom Alerts

Create `alerts.yml` for custom alerting rules:

```yaml
groups:
  - name: uc1-pro
    rules:
      - alert: HighGPUMemory
        expr: nvidia_gpu_memory_used_bytes / nvidia_gpu_memory_total_bytes > 0.9
        for: 5m
        annotations:
          summary: "GPU memory usage above 90%"
          
      - alert: ServiceDown
        expr: up == 0
        for: 1m
        annotations:
          summary: "Service {{ $labels.job }} is down"
```

## Resource Usage

- Prometheus: ~2GB RAM, grows with retention
- Grafana: ~200MB RAM
- Node Exporter: ~50MB RAM

## Maintenance

### Backup Prometheus Data
```bash
docker run --rm -v uc1-pro_prometheus_data:/data -v $(pwd):/backup alpine tar czf /backup/prometheus-backup.tar.gz -C /data .
```

### Clean Old Data
```bash
# Access Prometheus admin API
curl -X POST http://localhost:9090/api/v1/admin/tsdb/clean_tombstones
```

## Troubleshooting

### No GPU Metrics
Ensure gpu-exporter is running in main stack:
```bash
docker-compose ps gpu-exporter
```

### High Disk Usage
Reduce retention or increase scrape interval in prometheus.yml:
```yaml
global:
  scrape_interval: 30s  # Instead of 15s
```