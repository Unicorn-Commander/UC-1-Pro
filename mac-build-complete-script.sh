#!/bin/bash
# build-uc1-pro-mac.sh - Complete UC-1 Pro structure builder for Mac
# Run this on your Mac Studio to create the entire project structure

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          UC-1 Pro Complete Structure Builder           ║${NC}"
echo -e "${BLUE}║                   For Mac Studio                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Create root directory
echo -e "${GREEN}Creating UC-1 Pro directory structure...${NC}"
mkdir -p UC-1-Pro
cd UC-1-Pro

# Create all directories
echo "Creating directories..."
mkdir -p services/{model-manager,whisperx,kokoro-tts,reranker,tika-ocr,searxng}
mkdir -p scripts
mkdir -p config/prometheus
mkdir -p Drivers/BIOS

# ========================================
# Create main docker-compose.yml
# ========================================
echo -e "${YELLOW}Creating docker-compose.yml...${NC}"
cat > docker-compose.yml << 'EOF'
version: '3.8'

# Shared GPU runtime configuration
x-gpu-service: &gpu-service
  runtime: nvidia
  environment:
    - NVIDIA_DRIVER_CAPABILITIES=all
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: 1
            capabilities: [gpu]

services:
  # --- Database Services ---
  redis:
    image: redis:7-alpine
    container_name: unicorn-redis
    restart: unless-stopped
    command: >
      redis-server
      --maxmemory 16gb
      --maxmemory-policy allkeys-lru
      --client-output-buffer-limit pubsub 512mb 256mb 360
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    networks:
      unicorn-network:
        aliases:
          - redis
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  postgresql:
    image: postgres:16-alpine
    container_name: unicorn-postgresql
    restart: unless-stopped
    environment:
      POSTGRES_USER: "${POSTGRES_USER}"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      POSTGRES_DB: "${POSTGRES_DB}"
      POSTGRES_INITDB_ARGS: "--encoding=UTF8 --locale=en_US.UTF-8"
      POSTGRES_HOST_AUTH_METHOD: "scram-sha-256"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    networks:
      unicorn-network:
        aliases:
          - postgres
          - postgresql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # --- Vector Database Service ---
  qdrant:
    image: qdrant/qdrant:latest
    container_name: unicorn-qdrant
    restart: unless-stopped
    volumes:
      - qdrant_data:/qdrant/storage
    ports:
      - "6333:6333"
      - "6334:6334"
    networks:
      unicorn-network:
        aliases:
          - qdrant
          - vectordb
    environment:
      QDRANT__SERVICE__GRPC_PORT: "6334"
      QDRANT__SERVICE__HTTP_PORT: "6333"
      QDRANT__LOG_LEVEL: "INFO"

  # --- Main AI/LLM Service (RTX 5090) ---
  vllm:
    image: vllm/vllm-openai:latest
    container_name: unicorn-vllm
    restart: unless-stopped
    <<: *gpu-service
    ports:
      - "8000:8000"
    environment:
      NVIDIA_VISIBLE_DEVICES: "0"
      VLLM_API_KEY: "${VLLM_API_KEY:-dummy-key}"
      HF_TOKEN: "${HF_TOKEN:-}"
      CUDA_VISIBLE_DEVICES: "0"
    command: >
      --model ${DEFAULT_LLM_MODEL:-Qwen/Qwen2.5-32B-Instruct-AWQ}
      --quantization ${LLM_QUANTIZATION:-awq}
      --max-model-len ${MAX_MODEL_LEN:-16384}
      --gpu-memory-utilization ${GPU_MEMORY_UTIL:-0.95}
      --enable-prefix-caching
      --download-dir /models
      --tensor-parallel-size ${TENSOR_PARALLEL:-1}
      --disable-log-requests
      --trust-remote-code
    volumes:
      - vllm_models:/models
      - vllm_cache:/root/.cache/huggingface
    networks:
      unicorn-network:
        aliases:
          - vllm
          - llm
          - inference
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    shm_size: '8gb'
    ulimits:
      memlock: -1
      stack: 67108864

  # --- Embedding Service (Intel iGPU/CPU) ---
  embeddings:
    image: ghcr.io/huggingface/text-embeddings-inference:cpu-1.2
    container_name: unicorn-embeddings
    restart: unless-stopped
    ports:
      - "8082:80"
    environment:
      MODEL_ID: "${EMBEDDING_MODEL:-BAAI/bge-base-en-v1.5}"
      MAX_BATCH_TOKENS: "16384"
      MAX_CLIENT_BATCH_SIZE: "32"
    volumes:
      - embedding_models:/data
    networks:
      unicorn-network:
        aliases:
          - embeddings
          - embed

  # --- Speech-to-Text Service: WhisperX ---
  whisperx:
    build: ./services/whisperx
    container_name: unicorn-whisperx
    restart: unless-stopped
    ports:
      - "9000:9000"
    environment:
      WHISPER_MODEL: "${WHISPER_MODEL:-base}"
      DEVICE: "cpu"
      COMPUTE_TYPE: "int8"
      BATCH_SIZE: "16"
      HF_TOKEN: "${HF_TOKEN:-}"
    volumes:
      - whisperx_models:/app/models
    networks:
      unicorn-network:
        aliases:
          - whisperx
          - stt
          - speech

  # --- Text-to-Speech Service: Kokoro (Intel iGPU via OpenVINO) ---
  kokoro-tts:
    build: ./services/kokoro-tts
    container_name: unicorn-kokoro
    restart: unless-stopped
    devices:
      - /dev/dri:/dev/dri
    group_add:
      - video
      - render
    ports:
      - "8880:8880"
    environment:
      DEVICE: "GPU"
      DEFAULT_VOICE: "${KOKORO_VOICE:-af}"
    volumes:
      - kokoro_models:/app/models
    networks:
      unicorn-network:
        aliases:
          - kokoro
          - tts

  # --- Reranking Service (CPU) ---
  reranker:
    build: ./services/reranker
    container_name: unicorn-reranker
    restart: unless-stopped
    ports:
      - "8083:8080"
    environment:
      MODEL_NAME: "${RERANKER_MODEL:-BAAI/bge-reranker-v2-m3}"
      DEVICE: "cpu"
      MAX_LENGTH: "512"
    volumes:
      - reranker_models:/app/models
    networks:
      unicorn-network:
        aliases:
          - reranker
          - rerank

  # --- Web UI ---
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: unicorn-open-webui
    restart: unless-stopped
    volumes:
      - open_webui_data:/app/backend/data
    ports:
      - "8080:8080"
    environment:
      OPENAI_API_BASE_URLS: "http://unicorn-vllm:8000/v1"
      OPENAI_API_KEYS: "${VLLM_API_KEY:-dummy-key}"
      DATABASE_URL: "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@unicorn-postgresql:5432/${POSTGRES_DB}"
      WEBUI_SECRET_KEY: "${WEBUI_SECRET_KEY}"
      VECTOR_DB: "qdrant"
      QDRANT_URI: "http://unicorn-qdrant:6333"
      QDRANT_API_KEY: "${QDRANT_API_KEY:-}"
      REDIS_URL: "redis://unicorn-redis:6379/0"
      ENABLE_WEBSOCKET_SUPPORT: "true"
      WEBSOCKET_MANAGER: "redis"
      WEBSOCKET_REDIS_URL: "redis://unicorn-redis:6379/1"
      RAG_EMBEDDING_API_BASE_URL: "http://unicorn-embeddings"
      RAG_EMBEDDING_MODEL: "${EMBEDDING_MODEL:-BAAI/bge-base-en-v1.5}"
      RAG_RERANKING_MODEL_API_BASE_URL: "http://unicorn-reranker:8080"
      ENABLE_TIKA_EXTRACTION: "true"
      TIKA_BASE_URL: "http://unicorn-tika:9998"
      ENABLE_TTS: "true"
      TTS_PROVIDER: "custom"
      TTS_API_URL: "http://unicorn-kokoro:8880"
      TTS_API_KEY: ""
      ENABLE_STT: "true" 
      STT_PROVIDER: "custom"
      STT_API_URL: "http://unicorn-whisperx:9000"
      SEARCH_ENGINE: "searxng"
      SEARXNG_URL: "http://unicorn-searxng:8080"
      ENABLE_MODEL_FILTER: "false"
      MODEL_FILTER_LIST: ""
      ENABLE_OLLAMA_API: "false"
    networks:
      unicorn-network:
        aliases:
          - webui
          - openwebui
    depends_on:
      - postgresql
      - redis
      - qdrant
      - vllm

  # --- Document Intelligence: Tika OCR Service ---
  unicorn-tika:
    build: ./services/tika-ocr
    container_name: unicorn-tika
    restart: unless-stopped
    ports:
      - "9998:9998"
    environment:
      TESSDATA_PREFIX: "/usr/share/tesseract-ocr/5/tessdata"
      TIKA_OCR_STRATEGY: "ocr_and_text"
      TIKA_OCR_LANGUAGE: "eng+fra+deu+spa"
    volumes:
      - tika_data:/tmp/tika
    networks:
      unicorn-network:
        aliases:
          - tika
          - ocr

  # --- Self-hosted Search: SearXNG ---
  unicorn-searxng:
    build: ./services/searxng
    container_name: unicorn-searxng
    restart: unless-stopped
    volumes:
      - ./services/searxng:/etc/searxng:rw
    ports:
      - "8888:8080"
    networks:
      unicorn-network:
        aliases:
          - searxng
          - search
    environment:
      - BIND_ADDRESS=0.0.0.0:8080
      - INSTANCE_NAME=UnicornCommander
      - SEARXNG_BASE_URL=http://localhost:8888/
      - UWSGI_WORKERS=4
      - UWSGI_THREADS=2
      - SEARXNG_SECRET=${SEARXNG_SECRET}
      - SEARXNG_REDIS_URL=redis://unicorn-redis:6379/2
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETGID
      - SETUID
    depends_on:
      - redis

  # --- GPU Monitoring ---
  gpu-exporter:
    image: utkuozdemir/nvidia_gpu_exporter:1.2.0
    container_name: unicorn-gpu-exporter
    restart: unless-stopped
    runtime: nvidia
    environment:
      NVIDIA_VISIBLE_DEVICES: all
    ports:
      - "9835:9835"
    networks:
      unicorn-network:
        aliases:
          - gpu-metrics

  # --- Model Manager API ---
  model-manager:
    build: ./services/model-manager
    container_name: unicorn-model-manager
    restart: unless-stopped
    ports:
      - "8084:8080"
    environment:
      VLLM_URL: "http://unicorn-vllm:8000"
      VLLM_API_KEY: "${VLLM_API_KEY:-dummy-key}"
    networks:
      unicorn-network:
        aliases:
          - models
          - model-manager

  # --- System Monitoring (Optional) ---
  prometheus:
    image: prom/prometheus:latest
    container_name: unicorn-prometheus
    restart: unless-stopped
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
    volumes:
      - ./config/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    networks:
      unicorn-network:
        aliases:
          - prometheus
          - metrics

