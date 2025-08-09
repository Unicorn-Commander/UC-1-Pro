# Ollama Extension Integration

## Overview
Ollama is now integrated as an extension service in UC-1 Pro, providing local LLM inference capabilities alongside the core vLLM service.

## Status
- **Type:** Extension Service
- **Category:** Inference
- **Port:** 11434
- **GPU Support:** NVIDIA RTX 5090 detected and configured
- **Network:** Accessible on all interfaces (0.0.0.0)

## Features
- ✅ Fully integrated with UC-1 Pro stack
- ✅ Appears under "Extension Services" in the Operations Center
- ✅ Docker network integration (unicorn-network)
- ✅ GPU acceleration enabled
- ✅ Model management support

## Quick Start

### Start the Extension
```bash
cd /home/ucadmin/UC-1-Pro/extensions/ollama
docker-compose up -d
```

### Install Models
```bash
# Install a small model for testing
docker exec unicorn-ollama ollama pull llama3.2:1b

# Install a larger model
docker exec unicorn-ollama ollama pull llama3.2:3b

# For coding tasks
docker exec unicorn-ollama ollama pull codellama:7b
```

### List Installed Models
```bash
docker exec unicorn-ollama ollama list
```

## Access Points

### API Endpoint
- **URL:** http://localhost:11434
- **Available from network:** http://192.168.1.135:11434

### Test the API
```bash
# List models
curl http://localhost:11434/api/tags

# Generate completion
curl -X POST http://localhost:11434/api/generate -d '{
  "model": "llama3.2:1b",
  "prompt": "Hello, how are you?"
}'
```

## Integration with Open-WebUI

To use Ollama models in Open-WebUI:

1. Go to Open-WebUI Settings (http://localhost:8080)
2. Navigate to "Models" section
3. Add Ollama connection:
   - URL: `http://unicorn-ollama:11434`
4. Your Ollama models will appear alongside vLLM models

## Service Management

### Using Make commands
```bash
# In the extension directory
make start        # Start Ollama
make stop         # Stop Ollama
make status       # Check status
make logs         # View logs
make models       # List installed models
make install-model MODEL=llama3.2:3b  # Install a model
```

### Using Docker Compose
```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# Restart
docker-compose restart

# View logs
docker-compose logs -f
```

## Configuration

### Environment Variables (.env)
```env
# GPU Configuration
CUDA_VISIBLE_DEVICES=0
NVIDIA_VISIBLE_DEVICES=all

# Ollama Settings
OLLAMA_NUM_PARALLEL=2
OLLAMA_MAX_LOADED_MODELS=2
OLLAMA_KEEP_ALIVE=5m

# Network
OLLAMA_HOST=0.0.0.0
OLLAMA_ORIGINS=*
```

### Resource Allocation
- **GPU:** Shares RTX 5090 with vLLM (managed by CUDA)
- **Memory:** Automatically managed by Ollama
- **Models Path:** `/home/ucadmin/UC-1-Pro/volumes/ollama_models`

## Troubleshooting

### Container shows "unhealthy"
The healthcheck may fail initially if no models are installed. Install at least one model:
```bash
docker exec unicorn-ollama ollama pull llama3.2:1b
```

### GPU not detected
Check GPU availability:
```bash
docker exec unicorn-ollama nvidia-smi
```

### Port conflicts
If port 11434 is in use, modify the port mapping in `docker-compose.yml`:
```yaml
ports:
  - "11434:11434"  # Change first number to different port
```

## Models Recommendations

### Small Models (< 2GB)
- `llama3.2:1b` - Fastest, good for testing
- `phi3:mini` - Microsoft's efficient model

### Medium Models (2-8GB)
- `llama3.2:3b` - Good balance of speed and quality
- `mistral:7b` - Excellent general purpose
- `codellama:7b` - Optimized for coding

### Large Models (8GB+)
- `llama3.1:8b` - High quality responses
- `mixtral:8x7b` - MoE architecture
- `deepseek-coder:33b` - Advanced coding

## Integration Status

✅ **Completed:**
- Docker Compose configuration
- Network integration
- GPU support
- Service detection in Ops Center
- Appears as Extension Service
- Model management
- API accessibility

## Future Enhancements

- [ ] Ollama WebUI integration
- [ ] Automatic model download on startup
- [ ] Model performance monitoring
- [ ] Integration with UC-1 Pro backup system
- [ ] Model sharing between vLLM and Ollama