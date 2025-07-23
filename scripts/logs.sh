#!/bin/bash
if [ "$1" ]; then
    docker-compose logs -f "$1"
else
    echo "Available services:"
    docker-compose ps --services | sort
    echo ""
    echo "Usage: ./logs.sh [service_name]"
    echo "Example: ./logs.sh vllm"
fi
