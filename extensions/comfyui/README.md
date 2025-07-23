# ComfyUI Extension for UC-1 Pro

This extension adds ComfyUI with Flux Kontext support to your UC-1 Pro stack, enabling advanced image generation capabilities.

## Features

- ComfyUI with GPU acceleration
- Flux model support (including Flux Kontext Dev)
- Optional OpenAI-compatible API wrapper for Open-WebUI integration
- Shared GPU usage with the main stack

## Prerequisites

- UC-1 Pro main stack running
- At least 16GB free GPU memory (Flux models are memory-intensive)
- Downloaded Flux model files

## Quick Start

1. **Prepare GPU Resources**

   Since Flux models require significant GPU memory, you may need to reduce vLLM's memory usage:

   ```bash
   # Edit your main .env file
   GPU_MEMORY_UTIL=0.5  # Reduce from 0.95 to share GPU
   ```

   Then restart vLLM:
   ```bash
   docker-compose restart vllm
   ```

2. **Start ComfyUI**

   ```bash
   cd extensions/comfyui
   docker-compose up -d
   ```

3. **Access ComfyUI**

   - ComfyUI Interface: http://localhost:8188
   - API Wrapper (for Open-WebUI): http://localhost:8189

## Model Installation

1. **Download Flux Models**

   Place your models in the appropriate directories:
   
   ```bash
   # Flux checkpoint
   ./models/checkpoints/flux1-dev.safetensors
   
   # VAE (if separate)
   ./models/vae/
   
   # CLIP models
   ./models/clip/
   ```

2. **Install Custom Nodes for Flux**

   Access ComfyUI Manager in the web interface to install:
   - ComfyUI-KJNodes (for Flux Kontext)
   - ComfyUI-VideoHelperSuite (for video features)

## Integration with Open-WebUI

To use ComfyUI through Open-WebUI:

1. **Configure Open-WebUI**

   Add ComfyUI as an OpenAI-compatible endpoint:
   
   - Go to Settings → Connections in Open-WebUI
   - Add new OpenAI connection:
     - URL: `http://uc1-comfyui-wrapper:8080/v1`
     - API Key: `comfy-secret-key` (or your configured key)

2. **Create Image Generation Function**

   In Open-WebUI, create a new function that routes image requests to ComfyUI.

## Workflows

Save your workflows in the `./workflows` directory. They will persist between container restarts.

### Example Flux Workflow

A basic Flux text-to-image workflow is included in `./workflows/flux-basic.json`.

## Resource Management

### GPU Memory Optimization

If you encounter OOM errors:

1. **Reduce batch size** in your workflows
2. **Enable CPU offloading** by modifying docker-compose.yml:
   ```yaml
   environment:
     - COMMANDLINE_ARGS=--gpu-only --normalvram --use-pytorch-cross-attention
   ```
3. **Use quantized models** when available

### Dynamic GPU Switching

For development, you can stop vLLM while using ComfyUI:

```bash
# Stop vLLM to free GPU
docker-compose -f ../../docker-compose.yml stop vllm

# Use ComfyUI
# ...

# Restart vLLM when done
docker-compose -f ../../docker-compose.yml start vllm
```

## Troubleshooting

### Out of Memory Errors

1. Check GPU memory usage:
   ```bash
   nvidia-smi
   ```

2. Reduce memory usage:
   - Lower vLLM's GPU_MEMORY_UTIL
   - Use smaller Flux models (schnell instead of dev)
   - Enable attention slicing in workflows

### Slow Generation

- Ensure you're using the GPU: Check `nvidia-smi` shows ComfyUI process
- Use optimized attention: `--use-pytorch-cross-attention`
- Consider using Flux schnell for faster iterations

## Advanced Configuration

### Custom API Wrapper

The included wrapper provides basic OpenAI-compatible endpoints. To extend:

1. Edit `Dockerfile.wrapper` and `wrapper.py`
2. Add custom endpoints for specific workflows
3. Implement caching for frequently used prompts

### Multi-GPU Setup

If you have multiple GPUs, edit docker-compose.yml:

```yaml
environment:
  - NVIDIA_VISIBLE_DEVICES=1  # Use second GPU
```

## Maintenance

```bash
# View logs
docker-compose logs -f comfyui

# Update ComfyUI
docker-compose build --no-cache
docker-compose up -d

# Backup workflows and models
tar -czf comfyui-backup.tar.gz models/ workflows/
```