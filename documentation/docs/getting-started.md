# Getting Started

This guide provides a step-by-step process for setting up the UC-1 Pro stack on a new system.

## Prerequisites

Before you begin, ensure your system meets the following requirements:

- **Operating System**: Ubuntu 24.04 LTS (Secure Boot compatible)
- **GPU**: NVIDIA RTX 5090 with 32GB VRAM
- **RAM**: 96GB recommended (64GB minimum)
- **Storage**: 200GB+ of free space (500GB+ recommended for multiple models)
- **Network**: Internet connection for downloading models and images

## Step 1: Clone the Repository

First, clone the UC-1 Pro repository from GitHub:

```bash
git clone https://github.com/Unicorn-Commander/UC-1-Pro.git
cd UC-1-Pro
```

## Step 2: Run the Installer

UC-1 Pro includes a comprehensive installer that handles all dependencies automatically:

```bash
# Make the installer executable
chmod +x install.sh

# Run the installer
./install.sh
```

The installer will:
- ✅ Install Docker and Docker Compose
- ✅ Configure NVIDIA drivers (with Secure Boot support if needed)
- ✅ Install NVIDIA Container Toolkit
- ✅ Set up user permissions
- ✅ Create necessary directories
- ✅ Generate secure passwords for services
- ✅ Validate your GPU configuration

**Note**: If you have Secure Boot enabled, follow the on-screen instructions for signing the NVIDIA driver kernel module.

## Step 3: Pre-download Models (Optional but Recommended)

To speed up the initial startup, you can pre-download all required models:

```bash
./scripts/download-models.sh
```

This script will:
- Download the Kokoro TTS model (~300MB)
- Optionally download the vLLM model (15-70GB depending on selection)
- Create marker files for other models that auto-download

## Step 4: Start the Stack

Once installation is complete, start all services:

```bash
./start.sh
```

The first startup may take 10-30 minutes if models need to be downloaded. You can monitor progress with:

```bash
# View all logs
docker compose logs -f

# View specific service logs
docker compose logs -f vllm
```

## Step 5: Access the Services

Once running, access your AI services through these URLs:

| Service | URL | Description |
|---------|-----|-------------|
| **Open-WebUI** | http://localhost:8080 | Main AI chat interface |
| **vLLM API** | http://localhost:8000/docs | OpenAI-compatible API |
| **Model Manager** | http://localhost:8084 | Switch between LLM models |
| **SearXNG** | http://localhost:8888 | Private search engine |
| **Documentation** | http://localhost:8081 | This documentation |
| **GPU Metrics** | http://localhost:9835/metrics | NVIDIA GPU statistics |

## Step 6: Verify Installation

Run a quick health check to ensure all services are running correctly:

```bash
make health
```

You should see all services reporting as "healthy".

## Quick Management Commands

UC-1 Pro includes convenient commands for managing your stack:

```bash
# Service management
make start          # Start all services
make stop           # Stop all services
make restart        # Restart all services
make status         # Check service status
make logs           # View all logs

# Maintenance
make backup         # Backup databases
make update         # Update all images

# Model management
./scripts/download-models.sh    # Pre-download models
./scripts/switch-model.sh       # Switch LLM models
```

## Next Steps

- 📖 Read the [Configuration Guide](configuration.md) to customize your setup
- 🔧 Explore [Extensions](extensions.md) for additional features
- 📊 Set up [Monitoring](services/monitoring.md) for system insights
- 🎨 Try [ComfyUI](../extensions/comfyui/README.md) for image generation

## Troubleshooting

If you encounter issues:

1. **GPU not detected**: Run `nvidia-smi` to verify driver installation
2. **Services unhealthy**: Check logs with `docker compose logs [service-name]`
3. **Port conflicts**: Ensure no other services are using the required ports
4. **Out of memory**: Adjust `GPU_MEMORY_UTIL` in `.env` file

For more help, see our [Troubleshooting Guide](troubleshooting.md) or open an issue on [GitHub](https://github.com/Unicorn-Commander/UC-1-Pro/issues).