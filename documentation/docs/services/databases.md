# Databases

The UC-1 Pro stack uses three primary data services for persistence, caching, and vector storage.

## PostgreSQL

PostgreSQL is a powerful, open-source object-relational database system. It is used by Open-WebUI to store user data, chat history, and other application state.

- **Image**: `postgres:16.9-alpine`
- **Port**: `5432`

## Redis

Redis is an in-memory data structure store, used as a database, cache, and message broker. It is used by Open-WebUI and SearXNG for caching and by Open-WebUI for WebSocket management.

- **Image**: `redis:7.4.5-alpine`
- **Port**: `6379`

## Qdrant

Qdrant is a vector database and vector similarity search engine. It is used to store and search the vector embeddings of documents for the RAG system.

- **Image**: `qdrant/qdrant:v1.15.0`
- **Ports**: `6333` (HTTP), `6334` (gRPC)
