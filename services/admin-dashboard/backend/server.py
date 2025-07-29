from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect, BackgroundTasks, Depends, Request, Header
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, StreamingResponse
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
from network_manager import network_manager
from ai_model_manager import ai_model_manager, ModelSettingsUpdate, ModelDownloadRequest
from storage_manager import storage_backup_manager, StorageInfo, BackupConfig, BackupInfo, BackupStatus
from extension_manager import extension_manager, ExtensionInstallRequest, ExtensionActionRequest, ExtensionConfigUpdate
from log_manager import log_manager, LogFilter, LogExportRequest
from auth_manager import auth_manager, UserCreate, UserUpdate, PasswordChange, LoginCredentials, APIKeyCreate

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
    
    # Get available GPU memory
    try:
        gpus = GPUtil.getGPUs()
        if gpus:
            available_memory_gb = gpus[0].memoryFree / 1024
            total_gpu_memory_gb = gpus[0].memoryTotal / 1024
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
    """Get current system resource usage"""
    try:
        # CPU info
        cpu_percent = psutil.cpu_percent(interval=1)
        cpu_percent_per_core = psutil.cpu_percent(interval=1, percpu=True)
        cpu_count = psutil.cpu_count()
        
        # Memory info
        memory = psutil.virtual_memory()
        
        # Disk info
        disk = psutil.disk_usage('/')
        
        # GPU info (if available)
        gpu_info = []
        try:
            gpus = GPUtil.getGPUs()
            for gpu in gpus:
                gpu_info.append({
                    "name": gpu.name,
                    "utilization": round(gpu.load * 100, 1),
                    "memory_used": int(gpu.memoryUsed * 1024 * 1024),  # Convert to bytes
                    "memory_total": int(gpu.memoryTotal * 1024 * 1024),  # Convert to bytes
                    "temperature": gpu.temperature,
                    "power_draw": getattr(gpu, 'powerDraw', 0),
                    "power_limit": getattr(gpu, 'powerLimit', 0)
                })
        except Exception as e:
            print(f"GPU info error: {e}")
            # Add mock GPU data for development
            if os.environ.get('DEVELOPMENT', 'false').lower() == 'true':
                gpu_info.append({
                    "name": "NVIDIA GeForce RTX 5090 (Mock)",
                    "utilization": 45.5,
                    "memory_used": 8589934592,  # 8GB
                    "memory_total": 34359738368,  # 32GB
                    "temperature": 65,
                    "power_draw": 250,
                    "power_limit": 450
                })
        
        # Get CPU frequency
        cpu_freq = psutil.cpu_freq()
        
        # Get load average
        load_avg = os.getloadavg()
        
        # Get uptime
        boot_time = psutil.boot_time()
        uptime = int(time.time() - boot_time)
        
        # Get top processes
        processes = []
        try:
            for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_info', 'status']):
                try:
                    pinfo = proc.info
                    processes.append({
                        'pid': pinfo['pid'],
                        'name': pinfo['name'],
                        'cpu_percent': pinfo['cpu_percent'] or 0,
                        'memory_mb': pinfo['memory_info'].rss / (1024 * 1024) if pinfo['memory_info'] else 0,
                        'status': pinfo['status']
                    })
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    pass
            
            # Sort by CPU usage and take top 10
            processes.sort(key=lambda x: x['cpu_percent'], reverse=True)
            processes = processes[:10]
        except Exception as e:
            print(f"Error getting processes: {e}")
        
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
            "processes": processes
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/services")
async def list_services():
    """List all services with their status"""
    services = []
    
    # Use Docker service manager to discover all services
    try:
        all_services = docker_manager.discover_all_services()
        
        # Process core services
        for service in all_services.get('core', []):
            services.append({
                "name": service['name'],
                "display_name": service['display_name'],
                "status": service['status'],
                "port": service['ports'][0]['host'] if service['ports'] else None,
                "description": f"Core service: {service['name']}",
                "cpu_percent": service['stats']['cpu_percent'] if service['stats'] else 0,
                "memory_mb": service['stats']['memory_usage_mb'] if service['stats'] else 0,
                "uptime": None,  # TODO: Calculate from container start time
                "category": "core",
                "container_name": service['container_name'],
                "gpu_enabled": service['gpu_enabled'],
                "image": service['image']
            })
        
        # Process extension services
        for ext_name, ext_services in all_services.get('extensions', {}).items():
            for service in ext_services:
                services.append({
                    "name": service['name'],
                    "display_name": f"{service['display_name']} ({ext_name})",
                    "status": service['status'],
                    "port": service['ports'][0]['host'] if service['ports'] else None,
                    "description": f"Extension ({ext_name}): {service['name']}",
                    "cpu_percent": service['stats']['cpu_percent'] if service['stats'] else 0,
                    "memory_mb": service['stats']['memory_usage_mb'] if service['stats'] else 0,
                    "uptime": None,  # TODO: Calculate from container start time
                    "category": "extension",
                    "extension": ext_name,
                    "container_name": service['container_name'],
                    "gpu_enabled": service['gpu_enabled'],
                    "image": service['image']
                })
    
    except Exception as e:
        print(f"Error listing services: {e}")
        # Fall back to development mode if needed
        if os.environ.get('DEVELOPMENT', 'false').lower() == 'true':
            # Return mock services for development
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

@app.post("/api/v1/services/{container_name}/action")
async def service_action(container_name: str, action: ServiceAction):
    """Perform action on a service"""
    
    # Use Docker service manager to control the service
    result = docker_manager.control_service(container_name, action.action)
    
    if result["success"]:
        return {"status": "success", "action": action.action, "service": container_name, "message": result.get("message", "")}
    else:
        raise HTTPException(status_code=500, detail=result.get("error", "Unknown error"))

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
    """Get list of available extensions"""
    extensions = []
    
    # Check extensions directory
    if os.path.exists(EXTENSIONS_DIR):
        for ext_name in os.listdir(EXTENSIONS_DIR):
            ext_path = os.path.join(EXTENSIONS_DIR, ext_name)
            if os.path.isdir(ext_path) and os.path.exists(os.path.join(ext_path, "docker-compose.yml")):
                # Check if extension is running
                status = "stopped"
                if docker_client:
                    try:
                        # Check for containers with extension name
                        containers = docker_client.containers.list(filters={"label": f"extension={ext_name}"})
                        if containers:
                            status = "running"
                    except:
                        pass
                
                extensions.append({
                    "id": ext_name,
                    "status": status
                })
    
    return extensions

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
@app.get("/api/v1/extensions")
async def get_extensions():
    """Get list of installed extensions"""
    try:
        extensions = extension_manager.get_installed_extensions()
        return {"extensions": [ext.dict() for ext in extensions]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

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
        
        token = auth_manager.login(credentials, request_info)
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

# Mount static files at the end
# Only mount static files if dist directory exists
import os
if os.path.exists("dist"):
    app.mount("/", StaticFiles(directory="dist", html=True), name="static")
elif os.path.exists("../dist"):
    app.mount("/", StaticFiles(directory="../dist", html=True), name="static")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8084)