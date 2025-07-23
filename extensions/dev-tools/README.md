# Development Tools Extension

This extension provides web-based development and administration tools for UC-1 Pro.

## Services Included

1. **Jupyter Lab** (Port 8889)
   - TensorFlow notebook environment
   - Direct access to UC-1 Pro services
   - Perfect for AI/ML experimentation

2. **Code-Server** (Port 8890)
   - VS Code in your browser
   - Edit configuration files
   - Develop custom services

3. **pgAdmin** (Port 8891)
   - PostgreSQL administration
   - Query Open-WebUI database
   - Backup/restore capabilities

4. **Redis Commander** (Port 8892)
   - Redis key browser
   - Monitor cache usage
   - Debug session data

## Quick Start

```bash
cd extensions/dev-tools
docker-compose up -d
```

## Access Credentials

Default credentials (change in .env):
- Jupyter: Token = `uc1-jupyter`
- Code-Server: Password = `uc1-dev`
- pgAdmin: `admin@uc1.local` / `admin`
- Redis Commander: No auth required

## Usage Examples

### Jupyter Lab
Access vLLM from notebook:
```python
import requests
response = requests.post(
    "http://vllm:8000/v1/completions",
    json={"model": "Qwen/Qwen2.5-32B-Instruct-AWQ", "prompt": "Hello"}
)
```

### pgAdmin
1. Add server connection:
   - Host: `postgresql`
   - Port: `5432`
   - Database: `unicorn_db`
   - Username/Password: From main .env file

### Code-Server
- Workspace mounted at `/home/coder/workspace`
- Install extensions for Python, Docker, YAML