networks:
  unicorn-network:
    driver: bridge
    name: unicorn-network
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16

volumes:
  redis_data:
  postgres_data:
  qdrant_data:
  vllm_models:
  vllm_cache:
  embedding_models:
  whisperx_models:
  kokoro_models:
  reranker_models:
  open_webui_data:
  tika_data:
  prometheus_data:
EOF

# ========================================
# Create .env.template
# ========================================
echo -e "${YELLOW}Creating .env.template...${NC}"
cat > .env.template << 'EOF'
# UC-1 Pro Environment Configuration

# --- Database Configuration ---
POSTGRES_USER=unicorn
POSTGRES_PASSWORD=your_secure_password_here
POSTGRES_DB=unicorn_db

# --- Security Keys ---
WEBUI_SECRET_KEY=your_secret_key_here
VLLM_API_KEY=your_vllm_api_key_here
QDRANT_API_KEY=
SEARXNG_SECRET=your_searxng_secret_here

# --- Model Configuration ---
# Main LLM Model (vLLM on RTX 5090)
# Option 1: Qwen2.5 32B (Recommended - Great performance)
DEFAULT_LLM_MODEL=Qwen/Qwen2.5-32B-Instruct-AWQ
LLM_QUANTIZATION=awq

# Option 2: Gemma 2 27B (Requires AWQ/GPTQ version)
# DEFAULT_LLM_MODEL=casperhansen/gemma-2-27b-it-awq
# LLM_QUANTIZATION=awq

