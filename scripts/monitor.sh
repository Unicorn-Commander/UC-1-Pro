#!/bin/bash
while true; do
    clear
    echo "=== UC-1 Pro System Monitor ==="
    echo "$(date)"
    echo ""
    
    # Container Status
    echo "Container Status:"
    docker ps --format "table {{.Names}}\t{{.Status}}" | grep unicorn | head -10
    
    echo ""
    echo "Press Ctrl+C to exit"
    sleep 5
done
