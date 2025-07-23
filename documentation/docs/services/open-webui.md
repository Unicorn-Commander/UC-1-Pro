# Open-WebUI

Open-WebUI is the primary user interface for the UC-1 Pro stack. It provides a feature-rich, chat-based interface for interacting with the various AI services.

## Key Features

- **Chat Interface**: A familiar and intuitive interface for conversing with the LLM.
- **Model Selection**: Easily switch between different models available in the vLLM service.
- **RAG Integration**: Built-in support for Retrieval Augmented Generation, allowing you to chat with your documents.
- **Document Upload**: Upload documents directly through the web interface for processing and analysis.
- **User Management**: Support for multiple users and authentication.

## Service Configuration

- **Image**: `ghcr.io/open-webui/open-webui:main`
- **Port**: `8080`

## Environment Variables

Open-WebUI is configured to connect to all the other services in the stack. Here are the key environment variables used in `docker-compose.yml`:

- `OPENAI_API_BASE_URLS`: `http://unicorn-vllm:8000/v1`
- `DATABASE_URL`: `postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@unicorn-postgresql:5432/${POSTGRES_DB}`
- `VECTOR_DB`: `qdrant`
- `QDRANT_URI`: `http://unicorn-qdrant:6333`
- `REDIS_URL`: `redis://unicorn-redis:6379/0`
- `RAG_EMBEDDING_API_BASE_URL`: `http://unicorn-embeddings`
- `RAG_RERANKING_MODEL_API_BASE_URL`: `http://unicorn-reranker:8080`
- `TIKA_BASE_URL`: `http://unicorn-tika:9998`
- `TTS_API_URL`: `http://unicorn-kokoro:8880`
- `STT_API_URL`: `http://unicorn-whisperx:9000`
- `SEARXNG_URL`: `http://unicorn-searxng:8080`
