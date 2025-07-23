# Welcome to UC-1 Pro

UC-1 Pro is a modular, enterprise-grade AI infrastructure stack designed specifically for NVIDIA RTX 5090 GPUs. It implements a microservices architecture where each component is self-contained, independently deployable, and optimized for specific hardware resources.

This documentation site provides a comprehensive guide to the system's architecture, services, and operational procedures.

## Key Design Principles

- **Hardware Optimization**: Services are intelligently distributed across the RTX 5090, Intel iGPU, and CPU to maximize performance and efficiency.
- **Modular Architecture**: Each service is a self-contained module with its own Dockerfile, allowing for independent development, testing, and deployment.
- **Service Isolation**: The microservices design ensures that services can be updated or restarted without affecting the rest of the system.
- **Scalability**: The architecture is designed to be scalable, allowing for the addition of new services or the scaling of existing ones.

## Core Technologies

- **Docker & Docker Compose**: The entire stack is containerized, providing a consistent and reproducible environment.
- **vLLM**: The heart of the system, providing high-throughput LLM inference on the RTX 5090.
- **WhisperX**: State-of-the-art speech-to-text with word-level timestamps and speaker diarization.
- **Kokoro TTS**: High-quality, low-latency text-to-speech synthesis.
- **FastAPI**: The Python framework used for creating the custom AI/ML microservices.

## Getting Started

If you are new to the project, the best place to start is the [Getting Started](getting-started.md) guide, which will walk you through the installation and setup process.
