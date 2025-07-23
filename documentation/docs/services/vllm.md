# vLLM

vLLM is the high-performance LLM inference engine that powers the core of the UC-1 Pro stack. It is optimized for running large language models on the NVIDIA RTX 5090.

## Key Features

- **High Throughput**: Achieves high inference throughput with techniques like PagedAttention and continuous batching.
- **OpenAI-Compatible API**: Provides an API that is compatible with the OpenAI Chat Completions API, making it easy to integrate with other services.
- **Quantization Support**: Supports various quantization methods, including AWQ, to run large models with lower memory requirements.

## Service Configuration

- **Image**: `vllm/vllm-openai:v0.9.2`
- **Port**: `8000`
- **Hardware**: NVIDIA RTX 5090 (exclusive)

## Environment Variables

- `VLLM_API_KEY`: The API key to secure the service.
- `HF_TOKEN`: Hugging Face token for downloading models.
- `DEFAULT_LLM_MODEL`: The default model to load on startup.
- `LLM_QUANTIZATION`: The quantization method to use.
- `MAX_MODEL_LEN`: The maximum context length.
- `GPU_MEMORY_UTIL`: The percentage of GPU memory to use.
