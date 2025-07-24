# UC-1 Pro Admin Dashboard
## Product Requirements Document (PRD)

**Product Name**: UC-1 Pro Admin Dashboard (formerly Model Manager)  
**Version**: 2.0  
**Date**: January 2025  
**Owner**: Magic Unicorn Unconventional Technology & Stuff Inc

---

## 1. Executive Summary

Transform the Model Manager into a comprehensive admin dashboard for the UC-1 Pro appliance, providing centralized control over AI models, system settings, network configuration, and service management through an intuitive web interface.

## 2. Vision & Goals

### Vision
Create a unified control center that makes UC-1 Pro as easy to manage as a home router, while providing power-user features for AI enthusiasts and professionals.

### Primary Goals
1. **Simplify Model Management** - One-click model switching with intelligent resource management
2. **System Administration** - Network, storage, and system configuration without SSH
3. **Service Control** - Visual access to all microservices with health monitoring
4. **Resource Optimization** - Intelligent GPU/CPU/memory management based on usage patterns

## 3. User Personas

### 1. AI Enthusiast "Alex"
- Wants to experiment with different models
- Limited Linux/Docker experience
- Needs visual feedback and simple controls

### 2. Professional Developer "Dana"
- Runs production workloads
- Needs fine-grained control over resources
- Wants API access and automation

### 3. Home Lab Admin "Sam"
- Manages multiple services
- Needs network configuration tools
- Wants system monitoring and alerts

## 4. Core Features

### 4.1 Model Management
**Current State**: Basic model switching  
**Target State**: Comprehensive model lifecycle management

#### Requirements:
- **Model Library**
  - Browse HuggingFace models with filters (size, task, quantization)
  - One-click download with progress tracking
  - Model cards with performance benchmarks
  - Storage usage visualization
  
- **Smart Scheduling**
  - Configurable idle timeout (1-60 minutes)
  - Multiple idle policies:
    - Unload to CPU
    - Swap to smaller model
    - Complete unload
    - Keep loaded (disable idle)
  - Schedule model loading (e.g., business hours)
  - Usage pattern learning

- **Resource Management**
  - Real-time GPU memory usage
  - Model size predictions
  - Multi-model loading (if memory allows)
  - Automatic quantization recommendations

### 4.2 System Dashboard

#### Main Dashboard View
```
┌─────────────────────────────────────────────────────────┐
│                    UC-1 Pro Admin                       │
├─────────────┬─────────────┬─────────────┬─────────────┤
│             │             │             │             │
│   Chat UI   │    vLLM     │   Search    │    Docs     │
│   [Open]    │   [Open]    │   [Open]    │   [Open]    │
│             │             │             │             │
├─────────────┼─────────────┼─────────────┼─────────────┤
│             │             │             │             │
│  WhisperX   │  Kokoro TTS │  Embeddings │  Reranker   │
│   [Open]    │   [Open]    │   [Open]    │   [Open]    │
│             │             │             │             │
├─────────────┴─────────────┴─────────────┴─────────────┤
│ System Status:                                          │
│ • GPU: RTX 5090 (23% utilized, 7.8GB/32GB)            │
│ • CPU: 8 cores (15% load)                             │
│ • RAM: 64GB (38% used)                                │
│ • Storage: 1.2TB free                                 │
└─────────────────────────────────────────────────────────┘
```

#### Service Cards
Each service tile shows:
- Service name and icon
- Health status (green/yellow/red dot)
- Quick metrics (requests/sec, latency)
- [Open] button → launches service in new tab
- [Restart] [Logs] mini buttons

### 4.3 Network Management

#### Features:
- **Network Interfaces**
  - List all interfaces (eth0, wlan0, etc.)
  - Configure static/DHCP
  - Set DNS servers
  - View current IP addresses
  
- **WiFi Management**
  - Scan for networks
  - Connect/disconnect
  - Manage saved networks
  - Create hotspot mode
  
- **Bluetooth**
  - Device discovery
  - Pairing management
  - Audio device routing
  
- **Firewall**
  - Simple on/off toggle
  - Port forwarding rules
  - Service exposure settings

### 4.4 Storage Management

- Disk usage visualization
- Model storage breakdown
- Database sizes
- Log rotation settings
- Backup management
- External drive mounting

### 4.5 Service Configuration

Each service gets a config page:
- Environment variables editor
- Resource limits (CPU/memory)
- Restart policies
- Health check configuration
- Update notifications

## 5. Technical Architecture

### 5.1 Backend Stack
```python
# Core dependencies
FastAPI==0.110.0          # Web framework
docker==7.0.0             # Container management
psutil==5.9.8             # System monitoring
huggingface_hub==0.20.3   # Model discovery
pynetworkmanager==0.1.0   # Network management
python-bluetooth==0.3.0    # Bluetooth control
aiofiles==24.1.0          # Async file operations
asyncssh==2.14.2          # System command execution
```