# Option 3: Llama 3.1 70B (Larger but excellent)
# DEFAULT_LLM_MODEL=meta-llama/Llama-3.1-70B-Instruct-AWQ
# LLM_QUANTIZATION=awq

# Model Parameters
MAX_MODEL_LEN=16384
GPU_MEMORY_UTIL=0.95
TENSOR_PARALLEL=1

# Embedding Model (CPU/iGPU)
EMBEDDING_MODEL=BAAI/bge-base-en-v1.5

# Speech Models
WHISPER_MODEL=base
KOKORO_VOICE=af
TTS_MODEL=kokoro-v0_19

# Reranking Model
RERANKER_MODEL=BAAI/bge-reranker-v2-m3

# --- Hugging Face Token (for gated models like Llama) ---
HF_TOKEN=

# --- Performance Tuning ---
# Redis Memory (adjust based on your RAM)
REDIS_MAX_MEMORY=16gb

# --- Optional: BrightData Proxy for SearXNG ---
USE_ROTATING_PROXY=false
BRIGHTDATA_USERNAME=
BRIGHTDATA_PASSWORD=
BRIGHTDATA_GATEWAY=
BRIGHTDATA_PORT=

# --- WebSocket Configuration ---
ENABLE_WEBSOCKET_SUPPORT=true

# --- Model Download Locations ---
MODEL_CACHE_DIR=/models
EOF

# ========================================
# Create Model Manager Service
# ========================================
echo -e "${YELLOW}Creating Model Manager service...${NC}"

# Dockerfile
cat > services/model-manager/Dockerfile << 'EOF'
FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8080

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8080"]
EOF

# requirements.txt
cat > services/model-manager/requirements.txt << 'EOF'
fastapi==0.110.0
uvicorn==0.27.1
httpx==0.26.0
pydantic==2.6.1
EOF

# docker-compose.yml
cat > services/model-manager/docker-compose.yml << 'EOF'
version: '3.8'

services:
  model-manager:
    build: .
    container_name: model-manager-dev
    ports:
      - "8084:8080"
    environment:
      VLLM_URL: "http://localhost:8000"
      VLLM_API_KEY: "test-key"
EOF

# server.py
cat > services/model-manager/server.py << 'EOF'
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
import httpx
import os
from typing import List, Dict

app = FastAPI(title="UC-1 Pro Model Manager")

VLLM_URL = os.environ.get("VLLM_URL", "http://unicorn-vllm:8000")
VLLM_API_KEY = os.environ.get("VLLM_API_KEY", "dummy-key")

# Available models configuration
AVAILABLE_MODELS = [
    {
        "id": "Qwen/Qwen2.5-32B-Instruct-AWQ",
        "name": "Qwen 2.5 32B",
        "quantization": "awq",
        "description": "Excellent all-around model, great for coding and reasoning"
    },
    {
        "id": "casperhansen/gemma-2-27b-it-awq",
        "name": "Gemma 2 27B",
        "quantization": "awq", 
        "description": "Google's latest model, strong performance"
    },
    {
        "id": "meta-llama/Llama-3.1-70B-Instruct-AWQ",
        "name": "Llama 3.1 70B",
        "quantization": "awq",
        "description": "Meta's flagship model, excellent quality but larger"
    },
    {
        "id": "mistralai/Mistral-7B-Instruct-v0.3",
        "name": "Mistral 7B",
        "quantization": "none",
        "description": "Small, fast model for simple tasks"
    }
]

class ModelSwitch(BaseModel):
    model_id: str
    quantization: str = "awq"

