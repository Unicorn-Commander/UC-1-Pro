#!/bin/bash
echo "Checking UC-1 Pro services health..."
echo ""

# Function to check service
check_service() {
    local name=$1
    local url=$2
    
    if curl -s -f "$url" > /dev/null 2>&1; then
        echo -e "✓ $name: \033[0;32mHealthy\033[0m"
    else
        echo -e "✗ $name: \033[0;31mUnhealthy\033[0m"
    fi
}

# Check each service
check_service "vLLM API" "http://localhost:8000/health"
check_service "Open-WebUI" "http://localhost:8080"
check_service "Model Manager" "http://localhost:8084/health"
check_service "Embeddings" "http://localhost:8082/health"
check_service "WhisperX STT" "http://localhost:9000/health"
check_service "Kokoro TTS" "http://localhost:8880/health"
check_service "Reranker" "http://localhost:8083/health"
check_service "SearXNG" "http://localhost:8888"
check_service "Qdrant" "http://localhost:6333/health"
