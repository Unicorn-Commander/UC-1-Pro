from fastapi import FastAPI, HTTPException, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
import psutil
import docker
import asyncio
import json
import os
import subprocess
from datetime import datetime
from typing import Dict, List, Optional
import GPUtil
import aiofiles
from pydantic import BaseModel

app = FastAPI(title="UC-1 Pro Admin Dashboard API")

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
    docker_client = docker.DockerClient(base_url='unix://var/run/docker.sock')
except Exception as e:
    print(f"Warning: Docker client initialization failed: {e}")
    docker_client = None

# Service definitions
SERVICES = {
    "open-webui": {
        "container": "unicorn-open-webui",
        "name": "Chat UI",
        "port": 8080,
        "healthcheck": "/health"
    },
    "vllm": {
        "container": "unicorn-vllm",
        "name": "vLLM API",
        "port": 8000,
        "healthcheck": "/health"
    },
    "whisperx": {
        "container": "unicorn-whisperx",
        "name": "WhisperX",
        "port": 9000,
        "healthcheck": "/health"
    },
    "kokoro": {
        "container": "unicorn-kokoro",
        "name": "Kokoro TTS",
        "port": 8880,
        "healthcheck": "/health"
    },
    "embeddings": {
        "container": "unicorn-embeddings",
        "name": "Embeddings",
        "port": 8082,
        "healthcheck": "/health"
    },
    "reranker": {
        "container": "unicorn-reranker",
        "name": "Reranker",
        "port": 8083,
        "healthcheck": "/health"
    },
    "searxng": {
        "container": "unicorn-searxng",
        "name": "SearXNG",
        "port": 8888,
        "healthcheck": "/"
    },
    "prometheus": {
        "container": "unicorn-prometheus",
        "name": "Prometheus",
        "port": 9090,
        "healthcheck": "/-/healthy"
    }
}

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

# API Routes

