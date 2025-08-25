from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect, BackgroundTasks, Depends, Request, Header
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, StreamingResponse, JSONResponse
import psutil
import docker
import asyncio
import json
import os
import subprocess
import time
from datetime import datetime
from typing import Dict, List, Optional, Any
import GPUtil
import aiofiles
from pydantic import BaseModel
from fastapi import UploadFile, File
import httpx
import yaml
from pathlib import Path
import hashlib
import shutil
from collections import defaultdict
import re
from server_docker_manager import DockerServiceManager
from quick_docker_fix import get_running_services
from network_manager import network_manager
from ai_model_manager import ai_model_manager, ModelSettingsUpdate, ModelDownloadRequest
from storage_manager import storage_backup_manager, StorageInfo, BackupConfig, BackupInfo, BackupStatus
from extension_manager import extension_manager, ExtensionInstallRequest, ExtensionActionRequest, ExtensionConfigUpdate
from log_manager import log_manager, LogFilter, LogExportRequest
from auth_manager import auth_manager, UserCreate, UserUpdate, PasswordChange, LoginCredentials, APIKeyCreate
from hardware_info import hardware_detector
from update_manager import github_update_manager
from fastapi.responses import RedirectResponse
import secrets
import base64
from landing_config import landing_config

# Authentik SSO integration
try:
    from authentik_integration import (
        authentik_integration, 
        AuthentikUser, 
        AuthentikUserCreate, 
        AuthentikUserUpdate,
        AuthentikPasswordReset,
        AuthentikGroup
    )
    AUTHENTIK_ENABLED = True
except ImportError:
    print("Authentik integration not available")
    AUTHENTIK_ENABLED = False

# OAuth settings from environment
AUTHENTIK_URL = os.environ.get("AUTHENTIK_URL", "http://authentik-server:9000")
EXTERNAL_HOST = os.environ.get("EXTERNAL_HOST", "192.168.1.135")
EXTERNAL_PROTOCOL = os.environ.get("EXTERNAL_PROTOCOL", "http")
OAUTH_CLIENT_ID = "ops-center"
OAUTH_CLIENT_SECRET = os.environ.get("OPS_CENTER_OAUTH_CLIENT_SECRET", "a1b2c3d4e5f6789012345678901234567890abcd")
OAUTH_REDIRECT_URI = f"{EXTERNAL_PROTOCOL}://{EXTERNAL_HOST}:8084/auth/callback"

# Session storage (in production, use Redis or database)
sessions = {}

# Enhanced monitoring imports
try:
    from resource_monitor import ResourceMonitor
    resource_monitor = ResourceMonitor()
    ENHANCED_MONITORING = True
except ImportError:
    print("Enhanced monitoring not available, using basic monitoring")
    ENHANCED_MONITORING = False

try:
    from deployment_config import DeploymentService
    deployment_service = DeploymentService()
    DEPLOYMENT_CONFIG = True
except ImportError:
    print("Deployment config not available, using defaults")
    DEPLOYMENT_CONFIG = False

app = FastAPI(title="UC-1 Pro Admin Dashboard API")

# Initialize Docker service manager
docker_manager = DockerServiceManager()

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Enable GZip compression for faster response times
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Root redirect must be defined early to take precedence
@app.get("/", include_in_schema=False)
async def root_redirect(request: Request):
    """Serve public ops center page or redirect to Authentik for login"""
    print("Root redirect handler called!")
    session_token = request.cookies.get("session_token")
    if session_token and session_token in sessions:
        print("User authenticated, serving public ops center page")
        # Serve the original landing page for authenticated users
        static_path = "public/index.html"
        unicorn_path = "public/landing-unicorn.html"
        modern_path = "public/landing-modern.html"
        dynamic_path = "public/landing-dynamic.html"
        
        # Try original index.html first (matches GitHub screenshot)
        if os.path.exists(static_path):
            return FileResponse(static_path)
        elif os.path.exists("../public/index.html"):
            return FileResponse("../public/index.html")
        # Fallback to Unicorn Commander PRO page
        elif os.path.exists(unicorn_path):
            return FileResponse(unicorn_path)
        elif os.path.exists("../public/landing-unicorn.html"):
            return FileResponse("../public/landing-unicorn.html")
        # Fallback to modern page
        elif os.path.exists(modern_path):
            return FileResponse(modern_path)
        elif os.path.exists("../public/landing-modern.html"):
            return FileResponse("../public/landing-modern.html")
        # Fallback to dynamic page
        elif os.path.exists(dynamic_path):
            return FileResponse(dynamic_path)
        elif os.path.exists("../public/landing-dynamic.html"):
            return FileResponse("../public/landing-dynamic.html")
        else:
            # Fallback to admin if public page not found
            return RedirectResponse(url="/admin", status_code=302)
    else:
        print("User not authenticated, redirecting to Authentik")
        # Redirect directly to OAuth login
        return RedirectResponse(url="/auth/login", status_code=302)

# Initialize Docker client
try:
    docker_client = docker.from_env()
except Exception as e:
    print(f"Warning: Docker client initialization failed: {e}")
    docker_client = None

# Model registry storage
MODEL_REGISTRY_PATH = "/home/ucadmin/UC-1-Pro/volumes/model_registry.json"
MODELS_DIR = os.environ.get("MODELS_DIR", "/home/ucadmin/UC-1-Pro/volumes/vllm_models")
HF_TOKEN = os.environ.get("HF_TOKEN", "")

# Active downloads tracking
active_downloads = {}
download_progress = defaultdict(lambda: {"status": "pending", "progress": 0, "speed": 0, "eta": None})

# Initialize model registry
def load_model_registry():
    if os.path.exists(MODEL_REGISTRY_PATH):
        try:
            with open(MODEL_REGISTRY_PATH, 'r') as f:
                return json.load(f)
        except:
            pass
    return {
        "models": {},
        "active_model": None,
        "global_settings": {
            "default_retention": "keep",
            "default_context_size": 16384
        }
    }

def save_model_registry(registry):
    try:
        with open(MODEL_REGISTRY_PATH, 'w') as f:
            json.dump(registry, f, indent=2)
    except Exception as e:
        print(f"Error saving model registry: {e}")

model_registry = load_model_registry()

# Helper function to get directory size
def get_directory_size(path):
    """Get total size of a directory"""
    total = 0
    try:
        for entry in os.scandir(path):
            if entry.is_file():
                total += entry.stat().st_size
            elif entry.is_dir():
                total += get_directory_size(entry.path)
    except:
        pass
    
    # Format size
    if total > 1024**3:
        return f"{total / (1024**3):.1f} GB"
    elif total > 1024**2:
        return f"{total / (1024**2):.1f} MB"
    else:
        return f"{total / 1024:.1f} KB"

# Function to scan and discover existing models
def scan_existing_models():
    """Scan the models directory and update registry with found models"""
    if not os.path.exists(MODELS_DIR):
        print(f"Models directory not found: {MODELS_DIR}")
        return
    
    print(f"Scanning for models in {MODELS_DIR}")
    
    # Recursively look for model directories
    def scan_directory(base_path, parent_path=""):
        for item in os.listdir(base_path):
            item_path = os.path.join(base_path, item)
            if os.path.isdir(item_path):
                # Check if it's a model directory (contains config.json or similar)
                config_files = ['config.json', 'model.safetensors', 'model-00001-of-00005.safetensors', 'model.bin', 'pytorch_model.bin']
                has_config = any(os.path.exists(os.path.join(item_path, cf)) for cf in config_files)
                
                if has_config:
                    # Build full model ID from path
                    if parent_path:
                        model_id = f"{parent_path}/{item}"
                    else:
                        model_id = item
                    
                    # Check if it's already in registry
                    if model_id not in model_registry["models"]:
                        print(f"Found model: {model_id}")
                        
                        # Get model size
                        size = get_directory_size(item_path)
                        
                        # Determine quantization from name
                        quantization = "Unknown"
                        if "AWQ" in item:
                            quantization = "AWQ"
                        elif "GPTQ" in item:
                            quantization = "GPTQ"
                        elif "GGUF" in item:
                            quantization = "GGUF"
                        
                        # Determine if it's the active model based on env var
                        default_model = os.environ.get("DEFAULT_LLM_MODEL", "")
                        # Clean up the model ID for comparison
                        clean_model_id = model_id.replace("models--", "").replace("--", "/")
                        is_active = (model_id == default_model or 
                                   clean_model_id == default_model or 
                                   default_model.endswith(f"/{item}"))
                        
                        model_registry["models"][model_id] = {
                            "id": model_id,
                            "path": item_path,
                            "quantization": quantization,
                            "discovered_at": datetime.now().isoformat(),
                            "size": size,
                            "active": is_active
                        }
                else:
                    # Recursively scan subdirectories
                    scan_directory(item_path, f"{parent_path}/{item}" if parent_path else item)
    
    scan_directory(MODELS_DIR)
    save_model_registry(model_registry)
    print(f"Found {len(model_registry['models'])} models")

# Scan for existing models on startup
scan_existing_models()

# Service definitions
SERVICES = {
    "open-webui": {
        "container": "unicorn-open-webui",
        "name": "Chat UI",
        "port": 8080,
        "healthcheck": "/health",
        "description": "Web interface for AI chat interactions"
    },
    "vllm": {
        "container": "unicorn-vllm",
        "name": "vLLM API",
        "port": 8000,
        "healthcheck": "/health",
        "description": "High-performance LLM inference server"
    },
    "whisperx": {
        "container": "unicorn-whisperx",
        "name": "WhisperX",
        "port": 9000,
        "healthcheck": "/health",
        "description": "Advanced speech-to-text with speaker diarization"
    },
    "kokoro": {
        "container": "unicorn-kokoro",
        "name": "Kokoro TTS",
        "port": 8880,
        "healthcheck": "/health",
        "description": "High-quality text-to-speech synthesis"
    },
    "embeddings": {
        "container": "unicorn-embeddings",
        "name": "Embeddings",
        "port": 8082,
        "healthcheck": "/health",
        "description": "Text embedding service for RAG"
    },
    "reranker": {
        "container": "unicorn-reranker",
        "name": "Reranker",
        "port": 8083,
        "healthcheck": "/health",
        "description": "Document reranking for improved search"
    },
    "searxng": {
        "container": "unicorn-searxng",
        "name": "SearXNG",
        "port": 8888,
        "healthcheck": "/",
        "description": "Private search engine"
    },
    "qdrant": {
        "container": "unicorn-qdrant",
        "name": "Qdrant",
        "port": 6333,
        "healthcheck": "/health",
        "description": "Vector database for embeddings"
    },
    "tika-ocr": {
        "container": "unicorn-tika-ocr",
        "name": "Tika OCR",
        "port": 9998,
        "healthcheck": "/",
        "description": "Document parsing and OCR"
    },
    "postgres": {
        "container": "unicorn-postgres",
        "name": "PostgreSQL",
        "port": 5432,
        "healthcheck": None,
        "description": "Main database"
    },
    "redis": {
        "container": "unicorn-redis",
        "name": "Redis",
        "port": 6379,
        "healthcheck": None,
        "description": "Cache and message queue"
    },
    "prometheus": {
        "container": "unicorn-prometheus",
        "name": "Prometheus",
        "port": 9090,
        "healthcheck": "/-/healthy",
        "description": "Metrics collection"
    }
}

