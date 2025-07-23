#!/bin/bash
MODEL=${1}
QUANTIZATION=${2:-"awq"}

if [ -z "$MODEL" ]; then
    echo "Usage: ./switch-model.sh <model_id> [quantization]"
    echo ""
    echo "Available models:"
    echo "  - Qwen/Qwen2.5-32B-Instruct-AWQ (awq)"
    echo "  - casperhansen/gemma-2-27b-it-awq (awq)"
    echo "  - meta-llama/Llama-3.1-70B-Instruct-AWQ (awq)"
    echo "  - mistralai/Mistral-7B-Instruct-v0.3 (none)"
    exit 1
fi

echo "Switching to model: $MODEL with $QUANTIZATION quantization"

# Update the environment variable
cd "$(dirname "$0")/.."
sed -i '' "s|DEFAULT_LLM_MODEL=.*|DEFAULT_LLM_MODEL=$MODEL|" .env
sed -i '' "s|LLM_QUANTIZATION=.*|LLM_QUANTIZATION=$QUANTIZATION|" .env

# Restart vLLM
docker-compose restart vllm

echo "Model switch initiated. Monitor progress with:"
echo "  docker-compose logs -f vllm"
