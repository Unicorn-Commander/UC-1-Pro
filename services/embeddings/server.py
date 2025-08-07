from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer
import torch
import os
from typing import List, Union, Optional
import logging
import numpy as np

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Embeddings Service")

# Load model with better configuration
MODEL_NAME = os.environ.get("MODEL_NAME", "nomic-ai/nomic-embed-text-v1.5")
DEVICE = os.environ.get("DEVICE", "cpu")
MAX_LENGTH = int(os.environ.get("MAX_LENGTH", "8192"))
NORMALIZE = os.environ.get("NORMALIZE", "true").lower() == "true"

logger.info(f"Loading embedding model: {MODEL_NAME}")
logger.info(f"Device: {DEVICE}, Max length: {MAX_LENGTH}, Normalize: {NORMALIZE}")

# Configure model with trust_remote_code for nomic models
model = SentenceTransformer(
    MODEL_NAME,
    device=DEVICE,
    trust_remote_code=True  # Required for nomic models
)
model.max_seq_length = MAX_LENGTH

logger.info("Model loaded successfully")
logger.info(f"Model dimension: {model.get_sentence_embedding_dimension()}")

class EmbeddingRequest(BaseModel):
    input: Union[str, List[str]]
    model: Optional[str] = MODEL_NAME
    encoding_format: Optional[str] = "float"
    
class EmbeddingResponse(BaseModel):
    object: str = "list"
    data: List[dict]
    model: str
    usage: dict

@app.post("/embeddings")
@app.post("/v1/embeddings")  # OpenAI compatible endpoint
async def create_embeddings(request: EmbeddingRequest):
    """Create embeddings for the given input text(s)"""
    try:
        # Handle single string or list of strings
        if isinstance(request.input, str):
            texts = [request.input]
        else:
            texts = request.input
            
        logger.info(f"Creating embeddings for {len(texts)} text(s)")
        
        # Add task prefix for nomic models (improves performance)
        if "nomic" in MODEL_NAME.lower():
            texts = [f"search_document: {text}" for text in texts]
        
        # Generate embeddings
        embeddings = model.encode(
            texts,
            convert_to_tensor=False,
            normalize_embeddings=NORMALIZE,
            show_progress_bar=False
        )
        
        # Convert to list format
        if isinstance(embeddings, np.ndarray):
            embeddings_list = embeddings.tolist()
        else:
            embeddings_list = embeddings
        
        # Format response in OpenAI format
        data = []
        for i, embedding in enumerate(embeddings_list):
            data.append({
                "object": "embedding",
                "embedding": embedding,
                "index": i
            })
        
        # Calculate token usage (approximate)
        total_tokens = sum(len(text.split()) * 1.3 for text in texts)  # Rough estimate
        
        response = EmbeddingResponse(
            data=data,
            model=request.model or MODEL_NAME,
            usage={
                "prompt_tokens": int(total_tokens),
                "total_tokens": int(total_tokens)
            }
        )
        
        logger.info(f"Successfully created {len(data)} embeddings")
        return response
        
    except Exception as e:
        logger.error(f"Error creating embeddings: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "model": MODEL_NAME,
        "dimension": model.get_sentence_embedding_dimension(),
        "max_length": MAX_LENGTH
    }

@app.get("/models")
async def list_models():
    """List available models (OpenAI compatible)"""
    return {
        "object": "list",
        "data": [
            {
                "id": MODEL_NAME,
                "object": "model",
                "created": 1686935002,
                "owned_by": "organization-owner"
            }
        ]
    }

@app.get("/")
async def root():
    return {
        "service": "Embeddings",
        "version": "2.0",
        "model": MODEL_NAME,
        "dimension": model.get_sentence_embedding_dimension(),
        "endpoints": {
            "/embeddings": "POST - Create embeddings (native)",
            "/v1/embeddings": "POST - Create embeddings (OpenAI compatible)",
            "/models": "GET - List available models",
            "/health": "GET - Health check"
        }
    }