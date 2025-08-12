# UC-1 Pro - Enterprise AI Stack for RTX 5090 🚀

<div align="center">

[![GitHub Stars](https://img.shields.io/github/stars/Unicorn-Commander/UC-1-Pro?style=for-the-badge)](https://github.com/Unicorn-Commander/UC-1-Pro/stargazers)
[![License](https://img.shields.io/github/license/Unicorn-Commander/UC-1-Pro?style=for-the-badge)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue?style=for-the-badge&logo=docker)](https://www.docker.com/)
[![NVIDIA](https://img.shields.io/badge/RTX_5090-Optimized-76B900?style=for-the-badge&logo=nvidia)](https://www.nvidia.com/)

**Transform your RTX 5090 into an AI powerhouse with UC-1 Pro**

[🌐 Website](https://unicorncommander.com) • [📖 Documentation](http://localhost:8081) • [🏢 Company](https://magicunicorn.tech) • [🐛 Issues](https://github.com/Unicorn-Commander/UC-1-Pro/issues)

</div>

---

## 🎯 What is UC-1 Pro?

UC-1 Pro is a **production-ready, enterprise-grade AI infrastructure stack** that unleashes the full potential of NVIDIA RTX 5090 GPUs. Built by [Magic Unicorn Unconventional Technology & Stuff Inc](https://magicunicorn.tech), it provides professional AI capabilities with enterprise authentication, a modern Operations Center, and single-command deployment.

### 🏆 **Current Status: Enterprise Authentication Ready**
- ✅ **Enterprise SSO Support** - Microsoft 365, Google Workspace, LDAP/AD integration planned
- ✅ **Professional Operations Center** - Modern dashboard with instant navigation and real-time monitoring
- ✅ **Real Infrastructure Management** - Genuine Docker orchestration, model lifecycle, and service control
- ✅ **Production Optimized** - Performance improvements, background data loading, non-blocking UI

### ✨ Key Features

#### 🔐 **Enterprise Authentication (Coming Soon)**
- **Microsoft 365/Entra ID** - Seamless Azure AD integration with group-based roles
- **Google Workspace** - OAuth 2.0 with organizational unit mapping
- **LDAP/Active Directory** - On-premise AD support with Kerberos/NTLM
- **Unified SSO** - Single sign-on across all services including Open-WebUI
- **RBAC** - Role-based access control with fine-grained permissions

#### 🏢 **Enterprise Operations Center**
- **Instant Navigation** - Non-blocking UI with background data loading
- **Real Model Management** - Detect, activate, and delete vLLM/Ollama models
- **Live Service Control** - Genuine Docker container orchestration
- **Professional Dashboard** - Enterprise-ready design with Magic Unicorn theme
- **Real-time Monitoring** - WebSocket-based system health updates

#### ⚡ **AI Infrastructure**
- **🚀 vLLM Engine** - Running Qwen2.5-32B-Instruct-AWQ optimized for RTX 5090's 32GB VRAM
- **🦙 Ollama Integration** - 10+ models ready including Llama 3.2, Mistral, Gemma2, Qwen3
- **🎙️ WhisperX STT** - Advanced speech processing with speaker diarization
- **🗣️ Kokoro TTS** - Natural voice synthesis with Intel iGPU optimization
- **🔍 Center-Deep Search** - Custom SearXNG fork with AI-powered tool servers
- **📄 Apache Tika** - Document intelligence and OCR processing

#### 🛠️ **System Features**
- **📊 Built-in Monitoring** - Prometheus & Grafana for system insights
- **🔒 Enterprise Security** - Automated backups, SSL support, API authentication
- **🧩 Modular Architecture** - Enable only what you need
- **⚡ Smart Health Checks** - Accurate service status monitoring
- **📥 Model Management** - Download and manage AI models with progress tracking

## 📸 Operations Center Dashboard

UC-1 Pro includes a comprehensive web-based Operations Center for system administration and user access.

### 🏠 Main Dashboard Views

<div align="center">

#### User Dashboard & Homepage
<img src="screenshots/user-dashboard.png" alt="UC-1 Pro User Dashboard" width="700"/>
<p><em>User-friendly interface with search capabilities and quick access to AI services</em></p>

#### Admin Dashboard  
<img src="screenshots/admin-dashboard.png" alt="UC-1 Pro Admin Dashboard" width="700"/>
<p><em>Complete system oversight with real-time monitoring and service management</em></p>

</div>

### 🛠️ Management Features

<div align="center">

<table>
<tr>
<td width="33%" align="center">
<img src="screenshots/ai-model-management.png" alt="AI Model Management" width="300"/>
<br><strong>🤖 AI Model Management</strong>
<br>Search, download & manage LLM models
</td>
<td width="33%" align="center">
<img src="screenshots/service-management.png" alt="Service Management" width="300"/>
<br><strong>⚙️ Service Management</strong>  
<br>Real-time service monitoring & control
</td>
<td width="33%" align="center">
<img src="screenshots/system-monitoring.png" alt="System Monitoring" width="300"/>
<br><strong>📊 System Monitoring</strong>
<br>GPU, CPU, memory & disk analytics
</td>
</tr>
<tr>
<td width="33%" align="center">
<img src="screenshots/settings.png" alt="Settings" width="300"/>
<br><strong>🔧 Settings & Config</strong>
<br>System configuration & preferences
</td>
<td width="33%" align="center">
<img src="screenshots/extensions.png" alt="Extensions" width="300"/>
<br><strong>🧩 Extensions</strong>
<br>One-click extension deployment
</td>
<td width="33%" align="center">
<img src="screenshots/ai-model-management.png" alt="Security Management" width="300"/>
<br><strong>🔒 Security Center</strong>
<br>User accounts & API management
</td>
</tr>
</table>

</div>

## 🚀 Quick Start

### Prerequisites

- Ubuntu 24.04 LTS (Secure Boot compatible)
- NVIDIA RTX 5090 (32GB VRAM) - Detected and configured ✅
- 96GB RAM (minimum 64GB)
- 200GB+ storage (500GB+ recommended for models)
- Docker & NVIDIA Container Toolkit (auto-installed)

### Installation

```bash
# Clone the repository
git clone https://github.com/Unicorn-Commander/UC-1-Pro.git
cd UC-1-Pro

# Run the installer - it handles everything!
./install.sh

# (Optional) Pre-download models for faster startup
./scripts/download-models.sh

# Start your AI stack
./start.sh
```

That's it! The installer automatically configures Docker, NVIDIA drivers (with Secure Boot support), and all dependencies.

## 🖥️ Web Interfaces

Once running, access your AI services:

| Service | URL | Description |
|---------|-----|-------------|
| **Open-WebUI** | http://localhost:8080 | Main AI chat interface |
| **vLLM API** | http://localhost:8000 | OpenAI-compatible API |
| **Documentation** | http://localhost:8081 | Full system documentation |
| **Model Manager** | http://localhost:8084 | Manage AI models |
| **SearXNG** | http://localhost:8888 | Private search engine |

## 🏗️ Architecture

<details>
<summary>Click to expand architecture details</summary>

UC-1 Pro uses a microservices architecture with enterprise authentication gateway:

### Authentication Layer (New)
- **Auth Gateway** - Unified SSO for all services
- **Identity Providers** - Microsoft 365, Google, LDAP/AD
- **Session Management** - Redis-backed JWT tokens
- **RBAC Engine** - Role-based access control

### GPU Services (RTX 5090 - 32GB)
- **vLLM** - Running Qwen2.5-32B-Instruct-AWQ
- **ComfyUI** (Extension) - Flux image generation
- **Ollama** (Extension) - Additional model inference

### CPU/Intel iGPU Services  
- **WhisperX** - Speech-to-text processing
- **Kokoro TTS** - Text-to-speech on Intel AlderLake-S GT1
- **Embeddings** - BAAI/bge-base-en-v1.5
- **Reranker** - BAAI/bge-reranker-v2-m3

### Data Layer
- **PostgreSQL 16** - User accounts, metadata, RBAC
- **Redis 7.4** - Session store, caching, queuing
- **Qdrant 1.15** - Vector database for RAG

</details>

## 🛠️ Management Commands

```bash
# Quick actions
make start          # Start all services
make stop           # Stop all services
make status         # Check service status
make health         # Run health checks
make logs           # View all logs
make backup         # Backup databases

# Model management
./scripts/download-models.sh       # Pre-download all models
./scripts/switch-model.sh          # Switch between LLM models

# GPU management
./scripts/gpu-memory-manager.sh balanced  # Balance GPU between services
./scripts/gpu-memory-manager.sh full-llm  # Maximize for LLM

# Extensions
make monitoring     # Start Prometheus & Grafana
make comfyui       # Start ComfyUI for image generation
```

## 📦 Extensions

UC-1 Pro includes optional extensions for additional functionality:

- **🦙 Ollama** - Local LLM inference with 10+ models ready (port 11434) ✅ Integrated
- **🎨 ComfyUI** - Flux image generation with Kontext support
- **📊 Monitoring** - Prometheus + Grafana dashboards
- **🔧 Dev Tools** - Jupyter Lab, VS Code Server, database admin
- **🐳 Portainer** - Visual Docker management at port 9444 (ucadmin/MagicUnicorn!8-)
- **🔀 Traefik** - Reverse proxy with SSL/Let's Encrypt
- **⚡ Bolt.DIY** - Rapid AI app development
- **🔄 n8n** - Workflow automation
- **🔐 Keycloak** - Enterprise identity management (planned)

Enable extensions as needed:
```bash
cd extensions/[extension-name]
docker-compose up -d
```

## 🔧 Configuration

### Environment Variables

Key settings in `.env`:

```env
# Model Selection
DEFAULT_LLM_MODEL=Qwen/Qwen2.5-32B-Instruct-AWQ
GPU_MEMORY_UTIL=0.95

# Backup Schedule
BACKUP_SCHEDULE=0 2 * * *    # Daily at 2 AM
BACKUP_RETENTION_DAYS=7
```

### Switching Models

```bash
# Use the model manager UI
http://localhost:8084

# Or via script
./scripts/switch-model.sh
```

## 🛡️ Security & Maintenance

- **Automated Backups** - Daily backups with configurable retention
- **Health Monitoring** - Built-in health checks for all services
- **API Authentication** - Secure API keys for all endpoints
- **Update Management** - Simple Docker-based updates

## 📚 Documentation & Roadmap

Complete documentation is available at http://localhost:8081 after starting the stack.

### 📋 **Key Documentation**
- [DEVELOPMENT_CHECKLIST.md](DEVELOPMENT_CHECKLIST.md) - Complete development roadmap
- [AUTHENTICATION_ROADMAP.md](AUTHENTICATION_ROADMAP.md) - Enterprise SSO implementation plan
- [CLAUDE.md](CLAUDE.md) - Project context and architecture
- API Documentation - Swagger UI at `/docs`

### 🧪 **What's Actually Working**

**Real Infrastructure Management:**
- ✅ **Model Management** - Detect, activate, delete vLLM/Ollama models
- ✅ **Service Control** - Real Docker container orchestration
- ✅ **Network Configuration** - Interface detection, WiFi management
- ✅ **System Monitoring** - Live hardware and resource tracking
- ✅ **Backup System** - Functional backup and restore operations

**Performance Optimizations:**
- ✅ **Instant Navigation** - Non-blocking page transitions
- ✅ **Background Loading** - APIs load after UI renders
- ✅ **Request Timeouts** - Prevents hanging on slow endpoints
- ✅ **Progressive Enhancement** - Content fills in as available

Run the complete test suite:
```bash
./test_all_functionality.sh
```

View the detailed development checklist in [DEVELOPMENT_CHECKLIST.md](DEVELOPMENT_CHECKLIST.md)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏢 About Magic Unicorn Tech

UC-1 Pro is developed by [Magic Unicorn Unconventional Technology & Stuff Inc](https://magicunicorn.tech), a company dedicated to making advanced AI technology accessible and practical for real-world applications. We believe in the power of open-source collaboration and building tools that empower developers and organizations to harness the full potential of modern AI hardware.

### 🦄 Why UC-1 Pro?

Born from the need for a production-ready AI stack that "just works," UC-1 Pro eliminates the complexity of integrating multiple AI services. Unlike typical admin panels with mock data, UC-1 Pro provides **genuine infrastructure management** with real Docker orchestration, actual model lifecycle control, and enterprise-grade authentication.

### 🚀 What Makes Us Different

- **Real Functionality** - Not just a pretty UI, but actual infrastructure control
- **Enterprise Ready** - Built for business with SSO and RBAC on the roadmap
- **RTX 5090 Optimized** - Maximizes your 32GB VRAM investment
- **Magic Unicorn Edge** - Professional yet playful, serious yet approachable

---

<div align="center">

**Ready to unleash your RTX 5090?**

[⭐ Star this repo](https://github.com/Unicorn-Commander/UC-1-Pro) • [🚀 Get Started](#-quick-start) • [💬 Join our Community](https://github.com/Unicorn-Commander/UC-1-Pro/discussions)

Built with ❤️ and 🦄 magic by [Magic Unicorn Tech](https://magicunicorn.tech)

*Last Updated: August 12, 2025*

</div>