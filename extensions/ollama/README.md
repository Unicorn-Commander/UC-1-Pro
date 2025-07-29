# Ollama Extension for UC-1 Pro

Ollama is a powerful model server that allows you to run large language models locally with NVIDIA GPU acceleration.

## Features

- Run LLMs locally with full GPU acceleration
- Compatible with a wide range of models (Llama, Mistral, Phi, etc.)
- REST API compatible with OpenAI
- Model management and pulling from Ollama model library
- Optimized for NVIDIA GPUs

## Quick Start

1. Start the Ollama service:
   ```bash
   docker compose up -d
   ```

2. Pull a model:
   ```bash
   docker exec -it unicorn-ollama ollama pull llama2
   ```

3. Test the model:
   ```bash
   curl http://localhost:11434/api/generate -d '{
     "model": "llama2",
     "prompt": "Hello, how are you?"
   }'
   ```

## Available Models

Popular models you can run:
- `llama2` - Meta's Llama 2 model
- `mistral` - Mistral 7B
- `phi` - Microsoft's Phi-2
- `codellama` - Code-focused Llama model
- `vicuna` - Fine-tuned Llama model
- `neural-chat` - Intel's chat model

Pull any model with:
```bash
docker exec -it unicorn-ollama ollama pull <model-name>
```

## API Endpoints

- **Generate**: `POST http://localhost:11434/api/generate`
- **Chat**: `POST http://localhost:11434/api/chat`
- **List Models**: `GET http://localhost:11434/api/tags`
- **Model Info**: `GET http://localhost:11434/api/show`

## Integration with Open-WebUI

Ollama integrates seamlessly with Open-WebUI. To connect:

1. In Open-WebUI settings, add Ollama as a model provider
2. Set the API URL to: `http://unicorn-ollama:11434`
3. All downloaded models will appear automatically

## GPU Usage

This container is configured to use all available NVIDIA GPUs. You can monitor GPU usage with:
```bash
nvidia-smi
```

## Model Storage

Models are stored in two locations:
- Internal volume: `unicorn-ollama-models`
- Shared directory: `/home/ucadmin/UC-1-Pro/volumes/ollama_models`

This allows models to be shared with other services if needed.

## Environment Variables

- `OLLAMA_MODELS` - Model storage directory
- `NVIDIA_VISIBLE_DEVICES` - GPU visibility (default: all)
- `NVIDIA_DRIVER_CAPABILITIES` - NVIDIA capabilities

## Troubleshooting

### GPU Not Detected
Ensure NVIDIA Container Toolkit is installed:
```bash
nvidia-smi  # Should show your GPU
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi  # Test GPU in Docker
```

### Port Already in Use
If port 11434 is already in use, modify the port mapping in docker-compose.yml

### Model Download Issues
Check available disk space - models can be several GB in size

## Resources

- Official Ollama Documentation: https://ollama.ai/
- Model Library: https://ollama.ai/library
- GitHub: https://github.com/ollama/ollama