# WebSocket connections
websocket_connections = set()

# Pydantic models
class ServiceAction(BaseModel):
    action: str  # start, stop, restart

class NetworkConfig(BaseModel):
    interface: str
    method: str  # dhcp, static
    address: Optional[str] = None
    netmask: Optional[str] = None
    gateway: Optional[str] = None
    dns: Optional[List[str]] = None

class SystemSettings(BaseModel):
    idle_timeout_minutes: int = 5
    idle_policy: str = "swap"  # swap, unload, none
    idle_model: str = "microsoft/DialoGPT-small"
    enable_monitoring: bool = True
    enable_backups: bool = True
    backup_schedule: str = "0 2 * * *"

class ModelDownload(BaseModel):
    model_id: str
    quantization: Optional[str] = None

class ModelEstimate(BaseModel):
    model_id: str
    model_size: str
    quantization: str
    context_size: int = 16384

class ActiveModel(BaseModel):
    model_id: str

class ModelConfig(BaseModel):
    retention: Optional[str] = None
    context_size: Optional[int] = None

class GlobalModelSettings(BaseModel):
    default_retention: str = "keep"
    default_context_size: int = 16384

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    websocket_connections.add(websocket)
    try:
        while True:
            # Keep connection alive and handle messages
            data = await websocket.receive_text()
            # Handle incoming messages if needed
    except WebSocketDisconnect:
        websocket_connections.remove(websocket)

async def broadcast_progress(model_id: str, progress_data: dict):
    """Broadcast download progress to all connected WebSocket clients"""
    message = json.dumps({
        "type": "download_progress",
        "model_id": model_id,
        "data": progress_data
    })
    
    disconnected = set()
    for websocket in websocket_connections:
        try:
            await websocket.send_text(message)
        except:
            disconnected.add(websocket)
    
    # Clean up disconnected websockets
    for ws in disconnected:
        websocket_connections.discard(ws)

# Hugging Face API functions
async def search_huggingface_models(query: str, limit: int = 20):
    """Search Hugging Face for models"""
    async with httpx.AsyncClient() as client:
        headers = {}
        if HF_TOKEN:
            headers["Authorization"] = f"Bearer {HF_TOKEN}"
        
        # Search for text-generation models that are likely vLLM compatible
        params = {
            "search": query,
            "filter": "text-generation",
            "limit": limit,
            "sort": "downloads"
        }
        
        try:
            response = await client.get(
                "https://huggingface.co/api/models",
                params=params,
                headers=headers,
                timeout=10.0
            )
            
            if response.status_code == 200:
                models = response.json()
                
                # Process and enhance model data
                processed_models = []
                for model in models:
                    # Fetch model card to get more details
                    try:
                        card_response = await client.get(
                            f"https://huggingface.co/api/models/{model['id']}",
                            headers=headers,
                            timeout=5.0
                        )
                        if card_response.status_code == 200:
                            model_details = card_response.json()
                            
                            # Determine available quantizations
                            files = model_details.get("siblings", [])
                            quantizations = detect_quantizations(files)
                            
                            # Estimate model size
                            model_size = estimate_model_size_from_files(files)
                            
                            processed_models.append({
                                "id": model["id"],
                                "name": model.get("id", "").split("/")[-1],
                                "description": model.get("pipeline_tag", "Text generation model"),
                                "downloads": model_details.get("downloads", 0),
                                "likes": model_details.get("likes", 0),
                                "size": model_size,
                                "task": "text-generation",
                                "quantizations": quantizations,
                                "vllm_compatible": check_vllm_compatibility(model_details),
                                "trending": model_details.get("downloads", 0) > 100000
                            })
                    except:
                        # Fallback for models where detailed info fails
                        processed_models.append({
                            "id": model["id"],
                            "name": model.get("id", "").split("/")[-1],
                            "description": "Model from Hugging Face",
                            "downloads": model.get("downloads", 0),
                            "likes": model.get("likes", 0),
                            "size": "Unknown",
                            "task": "text-generation",
                            "quantizations": ["Q4_K_M", "Q5_K_M"],
                            "vllm_compatible": True
                        })
                
                return processed_models[:limit]
            
        except Exception as e:
            print(f"Error searching HuggingFace: {e}")
    
    # Return fallback trending models on error
    return get_trending_models()[:limit]

def get_trending_models():
    """Get trending models as fallback"""
    return [
        {
            "id": "meta-llama/Meta-Llama-3.1-8B-Instruct",
            "name": "Llama 3.1 8B Instruct",
            "description": "Latest Llama model optimized for instruction following",
            "downloads": 2500000,
            "likes": 15000,
            "size": "16GB",
            "task": "text-generation",
            "quantizations": ["Q4_K_M", "Q5_K_M", "Q8_0", "F16"],
            "vllm_compatible": True,
            "trending": True
        },
        {
            "id": "Qwen/Qwen2.5-32B-Instruct-AWQ",
            "name": "Qwen 2.5 32B Instruct AWQ",
            "description": "State-of-the-art model with 32K context length",
            "downloads": 1800000,
            "likes": 12000,
            "size": "18GB",
            "task": "text-generation",
            "quantizations": ["AWQ"],
            "vllm_compatible": True,
            "trending": True
        },
        {
            "id": "mistralai/Mistral-7B-Instruct-v0.2",
            "name": "Mistral 7B Instruct v0.2",
            "description": "Efficient 7B model with sliding window attention",
            "downloads": 3200000,
            "likes": 18000,
            "size": "14GB",
            "task": "text-generation",
            "quantizations": ["Q4_K_M", "Q5_K_M", "Q8_0"],
            "vllm_compatible": True,
            "trending": True
        }
    ]

def detect_quantizations(files):
    """Detect available quantizations from model files"""
    quantizations = set()
    
    for file in files:
        filename = file.get("rfilename", "")
        
        # Check for common quantization patterns
        if "awq" in filename.lower():
            quantizations.add("AWQ")
        if "gptq" in filename.lower():
            quantizations.add("GPTQ")
        if "q4_k_m" in filename.lower():
            quantizations.add("Q4_K_M")
        if "q5_k_m" in filename.lower():
            quantizations.add("Q5_K_M")
        if "q8_0" in filename.lower():
            quantizations.add("Q8_0")
        if "fp16" in filename.lower() or "f16" in filename.lower():
            quantizations.add("F16")
        if ".gguf" in filename:
            # GGUF files often have multiple quants
            quantizations.update(["Q4_K_M", "Q5_K_M", "Q8_0"])
    
    # Default quantizations if none detected
    if not quantizations:
        quantizations = {"Q4_K_M", "Q5_K_M"}
    
    return sorted(list(quantizations))

def estimate_model_size_from_files(files):
    """Estimate total model size from file listing"""
    total_size = 0
    
    for file in files:
        size = file.get("size", 0)
        total_size += size
    
    # Convert to human readable
    if total_size == 0:
        return "Unknown"
    
    gb = total_size / (1024 ** 3)
    if gb > 1:
        return f"{gb:.1f}GB"
    
    mb = total_size / (1024 ** 2)
    return f"{mb:.0f}MB"

def check_vllm_compatibility(model_details):
    """Check if model is likely vLLM compatible"""
    # Check model architecture
    config = model_details.get("config", {})
    arch = config.get("model_type", "").lower()
    
    # Known vLLM compatible architectures
    vllm_architectures = [
        "llama", "mistral", "qwen", "phi", "gemma", "gpt2", "gptj", 
        "gpt_neox", "opt", "bloom", "falcon", "mpt", "starcoder",
        "baichuan", "aquila", "chatglm", "internlm", "yi"
    ]
    
    for va in vllm_architectures:
        if va in arch:
            return True
    
    # Check tags
    tags = model_details.get("tags", [])
    if "text-generation" in tags:
        return True
    
    # Default to true for text-generation models
    return True

# Memory estimation
def calculate_model_memory(model_size_str: str, quantization: str, context_size: int = 16384):
    """Calculate memory requirements for a model"""
    # Parse model size
    size_gb = 0
    if "GB" in model_size_str.upper():
        size_gb = float(re.findall(r'[\d.]+', model_size_str)[0])
    elif "MB" in model_size_str.upper():
        size_gb = float(re.findall(r'[\d.]+', model_size_str)[0]) / 1024
    elif "B" in model_size_str:
        # Assume it's parameter count in billions
        param_b = float(re.findall(r'[\d.]+', model_size_str)[0])
        # Rough estimate: 2 bytes per parameter for fp16
        size_gb = (param_b * 2)
    
    # Quantization multipliers
    quant_multipliers = {
        'F16': 1.0,        # Full precision
        'FP16': 1.0,
        'Q8_0': 0.5,       # 8-bit quantization  
        'Q5_K_M': 0.375,   # 5-bit quantization
        'Q4_K_M': 0.25,    # 4-bit quantization
        'AWQ': 0.25,       # AWQ 4-bit
        'GPTQ': 0.25,      # GPTQ 4-bit
        'Q3_K_M': 0.1875   # 3-bit quantization
    }
    
    multiplier = quant_multipliers.get(quantization, 0.25)
    model_memory_gb = size_gb * multiplier
    
    # Context memory calculation
    # Rough estimate: 4 bytes per token for KV cache
    context_memory_gb = (context_size * 4 * 2) / (1024 ** 3)  # *2 for K and V
    
    # Add overhead (20% for safety)
    total_memory_gb = (model_memory_gb + context_memory_gb) * 1.2
    
    # Get available GPU memory using nvidia-smi instead of GPUtil
    try:
        result = subprocess.run(['nvidia-smi', '--query-gpu=memory.free,memory.total', '--format=csv,noheader,nounits'], 
                              capture_output=True, text=True, timeout=2)
        if result.returncode == 0:
            parts = result.stdout.strip().split(', ')
            if len(parts) >= 2:
                available_memory_gb = float(parts[0]) / 1024
                total_gpu_memory_gb = float(parts[1]) / 1024
                usage_percentage = (total_memory_gb / total_gpu_memory_gb) * 100
            else:
                available_memory_gb = 32  # Default for RTX 5090
                total_gpu_memory_gb = 32
                usage_percentage = (total_memory_gb / total_gpu_memory_gb) * 100
        else:
            available_memory_gb = 32  # Default for RTX 5090
            total_gpu_memory_gb = 32
            usage_percentage = (total_memory_gb / total_gpu_memory_gb) * 100
    except:
        available_memory_gb = 32
        total_gpu_memory_gb = 32
        usage_percentage = (total_memory_gb / total_gpu_memory_gb) * 100
    
    return {
        "model": round(model_memory_gb, 2),
        "context": round(context_memory_gb, 2),
        "total": round(total_memory_gb, 2),
        "available": round(available_memory_gb, 2),
        "percentage": round(usage_percentage, 1),
        "fits": total_memory_gb <= available_memory_gb
    }

