"""Extension Manager Module

This module handles extension installation, management, and configuration.
"""

import os
import json
import shutil
import subprocess
import tempfile
import asyncio
from pathlib import Path
from typing import Dict, List, Optional, Any
from datetime import datetime
import yaml
import requests
import tarfile
import zipfile
from pydantic import BaseModel, Field

class ExtensionConfig(BaseModel):
    """Extension configuration model"""
    id: str
    name: str
    version: str
    description: str
    author: str
    category: str
    status: str = "installed"  # installed, running, stopped, error
    install_date: Optional[str] = None
    config: Dict[str, Any] = Field(default_factory=dict)
    docker_compose_path: Optional[str] = None

class ExtensionInstallRequest(BaseModel):
    """Extension installation request model"""
    id: str
    name: str
    source_url: str
    version: str
    category: str

class ExtensionActionRequest(BaseModel):
    """Extension action request model"""
    action: str  # start, stop, restart, uninstall
    
class ExtensionConfigUpdate(BaseModel):
    """Extension configuration update model"""
    config: Dict[str, Any]

class ExtensionManager:
    """Manages UC-1 Pro extensions"""
    
    def __init__(self):
        self.base_dir = Path("/home/ucadmin/UC-1-Pro")
        self.extensions_dir = self.base_dir / "extensions"
        self.data_dir = self.base_dir / "services" / "admin-dashboard" / "data"
        self.extensions_config_file = self.data_dir / "extensions.json"
        
        # Ensure directories exist
        self.extensions_dir.mkdir(parents=True, exist_ok=True)
        self.data_dir.mkdir(parents=True, exist_ok=True)
        
        # Load extension configurations
        self.extensions = self._load_extensions()
        
    def _load_extensions(self) -> Dict[str, ExtensionConfig]:
        """Load extension configurations from file"""
        if self.extensions_config_file.exists():
            try:
                with open(self.extensions_config_file, 'r') as f:
                    data = json.load(f)
                    return {k: ExtensionConfig(**v) for k, v in data.items()}
            except Exception as e:
                print(f"Error loading extensions config: {e}")
        return {}
    
    def _save_extensions(self):
        """Save extension configurations to file"""
        try:
            data = {k: v.dict() for k, v in self.extensions.items()}
            with open(self.extensions_config_file, 'w') as f:
                json.dump(data, f, indent=2)
        except Exception as e:
            print(f"Error saving extensions config: {e}")
    
    def get_installed_extensions(self) -> List[ExtensionConfig]:
        """Get list of installed extensions"""
        # Scan the extensions directory for any extensions not in our config
        self._scan_extensions_directory()
        return list(self.extensions.values())
    
    def _scan_extensions_directory(self):
        """Scan extensions directory and update config"""
        if not self.extensions_dir.exists():
            return
            
        for ext_dir in self.extensions_dir.iterdir():
            if ext_dir.is_dir():
                # Check if this extension is in our config
                if ext_dir.name not in self.extensions:
                    # Try to load extension metadata
                    metadata = self._load_extension_metadata(ext_dir)
                    if metadata:
                        self.extensions[ext_dir.name] = ExtensionConfig(
                            id=ext_dir.name,
                            name=metadata.get('name', ext_dir.name),
                            version=metadata.get('version', 'unknown'),
                            description=metadata.get('description', ''),
                            author=metadata.get('author', 'Unknown'),
                            category=metadata.get('category', 'other'),
                            status='stopped',
                            install_date=datetime.now().isoformat(),
                            docker_compose_path=str(ext_dir / 'docker-compose.yml')
                        )
                        self._save_extensions()
    
    def _load_extension_metadata(self, ext_dir: Path) -> Optional[Dict[str, Any]]:
        """Load extension metadata from directory"""
        # Check for metadata.json
        metadata_file = ext_dir / 'metadata.json'
        if metadata_file.exists():
            try:
                with open(metadata_file, 'r') as f:
                    return json.load(f)
            except:
                pass
        
        # Check for docker-compose.yml labels
        compose_file = ext_dir / 'docker-compose.yml'
        if compose_file.exists():
            try:
                with open(compose_file, 'r') as f:
                    compose_data = yaml.safe_load(f)
                    
                # Extract metadata from labels
                for service_name, service_config in compose_data.get('services', {}).items():
                    labels = service_config.get('labels', {})
                    if 'uc1.extension.name' in labels:
                        return {
                            'name': labels.get('uc1.extension.name', ext_dir.name),
                            'version': labels.get('uc1.extension.version', 'unknown'),
                            'description': labels.get('uc1.extension.description', ''),
                            'author': labels.get('uc1.extension.author', 'Unknown'),
                            'category': labels.get('uc1.extension.category', 'other')
                        }
            except:
                pass
        
        return None
    
    async def install_extension(self, request: ExtensionInstallRequest) -> Dict[str, Any]:
        """Install an extension from a source URL"""
        ext_dir = self.extensions_dir / request.id
        
        try:
            # Check if already installed
            if ext_dir.exists():
                return {"success": False, "error": "Extension already installed"}
            
            # Create temporary directory for download
            with tempfile.TemporaryDirectory() as temp_dir:
                temp_path = Path(temp_dir)
                
                # Download the extension
                download_path = temp_path / "extension_download"
                
                # Simulate download (in real implementation, download from source_url)
                # For now, we'll create a basic structure
                self._create_sample_extension(ext_dir, request)
                
                # Add to config
                self.extensions[request.id] = ExtensionConfig(
                    id=request.id,
                    name=request.name,
                    version=request.version,
                    description=f"{request.name} extension",
                    author="UC-1 Pro",
                    category=request.category,
                    status='installed',
                    install_date=datetime.now().isoformat(),
                    docker_compose_path=str(ext_dir / 'docker-compose.yml')
                )
                self._save_extensions()
                
                return {
                    "success": True,
                    "message": f"Extension {request.name} installed successfully",
                    "extension": self.extensions[request.id].dict()
                }
                
        except Exception as e:
            # Clean up on error
            if ext_dir.exists():
                shutil.rmtree(ext_dir)
            return {"success": False, "error": str(e)}
    
    def _create_sample_extension(self, ext_dir: Path, request: ExtensionInstallRequest):
        """Create a sample extension structure"""
        ext_dir.mkdir(parents=True, exist_ok=True)
        
        # Create metadata.json
        metadata = {
            "id": request.id,
            "name": request.name,
            "version": request.version,
            "description": f"{request.name} extension for UC-1 Pro",
            "author": "UC-1 Pro",
            "category": request.category
        }
        
        with open(ext_dir / 'metadata.json', 'w') as f:
            json.dump(metadata, f, indent=2)
        
        # Create a sample docker-compose.yml
        compose_content = f"""version: '3.8'

services:
  {request.id}:
    image: nginx:alpine
    container_name: uc1-ext-{request.id}
    labels:
      uc1.extension.name: "{request.name}"
      uc1.extension.version: "{request.version}"
      uc1.extension.category: "{request.category}"
    networks:
      - unicorn-network
    restart: unless-stopped

networks:
  unicorn-network:
    external: true
"""
        
        with open(ext_dir / 'docker-compose.yml', 'w') as f:
            f.write(compose_content)
    
    async def uninstall_extension(self, extension_id: str) -> Dict[str, Any]:
        """Uninstall an extension"""
        try:
            if extension_id not in self.extensions:
                return {"success": False, "error": "Extension not found"}
            
            # Stop the extension first
            await self.control_extension(extension_id, "stop")
            
            # Remove extension directory
            ext_dir = self.extensions_dir / extension_id
            if ext_dir.exists():
                shutil.rmtree(ext_dir)
            
            # Remove from config
            del self.extensions[extension_id]
            self._save_extensions()
            
            return {"success": True, "message": f"Extension {extension_id} uninstalled successfully"}
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    async def control_extension(self, extension_id: str, action: str) -> Dict[str, Any]:
        """Control an extension (start, stop, restart)"""
        try:
            if extension_id not in self.extensions:
                return {"success": False, "error": "Extension not found"}
            
            ext_config = self.extensions[extension_id]
            ext_dir = self.extensions_dir / extension_id
            
            if not ext_dir.exists():
                return {"success": False, "error": "Extension directory not found"}
            
            compose_file = ext_dir / 'docker-compose.yml'
            if not compose_file.exists():
                return {"success": False, "error": "docker-compose.yml not found"}
            
            # Run docker-compose command
            cmd_map = {
                'start': ['docker-compose', '-f', str(compose_file), 'up', '-d'],
                'stop': ['docker-compose', '-f', str(compose_file), 'down'],
                'restart': ['docker-compose', '-f', str(compose_file), 'restart']
            }
            
            if action not in cmd_map:
                return {"success": False, "error": f"Invalid action: {action}"}
            
            # Execute command
            result = subprocess.run(
                cmd_map[action],
                capture_output=True,
                text=True,
                cwd=str(ext_dir)
            )
            
            if result.returncode == 0:
                # Update status
                if action == 'start':
                    ext_config.status = 'running'
                elif action == 'stop':
                    ext_config.status = 'stopped'
                
                self.extensions[extension_id] = ext_config
                self._save_extensions()
                
                return {
                    "success": True,
                    "message": f"Extension {extension_id} {action}ed successfully",
                    "output": result.stdout
                }
            else:
                return {
                    "success": False,
                    "error": result.stderr or f"Failed to {action} extension"
                }
                
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def update_extension_config(self, extension_id: str, config_update: ExtensionConfigUpdate) -> Dict[str, Any]:
        """Update extension configuration"""
        try:
            if extension_id not in self.extensions:
                return {"success": False, "error": "Extension not found"}
            
            # Update config
            self.extensions[extension_id].config.update(config_update.config)
            self._save_extensions()
            
            # Apply configuration if needed (extension-specific)
            # This would typically involve updating environment variables or config files
            
            return {
                "success": True,
                "message": "Configuration updated successfully",
                "extension": self.extensions[extension_id].dict()
            }
            
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def get_extension_logs(self, extension_id: str, lines: int = 100) -> Dict[str, Any]:
        """Get extension logs"""
        try:
            if extension_id not in self.extensions:
                return {"success": False, "error": "Extension not found"}
            
            ext_dir = self.extensions_dir / extension_id
            compose_file = ext_dir / 'docker-compose.yml'
            
            if not compose_file.exists():
                return {"success": False, "error": "docker-compose.yml not found"}
            
            # Get logs using docker-compose
            result = subprocess.run(
                ['docker-compose', '-f', str(compose_file), 'logs', '--tail', str(lines)],
                capture_output=True,
                text=True,
                cwd=str(ext_dir)
            )
            
            if result.returncode == 0:
                return {
                    "success": True,
                    "logs": result.stdout
                }
            else:
                return {
                    "success": False,
                    "error": result.stderr or "Failed to get logs"
                }
                
        except Exception as e:
            return {"success": False, "error": str(e)}

# Create singleton instance
extension_manager = ExtensionManager()