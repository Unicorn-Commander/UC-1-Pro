#!/bin/bash

# GPU Memory Manager - Helps switch between different GPU-intensive workloads
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

show_usage() {
    echo "GPU Memory Manager for UC-1 Pro"
    echo ""
    echo "Usage: $0 [mode]"
    echo ""
    echo "Modes:"
    echo "  full-llm     - Maximize GPU for LLM (95% memory)"
    echo "  balanced     - Balance LLM and image generation (50% memory)"
    echo "  minimal-llm  - Minimal LLM, max for other GPU tasks (25% memory)"
    echo "  status       - Show current GPU memory allocation"
    echo ""
    echo "Example: $0 balanced"
}

update_env() {
    local key=$1
    local value=$2
    
    if grep -q "^${key}=" .env; then
        sed -i.bak "s/^${key}=.*/${key}=${value}/" .env
    else
        echo "${key}=${value}" >> .env
    fi
}

case "$1" in
    full-llm)
        echo -e "${YELLOW}Setting GPU to full LLM mode (95% memory)...${NC}"
        update_env "GPU_MEMORY_UTIL" "0.95"
        echo -e "${GREEN}✓ Updated GPU_MEMORY_UTIL to 0.95${NC}"
        echo -e "${YELLOW}Restarting vLLM...${NC}"
        docker-compose restart vllm
        ;;
        
    balanced)
        echo -e "${YELLOW}Setting GPU to balanced mode (50% memory)...${NC}"
        update_env "GPU_MEMORY_UTIL" "0.50"
        echo -e "${GREEN}✓ Updated GPU_MEMORY_UTIL to 0.50${NC}"
        echo -e "${YELLOW}Restarting vLLM...${NC}"
        docker-compose restart vllm
        echo -e "${GREEN}✓ GPU memory now available for other tasks (ComfyUI, etc.)${NC}"
        ;;
        
    minimal-llm)
        echo -e "${YELLOW}Setting GPU to minimal LLM mode (25% memory)...${NC}"
        update_env "GPU_MEMORY_UTIL" "0.25"
        echo -e "${GREEN}✓ Updated GPU_MEMORY_UTIL to 0.25${NC}"
        echo -e "${YELLOW}Restarting vLLM...${NC}"
        docker-compose restart vllm
        echo -e "${GREEN}✓ Maximum GPU memory now available for other tasks${NC}"
        ;;
        
    status)
        echo -e "${YELLOW}Current GPU Status:${NC}"
        echo ""
        nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv
        echo ""
        echo -e "${YELLOW}Current vLLM GPU allocation:${NC}"
        grep "GPU_MEMORY_UTIL" .env || echo "GPU_MEMORY_UTIL=0.95 (default)"
        ;;
        
    *)
        show_usage
        exit 1
        ;;
esac