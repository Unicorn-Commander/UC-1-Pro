from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sentence_transformers import CrossEncoder
import os
from typing import List, Optional, Union
import logging
import torch

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Reranker Service")

# Load model with better configuration
MODEL_NAME = os.environ.get("MODEL_NAME", "mixedbread-ai/mxbai-rerank-large-v1")
MAX_LENGTH = int(os.environ.get("MAX_LENGTH", "512"))
DEVICE = os.environ.get("DEVICE", "cpu")

logger.info(f"Loading reranker model: {MODEL_NAME}")
logger.info(f"Device: {DEVICE}, Max length: {MAX_LENGTH}")

# Initialize model with trust_remote_code for compatibility
try:
    model = CrossEncoder(
        MODEL_NAME,
        max_length=MAX_LENGTH,
        device=DEVICE,
        trust_remote_code=True
    )
    logger.info("Model loaded successfully")
except Exception as e:
    logger.warning(f"Failed to load with trust_remote_code: {e}")
    # Fallback to standard loading
    model = CrossEncoder(MODEL_NAME, max_length=MAX_LENGTH, device=DEVICE)
    logger.info("Model loaded successfully (standard mode)")

class RerankRequest(BaseModel):
    query: str
    documents: List[str]
    top_k: Optional[int] = 10
    model: Optional[str] = MODEL_NAME
    return_documents: Optional[bool] = True

class RerankResponse(BaseModel):
    results: List[dict]
    model: str
    usage: Optional[dict] = None

@app.post("/rerank")
@app.post("/v1/rerank")  # OpenAI compatible endpoint
async def rerank(request: RerankRequest):
    """Rerank documents based on relevance to query"""
    try:
        if not request.documents:
            return RerankResponse(results=[], model=request.model or MODEL_NAME)
        
        logger.info(f"Reranking {len(request.documents)} documents")
        
        # Prepare pairs for scoring
        pairs = [[request.query, doc] for doc in request.documents]
        
        # Get scores with progress tracking for large batches
        if len(pairs) > 100:
            logger.info(f"Processing large batch of {len(pairs)} pairs...")
        
        scores = model.predict(pairs, show_progress_bar=False)
        
        # Create indexed results
        indexed_results = [
            {
                "index": i,
                "score": float(score),
                "document": doc if request.return_documents else None
            }
            for i, (doc, score) in enumerate(zip(request.documents, scores))
        ]
        
        # Sort by score (descending)
        indexed_results.sort(key=lambda x: x['score'], reverse=True)
        
        # Get top_k results
        top_results = indexed_results[:request.top_k] if request.top_k else indexed_results
        
        # Clean up results (remove None documents if not returning)
        if not request.return_documents:
            for result in top_results:
                result.pop('document', None)
        
        logger.info(f"Reranking complete. Top score: {top_results[0]['score'] if top_results else 0}")
        
        # Estimate token usage
        total_tokens = sum(len(doc.split()) + len(request.query.split()) for doc in request.documents) * 1.3
        
        return RerankResponse(
            results=top_results,
            model=request.model or MODEL_NAME,
            usage={
                "prompt_tokens": int(total_tokens),
                "total_tokens": int(total_tokens)
            }
        )
        
    except Exception as e:
        logger.error(f"Error in reranking: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "model": MODEL_NAME,
        "device": DEVICE,
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
        "service": "Reranker",
        "version": "2.0",
        "model": MODEL_NAME,
        "device": DEVICE,
        "endpoints": {
            "/rerank": "POST - Rerank documents (native)",
            "/v1/rerank": "POST - Rerank documents (OpenAI compatible)",
            "/models": "GET - List available models",
            "/health": "GET - Health check"
        }
    }
