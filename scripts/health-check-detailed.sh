#!/bin/bash

# Enhanced health check with performance metrics
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}UC-1 Pro Health Check - $(date)${NC}"
echo "============================================"

# Function to check service health
check_service() {
    local name=$1
    local url=$2
    local start_time=$(date +%s.%N)
    
    if curl -f -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|204"; then
        local end_time=$(date +%s.%N)
        local response_time=$(echo "$end_time - $start_time" | bc)
        echo -e "✅ ${GREEN}$name${NC} - Response time: ${response_time}s"
    else
        echo -e "❌ ${RED}$name${NC} - Not responding"
    fi
}

# GPU Status
echo -e "\n${YELLOW}GPU Status:${NC}"
nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu,temperature.gpu --format=csv,noheader | while read line; do
    echo "  🎮 $line"
done

# Memory Status
echo -e "\n${YELLOW}System Memory:${NC}"
free -h | grep Mem | awk '{print "  💾 Used: "$3" / "$2" ("$3/$2*100"%)"}'

# Service Health Checks
echo -e "\n${YELLOW}Service Health:${NC}"
check_service "vLLM API" "http://localhost:8000/health"
check_service "Open-WebUI" "http://localhost:8080"
check_service "WhisperX" "http://localhost:9000/health"
check_service "Kokoro TTS" "http://localhost:8880/health"
check_service "Model Manager" "http://localhost:8084/health"
check_service "Embeddings" "http://localhost:8082/health"
check_service "Reranker" "http://localhost:8083/health"

# Database Status
echo -e "\n${YELLOW}Database Status:${NC}"
docker exec unicorn-redis redis-cli ping > /dev/null 2>&1 && echo -e "✅ ${GREEN}Redis${NC}" || echo -e "❌ ${RED}Redis${NC}"
docker exec unicorn-postgresql pg_isready > /dev/null 2>&1 && echo -e "✅ ${GREEN}PostgreSQL${NC}" || echo -e "❌ ${RED}PostgreSQL${NC}"
curl -s http://localhost:6333/readyz > /dev/null 2>&1 && echo -e "✅ ${GREEN}Qdrant${NC}" || echo -e "❌ ${RED}Qdrant${NC}"

# Docker Resource Usage
echo -e "\n${YELLOW}Container Resources:${NC}"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep unicorn

echo -e "\n${BLUE}Health check complete!${NC}"