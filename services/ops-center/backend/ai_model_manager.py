"""
AI Model Management Module for UC-1 Pro Admin Dashboard
Handles vLLM and Ollama model management with granular settings
"""

import os
import json
import asyncio
import httpx
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any
from pydantic import BaseModel
import logging

logger = logging.getLogger(__name__)

# Configuration paths (adjusted for container environment)
MODEL_SETTINGS_PATH = "/volumes/model_settings.json"
VLLM_MODELS_DIR = "/volumes/vllm_models"
OLLAMA_MODELS_DIR = "/volumes/ollama_models"

# Pydantic models for API requests/responses
class VLLMSettings(BaseModel):
    gpu_memory_utilization: Optional[float] = None
    max_model_len: Optional[int] = None
    tensor_parallel_size: Optional[int] = None
    quantization: Optional[str] = None
    dtype: Optional[str] = None
    trust_remote_code: Optional[bool] = None
    download_dir: Optional[str] = None
    cpu_offload_gb: Optional[int] = None
    enforce_eager: Optional[bool] = None
    max_num_batched_tokens: Optional[int] = None
    max_num_seqs: Optional[int] = None
    disable_log_stats: Optional[bool] = None
    disable_log_requests: Optional[bool] = None

class OllamaSettings(BaseModel):
    models_path: Optional[str] = None
    gpu_layers: Optional[int] = None
    context_size: Optional[int] = None
    num_thread: Optional[int] = None
    use_mmap: Optional[bool] = None
    use_mlock: Optional[bool] = None
    repeat_penalty: Optional[float] = None
    temperature: Optional[float] = None
    top_k: Optional[int] = None
    top_p: Optional[float] = None
    seed: Optional[int] = None

class ModelSettingsUpdate(BaseModel):
    model_id: str
    backend: str  # 'vllm' or 'ollama'
    settings: Dict[str, Any]

class ModelDownloadRequest(BaseModel):
    model_id: str
    backend: str  # 'vllm' or 'ollama'
    settings: Optional[Dict[str, Any]] = None

