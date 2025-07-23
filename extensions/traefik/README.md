# Traefik Reverse Proxy

Traefik is a modern HTTP reverse proxy and load balancer that makes deploying microservices easy. It integrates directly with your existing infrastructure components (like Docker) and configures itself automatically and dynamically.

This setup provides a basic Traefik instance that can be used to route traffic to your UC-1 Pro services and other extensions.

## Features

- **Automatic Service Discovery**: Automatically discovers services running in Docker.
- **Dashboard**: A web UI to monitor and manage Traefik.
- **Let's Encrypt Integration**: (Optional) Automatically generates and renews SSL certificates.

## Setup and Usage

1.  **Navigate to the Traefik directory**:

    ```bash
    cd extensions/traefik
    ```

2.  **Start Traefik**:

    ```bash
    docker-compose up -d
    ```

3.  **Access the Dashboard**:

    Once Traefik is running, you can access its dashboard at `http://localhost:8080`.

    *Note: The dashboard is currently configured with a basic authentication (user: `test`, password: `test`). You should change this in `docker-compose.yml` for production use.*

4.  **Configure Services**: To route traffic to your services through Traefik, you need to add Traefik labels to their `docker-compose.yml` entries. For example, to expose Open-WebUI through Traefik:

    ```yaml
    # In your main docker-compose.yml, under the open-webui service:
    open-webui:
      # ... existing configuration ...
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.openwebui.rule=Host(`openwebui.localhost`)"
        - "traefik.http.routers.openwebui.entrypoint=web"
        - "traefik.http.services.openwebui.loadbalancer.server.port=8080"
    ```

    You would then access Open-WebUI at `http://openwebui.localhost` (after configuring your host's `hosts` file or DNS).

## Important Notes

-   **Security**: The provided `traefik.yml` and `docker-compose.yml` are for basic setup and local testing. For production, you should:
    -   Remove `api.insecure: true` from `traefik.yml`.
    -   Configure `certificatesResolvers` for HTTPS with Let's Encrypt.
    -   Change the basic authentication credentials for the dashboard.
-   **Network**: This Traefik instance connects to the `unicorn-network` to discover and route to your main UC-1 Pro services.
