# Embeddings

The Embeddings service is responsible for creating vector embeddings from text. These embeddings are used by the RAG system to find relevant documents in the vector database.

## Key Features

- **High-Throughput**: Optimized for high-throughput batch processing.
- **Multiple Model Support**: Can be configured to use different embedding models.
- **OpenAI-Compatible API**: Provides an API that is compatible with the OpenAI Embeddings API.

## Service Configuration

- **Image**: `ghcr.io/huggingface/text-embeddings-inference:cpu-1.2`
- **Port**: `8082`

## Environment Variables

- `MODEL_ID`: The Hugging Face model to use for creating embeddings.
- `MAX_BATCH_TOKENS`: The maximum number of tokens in a batch.
- `MAX_CLIENT_BATCH_SIZE`: The maximum number of requests in a batch.