class AIModelManager:
    def __init__(self):
        self.settings = self._load_settings()
        self.download_tasks = {}
        
    def _load_settings(self) -> Dict:
        """Load settings from disk"""
        if os.path.exists(MODEL_SETTINGS_PATH):
            try:
                with open(MODEL_SETTINGS_PATH, 'r') as f:
                    return json.load(f)
            except Exception as e:
                logger.error(f"Error loading settings: {e}")
        
        return {
            "global": {
                "vllm": {
                    "gpu_memory_utilization": 0.95,
                    "max_model_len": 16384,
                    "tensor_parallel_size": 1,
                    "quantization": "auto",
                    "dtype": "auto",
                    "trust_remote_code": False,
                    "download_dir": VLLM_MODELS_DIR,
                    "cpu_offload_gb": 0,
                    "enforce_eager": False,
                    "max_num_batched_tokens": None,
                    "max_num_seqs": 256,
                    "disable_log_stats": False,
                    "disable_log_requests": False
                },
                "ollama": {
                    "models_path": OLLAMA_MODELS_DIR,
                    "gpu_layers": -1,
                    "context_size": 2048,
                    "num_thread": 0,
                    "use_mmap": True,
                    "use_mlock": False,
                    "repeat_penalty": 1.1,
                    "temperature": 0.8,
                    "top_k": 40,
                    "top_p": 0.9,
                    "seed": -1
                }
            },
            "model_overrides": {}
        }
    
    def _save_settings(self):
        """Save settings to disk"""
        try:
            os.makedirs(os.path.dirname(MODEL_SETTINGS_PATH), exist_ok=True)
            with open(MODEL_SETTINGS_PATH, 'w') as f:
                json.dump(self.settings, f, indent=2)
        except Exception as e:
            logger.error(f"Error saving settings: {e}")
    
    def get_global_settings(self, backend: str) -> Dict:
        """Get global settings for a backend"""
        return self.settings["global"].get(backend, {})
    
    def update_global_settings(self, backend: str, settings: Dict) -> Dict:
        """Update global settings for a backend"""
        if backend not in ["vllm", "ollama"]:
            raise ValueError(f"Invalid backend: {backend}")
        
        # Update only provided settings
        for key, value in settings.items():
            if value is not None:
                self.settings["global"][backend][key] = value
        
        self._save_settings()
        return self.settings["global"][backend]
    
    def get_model_settings(self, model_id: str, backend: str) -> Dict:
        """Get effective settings for a model (global + overrides)"""
        global_settings = self.settings["global"].get(backend, {})
        overrides = self.settings["model_overrides"].get(f"{backend}:{model_id}", {})
        
        # Merge settings
        effective_settings = global_settings.copy()
        effective_settings.update(overrides)
        
        return {
            "global": global_settings,
            "overrides": overrides,
            "effective": effective_settings
        }
    
    def update_model_settings(self, model_id: str, backend: str, settings: Dict) -> Dict:
        """Update model-specific settings overrides"""
        key = f"{backend}:{model_id}"
        
        # Filter out None values and empty settings
        filtered_settings = {k: v for k, v in settings.items() if v is not None}
        
        if filtered_settings:
            self.settings["model_overrides"][key] = filtered_settings
        else:
            # Remove overrides if all are cleared
            self.settings["model_overrides"].pop(key, None)
        
        self._save_settings()
        return self.get_model_settings(model_id, backend)
    
    async def scan_local_models(self) -> Dict[str, List[Dict]]:
        """Scan for locally installed models"""
        models = {"vllm": [], "ollama": [], "embeddings": [], "reranker": []}
        
        # Scan vLLM models directory
        if os.path.exists(VLLM_MODELS_DIR):
            for model_dir in Path(VLLM_MODELS_DIR).iterdir():
                if model_dir.is_dir() and not model_dir.name.startswith('.'):
                    # Handle both simple directory structure and HuggingFace cache structure
                    if model_dir.name.startswith("models--"):
                        # HuggingFace cache format: models--Qwen--Qwen2.5-32B-Instruct-AWQ
                        model_name = model_dir.name.replace("models--", "").replace("--", "/")
                        display_name = model_name
                    else:
                        # Simple directory structure
                        model_name = model_dir.name
                        display_name = model_name
                    
                    model_info = {
                        "id": model_name,
                        "name": display_name,
                        "path": str(model_dir),
                        "size": self._get_dir_size(model_dir),
                        "last_modified": datetime.fromtimestamp(model_dir.stat().st_mtime).isoformat(),
                        "has_overrides": f"vllm:{model_name}" in self.settings.get("model_overrides", {})
                    }
                    models["vllm"].append(model_info)
        
        # Get Ollama models via API (with timeout)
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                response = await client.get("http://unicorn-ollama:11434/api/tags")
                if response.status_code == 200:
                    data = response.json()
                    for model in data.get("models", []):
                        model_info = {
                            "id": model["name"],
                            "name": model["name"],
                            "size": model.get("size", 0),
                            "last_modified": model.get("modified_at"),
                            "has_overrides": f"ollama:{model['name']}" in self.settings.get("model_overrides", {})
                        }
                        models["ollama"].append(model_info)
        except (httpx.ConnectError, httpx.TimeoutException) as e:
            logger.info(f"Ollama service not available: {e}")
        except Exception as e:
            logger.warning(f"Failed to fetch Ollama models: {e}")
        
        # Get Embeddings models via service API
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                response = await client.get("http://unicorn-embeddings:8082/model/cached")
                if response.status_code == 200:
                    data = response.json()
                    for model in data.get("cached_models", []):
                        models["embeddings"].append({
                            "id": model["name"],
                            "name": model["name"],
                            "size": model.get("size", 0),
                            "path": model.get("path", ""),
                            "active": model.get("active", False)
                        })
        except (httpx.ConnectError, httpx.TimeoutException) as e:
            logger.info(f"Embeddings service not available: {e}")
        except Exception as e:
            logger.warning(f"Failed to fetch Embeddings models: {e}")
        
        # Get Reranker models via service API
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                response = await client.get("http://unicorn-reranker:8083/model/cached")
                if response.status_code == 200:
                    data = response.json()
                    for model in data.get("cached_models", []):
                        models["reranker"].append({
                            "id": model["name"],
                            "name": model["name"],
                            "size": model.get("size", 0),
                            "path": model.get("path", ""),
                            "active": model.get("active", False)
                        })
        except (httpx.ConnectError, httpx.TimeoutException) as e:
            logger.info(f"Reranker service not available: {e}")
        except Exception as e:
            logger.warning(f"Failed to fetch Reranker models: {e}")
        
        return models
    
    def _get_dir_size(self, path: Path) -> int:
        """Get total size of a directory"""
        total = 0
        try:
            for entry in path.rglob('*'):
                if entry.is_file():
                    total += entry.stat().st_size
        except Exception:
            pass
        return total
    
    async def download_vllm_model(self, model_id: str, settings: Optional[Dict] = None) -> str:
        """Download a vLLM model from Hugging Face"""
        # Create download task ID
        task_id = f"vllm:{model_id}:{datetime.now().timestamp()}"
        
        # Get effective settings
        effective_settings = self.get_global_settings("vllm")
        if settings:
            effective_settings.update(settings)
        
        # Create download directory
        model_path = os.path.join(VLLM_MODELS_DIR, model_id.replace("/", "--"))
        os.makedirs(model_path, exist_ok=True)
        
        # Build huggingface-cli command
        cmd = [
            "huggingface-cli", "download",
            model_id,
            "--local-dir", model_path,
            "--local-dir-use-symlinks", "False"
        ]
        
        # Add token if available
        hf_token = os.environ.get("HF_TOKEN")
        if hf_token:
            cmd.extend(["--token", hf_token])
        
        # Start download process
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        self.download_tasks[task_id] = {
            "process": process,
            "model_id": model_id,
            "status": "downloading",
            "progress": 0,
            "started_at": datetime.now().isoformat()
        }
        
        # Monitor download in background
        asyncio.create_task(self._monitor_download(task_id, process))
        
        return task_id
    
    async def download_ollama_model(self, model_name: str) -> str:
        """Download an Ollama model"""
        task_id = f"ollama:{model_name}:{datetime.now().timestamp()}"
        
        # Use Ollama API to pull model
        async with httpx.AsyncClient(timeout=None) as client:
            # Start pull request
            response = await client.post(
                "http://localhost:11434/api/pull",
                json={"name": model_name},
                timeout=None
            )
            
            self.download_tasks[task_id] = {
                "model_id": model_name,
                "status": "downloading",
                "progress": 0,
                "started_at": datetime.now().isoformat()
            }
            
            # Process streaming response
            async for line in response.aiter_lines():
                if line:
                    try:
                        data = json.loads(line)
                        if "completed" in data and "total" in data:
                            progress = (data["completed"] / data["total"]) * 100
                            self.download_tasks[task_id]["progress"] = progress
                        
                        if data.get("status") == "success":
                            self.download_tasks[task_id]["status"] = "completed"
                            self.download_tasks[task_id]["progress"] = 100
                    except json.JSONDecodeError:
                        pass
        
        return task_id
    
    async def _monitor_download(self, task_id: str, process):
        """Monitor vLLM download progress"""
        try:
            stdout, stderr = await process.communicate()
            
            if process.returncode == 0:
                self.download_tasks[task_id]["status"] = "completed"
                self.download_tasks[task_id]["progress"] = 100
            else:
                self.download_tasks[task_id]["status"] = "failed"
                self.download_tasks[task_id]["error"] = stderr.decode()
        except Exception as e:
            self.download_tasks[task_id]["status"] = "failed"
            self.download_tasks[task_id]["error"] = str(e)
    
    def get_download_status(self, task_id: str) -> Optional[Dict]:
        """Get download task status"""
        return self.download_tasks.get(task_id)
    
    def get_all_downloads(self) -> Dict[str, Dict]:
        """Get all download tasks"""
        return self.download_tasks
    
    async def activate_vllm_model(self, model_id: str) -> Dict:
        """Activate a vLLM model by updating environment and restarting service"""
        # This would integrate with your Docker manager
        # For now, return a placeholder
        return {
            "status": "activated",
            "model_id": model_id,
            "message": "Model activation requires Docker integration"
        }
    
    async def delete_model(self, model_id: str, backend: str) -> Dict:
        """Delete a model"""
        if backend == "vllm":
            model_path = os.path.join(VLLM_MODELS_DIR, model_id.replace("/", "--"))
            if os.path.exists(model_path):
                import shutil
                shutil.rmtree(model_path)
                return {"status": "deleted", "model_id": model_id}
            else:
                raise FileNotFoundError(f"Model not found: {model_id}")
        
        elif backend == "ollama":
            # Use Ollama API to delete
            async with httpx.AsyncClient() as client:
                response = await client.delete(f"http://localhost:11434/api/delete/{model_id}")
                if response.status_code == 200:
                    return {"status": "deleted", "model_id": model_id}
                else:
                    raise Exception(f"Failed to delete Ollama model: {response.text}")
        
        else:
            raise ValueError(f"Invalid backend: {backend}")

# Create singleton instance
ai_model_manager = AIModelManager()