# Model download functionality
async def download_model_with_progress(model_id: str, quantization: Optional[str], background_tasks: BackgroundTasks):
    """Download a model using huggingface-cli with progress tracking"""
    download_id = hashlib.md5(f"{model_id}:{quantization}".encode()).hexdigest()
    
    # Initialize progress
    download_progress[download_id] = {
        "status": "initializing",
        "progress": 0,
        "speed": 0,
        "eta": None,
        "model_id": model_id,
        "quantization": quantization
    }
    
    try:
        # Create model directory
        model_path = os.path.join(MODELS_DIR, model_id.replace("/", "_"))
        os.makedirs(model_path, exist_ok=True)
        
        # Build huggingface-cli command
        cmd = ["huggingface-cli", "download", model_id, "--local-dir", model_path]
        
        if HF_TOKEN:
            cmd.extend(["--token", HF_TOKEN])
        
        if quantization:
            # Add pattern to download only specific quantization files
            if quantization == "AWQ":
                cmd.extend(["--include", "*awq*", "*.json", "*.txt"])
            elif quantization == "GPTQ":
                cmd.extend(["--include", "*gptq*", "*.json", "*.txt"])
            elif quantization in ["Q4_K_M", "Q5_K_M", "Q8_0"]:
                cmd.extend(["--include", f"*{quantization.lower()}*", "*.json", "*.txt"])
        
        # Start download process
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        download_progress[download_id]["status"] = "downloading"
        active_downloads[download_id] = process
        
        # Parse output for progress
        start_time = time.time()
        last_update = 0
        
        while True:
            line = await process.stderr.readline()
            if not line:
                break
            
            line = line.decode('utf-8').strip()
            
            # Parse progress from huggingface-cli output
            if "Downloading" in line or "%" in line:
                # Extract progress percentage
                match = re.search(r'(\d+)%', line)
                if match:
                    progress = int(match.group(1))
                    current_time = time.time()
                    
                    # Calculate speed
                    if current_time - last_update > 1:  # Update every second
                        elapsed = current_time - start_time
                        speed = progress / elapsed if elapsed > 0 else 0
                        eta = (100 - progress) / speed if speed > 0 else None
                        
                        download_progress[download_id].update({
                            "status": "downloading",
                            "progress": progress,
                            "speed": round(speed, 2),
                            "eta": round(eta) if eta else None
                        })
                        
                        # Broadcast progress
                        await broadcast_progress(model_id, download_progress[download_id])
                        last_update = current_time
        
        # Wait for completion
        await process.wait()
        
        if process.returncode == 0:
            # Success - register the model
            download_progress[download_id]["status"] = "completed"
            download_progress[download_id]["progress"] = 100
            
            # Add to model registry
            model_registry["models"][model_id] = {
                "id": model_id,
                "path": model_path,
                "quantization": quantization,
                "downloaded_at": datetime.now().isoformat(),
                "size": get_directory_size(model_path),
                "active": False
            }
            save_model_registry(model_registry)
            
            await broadcast_progress(model_id, download_progress[download_id])
        else:
            # Failed
            download_progress[download_id]["status"] = "failed"
            download_progress[download_id]["error"] = "Download failed"
            await broadcast_progress(model_id, download_progress[download_id])
    
    except Exception as e:
        download_progress[download_id]["status"] = "failed"
        download_progress[download_id]["error"] = str(e)
        await broadcast_progress(model_id, download_progress[download_id])
    
    finally:
        # Cleanup
        if download_id in active_downloads:
            del active_downloads[download_id]


# API Routes