@app.get("/api/v1/system/status")
async def get_system_status():
    """Get current system resource usage"""
    try:
        # CPU info
        cpu_percent = psutil.cpu_percent(interval=1)
        cpu_count = psutil.cpu_count()
        
        # Memory info
        memory = psutil.virtual_memory()
        
        # Disk info
        disk = psutil.disk_usage('/')
        
        # GPU info (if available)
        gpu_info = {"usage": 0, "memory": {"used": 0, "total": 0}, "temperature": 0}
        try:
            gpus = GPUtil.getGPUs()
            if gpus:
                gpu = gpus[0]  # Primary GPU
                gpu_info = {
                    "usage": round(gpu.load * 100, 1),
                    "memory": {
                        "used": round(gpu.memoryUsed / 1024, 1),
                        "total": round(gpu.memoryTotal / 1024, 1)
                    },
                    "temperature": gpu.temperature
                }
        except:
            pass
        
        return {
            "cpu": {
                "usage": round(cpu_percent, 1),
                "cores": cpu_count
            },
            "memory": {
                "used": round(memory.used / (1024**3), 1),
                "total": round(memory.total / (1024**3), 1),
                "percent": round(memory.percent, 1)
            },
            "disk": {
                "used": round(disk.used / (1024**3), 1),
                "total": round(disk.total / (1024**3), 1),
                "percent": round(disk.percent, 1)
            },
            "gpu": gpu_info
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/services")
async def list_services():
    """List all services with their status"""
    services = []
    
    if docker_client:
        try:
            containers = docker_client.containers.list(all=True)
            container_map = {c.name: c for c in containers}
            
            for service_id, service_info in SERVICES.items():
                container_name = service_info["container"]
                status = "unknown"
                
                if container_name in container_map:
                    container = container_map[container_name]
                    if container.status == "running":
                        # Check health if available
                        if hasattr(container, 'health'):
                            health = container.health
                            if health == "healthy":
                                status = "healthy"
                            elif health == "starting":
                                status = "starting"
                            else:
                                status = "unhealthy"
                        else:
                            status = "healthy"  # Assume healthy if no health check
                    else:
                        status = "stopped"
                
                services.append({
                    "id": service_id,
                    "name": service_info["name"],
                    "status": status,
                    "port": service_info["port"]
                })
        except Exception as e:
            print(f"Error listing services: {e}")
    
    return {"services": services}

@app.get("/api/v1/services/{service_id}")
async def get_service_details(service_id: str):
    """Get detailed information about a service"""
    if service_id not in SERVICES:
        raise HTTPException(status_code=404, detail="Service not found")
    
    service_info = SERVICES[service_id]
    details = {
        "id": service_id,
        "name": service_info["name"],
        "port": service_info["port"],
        "status": "unknown",
        "stats": {}
    }
    
    if docker_client:
        try:
            container = docker_client.containers.get(service_info["container"])
            details["status"] = container.status
            
            # Get container stats
            stats = container.stats(stream=False)
            details["stats"] = {
                "cpu_percent": calculate_cpu_percent(stats),
                "memory_usage": stats["memory_stats"]["usage"] / (1024**2),  # MB
                "network_rx": stats["networks"]["eth0"]["rx_bytes"] / (1024**2),  # MB
                "network_tx": stats["networks"]["eth0"]["tx_bytes"] / (1024**2),  # MB
            }
        except Exception as e:
            print(f"Error getting service details: {e}")
    
    return details

@app.post("/api/v1/services/{service_id}/action")
async def service_action(service_id: str, action: ServiceAction):
    """Start, stop, or restart a service"""
    if service_id not in SERVICES:
        raise HTTPException(status_code=404, detail="Service not found")
    
    service_info = SERVICES[service_id]
    
    try:
        if action.action == "restart":
            subprocess.run(["docker", "compose", "restart", service_info["container"]], check=True)
        elif action.action == "stop":
            subprocess.run(["docker", "compose", "stop", service_info["container"]], check=True)
        elif action.action == "start":
            subprocess.run(["docker", "compose", "start", service_info["container"]], check=True)
        else:
            raise HTTPException(status_code=400, detail="Invalid action")
        
        return {"status": "success", "message": f"Service {action.action} completed"}
    except subprocess.CalledProcessError as e:
        raise HTTPException(status_code=500, detail=f"Action failed: {e}")

@app.get("/api/v1/services/{service_id}/logs")
async def get_service_logs(service_id: str, lines: int = 100):
    """Get recent logs from a service"""
    if service_id not in SERVICES:
        raise HTTPException(status_code=404, detail="Service not found")
    
    service_info = SERVICES[service_id]
    
    try:
        result = subprocess.run(
            ["docker", "logs", "--tail", str(lines), service_info["container"]],
            capture_output=True,
            text=True
        )
        
        return {
            "logs": result.stdout,
            "errors": result.stderr
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/network/interfaces")
async def list_network_interfaces():
    """List all network interfaces"""
    interfaces = []
    
    for iface, addrs in psutil.net_if_addrs().items():
        iface_info = {
            "name": iface,
            "addresses": []
        }
        
        for addr in addrs:
            if addr.family == 2:  # IPv4
                iface_info["addresses"].append({
                    "type": "ipv4",
                    "address": addr.address,
                    "netmask": addr.netmask
                })
            elif addr.family == 17:  # MAC
                iface_info["mac"] = addr.address
        
        # Get interface stats
        stats = psutil.net_if_stats().get(iface)
        if stats:
            iface_info["is_up"] = stats.isup
            iface_info["speed"] = stats.speed
        
        interfaces.append(iface_info)
    
    return {"interfaces": interfaces}

@app.get("/api/v1/storage/usage")
async def get_storage_usage():
    """Get storage usage information"""
    partitions = []
    
    for partition in psutil.disk_partitions():
        try:
            usage = psutil.disk_usage(partition.mountpoint)
            partitions.append({
                "device": partition.device,
                "mountpoint": partition.mountpoint,
                "fstype": partition.fstype,
                "total": usage.total / (1024**3),  # GB
                "used": usage.used / (1024**3),    # GB
                "free": usage.free / (1024**3),    # GB
                "percent": usage.percent
            })
        except PermissionError:
            continue
    
    # Model storage breakdown
    model_dirs = {
        "vllm": "/models",
        "whisperx": "/app/models",
        "kokoro": "/app/models",
        "embeddings": "/data",
        "reranker": "/app/models"
    }
    
    model_usage = {}
    for name, path in model_dirs.items():
        if os.path.exists(path):
            size = get_directory_size(path)
            model_usage[name] = size / (1024**3)  # GB
    
    return {
        "partitions": partitions,
        "models": model_usage
    }

@app.get("/api/v1/settings")
async def get_settings():
    """Get current system settings"""
    # Load from config file or environment
    return SystemSettings()

@app.post("/api/v1/settings")
async def update_settings(settings: SystemSettings):
    """Update system settings"""
    # Save to config file
    # Update relevant services
    return {"status": "success", "settings": settings}

# WebSocket for real-time updates
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            # Send system status every 5 seconds
            status = await get_system_status()
            await websocket.send_json({"type": "status", "data": status})
            await asyncio.sleep(5)
    except Exception as e:
        print(f"WebSocket error: {e}")
    finally:
        await websocket.close()

# Helper functions
def calculate_cpu_percent(stats):
    """Calculate CPU percentage from Docker stats"""
    cpu_delta = stats["cpu_stats"]["cpu_usage"]["total_usage"] - \
                stats["precpu_stats"]["cpu_usage"]["total_usage"]
    system_delta = stats["cpu_stats"]["system_cpu_usage"] - \
                   stats["precpu_stats"]["system_cpu_usage"]
    
    if system_delta > 0:
        cpu_percent = (cpu_delta / system_delta) * 100
        return round(cpu_percent, 2)
    return 0

def get_directory_size(path):
    """Get total size of a directory"""
    total_size = 0
    for dirpath, dirnames, filenames in os.walk(path):
        for filename in filenames:
            filepath = os.path.join(dirpath, filename)
            if os.path.exists(filepath):
                total_size += os.path.getsize(filepath)
    return total_size

# Mount static files for the React app
app.mount("/", StaticFiles(directory="dist", html=True), name="static")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8084)