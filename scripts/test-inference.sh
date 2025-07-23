#!/bin/bash
echo "Testing vLLM inference..."

curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${VLLM_API_KEY:-dummy-key}" \
  -d '{
    "model": "'"${DEFAULT_LLM_MODEL:-Qwen/Qwen2.5-32B-Instruct-AWQ}"'",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Write a haiku about GPUs."}
    ],
    "temperature": 0.7,
    "max_tokens": 100
  }' | python3 -m json.tool