@app.get("/api/v1/system/status")
async def get_system_status():
    """Get current system resource usage with enhanced monitoring"""
    try:
        # Try enhanced monitoring first
        if ENHANCED_MONITORING:
            try:
                metrics = {
                    "cpu": resource_monitor.get_cpu_metrics(),
                    "memory": resource_monitor.get_memory_metrics(),
                    "gpu": resource_monitor.get_gpu_metrics(),
                    "disk": resource_monitor.get_disk_metrics(),
                    "network": resource_monitor.get_network_metrics(),
                    "processes": resource_monitor.get_top_processes()
                }
                
                # Format for API compatibility
                gpu_info = []
                if metrics["gpu"].get("nvidia_gpus"):
                    for gpu in metrics["gpu"]["nvidia_gpus"]:
                        gpu_info.append({
                            "name": gpu.get("name", "Unknown GPU"),
                            "utilization": gpu.get("utilization_percent", 0),
                            "memory_used": gpu.get("memory_used_mb", 0) * 1024 * 1024,
                            "memory_total": gpu.get("memory_total_mb", 0) * 1024 * 1024,
                            "temperature": gpu.get("temperature", 0),
                            "power_draw": gpu.get("power_w", 0),
                            "power_limit": gpu.get("power_limit_w", 0)
                        })
                
                return {
                    "cpu": {
                        "percent": metrics["cpu"].get("usage_percent", 0),
                        "per_cpu": metrics["cpu"].get("per_core_usage", []),
                        "cores": metrics["cpu"].get("cores", 0),
                        "freq_current": metrics["cpu"].get("frequency", {}).get("current", 0)
                    },
                    "memory": {
                        "used": int(metrics["memory"].get("ram", {}).get("used_gb", 0) * 1024 * 1024 * 1024),
                        "total": int(metrics["memory"].get("ram", {}).get("total_gb", 0) * 1024 * 1024 * 1024),
                        "available": int(metrics["memory"].get("ram", {}).get("available_gb", 0) * 1024 * 1024 * 1024),
                        "percent": metrics["memory"].get("ram", {}).get("percent", 0)
                    },
                    "disk": {
                        "used": int(metrics["disk"].get("partitions", [{}])[0].get("used_gb", 0) * 1024 * 1024 * 1024),
                        "total": int(metrics["disk"].get("partitions", [{}])[0].get("total_gb", 0) * 1024 * 1024 * 1024),
                        "percent": metrics["disk"].get("partitions", [{}])[0].get("percent", 0)
                    },
                    "gpu": gpu_info,
                    "uptime": int(time.time() - psutil.boot_time()),
                    "load_average": metrics["cpu"].get("load_average", [0, 0, 0]),
                    "processes": metrics.get("processes", []),
                    "enhanced_monitoring": True
                }
            except Exception as e:
                print(f"Enhanced monitoring failed, falling back to basic: {e}")
        
        # Fallback to basic monitoring
        # CPU info - use non-blocking calls
        cpu_percent = psutil.cpu_percent(interval=0)  # Non-blocking
        cpu_percent_per_core = psutil.cpu_percent(interval=0, percpu=True)  # Non-blocking
        cpu_count = psutil.cpu_count()
        
        # Memory info
        memory = psutil.virtual_memory()
        
        # Disk info
        disk = psutil.disk_usage('/')
        
        # GPU info (if available) - skip GPUtil for now as it might be blocking
        gpu_info = []
        # Temporarily disable GPUtil calls to fix performance
        # try:
        #     gpus = GPUtil.getGPUs()
        #     for gpu in gpus:
        #         gpu_info.append({
        #             "name": gpu.name,
        #             "utilization": round(gpu.load * 100, 1),
        #             "memory_used": int(gpu.memoryUsed * 1024 * 1024),  # Convert to bytes
        #             "memory_total": int(gpu.memoryTotal * 1024 * 1024),  # Convert to bytes
        #             "temperature": gpu.temperature,
        #             "power_draw": getattr(gpu, 'powerDraw', 0),
        #             "power_limit": getattr(gpu, 'powerLimit', 0)
        #         })
        # except Exception as e:
        #     print(f"GPU info error: {e}")
        
        # Use nvidia-smi for GPU info instead
        try:
            result = subprocess.run(['nvidia-smi', '--query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw,power.limit', 
                                   '--format=csv,noheader,nounits'], 
                                  capture_output=True, text=True, timeout=2)
            if result.returncode == 0:
                for line in result.stdout.strip().split('\n'):
                    parts = line.split(', ')
                    if len(parts) >= 7:
                        gpu_info.append({
                            "name": parts[0],
                            "utilization": float(parts[1]) if parts[1] != '[N/A]' else 0,
                            "memory_used": int(float(parts[2]) * 1024 * 1024) if parts[2] != '[N/A]' else 0,
                            "memory_total": int(float(parts[3]) * 1024 * 1024) if parts[3] != '[N/A]' else 0,
                            "temperature": float(parts[4]) if parts[4] != '[N/A]' else 0,
                            "power_draw": float(parts[5]) if parts[5] != '[N/A]' else 0,
                            "power_limit": float(parts[6]) if parts[6] != '[N/A]' else 0
                        })
        except Exception as e:
            print(f"GPU info error: {e}")
        
        # Get CPU frequency
        cpu_freq = psutil.cpu_freq()
        
        # Get load average
        load_avg = os.getloadavg()
        
        # Get uptime
        boot_time = psutil.boot_time()
        uptime = int(time.time() - boot_time)
        
        # Get top processes - skip for performance
        processes = []
        # Skip process enumeration for now to improve performance
        # This was causing significant delays in the API response
        # try:
        #     for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_info', 'status']):
        #         try:
        #             pinfo = proc.info
        #             processes.append({
        #                 'pid': pinfo['pid'],
        #                 'name': pinfo['name'],
        #                 'cpu_percent': pinfo['cpu_percent'] or 0,
        #                 'memory_mb': pinfo['memory_info'].rss / (1024 * 1024) if pinfo['memory_info'] else 0,
        #                 'status': pinfo['status']
        #             })
        #         except (psutil.NoSuchProcess, psutil.AccessDenied):
        #             pass
        #     
        #     # Sort by CPU usage and take top 10
        #     processes.sort(key=lambda x: x['cpu_percent'], reverse=True)
        #     processes = processes[:10]
        # except Exception as e:
        #     print(f"Error getting processes: {e}")
        
        return {
            "cpu": {
                "percent": round(cpu_percent, 1),
                "per_cpu": [round(p, 1) for p in cpu_percent_per_core],
                "cores": cpu_count,
                "freq_current": int(cpu_freq.current) if cpu_freq else 0
            },
            "memory": {
                "used": memory.used,
                "total": memory.total,
                "available": memory.available,
                "percent": round(memory.percent, 1)
            },
            "disk": {
                "used": disk.used,
                "total": disk.total,
                "percent": round(disk.percent, 1)
            },
            "gpu": gpu_info,
            "uptime": uptime,
            "load_average": list(load_avg),
            "processes": processes,
            "enhanced_monitoring": False
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/system/hardware")
async def get_hardware_info():
    """Get detailed hardware information"""
    try:
        return hardware_detector.get_all_hardware_info()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/system/disk-io")
async def get_disk_io_stats():
    """Get current disk I/O statistics"""
    try:
        import psutil
        import time
        
        # Get disk I/O counters
        disk_io = psutil.disk_io_counters()
        
        if disk_io:
            return {
                "read_bytes": disk_io.read_bytes,
                "write_bytes": disk_io.write_bytes,
                "read_count": disk_io.read_count,
                "write_count": disk_io.write_count,
                "read_time": disk_io.read_time,
                "write_time": disk_io.write_time,
                "timestamp": time.time()
            }
        else:
            return {
                "read_bytes": 0,
                "write_bytes": 0,
                "read_count": 0,
                "write_count": 0,
                "read_time": 0,
                "write_time": 0,
                "timestamp": time.time()
            }
    except Exception as e:
        logger.error(f"Disk I/O stats error: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get disk I/O stats: {str(e)}")

@app.get("/api/v1/deployment/config")
async def get_deployment_config():
    """Get deployment configuration"""
    try:
        if DEPLOYMENT_CONFIG:
            # Use the enhanced deployment service
            config = {
                "deployment_type": deployment_service.detect_deployment_type(),
                "primary_app_url": deployment_service.get_primary_app_url(),
                "admin_only_mode": deployment_service.is_admin_only_mode(),
                "registered_applications": deployment_service.get_registered_applications(),
                "enabled_features": deployment_service.get_enabled_features(),
                "branding": deployment_service.get_branding_config()
            }
        else:
            # Fallback configuration for UC-1 Pro
            config = {
                "deployment_type": "enterprise",
                "primary_app_url": "http://localhost:8080",
                "admin_only_mode": False,
                "registered_applications": ["open-webui", "center-deep", "vllm"],
                "enabled_features": ["vllm", "gpu_monitoring", "enterprise_auth", "model_management"],
                "branding": {
                    "name": "UC-1 Pro Operations Center",
                    "theme": "unicorn"
                }
            }
        return config
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ===========================
# Landing Page Customization
# ===========================

@app.get("/api/v1/landing/config")
async def get_landing_config():
    """Get landing page configuration"""
    try:
        return landing_config.get_config()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/landing/config")
async def update_landing_config(updates: dict):
    """Update landing page configuration"""
    try:
        success = landing_config.update_config(updates)
        if success:
            return {"status": "success", "config": landing_config.get_config()}
        else:
            raise HTTPException(status_code=500, detail="Failed to update configuration")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/landing/theme/{preset}")
async def apply_theme_preset(preset: str):
    """Apply a theme preset"""
    try:
        if preset not in landing_config.THEME_PRESETS:
            raise HTTPException(status_code=400, detail=f"Invalid preset: {preset}")
        
        success = landing_config.apply_theme_preset(preset)
        if success:
            return {"status": "success", "config": landing_config.get_config()}
        else:
            raise HTTPException(status_code=500, detail="Failed to apply theme")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/landing/themes")
async def get_available_themes():
    """Get available theme presets"""
    return landing_config.THEME_PRESETS

@app.get("/api/v1/service-urls")
async def get_service_urls():
    """Get service URLs with proper domain configuration"""
    external_host = os.getenv("EXTERNAL_HOST", "localhost")
    external_protocol = os.getenv("EXTERNAL_PROTOCOL", "http")
    
    # Build base URL
    if external_host != "localhost":
        base_url = f"{external_protocol}://{external_host}"
    else:
        base_url = ""  # Empty for relative URLs when using localhost
    
    # Define service URLs with subdomain support
    service_urls = {
        'vllm': f"{base_url}:8000/docs" if base_url else "http://localhost:8000/docs",
        'open-webui': f"{external_protocol}://chat.{external_host}" if external_host != "localhost" else "http://localhost:8080",
        'searxng': f"{external_protocol}://search.{external_host}" if external_host != "localhost" else "http://localhost:8888",
        'prometheus': f"{base_url}:9090" if base_url else "http://localhost:9090",
        'grafana': f"{base_url}:3000" if base_url else "http://localhost:3000",
        'portainer': f"{base_url}:9443" if base_url else "http://localhost:9443",
        'comfyui': f"{base_url}:8188" if base_url else "http://localhost:8188",
        'n8n': f"{base_url}:5678" if base_url else "http://localhost:5678",
        'qdrant': f"{base_url}:6333/dashboard" if base_url else "http://localhost:6333/dashboard",
        'admin-dashboard': f"{base_url}:8084" if base_url else "http://localhost:8084",
        'ollama': f"{base_url}:11434" if base_url else "http://localhost:11434",
        'ollama-webui': f"{base_url}:11435" if base_url else "http://localhost:11435"
    }
    
    return {
        "base_url": base_url,
        "external_host": external_host,
        "external_protocol": external_protocol,
        "service_urls": service_urls
    }

@app.post("/api/v1/landing/service/{service_id}")
async def update_landing_service(service_id: str, updates: dict):
    """Update a specific service configuration"""
    try:
        success = landing_config.update_service(service_id, updates)
        if success:
            return {"status": "success", "config": landing_config.get_config()}
        else:
            raise HTTPException(status_code=404, detail=f"Service {service_id} not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/landing/custom-link")
async def add_custom_link(link_data: dict):
    """Add a custom service link"""
    try:
        success = landing_config.add_custom_link(link_data)
        if success:
            return {"status": "success", "config": landing_config.get_config()}
        else:
            raise HTTPException(status_code=500, detail="Failed to add custom link")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/v1/landing/custom-link/{link_id}")
async def remove_custom_link(link_id: str):
    """Remove a custom service link"""
    try:
        success = landing_config.remove_custom_link(link_id)
        if success:
            return {"status": "success", "config": landing_config.get_config()}
        else:
            raise HTTPException(status_code=404, detail=f"Link {link_id} not found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/landing/reorder")
async def reorder_services(service_order: list):
    """Reorder services on landing page"""
    try:
        success = landing_config.reorder_services(service_order)
        if success:
            return {"status": "success", "config": landing_config.get_config()}
        else:
            raise HTTPException(status_code=500, detail="Failed to reorder services")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/landing/reset")
async def reset_landing_config():
    """Reset landing page to default configuration"""
    try:
        success = landing_config.reset_to_default()
        if success:
            return {"status": "success", "config": landing_config.get_config()}
        else:
            raise HTTPException(status_code=500, detail="Failed to reset configuration")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/landing/export")
async def export_landing_config():
    """Export landing page configuration"""
    try:
        config_json = landing_config.export_config()
        return JSONResponse(
            content={"config": config_json},
            headers={"Content-Disposition": "attachment; filename=landing_config.json"}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/landing/import")
async def import_landing_config(config_data: dict):
    """Import landing page configuration"""
    try:
        config_json = json.dumps(config_data)
        success = landing_config.import_config(config_json)
        if success:
            return {"status": "success", "config": landing_config.get_config()}
        else:
            raise HTTPException(status_code=400, detail="Invalid configuration format")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ===========================
# Service Management
# ===========================

@app.get("/api/v1/services")
async def list_services():
    """List all services with their status"""
    try:
        # Use Quick Docker Fix for reliable container detection
        services = get_running_services()
        print(f"DEBUG: Quick Docker Fix returned {len(services)} services")
        
        # Format the services for the expected API response
        formatted_services = []
        for service in services:
            formatted_services.append({
                "name": service['name'],
                "display_name": service['display_name'],
                "status": service['status'],
                "port": service['port'],
                "description": service['description'],
                "cpu_percent": service['cpu_percent'],
                "memory_mb": service['memory_mb'],
                "uptime": service['uptime'],
                "type": service.get('type', 'core'),
                "category": service.get('category', 'general'),
                "container_name": service['container_name'],
                "gpu_enabled": service['gpu_enabled'],
                "image": service['image']
            })
        
        return formatted_services
    
    except Exception as e:
        print(f"Error listing services with Quick Docker Fix: {e}")
        # Fall back to development mode mock data
        if os.environ.get('DEVELOPMENT', 'false').lower() == 'true':
            services = []
            for service_id, service_info in SERVICES.items():
                services.append({
                    "name": service_id,
                    "display_name": service_info["name"],
                    "status": "healthy" if service_id in ["vllm", "open-webui"] else "stopped",
                    "port": service_info["port"],
                    "description": service_info.get("description", ""),
                    "cpu_percent": 12.5 if service_id == "vllm" else 2.1,
                    "memory_mb": 8192 if service_id == "vllm" else 512,
                    "uptime": "2h 15m" if service_id in ["vllm", "open-webui"] else None,
                    "category": "core",
                    "container_name": service_info["container"],
                    "gpu_enabled": False,
                    "image": "unknown"
                })
            return services
        
        # Return empty list as fallback
        return []

@app.post("/api/v1/services/{container_name}/action")
async def service_action(container_name: str, action: ServiceAction):
    """Perform action on a service"""
    try:
        # Use direct Docker CLI commands for reliable service control
        result = subprocess.run(
            ['docker', action.action, container_name],
            capture_output=True, 
            text=True, 
            timeout=30
        )
        
        if result.returncode == 0:
            return {
                "status": "success", 
                "action": action.action, 
                "service": container_name,
                "message": f"Successfully {action.action}ed {container_name}"
            }
        else:
            raise HTTPException(
                status_code=500, 
                detail=f"Failed to {action.action} {container_name}: {result.stderr}"
            )
    except subprocess.TimeoutExpired:
        raise HTTPException(
            status_code=500, 
            detail=f"Timeout while trying to {action.action} {container_name}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500, 
            detail=f"Error controlling service: {str(e)}"
        )

@app.get("/api/v1/services/{container_name}/logs")
async def get_service_logs(container_name: str, lines: int = 100):
    """Get logs from a service container"""
    logs = docker_manager.get_service_logs(container_name, lines)
    return {"container": container_name, "logs": logs}

@app.get("/api/v1/services/{container_name}/stats")
async def get_service_stats(container_name: str):
    """Get detailed stats for a service container"""
    stats = docker_manager._get_container_stats(container_name)
    if stats:
        return {"container": container_name, "stats": stats}
    else:
        # Return basic stats when Docker API is not available
        # Look for the service in our current services list
        services = docker_manager.discover_all_services()
        all_services = services.get("core", [])
        
        # Flatten extension services (it's a dict of lists)
        extensions = services.get("extensions", {})
        if isinstance(extensions, dict):
            for ext_name, ext_services in extensions.items():
                all_services.extend(ext_services)
        else:
            all_services.extend(extensions)
        
        for service in all_services:
            if service.get("container_name") == container_name:
                # Return basic info we have
                return {
                    "container": container_name,
                    "stats": {
                        "name": service.get("name"),
                        "display_name": service.get("display_name"),
                        "status": service.get("status"),
                        "cpu_percent": service.get("cpu_percent", 0),
                        "memory_mb": service.get("memory_mb", 0),
                        "uptime": service.get("uptime"),
                        "created": None,
                        "ports": [service.get("port")] if service.get("port") else [],
                        "networks": [],
                        "volumes": [],
                        "environment": {},
                        "labels": {},
                        "image": service.get("image", "unknown")
                    }
                }
        
        # If container not found at all
        raise HTTPException(status_code=404, detail="Container not found")

# Model Management Routes

@app.get("/api/v1/models/search")
async def search_models(q: Optional[str] = None):
    """Search for models on Hugging Face"""
    if not q:
        # Return trending models
        trending = await search_huggingface_models("", limit=10)
        return trending
    
    # Search with query
    results = await search_huggingface_models(q, limit=20)
    return results

@app.post("/api/v1/models/estimate-memory")
async def estimate_memory(request: ModelEstimate):
    """Estimate memory requirements for a model"""
    return calculate_model_memory(
        request.model_size,
        request.quantization,
        request.context_size
    )

@app.post("/api/v1/models/download")
async def download_model(request: ModelDownload, background_tasks: BackgroundTasks):
    """Start downloading a model"""
    # Check if already downloading
    for download_id, progress in download_progress.items():
        if progress.get("model_id") == request.model_id and progress.get("status") in ["initializing", "downloading"]:
            return {"status": "already_downloading", "model_id": request.model_id}
    
    # Start download in background
    background_tasks.add_task(
        download_model_with_progress,
        request.model_id,
        request.quantization
    )
    
    return {"status": "started", "model_id": request.model_id}

@app.get("/api/v1/models/download-progress/{model_id:path}")
async def get_download_progress(model_id: str):
    """Get download progress for a model"""
    # Find progress for this model
    for download_id, progress in download_progress.items():
        if progress.get("model_id") == model_id:
            return progress
    
    return {"status": "not_found"}

@app.get("/api/v1/models")
async def get_models():
    """Get list of downloaded models"""
    models = []
    
    for model_id, model_info in model_registry["models"].items():
        models.append({
            "id": model_id,
            "name": model_id.split("/")[-1],
            "type": "Local",
            "size": model_info.get("size", "Unknown"),
            "last_used": model_info.get("last_used", "Never"),
            "active": model_info.get("active", False),
            "quantization": model_info.get("quantization", "Unknown"),
            "path": model_info.get("path", "")
        })
    
    return models

@app.delete("/api/v1/models/{model_id:path}")
async def delete_model(model_id: str):
    """Delete a model"""
    if model_id in model_registry["models"]:
        model_info = model_registry["models"][model_id]
        model_path = model_info.get("path", "")
        
        # Delete files
        if os.path.exists(model_path):
            shutil.rmtree(model_path)
        
        # Remove from registry
        del model_registry["models"][model_id]
        save_model_registry(model_registry)
        
        return {"status": "deleted", "model_id": model_id}
    
    raise HTTPException(status_code=404, detail="Model not found")

@app.post("/api/v1/models/active")
async def set_active_model(request: ActiveModel):
    """Set the active model and restart vLLM"""
    model_id = request.model_id
    
    if model_id not in model_registry["models"]:
        raise HTTPException(status_code=404, detail="Model not found")
    
    # Update registry
    for mid in model_registry["models"]:
        model_registry["models"][mid]["active"] = (mid == model_id)
    
    model_registry["active_model"] = model_id
    save_model_registry(model_registry)
    
    # Update vLLM configuration
    if docker_client:
        try:
            # Get vLLM container
            vllm_container = docker_client.containers.get("unicorn-vllm")
            
            # Update environment variable
            env_vars = vllm_container.attrs['Config']['Env']
            new_env = []
            
            for env in env_vars:
                if not env.startswith("MODEL="):
                    new_env.append(env)
            
            new_env.append(f"MODEL={model_id}")
            
            # Restart container with new model
            vllm_container.stop()
            vllm_container.remove()
            
            # Get original run config
            config = vllm_container.attrs
            
            # Start new container with updated model
            docker_client.containers.run(
                image=config['Config']['Image'],
                name="unicorn-vllm",
                environment=new_env,
                ports={"8000/tcp": 8000},
                volumes=config['Mounts'],
                detach=True,
                restart_policy={"Name": "unless-stopped"}
            )
            
            return {"status": "activated", "model_id": model_id}
        
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to switch model: {str(e)}")
    
    return {"status": "activated", "model_id": model_id, "note": "Docker not available, model marked as active"}

@app.put("/api/v1/models/{model_id:path}/config")
async def update_model_config(model_id: str, config: ModelConfig):
    """Update model-specific configuration"""
    if model_id not in model_registry["models"]:
        raise HTTPException(status_code=404, detail="Model not found")
    
    if config.retention is not None:
        model_registry["models"][model_id]["retention"] = config.retention
    
    if config.context_size is not None:
        model_registry["models"][model_id]["context_size"] = config.context_size
    
    save_model_registry(model_registry)
    
    return {"status": "updated", "model_id": model_id}

@app.get("/api/v1/models/settings")
async def get_model_settings():
    """Get global model settings"""
    return model_registry["global_settings"]

@app.put("/api/v1/models/settings")
async def update_model_settings(settings: GlobalModelSettings):
    """Update global model settings"""
    model_registry["global_settings"].update(settings.dict())
    save_model_registry(model_registry)
    
    return {"status": "updated"}

@app.post("/api/v1/models/upload")
async def upload_model(model: UploadFile = File(...)):
    """Upload a model file"""
    try:
        # Save to models directory
        if not os.path.exists(MODELS_DIR):
            os.makedirs(MODELS_DIR)
        
        file_path = os.path.join(MODELS_DIR, model.filename)
        
        # Save file
        async with aiofiles.open(file_path, 'wb') as f:
            content = await model.read()
            await f.write(content)
        
        # Add to registry
        model_id = f"local/{model.filename}"
        model_registry["models"][model_id] = {
            "id": model_id,
            "path": file_path,
            "uploaded_at": datetime.now().isoformat(),
            "size": get_directory_size(file_path),
            "active": False
        }
        save_model_registry(model_registry)
        
        return {"status": "uploaded", "model_id": model_id, "path": file_path}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# New AI Model Management endpoints
@app.get("/api/v1/models/settings/{backend}")
async def get_backend_settings(backend: str):
    """Get global settings for vLLM or Ollama"""
    if backend not in ["vllm", "ollama"]:
        raise HTTPException(status_code=400, detail="Invalid backend. Use 'vllm' or 'ollama'")
    
    return ai_model_manager.get_global_settings(backend)

@app.put("/api/v1/models/settings/{backend}")
async def update_backend_settings(backend: str, settings: Dict[str, Any]):
    """Update global settings for vLLM or Ollama"""
    if backend not in ["vllm", "ollama"]:
        raise HTTPException(status_code=400, detail="Invalid backend. Use 'vllm' or 'ollama'")
    
    updated = ai_model_manager.update_global_settings(backend, settings)
    return {"status": "updated", "settings": updated}

@app.get("/api/v1/models/{backend}/{model_id:path}/settings")
async def get_model_settings(backend: str, model_id: str):
    """Get effective settings for a specific model"""
    if backend not in ["vllm", "ollama"]:
        raise HTTPException(status_code=400, detail="Invalid backend")
    
    return ai_model_manager.get_model_settings(model_id, backend)

@app.post("/api/v1/models/settings")
async def update_model_settings(update: ModelSettingsUpdate):
    """Update model-specific settings overrides"""
    result = ai_model_manager.update_model_settings(
        update.model_id, 
        update.backend, 
        update.settings
    )
    return {"status": "updated", "settings": result}

@app.get("/api/v1/models/installed")
async def get_installed_models():
    """Get all installed models for both vLLM and Ollama"""
    models = await ai_model_manager.scan_local_models()
    return models

@app.post("/api/v1/models/download")
async def download_model(request: ModelDownloadRequest):
    """Download a model from Hugging Face or Ollama Hub"""
    try:
        if request.backend == "vllm":
            task_id = await ai_model_manager.download_vllm_model(
                request.model_id, 
                request.settings
            )
        elif request.backend == "ollama":
            task_id = await ai_model_manager.download_ollama_model(request.model_id)
        else:
            raise HTTPException(status_code=400, detail="Invalid backend")
        
        return {"status": "started", "task_id": task_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/models/downloads")
async def get_download_status():
    """Get status of all download tasks"""
    return ai_model_manager.get_all_downloads()

@app.get("/api/v1/models/downloads/{task_id}")
async def get_download_task_status(task_id: str):
    """Get status of a specific download task"""
    status = ai_model_manager.get_download_status(task_id)
    if not status:
        raise HTTPException(status_code=404, detail="Download task not found")
    return status

@app.post("/api/v1/models/{backend}/{model_id:path}/activate")
async def activate_model(backend: str, model_id: str):
    """Activate a model for use"""
    if backend == "vllm":
        result = await ai_model_manager.activate_vllm_model(model_id)
        return result
    elif backend == "ollama":
        # Ollama models are activated on demand
        return {"status": "ready", "model_id": model_id, "message": "Ollama models are activated on demand"}
    else:
        raise HTTPException(status_code=400, detail="Invalid backend")

@app.delete("/api/v1/models/{backend}/{model_id:path}")
async def delete_model_by_backend(backend: str, model_id: str):
    """Delete a model"""
    try:
        result = await ai_model_manager.delete_model(model_id, backend)
        return result
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Network management routes
@app.get("/api/v1/network/status")
async def get_network_status():
    """Get network status and interfaces"""
    try:
        network_status = {
            "ethernet": {"connected": False, "ip": None, "interface": None},
            "wifi": {"connected": False, "ssid": None, "signal": 0, "interface": None},
            "bluetooth": {"enabled": False, "devices": 0}
        }
        
        # Get network interfaces using Ubuntu Server native tools
        try:
            interfaces = network_manager.get_network_interfaces()
            
            # Process interfaces
            for ifname, info in interfaces.items():
                if info['type'] == 'ethernet' and info['state'] == 'UP':
                    ip_addr = None
                    if info['ip_addresses']:
                        ip_addr = info['ip_addresses'][0]['address']
                    
                    network_status["ethernet"] = {
                        "connected": True,
                        "ip": ip_addr,
                        "interface": ifname,
                        "ip_address": ip_addr,  # For compatibility
                        "speed": "1000"  # Default, could be detected
                    }
                elif info['type'] == 'wifi':
                    # Check for WiFi connection
                    wifi_conn = network_manager.get_current_wifi_connection()
                    if wifi_conn:
                        network_status["wifi"] = {
                            "connected": True,
                            "ssid": wifi_conn.get('ssid', ''),
                            "signal": wifi_conn.get('signal', 0),
                            "interface": wifi_conn['interface'],
                            "ip": wifi_conn['ip_addresses'][0]['address'] if wifi_conn['ip_addresses'] else None
                        }
        except Exception as e:
            print(f"Error getting network status: {e}")
        
        # Check Bluetooth status
        try:
            bt_result = subprocess.run(
                ["systemctl", "is-active", "bluetooth"],
                capture_output=True, text=True, timeout=5
            )
            network_status["bluetooth"]["enabled"] = (bt_result.returncode == 0 and bt_result.stdout.strip() == "active")
            
            if network_status["bluetooth"]["enabled"]:
                # Count paired devices
                bt_devices = subprocess.run(
                    ["bluetoothctl", "devices"],
                    capture_output=True, text=True, timeout=5
                )
                if bt_devices.returncode == 0:
                    network_status["bluetooth"]["devices"] = len(bt_devices.stdout.strip().split('\n'))
        except:
            pass
        
        return network_status
    except Exception as e:
        print(f"Network status error: {e}")
        # Return simulated data as fallback
        return {
            "ethernet": {"connected": True, "ip": "192.168.1.100", "interface": "eth0"},
            "wifi": {"connected": False, "ssid": None, "signal": 0},
            "bluetooth": {"enabled": True, "devices": 0}
        }

@app.get("/api/v1/network/wifi/scan")
async def scan_wifi():
    """Scan for WiFi networks"""
    try:
        networks = network_manager.get_wifi_networks()
        
        # Sort by signal strength
        networks.sort(key=lambda x: x.get('signal', 0), reverse=True)
        
        # Format for frontend compatibility
        formatted_networks = []
        for network in networks:
            formatted_networks.append({
                "ssid": network.get('ssid', 'Hidden Network'),
                "signal": network.get('signal', 0),
                "signal_strength": network.get('signal', 0),  # For compatibility
                "security": network.get('security', 'Open'),
                "bssid": network.get('bssid', ''),
                "frequency": network.get('frequency', 0)
            })
        
        return formatted_networks
    
    except Exception as e:
        print(f"WiFi scan error: {e}")
        # Return mock data as fallback
        return [
            {"ssid": "Network scan failed", "signal": 0, "security": "Unknown"},
        ]

@app.post("/api/v1/network/wifi/connect")
async def connect_wifi(request: dict):
    """Connect to a WiFi network"""
    ssid = request.get("ssid")
    password = request.get("password", "")
    
    if not ssid:
        raise HTTPException(status_code=400, detail="SSID is required")
    
    try:
        success = network_manager.connect_to_wifi(ssid, password)
        
        if success:
            return {"status": "connected", "message": f"Connected to {ssid}"}
        else:
            raise HTTPException(status_code=500, detail="Failed to connect to WiFi")
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/network/wifi/disconnect")
async def disconnect_wifi():
    """Disconnect from current WiFi network"""
    try:
        success = network_manager.disconnect_wifi()
        
        if success:
            return {"status": "disconnected", "message": "WiFi disconnected"}
        else:
            raise HTTPException(status_code=400, detail="No active WiFi connection")
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/network/configure")
async def configure_network(config: NetworkConfig):
    """Configure network interface (static IP, DHCP, etc.)"""
    try:
        interface = config.interface
        
        # Convert netmask to prefix length if needed
        prefix = 24  # Default
        if config.netmask:
            # Simple conversion for common netmasks
            netmask_to_prefix = {
                "255.255.255.0": 24,
                "255.255.0.0": 16,
                "255.0.0.0": 8,
                "255.255.255.128": 25,
                "255.255.255.192": 26,
                "255.255.255.224": 27,
                "255.255.255.240": 28,
                "255.255.255.248": 29,
                "255.255.255.252": 30
            }
            prefix = netmask_to_prefix.get(config.netmask, 24)
        
        # Prepare configuration
        net_config = {
            "method": config.method,
            "address": config.address,
            "prefix": prefix,
            "gateway": config.gateway,
            "dns": config.dns
        }
        
        success = network_manager.update_interface_config(interface, net_config)
        
        if success:
            return {"status": "configured", "message": f"Interface {interface} configured successfully"}
        else:
            raise HTTPException(status_code=500, detail="Failed to configure network interface")
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/v1/network/wifi/forget/{ssid}")
async def forget_wifi_network(ssid: str):
    """Forget a saved WiFi network"""
    try:
        result = subprocess.run(
            ["nmcli", "connection", "delete", ssid],
            capture_output=True, text=True
        )
        
        if result.returncode == 0:
            return {"status": "forgotten", "message": f"Network {ssid} forgotten"}
        else:
            raise HTTPException(status_code=404, detail="Network not found")
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Settings routes
@app.get("/api/v1/settings")
async def get_settings():
    """Get system settings"""
    return {
        "system": {
            "idle_timeout": 300,
            "auto_swap_enabled": True,
            "max_memory_percent": 95,
            "log_level": "info"
        },
        "notifications": {
            "email_enabled": False,
            "email_address": "",
            "webhook_enabled": False,
            "webhook_url": "",
            "alert_on_errors": True,
            "alert_on_updates": False
        },
        "security": {
            "auth_enabled": True,
            "session_timeout": 3600,
            "api_keys": []
        },
        "backup": {
            "auto_backup_enabled": True,
            "backup_schedule": "0 2 * * *",
            "retention_days": 7,
            "backup_location": "/backups"
        }
    }

@app.put("/api/v1/settings")
async def update_settings(settings: SystemSettings):
    """Update system settings"""
    # Save settings (mock for now)
    return {"status": "updated"}

# Extension management
EXTENSIONS_DIR = "/home/ucadmin/UC-1-Pro/extensions"

@app.get("/api/v1/extensions")
async def get_extensions():
    """Get list of installed extensions with full metadata"""
    extensions = []
    ext_dir = Path('/home/ucadmin/UC-1-Pro/extensions')
    
    if ext_dir.exists():
        for item in ext_dir.iterdir():
            if item.is_dir() and (item / 'docker-compose.yml').exists():
                # Read description from README
                description = ''
                readme = item / 'README.md'
                if readme.exists():
                    try:
                        with open(readme, 'r') as f:
                            lines = f.readlines()
                            if len(lines) > 2:
                                description = lines[2].strip() if lines[2].strip() else lines[0].strip().replace('#', '').strip()
                    except:
                        pass
                
                # Check if running
                status = 'stopped'
                try:
                    result = subprocess.run(
                        ['docker', 'ps', '--filter', f'name={item.name}', '--format', '{{.Names}}'],
                        capture_output=True,
                        text=True
                    )
                    if result.returncode == 0 and result.stdout.strip():
                        status = 'running'
                except:
                    pass
                
                # Get friendly name
                name_map = {
                    'bolt.diy': 'Bolt.DIY',
                    'comfyui': 'ComfyUI',
                    'dev-tools': 'Development Tools',
                    'monitoring': 'Grafana Monitoring',
                    'n8n': 'n8n Workflows',
                    'ollama': 'Ollama',
                    'portainer': 'Portainer CE',
                    'traefik': 'Traefik Proxy'
                }
                
                extensions.append({
                    'id': item.name,
                    'name': name_map.get(item.name, item.name.replace('-', ' ').title()),
                    'description': description or f'{item.name} extension',
                    'status': status,
                    'category': _determine_extension_category(item.name)
                })
    
    return {"extensions": extensions}

def _determine_extension_category(name: str) -> str:
    """Determine category based on extension name"""
    categories = {
        'monitoring': 'Monitoring',
        'grafana': 'Monitoring',
        'prometheus': 'Monitoring',
        'comfyui': 'AI Tools',
        'ollama': 'AI Tools',
        'stable-diffusion': 'AI Tools',
        'portainer': 'Management',
        'traefik': 'Networking',
        'n8n': 'Automation',
        'dev-tools': 'Development',
        'code-server': 'Development',
        'bolt': 'Development'
    }
    
    name_lower = name.lower()
    for key, category in categories.items():
        if key in name_lower:
            return category
    return 'Other'

@app.post("/api/v1/extensions/{extension_id}/start")
async def start_extension(extension_id: str):
    """Start an extension"""
    ext_path = os.path.join(EXTENSIONS_DIR, extension_id)
    if not os.path.exists(ext_path):
        raise HTTPException(status_code=404, detail="Extension not found")
    
    try:
        # Run docker-compose up for the extension
        result = subprocess.run(
            ["docker", "compose", "up", "-d"],
            cwd=ext_path,
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            return {"status": "started", "extension": extension_id}
        else:
            raise HTTPException(status_code=500, detail=result.stderr)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/extensions/{extension_id}/stop")
async def stop_extension(extension_id: str):
    """Stop an extension"""
    ext_path = os.path.join(EXTENSIONS_DIR, extension_id)
    if not os.path.exists(ext_path):
        raise HTTPException(status_code=404, detail="Extension not found")
    
    try:
        # Run docker-compose down for the extension
        result = subprocess.run(
            ["docker", "compose", "down"],
            cwd=ext_path,
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            return {"status": "stopped", "extension": extension_id}
        else:
            raise HTTPException(status_code=500, detail=result.stderr)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Storage & Backup Management Routes

@app.get("/api/v1/storage", response_model=StorageInfo)
async def get_storage_info():
    """Get comprehensive storage information"""
    try:
        return storage_backup_manager.get_storage_info()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/storage/volumes/{volume_name}")  
async def get_volume_details(volume_name: str):
    """Get detailed information about a specific volume"""
    try:
        details = storage_backup_manager.get_volume_details(volume_name)
        if not details:
            raise HTTPException(status_code=404, detail="Volume not found")
        return details
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/backup/status", response_model=BackupStatus)
async def get_backup_status():
    """Get backup status and history"""
    try:
        return storage_backup_manager.get_backup_status()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/backup/create")
async def create_backup(background_tasks: BackgroundTasks, backup_type: str = "manual"):
    """Create a new backup"""
    try:
        backup_id = await storage_backup_manager.create_backup(backup_type)
        return {"status": "created", "backup_id": backup_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/backup/{backup_id}/restore")
async def restore_backup(backup_id: str, restore_path: Optional[str] = None):
    """Restore from a backup"""
    try:
        success = await storage_backup_manager.restore_backup(backup_id, restore_path)
        if success:
            return {"status": "restored", "backup_id": backup_id, "restore_path": restore_path}
        else:
            raise HTTPException(status_code=500, detail="Restore failed")
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/v1/backup/{backup_id}")
async def delete_backup(backup_id: str):
    """Delete a backup"""
    try:
        success = storage_backup_manager.delete_backup(backup_id)
        if success:
            return {"status": "deleted", "backup_id": backup_id}
        else:
            raise HTTPException(status_code=500, detail="Delete failed")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/v1/backup/config", response_model=BackupConfig)
async def update_backup_config(config: Dict[str, Any]):
    """Update backup configuration"""
    try:
        updated_config = storage_backup_manager.update_backup_config(config)
        return updated_config
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/backup/config", response_model=BackupConfig)
async def get_backup_config():
    """Get current backup configuration"""
    try:
        return storage_backup_manager.backup_config
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Extension Management endpoints
# Commented out - using direct implementation above
# @app.get("/api/v1/extensions")
# async def get_extensions():
#     """Get list of installed extensions"""
#     try:
#         extensions = extension_manager.get_installed_extensions()
#         return {"extensions": [ext.dict() for ext in extensions]}
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/extensions/install")
async def install_extension(request: ExtensionInstallRequest):
    """Install a new extension"""
    try:
        result = await extension_manager.install_extension(request)
        if result["success"]:
            return result
        else:
            raise HTTPException(status_code=400, detail=result["error"])
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/v1/extensions/{extension_id}")
async def uninstall_extension(extension_id: str):
    """Uninstall an extension"""
    try:
        result = await extension_manager.uninstall_extension(extension_id)
        if result["success"]:
            return result
        else:
            raise HTTPException(status_code=400, detail=result["error"])
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/extensions/{extension_id}/control")
async def control_extension(extension_id: str, request: ExtensionActionRequest):
    """Control an extension (start, stop, restart)"""
    try:
        result = await extension_manager.control_extension(extension_id, request.action)
        if result["success"]:
            return result
        else:
            raise HTTPException(status_code=400, detail=result["error"])
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/v1/extensions/{extension_id}/config")
async def update_extension_config(extension_id: str, config_update: ExtensionConfigUpdate):
    """Update extension configuration"""
    try:
        result = extension_manager.update_extension_config(extension_id, config_update)
        if result["success"]:
            return result
        else:
            raise HTTPException(status_code=400, detail=result["error"])
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/extensions/{extension_id}/logs")
async def get_extension_logs(extension_id: str, lines: int = 100):
    """Get extension logs"""
    try:
        result = extension_manager.get_extension_logs(extension_id, lines)
        if result["success"]:
            return result
        else:
            raise HTTPException(status_code=400, detail=result["error"])
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Log Management endpoints
@app.get("/api/v1/logs/sources")
async def get_log_sources():
    """Get available log sources"""
    try:
        sources = await log_manager.get_log_sources()
        return {"sources": sources}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/logs/stats")
async def get_log_stats():
    """Get log statistics"""
    try:
        stats = await log_manager.get_log_stats()
        return stats
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/logs/search")
async def search_logs(filters: LogFilter):
    """Search logs based on filters"""
    try:
        logs = await log_manager.search_logs(filters)
        return {"logs": [log.dict() for log in logs], "count": len(logs)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/logs/export")
async def export_logs(request: LogExportRequest):
    """Export logs to file"""
    try:
        result = await log_manager.export_logs(request)
        if result["success"]:
            return result
        else:
            raise HTTPException(status_code=400, detail=result["error"])
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# WebSocket endpoint for log streaming
@app.websocket("/ws/logs/{source_id}")
async def websocket_log_stream(websocket: WebSocket, source_id: str):
    """Stream logs via WebSocket"""
    await websocket.accept()
    
    try:
        # Parse filters from query params
        filters = None
        if websocket.query_params:
            filter_dict = {}
            if "levels" in websocket.query_params:
                filter_dict["levels"] = websocket.query_params["levels"].split(",")
            if "search" in websocket.query_params:
                filter_dict["search"] = websocket.query_params["search"]
            if filter_dict:
                filters = LogFilter(**filter_dict)
        
        # Stream logs
        async for log_line in log_manager.stream_logs(source_id, filters):
            await websocket.send_text(log_line)
            
    except WebSocketDisconnect:
        print(f"WebSocket disconnected for log source: {source_id}")
    except Exception as e:
        print(f"Error in log streaming: {e}")
        await websocket.close()

# Authentication endpoints
security = HTTPBearer()

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Get current user from JWT token"""
    token = credentials.credentials
    user_info = auth_manager.verify_token(token)
    
    if not user_info:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    
    return user_info

async def require_admin(current_user: dict = Depends(get_current_user)):
    """Require admin role"""
    if current_user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    return current_user

@app.post("/api/v1/auth/login")
async def login(credentials: LoginCredentials, request: Request):
    """Login and get access token"""
    try:
        # Get request info
        request_info = {
            "ip_address": request.client.host if request.client else "unknown",
            "user_agent": request.headers.get("user-agent", "unknown")
        }
        
        token = await auth_manager.login(credentials, request_info)
        return token
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/auth/logout")
async def logout(current_user: dict = Depends(get_current_user)):
    """Logout and invalidate session"""
    try:
        auth_manager.logout(current_user.get("session_id"))
        return {"message": "Logged out successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/auth/me")
async def get_me(current_user: dict = Depends(get_current_user)):
    """Get current user info"""
    try:
        user = auth_manager.get_user(current_user["user_id"])
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return user
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# User Management endpoints (admin only)
@app.get("/api/v1/users")
async def get_users(current_user: dict = Depends(require_admin)):
    """Get all users (admin only)"""
    try:
        users = auth_manager.get_users()
        return {"users": users}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/users")
async def create_user(user_create: UserCreate, current_user: dict = Depends(require_admin)):
    """Create a new user (admin only)"""
    try:
        user = auth_manager.create_user(user_create)
        return user
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/users/{user_id}")
async def get_user(user_id: str, current_user: dict = Depends(require_admin)):
    """Get user by ID (admin only)"""
    try:
        user = auth_manager.get_user(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return user
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/v1/users/{user_id}")
async def update_user(user_id: str, user_update: UserUpdate, current_user: dict = Depends(require_admin)):
    """Update user (admin only)"""
    try:
        user = auth_manager.update_user(user_id, user_update)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return user
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/v1/users/{user_id}")
async def delete_user(user_id: str, current_user: dict = Depends(require_admin)):
    """Delete user (admin only)"""
    try:
        # Prevent self-deletion
        if user_id == current_user["user_id"]:
            raise HTTPException(status_code=400, detail="Cannot delete your own account")
        
        success = auth_manager.delete_user(user_id)
        if not success:
            raise HTTPException(status_code=404, detail="User not found")
        return {"message": "User deleted successfully"}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Password Management
@app.post("/api/v1/auth/change-password")
async def change_password(password_change: PasswordChange, current_user: dict = Depends(get_current_user)):
    """Change current user's password"""
    try:
        success = auth_manager.change_password(current_user["user_id"], password_change)
        if not success:
            raise HTTPException(status_code=400, detail="Invalid current password")
        return {"message": "Password changed successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# API Key Management
@app.get("/api/v1/api-keys")
async def get_api_keys(current_user: dict = Depends(get_current_user)):
    """Get current user's API keys"""
    try:
        keys = auth_manager.get_user_api_keys(current_user["user_id"])
        return {"api_keys": keys}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/api-keys")
async def create_api_key(key_create: APIKeyCreate, current_user: dict = Depends(get_current_user)):
    """Create a new API key"""
    try:
        api_key = auth_manager.create_api_key(current_user["user_id"], key_create)
        return api_key
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/v1/api-keys/{key_id}")
async def delete_api_key(key_id: str, current_user: dict = Depends(get_current_user)):
    """Delete an API key"""
    try:
        success = auth_manager.delete_api_key(key_id, current_user["user_id"])
        if not success:
            raise HTTPException(status_code=404, detail="API key not found")
        return {"message": "API key deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Authentik SSO User Management
if AUTHENTIK_ENABLED:
    @app.get("/api/v1/sso/users")
    async def get_sso_users(current_user: dict = Depends(require_admin)):
        """Get all users from Authentik (admin only)"""
        users = await authentik_integration.get_users()
        return {"users": users}
    
    @app.post("/api/v1/sso/users")
    async def create_sso_user(user: AuthentikUserCreate, current_user: dict = Depends(require_admin)):
        """Create a new user in Authentik (admin only)"""
        created_user = await authentik_integration.create_user(user)
        if not created_user:
            raise HTTPException(status_code=400, detail="Failed to create user")
        return created_user
    
    @app.put("/api/v1/sso/users/{user_id}")
    async def update_sso_user(user_id: str, update: AuthentikUserUpdate, current_user: dict = Depends(require_admin)):
        """Update a user in Authentik (admin only)"""
        updated_user = await authentik_integration.update_user(user_id, update)
        if not updated_user:
            raise HTTPException(status_code=404, detail="User not found")
        return updated_user
    
    @app.delete("/api/v1/sso/users/{user_id}")
    async def delete_sso_user(user_id: str, current_user: dict = Depends(require_admin)):
        """Delete a user from Authentik (admin only)"""
        success = await authentik_integration.delete_user(user_id)
        if not success:
            raise HTTPException(status_code=404, detail="User not found")
        return {"message": "User deleted successfully"}
    
    @app.post("/api/v1/sso/users/{user_id}/set-password")
    async def set_sso_user_password(user_id: str, reset: AuthentikPasswordReset, current_user: dict = Depends(require_admin)):
        """Set a user's password in Authentik (admin only)"""
        success = await authentik_integration.set_user_password(user_id, reset.password)
        if not success:
            raise HTTPException(status_code=400, detail="Failed to set password")
        return {"message": "Password set successfully"}
    
    @app.get("/api/v1/sso/groups")
    async def get_sso_groups(current_user: dict = Depends(require_admin)):
        """Get all groups from Authentik (admin only)"""
        groups = await authentik_integration.get_groups()
        return {"groups": groups}
    
    @app.post("/api/v1/sso/groups")
    async def create_sso_group(name: str, is_superuser: bool = False, current_user: dict = Depends(require_admin)):
        """Create a new group in Authentik (admin only)"""
        group = await authentik_integration.create_group(name, is_superuser)
        if not group:
            raise HTTPException(status_code=400, detail="Failed to create group")
        return group
    
    @app.post("/api/v1/sso/users/{user_id}/groups/{group_id}")
    async def add_user_to_group(user_id: str, group_id: str, current_user: dict = Depends(require_admin)):
        """Add a user to a group in Authentik (admin only)"""
        success = await authentik_integration.add_user_to_group(user_id, group_id)
        if not success:
            raise HTTPException(status_code=400, detail="Failed to add user to group")
        return {"message": "User added to group successfully"}
    
    @app.get("/api/v1/sso/stats")
    async def get_sso_stats(current_user: dict = Depends(get_current_user)):
        """Get SSO user statistics"""
        stats = await authentik_integration.get_user_stats()
        return stats

# Session Management
@app.get("/api/v1/sessions")
async def get_sessions(current_user: dict = Depends(get_current_user)):
    """Get current user's sessions"""
    try:
        sessions = auth_manager.get_user_sessions(current_user["user_id"])
        return {"sessions": sessions}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/v1/sessions/{session_id}")
async def revoke_session(session_id: str, current_user: dict = Depends(get_current_user)):
    """Revoke a session"""
    try:
        success = auth_manager.revoke_session(session_id, current_user["user_id"])
        if not success:
            raise HTTPException(status_code=404, detail="Session not found")
        return {"message": "Session revoked successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Update Management endpoints
@app.get("/api/v1/updates/status")
async def get_update_status():
    """Get current update status"""
    try:
        return github_update_manager.get_update_status()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/updates/check")
async def check_for_updates():
    """Check for available updates"""
    try:
        result = await github_update_manager.check_for_updates()
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/updates/apply")
async def apply_update(backup_first: bool = True):
    """Apply available updates"""
    try:
        result = await github_update_manager.apply_update(backup_first)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/updates/changelog")
async def get_changelog(limit: int = 10):
    """Get recent changelog entries"""
    try:
        changelog = await github_update_manager.get_changelog(limit)
        return {"changelog": changelog}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Direct login endpoint
@app.post("/auth/direct-login")
async def direct_login(request: Request, credentials: dict):
    """Direct authentication with Authentik"""
    username = credentials.get("username")
    password = credentials.get("password")
    
    if not username or not password:
        raise HTTPException(status_code=400, detail="Username and password required")
    
    # Authenticate against Authentik
    async with httpx.AsyncClient() as client:
        # Try to authenticate using Authentik's password flow
        auth_url = "https://auth.yoda.magicunicorn.tech" if "yoda.magicunicorn.tech" in str(request.url) else f"{AUTHENTIK_URL}"
        
        # Use OAuth password grant
        token_url = f"{auth_url}/application/o/token/"
        data = {
            "grant_type": "password",
            "username": username,
            "password": password,
            "client_id": OAUTH_CLIENT_ID,
            "client_secret": OAUTH_CLIENT_SECRET,
            "scope": "openid profile email"
        }
        
        try:
            response = await client.post(token_url, data=data)
            
            if response.status_code == 200:
                tokens = response.json()
                access_token = tokens.get("access_token")
                
                # Get user info
                userinfo_url = f"{auth_url}/application/o/userinfo/"
                headers = {"Authorization": f"Bearer {access_token}"}
                user_response = await client.get(userinfo_url, headers=headers)
                
                if user_response.status_code == 200:
                    user_info = user_response.json()
                    
                    # Create session
                    session_token = base64.urlsafe_b64encode(secrets.token_bytes(32)).decode('utf-8')
                    sessions[session_token] = {
                        "user": user_info,
                        "access_token": access_token,
                        "created": time.time()
                    }
                    
                    # Create response with session cookie
                    response = JSONResponse({"success": True, "user": user_info})
                    response.set_cookie(
                        key="session_token",
                        value=session_token,
                        httponly=True,
                        secure=("https" in str(request.url)),
                        samesite="lax",
                        max_age=86400  # 24 hours
                    )
                    return response
            else:
                # Authentication failed
                return JSONResponse(
                    {"success": False, "detail": "Invalid username or password"},
                    status_code=401
                )
                
        except Exception as e:
            print(f"Direct login error: {e}")
            return JSONResponse(
                {"success": False, "detail": "Authentication service unavailable"},
                status_code=503
            )

# OAuth endpoints
@app.get("/auth/login")
async def oauth_login(request: Request):
    """Redirect to Authentik OAuth authorization"""
    state = secrets.token_urlsafe(32)
    sessions[state] = {"created": time.time()}
    
    # Build redirect URI based on the request host
    if "yoda.magicunicorn.tech" in str(request.url):
        redirect_uri = "https://yoda.magicunicorn.tech/auth/callback"
        auth_base = "https://auth.yoda.magicunicorn.tech"
    else:
        # Use the external host from environment
        redirect_uri = f"https://{EXTERNAL_HOST}/auth/callback"
        auth_base = f"https://auth.{EXTERNAL_HOST}"
    
    auth_url = (
        f"{auth_base}/application/o/authorize/"
        f"?client_id={OAUTH_CLIENT_ID}"
        f"&redirect_uri={redirect_uri}"
        f"&response_type=code"
        f"&scope=openid%20profile%20email"
        f"&state={state}"
    )
    return RedirectResponse(url=auth_url)

@app.get("/auth/callback")
async def oauth_callback(request: Request, code: str, state: str = None):
    """Handle OAuth callback from Authentik"""
    # Log immediately to file to debug
    with open("/tmp/oauth_debug.log", "a") as f:
        f.write(f"=== OAuth callback at {datetime.now()} ===\n")
        f.write(f"Code: {code[:10] if code else 'None'}...\n")
        f.write(f"State: {state}\n")
        f.write(f"URL: {request.url}\n")
        f.write(f"Client ID: {OAUTH_CLIENT_ID}\n")
        f.write(f"Client Secret exists: {bool(OAUTH_CLIENT_SECRET)}\n")
    
    # Build correct redirect URI based on the request
    if "yoda.magicunicorn.tech" in str(request.url):
        redirect_uri = "https://yoda.magicunicorn.tech/auth/callback"
        token_url = "https://auth.yoda.magicunicorn.tech/application/o/token/"
    else:
        redirect_uri = f"https://{EXTERNAL_HOST}/auth/callback"
        token_url = f"https://auth.{EXTERNAL_HOST}/application/o/token/"
    
    # Exchange code for token
    async with httpx.AsyncClient() as client:
        data = {
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirect_uri,
            "client_id": OAUTH_CLIENT_ID,
            "client_secret": OAUTH_CLIENT_SECRET
        }
        
        try:
            print(f"Starting token exchange to: {token_url}")
            print(f"With data: client_id={OAUTH_CLIENT_ID}, code={code[:10]}...")
            response = await client.post(token_url, data=data)
            print(f"Token exchange response: {response.status_code}")
            
            if response.status_code == 200:
                try:
                    tokens = response.json()
                    access_token = tokens.get("access_token")
                    print(f"Got access token: {access_token[:20] if access_token else 'None'}...")
                    
                    if not access_token:
                        print(f"No access token in response: {tokens}")
                        return RedirectResponse(url="/?error=no_access_token")
                except Exception as e:
                    print(f"Failed to parse token response: {e}")
                    print(f"Response text: {response.text}")
                    return RedirectResponse(url="/?error=token_parse_error")
                
                # Get user info
                if "yoda.magicunicorn.tech" in str(request.url):
                    userinfo_url = "https://auth.yoda.magicunicorn.tech/application/o/userinfo/"
                else:
                    userinfo_url = f"{AUTHENTIK_URL}/application/o/userinfo/"
                
                print(f"Getting user info from: {userinfo_url}")
                headers = {"Authorization": f"Bearer {access_token}"}
                user_response = await client.get(userinfo_url, headers=headers)
                print(f"User info response: {user_response.status_code}")
                
                if user_response.status_code == 200:
                    user_info = user_response.json()
                    print(f"User info retrieved: {user_info.get('username', 'unknown')}")
                    
                    # Create session
                    session_token = secrets.token_urlsafe(32)
                    sessions[session_token] = {
                        "user": user_info,
                        "access_token": access_token,
                        "created": time.time()
                    }
                    print(f"Session created with token: {session_token[:10]}...")
                    print(f"Total sessions: {len(sessions)}")
                    
                    # Redirect to root (public ops center) with session token
                    response = RedirectResponse(url="/")
                    
                    # Set cookie with domain for subdomain access if using magicunicorn.tech
                    cookie_kwargs = {
                        "key": "session_token",
                        "value": session_token,
                        "path": "/",  # Ensure cookie is available for all paths
                        "httponly": True,
                        "secure": (EXTERNAL_PROTOCOL == "https"),
                        "samesite": "lax",
                        "max_age": 86400  # 24 hours
                    }
                    
                    # If using subdomain, set domain to allow cookie sharing
                    if "magicunicorn.tech" in EXTERNAL_HOST:
                        # Set domain to parent domain for subdomain sharing
                        cookie_kwargs["domain"] = ".yoda.magicunicorn.tech"
                    
                    response.set_cookie(**cookie_kwargs)
                    print(f"Redirecting to / with session cookie")
                    return response
                else:
                    print(f"Failed to get user info: {user_response.status_code}")
                    print(f"User info error: {user_response.text}")
            else:
                print(f"Token exchange failed: {response.status_code}")
                print(f"Token error: {response.text}")
        except Exception as e:
            print(f"OAuth error: {e}")
            import traceback
            traceback.print_exc()
    
    # On error, redirect back to root which will restart auth flow
    return RedirectResponse(url="/?error=authentication_failed")

@app.get("/auth/logout")
async def logout(request: Request):
    """Logout and clear session"""
    session_token = request.cookies.get("session_token")
    if session_token and session_token in sessions:
        del sessions[session_token]
    
    # Redirect to root, which will trigger auth flow again
    response = RedirectResponse(url="/")
    response.delete_cookie("session_token")
    return response

@app.get("/auth/user")
async def get_current_user(request: Request):
    """Get current authenticated user info"""
    session_token = request.cookies.get("session_token")
    print(f"Auth check - Token from cookie: {session_token[:10] if session_token else 'None'}...")
    print(f"Auth check - Sessions count: {len(sessions)}")
    
    if not session_token or session_token not in sessions:
        print(f"Auth check - Token not found in sessions")
        raise HTTPException(status_code=401, detail="Not authenticated")
    
    session = sessions[session_token]
    print(f"Auth check - User: {session['user'].get('username', 'unknown')}")
    return {"user": session["user"]}

@app.get("/auth/check")
async def check_auth(request: Request):
    """Check authentication for Traefik ForwardAuth"""
    session_token = request.cookies.get("session_token")
    if not session_token or session_token not in sessions:
        # Return 401 to trigger redirect to login
        raise HTTPException(status_code=401, detail="Authentication required")
    
    # Return 200 to allow access
    return {"authenticated": True}

@app.get("/api/v1/auth/session")
async def get_session_info(request: Request):
    """Bridge OAuth session to React app"""
    print(f"Session endpoint called. Cookies: {request.cookies}")
    session_token = request.cookies.get("session_token")
    print(f"Session token from cookie: {session_token[:10] if session_token else 'None'}...")
    print(f"Available sessions: {len(sessions)}")
    
    if session_token and session_token in sessions:
        session = sessions[session_token]
        user_info = session.get("user", {})
        
        # Generate a token for the React app to use
        import json
        import base64
        token_data = {
            "username": user_info.get("username", user_info.get("preferred_username", "user")),
            "role": "admin",
            "auth_method": "oauth"
        }
        # Simple token for React app (not secure, just for session bridging)
        token = base64.b64encode(json.dumps(token_data).encode()).decode()
        
        return {
            "authenticated": True,
            "token": token,
            "user": {
                "username": user_info.get("username", user_info.get("preferred_username", "user")),
                "email": user_info.get("email", ""),
                "name": user_info.get("name", ""),
                "role": "admin"
            }
        }
    
    # No valid session found
    print(f"No valid session found. Token exists: {bool(session_token)}, In sessions: {session_token in sessions if session_token else False}")
    return JSONResponse(
        status_code=401,
        content={"authenticated": False, "detail": "No valid session"}
    )


# Login page endpoint - now just redirects to OAuth
@app.get("/login.html")
async def serve_login():
    """Redirect to OAuth login flow"""
    return RedirectResponse(url="/auth/login")

# Serve the React app for admin routes
@app.get("/admin")
@app.get("/admin/{path:path}")
async def serve_admin(request: Request, path: str = ""):
    """Serve the React admin app for all /admin routes"""
    # Check if user is authenticated via session cookie
    session_token = request.cookies.get("session_token")
    
    # If authenticated via OAuth, create a bridge to the React app
    if session_token and session_token in sessions:
        # User is authenticated, serve the admin page
        # The React app will need to call /api/v1/auth/me to get user info
        if os.path.exists("dist/index.html"):
            return FileResponse("dist/index.html")
        elif os.path.exists("../dist/index.html"):
            return FileResponse("../dist/index.html")
    else:
        # Not authenticated, redirect to OAuth login
        return RedirectResponse(url="/auth/login", status_code=302)
    
    raise HTTPException(status_code=404, detail="Admin interface not found")

# Serve the React app for all non-API routes
@app.get("/{full_path:path}")
async def serve_spa(full_path: str, request: Request):
    """Serve the React app for all routes"""
    # Skip empty path as it's handled by the root redirect
    if full_path == "":
        print("Catch-all got empty path, this shouldn't happen")
        return RedirectResponse(url="/login.html", status_code=302)
    
    # Check if requesting a static file
    if full_path.startswith("assets/") or full_path.endswith((".js", ".css", ".png", ".jpg", ".svg", ".ico")):
        file_path = os.path.join("dist", full_path)
        if os.path.exists(file_path):
            return FileResponse(file_path)
    
    # For all other routes, return the index.html (for React Router)
    index_path = "dist/index.html"
    if os.path.exists(index_path):
        return FileResponse(index_path)
    else:
        raise HTTPException(status_code=404, detail="Frontend not found")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8084)