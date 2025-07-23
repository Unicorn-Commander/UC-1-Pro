# Reranker

The Reranker service improves the relevance of search results by using a cross-encoder model to score and rerank documents based on a query.

## Key Features

- **Improved Relevance**: Significantly improves the quality of search results for RAG.
- **Cross-Encoder Models**: Uses powerful cross-encoder models for accurate scoring.

## Service Configuration

- **Build Context**: `services/reranker`
- **Port**: `8083`

## API Endpoints

- `POST /rerank`: Reranks a list of documents based on a query.
- `GET /health`: A simple health check endpoint.

## Environment Variables

- `MODEL_NAME`: The name of the cross-encoder model to use.
- `DEVICE`: The device to run the model on (`cpu` or `cuda`).
- `MAX_LENGTH`: The maximum sequence length for the model.
