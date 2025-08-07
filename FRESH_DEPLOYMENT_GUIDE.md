# UC-1 Pro Fresh Deployment Guide
**Version**: 2.0  
**Updated**: August 7, 2025  
**Company**: Magic Unicorn Unconventional Technology & Stuff Inc

## 📋 Pre-Deployment Checklist

### System Requirements
- [ ] Ubuntu 24.04 LTS (recommended) or Ubuntu 22.04 LTS
- [ ] NVIDIA RTX 5090 GPU (32GB VRAM)
- [ ] Minimum 64GB System RAM (96GB+ recommended)
- [ ] 500GB+ NVMe SSD storage
- [ ] Internet connection for downloading models

### Required Software
- [ ] NVIDIA Driver 550+ installed
- [ ] Docker 24.0+ installed
- [ ] Docker Compose 2.24+ installed
- [ ] NVIDIA Container Toolkit installed
- [ ] Git installed

## 🚀 Quick Deployment (Automated)

For a fresh Ubuntu 24.04 LTS system:

```bash
# Clone the repository
git clone https://github.com/your-org/UC-1-Pro.git
cd UC-1-Pro

# Run the automated installer
chmod +x install.sh
./install.sh
```

The installer will:
1. Install all system dependencies
2. Configure Docker and NVIDIA Container Toolkit
3. Generate secure passwords
4. Set up the environment
5. Prepare the system for deployment

## 📦 Manual Deployment Steps

### Step 1: System Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install prerequisites
sudo apt install -y curl wget git build-essential software-properties-common

# Install Docker
curl -fsSL https://get.docker.com | sudo sh

# Add user to docker group
sudo usermod -aG docker $USER
sudo usermod -aG render $USER  # For GPU access
sudo usermod -aG video $USER   # For GPU access

# Log out and back in for group changes to take effect
```

### Step 2: NVIDIA Setup

```bash
# Install NVIDIA drivers (if not already installed)
sudo apt install -y nvidia-driver-550

# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt update
sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Verify GPU access
docker run --rm --runtime=nvidia --gpus all nvidia/cuda:12.0-base nvidia-smi
```

### Step 3: UC-1 Pro Deployment

```bash
# Clone repository
git clone https://github.com/your-org/UC-1-Pro.git
cd UC-1-Pro

# Create environment file
cp .env.template .env

# Edit .env file with your preferred editor
nano .env  # Set secure passwords and configure models

# Create necessary directories
mkdir -p backups volumes

# Build services with curl installed (for health checks)
docker-compose build

# Start the stack
docker-compose up -d

# Monitor startup
docker-compose logs -f
```

## 🔧 Environment Configuration

### Updated Model Configuration (.env)

```env
# Enhanced AI Models (Updated August 2025)
DEFAULT_LLM_MODEL=Qwen/Qwen2.5-32B-Instruct-AWQ
EMBEDDING_MODEL=nomic-ai/nomic-embed-text-v1.5
RERANKER_MODEL=mixedbread-ai/mxbai-rerank-large-v1
WHISPER_MODEL=base
KOKORO_VOICE=af

# GPU Configuration
GPU_MEMORY_UTIL=0.95
MAX_MODEL_LEN=16384
TENSOR_PARALLEL=1
```

## 📦 Service Components

### Core Services
| Service | Image/Build | Port | Purpose |
|---------|------------|------|---------|
| vLLM | vllm/vllm-openai:v0.9.2 | 8000 | LLM inference engine |
| Open-WebUI | ghcr.io/open-webui/open-webui:main | 8080 | Chat interface |
| Embeddings | ./services/embeddings | 8082 | Text embeddings (nomic-embed-text-v1.5) |
| Reranker | ./services/reranker | 8083 | Document reranking (mxbai-rerank-large-v1) |
| WhisperX | ./services/whisperx | 9000 | Speech-to-text |
| Kokoro TTS | ./services/kokoro-tts | 8880 | Text-to-speech |
| Center-Deep | ./services/searxng | 8888 | Private search engine |
| Tika OCR | ./services/tika-ocr | 9998 | Document processing |

### Data Services
| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| PostgreSQL | postgres:16.9-alpine | 5432 | Relational database |
| Redis | redis:7.4.5-alpine | 6379 | Cache and queue |
| Qdrant | qdrant/qdrant:v1.15.0 | 6333/6334 | Vector database |

### Monitoring (Optional)
| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| GPU Exporter | utkuozdemir/nvidia_gpu_exporter:1.2.0 | 9835 | GPU metrics |
| Portainer | portainer/portainer-ce:latest | 9443/9444 | Container management |
| Prometheus | prom/prometheus:latest | 9090 | Metrics collection |
| Grafana | grafana/grafana:latest | 3000 | Metrics visualization |

## 🔍 Post-Deployment Verification

### 1. Check Service Health

```bash
# Check all services are running
docker-compose ps

