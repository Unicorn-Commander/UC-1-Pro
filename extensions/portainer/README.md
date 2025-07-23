# Portainer Extension for UC-1 Pro

Portainer provides a powerful web-based Docker management interface for your UC-1 Pro stack.

## Features

- **Visual Container Management** - Start, stop, restart containers with one click
- **Resource Monitoring** - Real-time CPU, memory, and network usage
- **Log Viewer** - Browse container logs without SSH
- **Image Management** - Pull, delete, and manage Docker images
- **Volume & Network Management** - Visual interface for Docker resources
- **Stack Deployment** - Deploy new services via web UI
- **User Management** - Multi-user support with role-based access

## Quick Start

1. **Create admin password file:**
   ```bash
   echo "your-secure-password" > portainer_password.txt
   chmod 600 portainer_password.txt
   ```

2. **Start Portainer:**
   ```bash
   docker-compose up -d
   ```

3. **Access Portainer:**
   - HTTP: http://localhost:9000
   - HTTPS: https://localhost:9443 (self-signed cert)

4. **Initial Setup:**
   - Username: `admin`
   - Password: Contents of `portainer_password.txt`

## Integration with UC-1 Pro

Portainer automatically detects all UC-1 Pro services since it's connected to the same Docker daemon. You can:

- Monitor all UC-1 Pro containers
- View logs from vLLM, Open-WebUI, etc.
- Restart services without command line
- Check resource usage per service
- Update container images

## Security Considerations

- Portainer has full Docker daemon access
- Use strong admin password
- Consider using HTTPS in production
- Restrict network access if exposed

## Advanced Configuration

### Custom Admin Username

Edit docker-compose.yml:
```yaml
command: >
  --http-enabled
  --admin-password-file /run/secrets/portainer_pass
  --admin-username myusername
```

### SSL/TLS Certificates

For production, mount real certificates:
```yaml
volumes:
  - ./certs:/certs
command: >
  --http-enabled
  --ssl
  --sslcert /certs/cert.pem
  --sslkey /certs/key.pem
```

### Disable HTTP (HTTPS only)

Remove `--http-enabled` from the command section.

## Container Templates

Portainer can use templates to quickly deploy new services. Access via:
Settings → App Templates

Consider adding custom templates for:
- Additional LLM models
- Database replicas
- Monitoring tools

## Backup

Portainer stores its data in the `portainer_data` volume. To backup:

```bash
docker run --rm \
  -v uc1-pro_portainer_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/portainer-backup.tar.gz -C /data .
```

## Troubleshooting

### Can't Access Portainer
- Check if running: `docker ps | grep portainer`
- Check logs: `docker logs uc1-portainer`
- Ensure ports 9000/9443 aren't in use

### Forgot Admin Password
1. Stop Portainer: `docker-compose down`
2. Update `portainer_password.txt`
3. Start again: `docker-compose up -d`

### Container Management Issues
- Ensure Docker socket is mounted correctly
- Check Portainer has proper permissions
- Verify uc1-network exists

## Resource Usage

- Memory: ~50-100MB
- CPU: Minimal
- Disk: ~10MB + data