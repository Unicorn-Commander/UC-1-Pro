# Monitoring

The UC-1 Pro stack includes services for monitoring the health and performance of the system.

## Prometheus

Prometheus is an open-source systems monitoring and alerting toolkit. It scrapes metrics from various services and stores them in a time-series database.

- **Image**: `prom/prometheus:latest`
- **Port**: `9090`

## GPU Exporter

The GPU Exporter is a service that exports NVIDIA GPU metrics in a format that can be scraped by Prometheus.

- **Image**: `utkuozdemir/nvidia_gpu_exporter:1.2.0`
- **Port**: `9835`
