#!/bin/bash

# UC-1 Pro Model Downloader
# Downloads all required models for the stack

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         UC-1 Pro Model Downloader                      ║${NC}"
echo -e "${BLUE}║     Download all required models for the stack         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Create base directories
mkdir -p volumes/{kokoro_models,whisperx_models,reranker_models,embedding_models}

# Track success
FAILED_DOWNLOADS=""

# Function to download with progress
download_file() {
    local url=$1
    local output=$2
    local description=$3
    
    echo -e "${YELLOW}Downloading $description...${NC}"
    if wget --progress=bar:force -O "$output" "$url" 2>&1 | grep -E -o '[0-9]+%' | tail -1; then
        echo -e "${GREEN}✓ Downloaded $description${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to download $description${NC}"
        FAILED_DOWNLOADS="$FAILED_DOWNLOADS\n- $description"
        return 1
    fi
}

# Function to check file size
check_file_size() {
    local file=$1
    local min_size_mb=$2
    local description=$3
    
    if [ -f "$file" ]; then
        local size=$(du -m "$file" | cut -f1)
        if [ "$size" -ge "$min_size_mb" ]; then
            echo -e "${GREEN}✓ $description size verified: ${size}MB${NC}"
            return 0
        else
            echo -e "${RED}✗ $description too small: ${size}MB (expected >${min_size_mb}MB)${NC}"
            rm -f "$file"
            return 1
        fi
    else
        return 1
    fi
}

echo -e "\n${BLUE}=== Kokoro TTS Model ===${NC}"
if [ -f "volumes/kokoro_models/kokoro-v0_19.onnx" ]; then
    echo -e "${GREEN}✓ Kokoro model already exists${NC}"
else
    KOKORO_URLS=(
        "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files/kokoro-v0_19.onnx"
        "https://huggingface.co/NeuML/kokoro-base-onnx/resolve/main/model.onnx"
    )
    
    for url in "${KOKORO_URLS[@]}"; do
        if download_file "$url" "volumes/kokoro_models/kokoro-v0_19.onnx" "Kokoro TTS model"; then
            if check_file_size "volumes/kokoro_models/kokoro-v0_19.onnx" 200 "Kokoro model"; then
                # Create voices.json
                echo '{"voices": ["af", "af_bella", "af_sarah", "am_adam", "am_michael", "bf_emma", "bf_isabella", "bm_george", "bm_lewis"]}' > volumes/kokoro_models/voices.json
                break
            fi
        fi
    done
fi

echo -e "\n${BLUE}=== WhisperX Model ===${NC}"
if [ -f "volumes/whisperx_models/whisper_model_downloaded" ]; then
    echo -e "${GREEN}✓ WhisperX models already downloaded${NC}"
else
    echo -e "${YELLOW}WhisperX models will be downloaded on first run${NC}"
    echo "This is handled automatically by the WhisperX service"
    touch volumes/whisperx_models/whisper_model_downloaded
fi

echo -e "\n${BLUE}=== Embedding Model ===${NC}"
if [ -f "volumes/embedding_models/model_downloaded" ]; then
    echo -e "${GREEN}✓ Embedding model already downloaded${NC}"
else
    echo -e "${YELLOW}Embedding model (${EMBEDDING_MODEL:-BAAI/bge-base-en-v1.5}) will be downloaded on first run${NC}"
    echo "This is handled automatically by the text-embeddings-inference service"
    touch volumes/embedding_models/model_downloaded
fi

echo -e "\n${BLUE}=== Reranker Model ===${NC}"
if [ -f "volumes/reranker_models/model_downloaded" ]; then
    echo -e "${GREEN}✓ Reranker model already downloaded${NC}"
else
    echo -e "${YELLOW}Reranker model (${RERANKER_MODEL:-BAAI/bge-reranker-v2-m3}) will be downloaded on first run${NC}"
    echo "This is handled automatically by the reranker service"
    touch volumes/reranker_models/model_downloaded
fi

