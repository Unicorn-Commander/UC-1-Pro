# System Architecture

UC-1 Pro is designed as a modular, microservices-based system. This architecture provides flexibility, scalability, and clear separation of concerns.

## Architecture Diagram

The following diagram illustrates the high-level architecture of the system:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Client Applications                             │
│                        (Web Browser, API Clients, Mobile)                    │
└────────────────────────────────┬───────────────────────────────────────────┘
                                 │
┌────────────────────────────────┴───────────────────────────────────────────┐
│                           API Gateway / Load Balancer                       │
│                              (ports 8080, 8000)                            │
└────────────────────────────────┬───────────────────────────────────────────┘
                                 │
┌────────────────────────────────┴───────────────────────────────────────────┐
│                              Docker Network                                 │
│                           (unicorn-network: 172.20.0.0/16)                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────┐  ┌─────────────────────┐  ┌──────────────────┐   │
│  │   Open-WebUI (8080) │  │  Model Manager      │  │ Prometheus (9090)│   │
│  │   Main Interface    │  │  (8084)             │  │ Monitoring       │   │
│  └──────────┬──────────┘  └──────────┬──────────┘  └────────┬─────────┘   │
│             │                         │                       │             │
│  ┌──────────┴──────────────────────┴─────────────────────────┴──────────┐  │
│  │                         Service Communication Bus                     │  │
│  └──┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬──────┘  │
│     │         │         │         │         │         │         │          │
│  ┌──┴────┐ ┌─┴────┐ ┌─┴────┐ ┌─┴────┐ ┌─┴────┐ ┌─┴────┐ ┌─┴────┐      │
│  │ vLLM  │ │Embed │ │Whisper│ │Kokoro│ │Rerank│ │Tika  │ │SearX │      │
│  │(8000) │ │(8082)│ │(9000) │ │(8880)│ │(8083)│ │(9998)│ │(8888)│      │
│  └───┬───┘ └──┬───┘ └───┬───┘ └──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘      │
│      │        │          │        │        │        │        │           │
└──────┼────────┼──────────┼────────┼────────┼────────┼────────┼───────────┘
       │        │          │        │        │        │        │
┌──────┴────┐ ┌┴──────────┴────────┴────────┴────┐ ┌┴────────┴───────────┐
│ RTX 5090  │ │      Intel iGPU / CPU            │ │   CPU Only         │
│  (32GB)   │ │    (Shared System RAM)           │ │                    │
└───────────┘ └──────────────────────────────────┘ └────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                            Data Persistence Layer                           │
├─────────────────┬─────────────────────┬────────────────────────────────────┤
│  PostgreSQL     │     Redis           │        Qdrant                      │
│  (5432)         │     (6379)          │        (6333/6334)                 │
│  Metadata       │     Cache/Queue     │        Vector Store                │
└─────────────────┴─────────────────────┴────────────────────────────────────┘
```

## Network Architecture

All services communicate over a custom Docker bridge network named `unicorn-network`.

- **Subnet**: `172.20.0.0/16`
- **Driver**: `bridge`

This setup provides service discovery, allowing services to communicate with each other using their container names as hostnames (e.g., `http://unicorn-vllm:8000`).

## Data Flow

The system supports several key data flows:

### 1. Chat Completion Flow

`User -> Open-WebUI -> vLLM -> Response`

### 2. RAG (Retrieval Augmented Generation) Flow

`Document -> Tika OCR -> Text -> Embeddings -> Qdrant -> Reranker -> Context -> vLLM -> Response`

### 3. Speech Processing Flow

`Audio -> WhisperX -> Text -> vLLM -> Response -> Kokoro TTS -> Audio`

## Hardware Resource Allocation

- **NVIDIA RTX 5090**: Exclusively used by the `vLLM` service for maximum performance.
- **Intel iGPU**: Used by the `Kokoro TTS` service for hardware-accelerated text-to-speech.
- **CPU**: Used by all other services, including `WhisperX`, `Reranker`, `Embeddings`, and the data services.