# Check for unhealthy services
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(unhealthy|restarting)"

# Run comprehensive health check
./scripts/health-check-detailed.sh
```

### 2. Test Service Endpoints

```bash
# Test vLLM (requires API key from .env)
VLLM_API_KEY=$(grep "VLLM_API_KEY=" .env | cut -d'=' -f2)
curl -H "Authorization: Bearer $VLLM_API_KEY" http://localhost:8000/v1/models

# Test Embeddings
curl -X POST http://localhost:8082/v1/embeddings \
  -H "Content-Type: application/json" \
  -d '{"input": "Hello world"}'

# Test Reranker
curl -X POST http://localhost:8083/v1/rerank \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is AI?",
    "documents": ["AI is artificial intelligence", "The sky is blue"]
  }'

# Test WhisperX
curl http://localhost:9000/health

# Test Kokoro TTS
curl http://localhost:8880/health
```

### 3. Access Web Interfaces

- **Open-WebUI**: http://localhost:8080
- **Center-Deep Search**: http://localhost:8888
- **Documentation**: http://localhost:8081
- **Ops Center**: http://localhost:8084
- **Portainer** (if enabled): https://localhost:9443

## 🛠️ Troubleshooting

### Common Issues and Solutions

#### 1. Services Show as Unhealthy
```bash
# Rebuild services with curl installed (required for health checks)
docker-compose build --no-cache embeddings reranker whisperx
docker-compose up -d
```

#### 2. GPU Not Detected
```bash
# Verify NVIDIA runtime
docker run --rm --runtime=nvidia --gpus all nvidia/cuda:12.0-base nvidia-smi

# Check container toolkit
nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

#### 3. Out of Memory Errors
```bash
# Reduce GPU memory allocation in .env
GPU_MEMORY_UTIL=0.90  # Reduce from 0.95

# Use smaller model
DEFAULT_LLM_MODEL=Qwen/Qwen2.5-14B-Instruct-AWQ
```

#### 4. Model Download Issues
```bash
# Pre-download models before starting
./scripts/download-models.sh

# Or set HF_TOKEN in .env for gated models
HF_TOKEN=your_huggingface_token
```

## 📝 Important Notes

### Security Considerations
- Always change default passwords in .env
- Use the installer's auto-generated passwords for production
- Keep API keys secure and rotate regularly
- Consider enabling firewall rules for production

### Performance Optimization
- RTX 5090 allocates 95% VRAM (~31GB) to vLLM by default
- Adjust MAX_MODEL_LEN for your use case (default: 16384 tokens)
- Enable tensor parallelism for multi-GPU setups
- Use AWQ quantization for optimal speed/quality balance

### Backup Strategy
- Automated daily backups configured in .env
- Backup location: ./backups/
- Retention: 7 days (configurable)
- Manual backup: `make backup`

## 🎯 Quick Commands Reference

```bash
# Service Management
make start          # Start all services
make stop           # Stop all services
make restart        # Restart all services
make status         # Check service status

# Logs and Monitoring
make logs           # View all logs
make logs-vllm      # View vLLM logs
make logs-ui        # View Open-WebUI logs
make health         # Run health check

# GPU Management
make gpu-status     # Check GPU status
nvidia-smi          # Monitor GPU usage
nvitop              # Advanced GPU monitoring

# Maintenance
make backup         # Manual backup
make clean          # Clean Docker resources
make update         # Update containers

# Extensions
make monitoring     # Start Prometheus/Grafana
make portainer      # Start Portainer
make comfyui        # Start ComfyUI
```

## 📚 Additional Resources

- **Documentation**: http://localhost:8081
- **Admin Dashboard**: http://localhost:8084
- **UC-1 Pro GitHub**: https://github.com/your-org/UC-1-Pro
- **Support**: support@unicorncommander.com

## ✅ Deployment Complete!

Once all services are healthy:
1. Access Open-WebUI at http://localhost:8080
2. Create your first admin user
3. Configure your preferred settings
4. Start using UC-1 Pro!

---
*UC-1 Pro - Enterprise AI Infrastructure Stack*  
*Magic Unicorn Unconventional Technology & Stuff Inc*