echo -e "\n${BLUE}=== vLLM Model ===${NC}"
# Source .env if it exists to get model choice
if [ -f ".env" ]; then
    source .env
fi
LLM_MODEL="${DEFAULT_LLM_MODEL:-Qwen/Qwen2.5-32B-Instruct-AWQ}"
MODEL_DIR="volumes/vllm_models"

echo -e "${YELLOW}Checking vLLM model: $LLM_MODEL${NC}"

# Function to download Hugging Face model
download_hf_model() {
    local model_id=$1
    local model_dir=$2
    
    echo -e "${YELLOW}Downloading $model_id from Hugging Face...${NC}"
    echo "This may take a while for large models..."
    
    # Use huggingface-cli if available, otherwise use git lfs
    if command -v huggingface-cli &> /dev/null; then
        huggingface-cli download "$model_id" --local-dir "$model_dir/$model_id" --local-dir-use-symlinks False
    else
        # Install git-lfs if not present
        if ! command -v git-lfs &> /dev/null; then
            echo "Installing git-lfs..."
            sudo apt-get update && sudo apt-get install -y git-lfs
            git lfs install
        fi
        
        # Clone the model
        if [ -d "$model_dir/$model_id" ]; then
            echo "Model directory exists, pulling updates..."
            cd "$model_dir/$model_id"
            git pull
            cd -
        else
            git clone "https://huggingface.co/$model_id" "$model_dir/$model_id"
        fi
    fi
}

# Check if model already exists
if [ -d "$MODEL_DIR/$LLM_MODEL" ] && [ -f "$MODEL_DIR/$LLM_MODEL/config.json" ]; then
    echo -e "${GREEN}✓ vLLM model already downloaded${NC}"
else
    read -p "Download vLLM model ($LLM_MODEL)? This is 15-70GB depending on model. (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        download_hf_model "$LLM_MODEL" "$MODEL_DIR"
        if [ -f "$MODEL_DIR/$LLM_MODEL/config.json" ]; then
            echo -e "${GREEN}✓ vLLM model downloaded successfully${NC}"
        else
            echo -e "${RED}✗ vLLM model download may have failed${NC}"
            FAILED_DOWNLOADS="$FAILED_DOWNLOADS\n- vLLM model: $LLM_MODEL"
        fi
    else
        echo -e "${YELLOW}Skipping vLLM model download - will download on first run${NC}"
    fi
fi

echo -e "\n${BLUE}=== Additional Models ===${NC}"
echo ""
echo "Other available models you might want to pre-download:"
echo "1. Gemma 2 27B: casperhansen/gemma-2-27b-it-awq"
echo "2. Llama 3.1 70B: meta-llama/Llama-3.1-70B-Instruct-AWQ"  
echo "3. Mistral 7B: mistralai/Mistral-7B-Instruct-v0.3"
echo ""
read -p "Download additional models? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Enter model ID (e.g., mistralai/Mistral-7B-Instruct-v0.3):"
    read -r additional_model
    if [ ! -z "$additional_model" ]; then
        download_hf_model "$additional_model" "$MODEL_DIR"
    fi
fi

# Summary
echo -e "\n${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                     Summary                             ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"

if [ -z "$FAILED_DOWNLOADS" ]; then
    echo -e "\n${GREEN}All models are ready!${NC}"
    echo ""
    echo "Some models download automatically on first run:"
    echo "- vLLM: Large language model"
    echo "- WhisperX: Speech recognition models"
    echo "- Embeddings: Text embedding model"
    echo "- Reranker: Reranking model"
else
    echo -e "\n${YELLOW}Some downloads failed:${NC}"
    echo -e "$FAILED_DOWNLOADS"
    echo ""
    echo "You can:"
    echo "1. Re-run this script to retry"
    echo "2. Download manually and place in volumes/ directory"
    echo "3. Let services download on first run (may be slower)"
fi

echo ""
echo -e "${GREEN}Next step: ./start.sh${NC}"
echo ""