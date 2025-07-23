# Configuration

The entire UC-1 Pro stack is configured through the `.env` file. This file is created from the `.env.template` during the initial setup.

Below is a detailed explanation of each configuration variable.

## PostgreSQL Database

These variables configure the connection to the PostgreSQL database, which is primarily used by Open-WebUI for storing user data, chat history, and other application state.

- `POSTGRES_USER`: The username for the PostgreSQL database. (Default: `unicorn`)
- `POSTGRES_PASSWORD`: The password for the PostgreSQL database. **This should be changed to a strong, unique password.**
- `POSTGRES_DB`: The name of the database to create and use. (Default: `unicorn_db`)

## vLLM Configuration

These variables control the behavior of the core vLLM service.

- `VLLM_API_KEY`: An API key to secure the vLLM service. Open-WebUI uses this key to authenticate. **This should be changed to a secret value.** (Default: `dummy-key-changeme`)
- `HF_TOKEN`: Your Hugging Face Hub API token. This is optional but required for downloading gated models and for using the speaker diarization feature in WhisperX.
- `DEFAULT_LLM_MODEL`: The Hugging Face model repository to load when the vLLM service starts. (Default: `Qwen/Qwen2.5-32B-Instruct-AWQ`)
- `LLM_QUANTIZATION`: The quantization method to use for the model (e.g., `awq`, `gptq`, `squeezellm`). (Default: `awq`)
- `MAX_MODEL_LEN`: The maximum context length the model can handle. (Default: `16384`)
- `GPU_MEMORY_UTIL`: The percentage of GPU memory to allocate to the vLLM service. (Default: `0.95`)
- `TENSOR_PARALLEL`: The number of GPUs to use for tensor parallelism. For a single GPU setup, this should be `1`. (Default: `1`)

## Auxiliary AI Services

These variables configure the supporting AI/ML models.

- `EMBEDDING_MODEL`: The Hugging Face model to use for creating text embeddings. (Default: `BAAI/bge-base-en-v1.5`)
- `WHISPER_MODEL`: The size of the Whisper model to use for speech-to-text (e.g., `tiny`, `base`, `small`, `medium`, `large-v3`). (Default: `base`)
- `KOKORO_VOICE`: The default voice to use for the Kokoro TTS service. (Default: `af`)
- `RERANKER_MODEL`: The model to use for reranking search results to improve relevance. (Default: `BAAI/bge-reranker-v2-m3`)

## Web UI & Security

These variables control security aspects of the web-facing services.

- `WEBUI_SECRET_KEY`: A secret key used by Open-WebUI for session management and security. **This should be changed to a long, random, and secret string.** (Default: `a_very_secret_key_changeme`)
- `QDRANT_API_KEY`: The API key for the Qdrant vector database, if you have configured one in Qdrant's own settings. (Default: blank)
- `SEARXNG_SECRET`: A secret key for the SearXNG metasearch engine. **This should be changed to a long, random, and secret string.** (Default: `another_very_secret_key_changeme`)
