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
    
    class Config:
        protected_namespaces = ()  # Disable protected namespace warning

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