### 5.2 Frontend Stack
```javascript
// Modern reactive UI
- React 18 or Vue 3
- Tailwind CSS for styling
- Chart.js for metrics
- WebSocket for real-time updates
- Progressive Web App (PWA) capable
```

### 5.3 API Design

```yaml
# RESTful + WebSocket API
/api/v1/
  /models
    GET    - List available models
    POST   - Download/switch model
    DELETE - Remove model
  
  /services
    GET           - List all services
    GET /{id}     - Service details
    POST /{id}/restart
    GET /{id}/logs
    
  /system
    /network
      GET /interfaces
      PUT /interfaces/{id}
      GET /wifi/scan
      POST /wifi/connect
    
    /storage
      GET /usage
      GET /mounts
      POST /mounts
    
    /metrics
      WS /stream - Real-time metrics
```

### 5.4 Security Requirements

- **Authentication**
  - Local user/password (stored in .env)
  - Optional OAuth2 integration
  - Session management with JWT
  
- **Authorization**
  - Read-only guest mode
  - Admin mode for changes
  - API key for automation
  
- **Network Security**
  - HTTPS by default (self-signed cert)
  - CORS configuration
  - Rate limiting

## 6. UI/UX Design Principles

### Visual Design
- **Clean & Modern**: Inspired by UniFi, Proxmox, and modern router interfaces
- **Dark/Light Modes**: System preference detection
- **Responsive**: Works on phone, tablet, desktop
- **Accessible**: WCAG 2.1 AA compliance

### Navigation Structure
```
┌─────────────────────────────┐
│ 🦄 UC-1 Pro      [User] [⚙️] │
├─────────────────────────────┤
│ 📊 Dashboard               │
│ 🤖 Models                  │
│ 🔧 Services                │
│ 🌐 Network                 │
│ 💾 Storage                 │
│ 📈 Monitoring              │
│ ⚙️  Settings               │
└─────────────────────────────┘
```

### Component Library
- Service cards with consistent styling
- Status indicators (traffic lights)
- Progress bars with percentages
- Collapsible sections
- Modal dialogs for confirmations
- Toast notifications

## 7. Implementation Phases

### Phase 1: Core Dashboard (Week 1-2)
- [ ] Service card grid layout
- [ ] Basic health monitoring
- [ ] Service launcher buttons
- [ ] System resource widgets

### Phase 2: Enhanced Model Management (Week 3-4)
- [ ] Model search with filters
- [ ] Download progress tracking
- [ ] Configurable idle policies
- [ ] Usage analytics

### Phase 3: Network Management (Week 5-6)
- [ ] Network interface configuration
- [ ] WiFi management
- [ ] Basic firewall controls
- [ ] Bluetooth device management

### Phase 4: Advanced Features (Week 7-8)
- [ ] Storage management UI
- [ ] Service configuration editor
- [ ] Backup/restore functionality
- [ ] Update management

### Phase 5: Polish & Deploy (Week 9-10)
- [ ] UI/UX refinements
- [ ] Performance optimization
- [ ] Documentation
- [ ] Testing & bug fixes

## 8. Success Metrics

### Quantitative
- Page load time < 2 seconds
- Model switch time < 30 seconds
- 99% uptime for dashboard
- < 100MB memory footprint

### Qualitative
- Users can manage system without SSH
- Intuitive enough for non-technical users
- Powerful enough for advanced users
- Consistent with modern web standards

## 9. Future Enhancements

### Version 2.1
- Mobile app (React Native)
- Multi-node cluster management
- Model performance benchmarking
- Custom model training UI

### Version 3.0
- AI-powered system optimization
- Predictive model preloading
- Integration with cloud services
- Marketplace for models/extensions

## 10. Technical Constraints

### Must Have
- Run in Docker container
- < 500MB container size
- Work without internet (after setup)
- Compatible with UC-1 Pro architecture

### Nice to Have
- PWA offline capability
- Kubernetes operator mode
- Multi-language support
- Plugin architecture

---

## Appendix A: API Examples

### Model Switch Request
```bash
POST /api/v1/models/current
{
  "model_id": "Qwen/Qwen2.5-32B-Instruct-AWQ",
  "idle_policy": "swap_to_small",
  "idle_timeout_minutes": 10
}
```

### Network Configuration
```bash
PUT /api/v1/system/network/interfaces/eth0
{
  "method": "static",
  "address": "192.168.1.100",
  "netmask": "255.255.255.0",
  "gateway": "192.168.1.1",
  "dns": ["8.8.8.8", "8.8.4.4"]
}
```

### Service Control
```bash
POST /api/v1/services/vllm/restart
{
  "graceful": true,
  "timeout_seconds": 30
}
```

---

*This PRD is a living document and will be updated as requirements evolve.*