@app.get("/")
async def root():
    """Simple web interface"""
    html = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>UC-1 Pro Model Manager</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
            .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            .model-card { border: 1px solid #ddd; padding: 20px; margin: 15px 0; border-radius: 8px; transition: all 0.3s; }
            .model-card:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
            .current { background-color: #e8f5e9; border-color: #4caf50; }
            button { padding: 10px 20px; margin: 5px; cursor: pointer; border: none; border-radius: 5px; background: #2196f3; color: white; transition: background 0.3s; }
            button:hover { background: #1976d2; }
            .status { margin: 20px 0; padding: 20px; background: #f5f5f5; border-radius: 8px; }
            .loading { color: #ff9800; }
            .ready { color: #4caf50; }
            .error { color: #f44336; }
            h1 { color: #333; }
            h3 { color: #666; margin-top: 30px; }
            .model-id { font-family: monospace; font-size: 0.9em; color: #666; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>UC-1 Pro Model Manager</h1>
            <div class="status">
                <h3>Current Status</h3>
                <div id="status">Loading...</div>
            </div>
            <h3>Available Models</h3>
            <div id="models"></div>
        </div>
        
        <script>
            async function checkStatus() {
                try {
                    const response = await fetch('/api/status');
                    const data = await response.json();
                    const statusClass = data.ready ? 'ready' : 'loading';
                    document.getElementById('status').innerHTML = `
                        <strong>Model:</strong> ${data.current_model || 'None loaded'}<br>
                        <strong>Status:</strong> <span class="${statusClass}">${data.ready ? 'Ready' : 'Not ready'}</span>
                    `;
                } catch (e) {
                    document.getElementById('status').innerHTML = '<span class="error">Error checking status</span>';
                }
            }
            
            async function loadModels() {
                const response = await fetch('/api/models');
                const models = await response.json();
                
                const html = models.map(model => `
                    <div class="model-card">
                        <h4>${model.name}</h4>
                        <p>${model.description}</p>
                        <p class="model-id">ID: ${model.id}</p>
                        <button onclick="switchModel('${model.id}', '${model.quantization}')">
                            Load This Model
                        </button>
                    </div>
                `).join('');
                
                document.getElementById('models').innerHTML = html;
            }
            
            async function switchModel(modelId, quantization) {
                if (!confirm(`Switch to ${modelId}?\\n\\nNote: This requires restarting the vLLM container.`)) {
                    return;
                }
                
                const response = await fetch('/api/switch', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({model_id: modelId, quantization: quantization})
                });
                
                const result = await response.json();
                alert(result.message);
                checkStatus();
            }
            
            // Initial load
            checkStatus();
            loadModels();
            
            // Refresh status every 10 seconds
            setInterval(checkStatus, 10000);
        </script>
    </body>
    </html>
    """
    return HTMLResponse(content=html)

@app.get("/api/models")
async def list_available_models():
    """List available models"""
    return AVAILABLE_MODELS

@app.get("/api/status")
async def get_status():
    """Get current model status"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{VLLM_URL}/v1/models",
                headers={"Authorization": f"Bearer {VLLM_API_KEY}"}
            )
            if response.status_code == 200:
                data = response.json()
                current_model = data['data'][0]['id'] if data['data'] else None
                return {
                    "current_model": current_model,
                    "ready": True
                }
    except:
        pass
    
    return {"current_model": None, "ready": False}

@app.post("/api/switch")
async def switch_model(request: ModelSwitch):
    """Switch to a different model"""
    return {
        "status": "manual_action_required",
        "message": f"To switch to {request.model_id}, run:\n\n" +
                  f"docker-compose exec vllm pkill -f 'vllm.entrypoints.openai.api_server'\n" +
                  f"Then update DEFAULT_LLM_MODEL in .env and run: docker-compose restart vllm",
        "model": request.model_id,
        "quantization": request.quantization
    }

@app.get("/health")
async def health():
    return {"status": "healthy"}
EOF

# README.md
cat > services/model-manager/README.md << 'EOF'
# Model Manager Service

Web UI for managing vLLM models in UC-1 Pro.

## Features
- View currently loaded model
- Switch between pre-configured models
- Simple web interface

## API Endpoints
- `GET /` - Web UI
- `GET /api/models` - List available models
- `GET /api/status` - Current model status
- `POST /api/switch` - Switch model (returns instructions)
- `GET /health` - Health check

## Testing Standalone
```bash
cd services/model-manager
docker-compose up
# Visit http://localhost:8084
```

## Environment Variables
- `VLLM_URL` - vLLM API endpoint
- `VLLM_API_KEY` - API key for vLLM
EOF

# ========================================
# Create WhisperX Service
# ========================================
echo -e "${YELLOW}Creating WhisperX service...${NC}"

# Dockerfile
cat > services/whisperx/Dockerfile << 'EOF'
FROM python:3.10-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install WhisperX and dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 9000

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "9000"]
EOF

# requirements.txt
cat > services/whisperx/requirements.txt << 'EOF'
git+https://github.com/m-bain/whisperx.git
fastapi==0.110.0
uvicorn==0.27.1
python-multipart==0.0.9
torch==2.1.2
torchaudio==2.1.2
EOF

# docker-compose.yml
cat > services/whisperx/docker-compose.yml << 'EOF'
version: '3.8'

services:
  whisperx:
    build: .
    container_name: whisperx-dev
    ports:
      - "9000:9000"
    environment:
      WHISPER_MODEL: "base"
      DEVICE: "cpu"
      COMPUTE_TYPE: "int8"
    volumes:
      - ./models:/app/models
EOF

# server.py
cat > services/whisperx/server.py << 'EOF'
from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import JSONResponse
import whisperx
import os
import tempfile
import torch
import gc
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="WhisperX STT Service")

# Model configuration
MODEL_SIZE = os.environ.get("WHISPER_MODEL", "base")
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
COMPUTE_TYPE = os.environ.get("COMPUTE_TYPE", "float16" if DEVICE == "cuda" else "int8")
BATCH_SIZE = int(os.environ.get("BATCH_SIZE", "16"))
HF_TOKEN = os.environ.get("HF_TOKEN", "")

# Load model once at startup
logger.info(f"Loading WhisperX model: {MODEL_SIZE} on {DEVICE}")
model = whisperx.load_model(MODEL_SIZE, DEVICE, compute_type=COMPUTE_TYPE)

# Load alignment model for English
logger.info("Loading alignment model...")
model_a, metadata = whisperx.load_align_model(language_code="en", device=DEVICE)

@app.post("/v1/audio/transcriptions")
async def transcribe(
    file: UploadFile = File(...),
    diarize: bool = Form(False),
    min_speakers: int = Form(None),
    max_speakers: int = Form(None)
):
    """Transcribe audio file with optional speaker diarization"""
    
    # Save uploaded file
    with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
        content = await file.read()
        tmp.write(content)
        tmp_path = tmp.name
    
    try:
        logger.info(f"Processing audio file: {file.filename}")
        
        # Load audio
        audio = whisperx.load_audio(tmp_path)
        
        # Transcribe with WhisperX
        logger.info("Transcribing...")
        result = model.transcribe(audio, batch_size=BATCH_SIZE)
        
        # Align whisper output
        logger.info("Aligning...")
        result = whisperx.align(result["segments"], model_a, metadata, audio, DEVICE)
        
        # Optional: Speaker diarization
        if diarize and HF_TOKEN:
            logger.info("Performing speaker diarization...")
            diarize_model = whisperx.DiarizationPipeline(use_auth_token=HF_TOKEN, device=DEVICE)
            diarize_segments = diarize_model(audio, min_speakers=min_speakers, max_speakers=max_speakers)
            result = whisperx.assign_word_speakers(diarize_segments, result)
        
        # Format response
        text = " ".join([segment["text"] for segment in result["segments"]])
        
        return {
            "text": text,
            "segments": result["segments"],
            "language": result.get("language", "en"),
            "words": result.get("word_segments", [])
        }
        
    except Exception as e:
        logger.error(f"Error processing audio: {str(e)}")
        raise
        
    finally:
        os.unlink(tmp_path)
        gc.collect()

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "model": MODEL_SIZE,
        "device": DEVICE,
        "compute_type": COMPUTE_TYPE
    }

@app.get("/")
async def root():
    return {
        "service": "WhisperX STT",
        "version": "1.0",
        "endpoints": {
            "/v1/audio/transcriptions": "POST - Transcribe audio",
            "/health": "GET - Health check"
        }
    }
EOF

# README.md
cat > services/whisperx/README.md << 'EOF'
# WhisperX Speech-to-Text Service

Advanced speech recognition with word-level timestamps and speaker diarization.

## Features
- High-accuracy transcription using Whisper
- Word-level timestamps
- Speaker diarization (requires HF_TOKEN)
- Batch processing for efficiency

## API Endpoints
- `POST /v1/audio/transcriptions` - Transcribe audio file
- `GET /health` - Service health check

## Environment Variables
- `WHISPER_MODEL` - Model size (tiny, base, small, medium, large)
- `DEVICE` - Computing device (cpu, cuda)
- `COMPUTE_TYPE` - Computation type (int8, float16)
- `BATCH_SIZE` - Batch size for processing
- `HF_TOKEN` - Hugging Face token for diarization models

## Testing Standalone
```bash
cd services/whisperx
docker-compose up

# Test with curl
curl -X POST http://localhost:9000/v1/audio/transcriptions \
  -F "file=@test.wav" \
  -F "diarize=false"
```
EOF

# ========================================
# Create Kokoro TTS Service
# ========================================
echo -e "${YELLOW}Creating Kokoro TTS service...${NC}"

# Dockerfile
cat > services/kokoro-tts/Dockerfile << 'EOF'
FROM python:3.10-slim

RUN apt-get update && apt-get install -y \
    git \
    wget \
    libgomp1 \
    libtbb12 \
    ocl-icd-libopencl1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Download Kokoro models
RUN mkdir -p models && cd models && \
    wget -q https://github.com/thewh1teagle/kokoro-fastapi/releases/download/v0.1.0/kokoro-v0_19.onnx && \
    wget -q https://github.com/thewh1teagle/kokoro-fastapi/releases/download/v0.1.0/voices.json

COPY . .

EXPOSE 8880

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8880"]
EOF

# requirements.txt
cat > services/kokoro-tts/requirements.txt << 'EOF'
fastapi==0.110.0
uvicorn==0.27.1
onnxruntime==1.17.0
numpy==1.24.3
scipy==1.11.4
soundfile==0.12.1
EOF

# docker-compose.yml
cat > services/kokoro-tts/docker-compose.yml << 'EOF'
version: '3.8'

services:
  kokoro-tts:
    build: .
    container_name: kokoro-dev
    ports:
      - "8880:8880"
    environment:
      DEVICE: "CPU"
      DEFAULT_VOICE: "af"
EOF

# server.py
cat > services/kokoro-tts/server.py << 'EOF'
from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
import onnxruntime as ort
import numpy as np
import io
import json
import soundfile as sf
from typing import Optional
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Kokoro TTS Service")

# Load voices configuration
with open("models/voices.json", "r") as f:
    voices = json.load(f)

# Initialize ONNX Runtime
logger.info("Loading Kokoro model...")
session = ort.InferenceSession("models/kokoro-v0_19.onnx")

class TTSRequest(BaseModel):
    text: str
    voice: Optional[str] = "af"
    speed: Optional[float] = 1.0
    stream: Optional[bool] = False

def text_to_phonemes(text: str):
    """Simple text to phoneme conversion - in production use a proper phonemizer"""
    # This is a placeholder - real implementation would use a phonemizer
    return text.lower()

def synthesize_speech(text: str, voice: str = "af", speed: float = 1.0):
    """Synthesize speech using Kokoro model"""
    # Prepare input
    phonemes = text_to_phonemes(text)
    
    # Create input arrays (simplified - real implementation needs proper preprocessing)
    phoneme_ids = np.array([[ord(c) for c in phonemes]], dtype=np.int64)
    
    # Run inference
    inputs = {
        session.get_inputs()[0].name: phoneme_ids
    }
    
    outputs = session.run(None, inputs)
    audio = outputs[0]
    
    # Apply speed adjustment
    if speed != 1.0:
        # Simple speed adjustment - production would use proper resampling
        indices = np.arange(0, len(audio[0]), speed)
        audio = np.interp(indices, np.arange(len(audio[0])), audio[0])
    else:
        audio = audio[0]
    
    # Normalize audio
    audio = np.clip(audio, -1, 1)
    
    return audio

@app.post("/v1/audio/speech")
async def text_to_speech(request: TTSRequest):
    try:
        logger.info(f"Synthesizing speech for text: {request.text[:50]}...")
        
        # Synthesize speech
        audio_data = synthesize_speech(
            request.text,
            request.voice,
            request.speed
        )
        
        # Convert to WAV format
        audio_bytes = io.BytesIO()
        sf.write(audio_bytes, audio_data, 24000, format='WAV')
        audio_bytes.seek(0)
        
        return StreamingResponse(
            audio_bytes,
            media_type="audio/wav",
            headers={"Content-Disposition": "inline; filename=speech.wav"}
        )
        
    except Exception as e:
        logger.error(f"Error in TTS: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/voices")
async def list_voices():
    return {"voices": list(voices.keys())}

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "model": "kokoro-v0_19",
        "backend": "ONNX Runtime"
    }

@app.get("/")
async def root():
    return {
        "service": "Kokoro TTS",
        "version": "1.0",
        "endpoints": {
            "/v1/audio/speech": "POST - Generate speech from text",
            "/voices": "GET - List available voices",
            "/health": "GET - Health check"
        }
    }
EOF

# README.md
cat > services/kokoro-tts/README.md << 'EOF'
# Kokoro Text-to-Speech Service

Natural text-to-speech synthesis using Kokoro models.

## Features
- Multiple voice options
- Speed control
- Low latency synthesis
- ONNX Runtime backend

## API Endpoints
- `POST /v1/audio/speech` - Generate speech from text
- `GET /voices` - List available voices
- `GET /health` - Service health check

## Environment Variables
- `DEVICE` - Computing device (CPU, GPU)
- `DEFAULT_VOICE` - Default voice to use

## Testing Standalone
```bash
cd services/kokoro-tts
docker-compose up

# Test with curl
curl -X POST http://localhost:8880/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello world", "voice": "af"}'
```
EOF

# ========================================
# Create Reranker Service
# ========================================
echo -e "${YELLOW}Creating Reranker service...${NC}"

# Dockerfile
cat > services/reranker/Dockerfile << 'EOF'
FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8080

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8080"]
EOF

# requirements.txt
cat > services/reranker/requirements.txt << 'EOF'
torch==2.1.2 --index-url https://download.pytorch.org/whl/cpu
transformers==4.37.2
sentence-transformers==2.3.1
fastapi==0.110.0
uvicorn==0.27.1
pydantic==2.6.1
EOF

# docker-compose.yml
cat > services/reranker/docker-compose.yml << 'EOF'
version: '3.8'

services:
  reranker:
    build: .
    container_name: reranker-dev
    ports:
      - "8083:8080"
    environment:
      MODEL_NAME: "BAAI/bge-reranker-v2-m3"
      DEVICE: "cpu"
EOF

# server.py
cat > services/reranker/server.py << 'EOF'
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sentence_transformers import CrossEncoder
import os
from typing import List
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Reranker Service")

# Load model
MODEL_NAME = os.environ.get("MODEL_NAME", "BAAI/bge-reranker-v2-m3")
MAX_LENGTH = int(os.environ.get("MAX_LENGTH", "512"))

logger.info(f"Loading reranker model: {MODEL_NAME}")
model = CrossEncoder(MODEL_NAME, max_length=MAX_LENGTH)
logger.info("Model loaded successfully")

class RerankRequest(BaseModel):
    query: str
    documents: List[str]
    top_k: int = 10

class RerankResponse(BaseModel):
    results: List[dict]

@app.post("/rerank", response_model=RerankResponse)
async def rerank(request: RerankRequest):
    """Rerank documents based on relevance to query"""
    try:
        logger.info(f"Reranking {len(request.documents)} documents")
        
        # Prepare pairs for scoring
        pairs = [[request.query, doc] for doc in request.documents]
        
        # Get scores
        scores = model.predict(pairs)
        
        # Sort by score
        scored_docs = list(zip(request.documents, scores))
        scored_docs.sort(key=lambda x: x[1], reverse=True)
        
        # Return top_k results
        results = [
            {"document": doc, "score": float(score), "index": i}
            for i, (doc, score) in enumerate(scored_docs[:request.top_k])
        ]
        
        logger.info(f"Reranking complete. Top score: {results[0]['score'] if results else 0}")
        
        return RerankResponse(results=results)
        
    except Exception as e:
        logger.error(f"Error in reranking: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health():
    return {"status": "healthy", "model": MODEL_NAME}

@app.get("/")
async def root():
    return {
        "service": "Reranker",
        "version": "1.0",
        "model": MODEL_NAME,
        "endpoints": {
            "/rerank": "POST - Rerank documents",
            "/health": "GET - Health check"
        }
    }
EOF

# README.md
cat > services/reranker/README.md << 'EOF'
# Reranker Service

Document reranking service using cross-encoder models for improved search relevance.

## Features
- Cross-encoder based reranking
- Configurable models
- Batch processing support
- RESTful API

## API Endpoints
- `POST /rerank` - Rerank documents based on query
- `GET /health` - Service health check

## Environment Variables
- `MODEL_NAME` - Reranker model to use (default: BAAI/bge-reranker-v2-m3)
- `DEVICE` - Computing device (cpu, cuda)
- `MAX_LENGTH` - Maximum sequence length

## Testing Standalone
```bash
cd services/reranker
docker-compose up

# Test with curl
curl -X POST http://localhost:8083/rerank \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is machine learning?",
    "documents": ["ML is...", "Cooking is...", "AI involves..."],
    "top_k": 2
  }'
```
EOF

# ========================================
# Create placeholder directories for tika and searxng
# ========================================
echo -e "${YELLOW}Creating placeholder directories for tika-ocr and searxng...${NC}"

# Tika placeholder
cat > services/tika-ocr/README.md << 'EOF'
# Tika OCR Service

Copy this directory from your UC-1 project:
```bash
cp -r ../UC-1/tika-ocr/* ./
```

Or create a basic Dockerfile if starting fresh.
EOF

# SearXNG placeholder
cat > services/searxng/README.md << 'EOF'
# SearXNG Search Service

Copy this directory from your UC-1 project:
```bash
cp -r ../UC-1/searxng/* ./
```

Or create a basic configuration if starting fresh.
EOF

# ========================================
# Create Scripts
# ========================================
echo -e "${YELLOW}Creating scripts...${NC}"

# start.sh
cat > scripts/start.sh << 'EOF'
#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo -e "${GREEN}UC-1 Pro Deployment Script${NC}"
echo "================================"

# Check for .env file
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env from template...${NC}"
    cp .env.template .env
    echo -e "${RED}Please edit .env file to set passwords!${NC}"
    exit 1
fi

# Load environment variables
set -a
[ -f .env ] && . ./.env
set +a

echo -e "\n${GREEN}Starting UC-1 Pro stack...${NC}"

# Pull images first
echo "Pulling Docker images..."
docker-compose pull

# Build custom services
echo "Building custom services..."
docker-compose build

# Start the stack
echo "Starting services..."
docker-compose up -d

echo -e "\n${GREEN}UC-1 Pro stack is starting!${NC}"
echo ""
echo "Services will be available at:"
echo "  - Open-WebUI: http://localhost:8080"
echo "  - vLLM API: http://localhost:8000/docs"
echo "  - Model Manager: http://localhost:8084"
echo "  - SearXNG: http://localhost:8888"
echo "  - GPU Metrics: http://localhost:9835/metrics"
echo "  - Prometheus: http://localhost:9090"
echo ""
echo "First-time model download may take 10-30 minutes."
echo "Check logs with: docker-compose logs -f vllm"
EOF

# switch-model.sh
cat > scripts/switch-model.sh << 'EOF'
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
EOF

# monitor.sh
cat > scripts/monitor.sh << 'EOF'
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
EOF

# health-check.sh
cat > scripts/health-check.sh << 'EOF'
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
EOF

# logs.sh
cat > scripts/logs.sh << 'EOF'
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
EOF

# backup.sh
cat > scripts/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Creating backup in $BACKUP_DIR..."

# Backup configuration
cp .env "$BACKUP_DIR/"
cp docker-compose.yml "$BACKUP_DIR/"

echo "Backup completed in $BACKUP_DIR"
EOF

# test-inference.sh
cat > scripts/test-inference.sh << 'EOF'
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
EOF

# Make all scripts executable
chmod +x scripts/*.sh

# ========================================
# Create Prometheus config
# ========================================
echo -e "${YELLOW}Creating Prometheus configuration...${NC}"
cat > config/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'nvidia_gpu'
    static_configs:
      - targets: ['unicorn-gpu-exporter:9835']

  - job_name: 'vllm'
    static_configs:
      - targets: ['unicorn-vllm:8000']

  - job_name: 'postgres'
    static_configs:
      - targets: ['unicorn-postgresql:5432']

  - job_name: 'redis'
    static_configs:
      - targets: ['unicorn-redis:6379']
EOF

# ========================================
# Create Driver scripts
# ========================================
echo -e "${YELLOW}Creating driver installation scripts...${NC}"

# install-nvidia-driver.sh
cat > Drivers/install-nvidia-driver.sh << 'EOF'
#!/bin/bash
# install-nvidia-driver.sh - NVIDIA Driver 570.172.08 Installation Script for UC-1 Pro

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Driver configuration
DRIVER_VERSION="570.172.08"
DRIVER_URL="https://us.download.nvidia.com/XFree86/Linux-x86_64/${DRIVER_VERSION}/NVIDIA-Linux-x86_64-${DRIVER_VERSION}.run"
DRIVER_FILE="NVIDIA-Linux-x86_64-${DRIVER_VERSION}.run"

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        NVIDIA Driver ${DRIVER_VERSION} Installer             ║${NC}"
echo -e "${BLUE}║           For UC-1 Pro (RTX 5090)                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

echo -e "${YELLOW}Downloading NVIDIA driver ${DRIVER_VERSION}...${NC}"
wget -O "${DRIVER_FILE}" "${DRIVER_URL}"
chmod +x "${DRIVER_FILE}"

echo -e "${GREEN}Download complete!${NC}"
echo ""
echo "To install the driver, run:"
echo "  sudo ./${DRIVER_FILE}"
echo ""
echo "For silent installation, use:"
echo "  sudo ./${DRIVER_FILE} --silent --dkms"
EOF

# install-nvidia-container-toolkit.sh
cat > Drivers/install-nvidia-container-toolkit.sh << 'EOF'
#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Installing NVIDIA Container Toolkit...${NC}"

# Add the repository
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
    sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Update and install
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Configure Docker
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Test
echo -e "${YELLOW}Testing NVIDIA Container Toolkit...${NC}"
docker run --rm --runtime=nvidia nvidia/cuda:12.0-base nvidia-smi

echo -e "${GREEN}NVIDIA Container Toolkit installed successfully!${NC}"
EOF

# Drivers README
cat > Drivers/README.md << 'EOF'
# UC-1 Pro Drivers Directory

This directory contains scripts and references for system drivers needed for UC-1 Pro.

## NVIDIA Driver

**Version**: 570.172.08  
**Release Date**: July 17, 2025  
**Compatibility**: RTX 5090, RTX 5080, RTX 5070 series  
**Type**: Linux 64-bit

### Installation

Use the provided installation script:

```bash
sudo ./install-nvidia-driver.sh
```

### NVIDIA Container Toolkit

After installing the driver, install the container toolkit:

```bash
sudo ./install-nvidia-container-toolkit.sh
```

## BIOS Updates

**Motherboard**: ASUS TUF GAMING Z790-PLUS WIFI  
**Latest BIOS**: Version 1820 (2025/05/21)  
**System BIOS**: Version 1604 (12/15/2023) - Update recommended

**File**: TUF-GAMING-Z790-PLUS-WIFI-ASUS-1820.CAP

Store BIOS file in `Drivers/BIOS/` directory.
EOF

chmod +x Drivers/*.sh

# ========================================
# Create main README.md
# ========================================
echo -e "${YELLOW}Creating main README.md...${NC}"
cat > README.md << 'EOF'
# UC-1 Pro - Enterprise AI Stack for RTX 5090

A modular, production-ready AI infrastructure optimized for NVIDIA RTX 5090 GPUs.

## Quick Start

1. Clone this repository
2. Copy `.env.template` to `.env` and configure
3. Run `./scripts/start.sh`

## Architecture

- **vLLM** on RTX 5090 for primary LLM inference
- **WhisperX** for advanced speech-to-text
- **Kokoro TTS** for text-to-speech
- **Modular microservices** architecture
- **Docker-based** deployment

## Directory Structure

```
UC-1-Pro/
├── docker-compose.yml      # Main orchestration
├── services/              # Modular microservices
├── scripts/               # Management scripts
├── config/                # Configuration files
└── Drivers/               # System drivers
```

## Services

- **Port 8080**: Open-WebUI (Main Interface)
- **Port 8000**: vLLM API
- **Port 8084**: Model Manager
- **Port 9000**: WhisperX STT
- **Port 8880**: Kokoro TTS
- **Port 8083**: Reranker
- **Port 8888**: SearXNG
- **Port 9998**: Tika OCR

## Requirements

- Ubuntu Server 24.04 LTS
- NVIDIA RTX 5090 (32GB VRAM)
- 96GB RAM recommended
- Docker & Docker Compose
- NVIDIA Container Toolkit

See full documentation in the docs/ directory.
EOF

# ========================================
# Final message
# ========================================
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           UC-1 Pro structure created successfully!      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Next steps:"
echo "1. Copy tika-ocr and searxng from UC-1:"
echo "   cp -r path/to/UC-1/tika-ocr services/"
echo "   cp -r path/to/UC-1/searxng services/"
echo ""
echo "2. Add BIOS file to Drivers/BIOS/"
echo ""
echo "3. Commit to GitHub:"
echo "   git init"
echo "   git add ."
echo "   git commit -m 'Initial UC-1 Pro setup'"
echo "   git remote add origin <your-repo>"
echo "   git push -u origin main"
echo ""
echo "4. On the server, clone and run:"
echo "   git clone <your-repo> UC-1-Pro"
echo "   cd UC-1-Pro"
echo "   cp .env.template .env"
echo "   # Edit .env"
echo "   ./scripts/start.sh"
EOF