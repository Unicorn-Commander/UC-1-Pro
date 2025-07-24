# UC-1 Pro Admin Dashboard

The evolution of Model Manager into a complete system administration interface.

## Quick Start

```bash
cd services/admin-dashboard
docker compose up -d
```

Access at: http://localhost:8084

## Features

### 🎯 Current (v1.0)
- Model search and download
- Basic model switching
- Performance metrics
- Health monitoring

### 🚀 Coming Soon (v2.0)
- **Service Launcher**: Beautiful cards for each microservice
- **Network Manager**: WiFi, Ethernet, Bluetooth configuration  
- **Storage Manager**: Disk usage, model cleanup
- **Idle Policies**: Customizable GPU memory management
- **System Monitor**: Real-time resource usage

## Architecture

```
┌─────────────────────────────────────┐
│         Admin Dashboard UI          │
│         (React + Tailwind)          │
└──────────────┬──────────────────────┘
               │ HTTP/WebSocket
┌──────────────┴──────────────────────┐
│        FastAPI Backend              │
│   - Model Management API            │
│   - System Control API              │
│   - Network Management API          │
│   - Docker Integration              │
└──────────────┬──────────────────────┘
               │
┌──────────────┴──────────────────────┐
│     System Resources                │
│   - Docker Socket                   │
│   - NetworkManager D-Bus            │
│   - System Commands                 │
└─────────────────────────────────────┘
```

## Configuration

Environment variables:
```env
# Dashboard Settings
DASHBOARD_PORT=8084
DASHBOARD_TITLE="UC-1 Pro Admin"
ENABLE_AUTH=true
ADMIN_USERNAME=ucadmin
ADMIN_PASSWORD=MagicUnicorn!8-)

# Idle Management
DEFAULT_IDLE_TIMEOUT=300  # 5 minutes
IDLE_MODEL=microsoft/DialoGPT-small
IDLE_POLICY=swap  # swap, unload, or none

# Network Management  
ENABLE_NETWORK_CONFIG=true
ENABLE_WIFI_CONFIG=true
ENABLE_BLUETOOTH=true
```

## Development

### Backend Requirements
```txt
fastapi==0.110.0
docker==7.0.0
psutil==5.9.8
huggingface_hub==0.20.3
asyncio==3.4.3
aiofiles==24.1.0
python-networkmanager==2.2
```

### Frontend Stack
- React 18
- Tailwind CSS
- Axios for API calls
- Socket.io for real-time updates
- Recharts for metrics visualization

## API Endpoints

### Models
- `GET /api/v1/models` - List all models
- `POST /api/v1/models/search` - Search HuggingFace
- `POST /api/v1/models/download` - Download model
- `POST /api/v1/models/switch` - Switch active model
- `DELETE /api/v1/models/{id}` - Delete model

### Services  
- `GET /api/v1/services` - List all services
- `GET /api/v1/services/{id}` - Service details
- `POST /api/v1/services/{id}/action` - Start/stop/restart
- `GET /api/v1/services/{id}/logs` - Get logs

### System
- `GET /api/v1/system/resources` - CPU/RAM/GPU usage
- `GET /api/v1/system/network` - Network interfaces
- `PUT /api/v1/system/network/{interface}` - Configure network
- `GET /api/v1/system/storage` - Storage usage

## Security

- JWT-based authentication
- HTTPS support (self-signed cert)
- CORS configured for local access
- Rate limiting on API endpoints
- Docker socket access restricted

## Roadmap

### v1.1 (Next Week)
- [ ] Service launcher cards
- [ ] Improved UI styling
- [ ] WebSocket for real-time updates

### v1.2
- [ ] Network configuration UI
- [ ] WiFi network scanning
- [ ] Static IP configuration

### v2.0
- [ ] Full system dashboard
- [ ] Advanced idle policies
- [ ] Backup/restore functionality
- [ ] Update management

---

Part of UC-1 Pro by Magic Unicorn Unconventional Technology & Stuff Inc