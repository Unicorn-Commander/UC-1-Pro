# Extensions

The `extensions/` directory contains optional services that can be run alongside the main UC-1 Pro stack. Each extension is self-contained with its own `docker-compose.yml` and `README.md` for specific setup and usage instructions.

These extensions are designed to connect to the `unicorn-network`, allowing them to seamlessly integrate and communicate with your core UC-1 Pro services (e.g., vLLM, Open-WebUI).

## How to Use Extensions

To run an extension, navigate to its specific directory and use `docker-compose up -d`:

```bash
cd extensions/<extension-name>
docker-compose up -d
```

## Available Extensions

### Traefik

Traefik is a modern HTTP reverse proxy and load balancer that makes deploying microservices easy. It integrates directly with your existing infrastructure components (like Docker) and configures itself automatically and dynamically.

For detailed setup and usage instructions, see: [`extensions/traefik/README.md`](../../extensions/traefik/README.md)

### Bolt.DIY

Bolt.DIY is a development environment for building AI applications. It allows you to quickly prototype and experiment with different LLMs and AI tools.

For detailed setup and usage instructions, see: [`extensions/bolt.diy/README.md`](../../extensions/bolt.diy/README.md)

### n8n

n8n is a free and open-source workflow automation tool. It allows you to connect anything to everything with its 400+ integrations, enabling powerful automation workflows.

For detailed setup and usage instructions, see: [`extensions/n8n/README.md`](../../extensions/n8n/README.md)
