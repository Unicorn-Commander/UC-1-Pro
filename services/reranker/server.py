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
