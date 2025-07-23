# n8n Workflow Automation

n8n is a free and open-source workflow automation tool. It allows you to connect anything to everything with its 400+ integrations.

## Setup and Usage

1.  **Navigate to the n8n directory**:

    ```bash
    cd extensions/n8n
    ```

2.  **Start n8n**:

    ```bash
    docker-compose up -d
    ```

3.  **Access n8n**:

    Once n8n is running, you can access its web interface at `http://localhost:5678`.

## Important Notes

-   **Timezone**: Remember to adjust the `GENERIC_TIMEZONE` environment variable in `docker-compose.yml` to your local timezone.
-   **Data Persistence**: For persistent data (workflows, credentials), you should uncomment the `volumes` line in `docker-compose.yml` and ensure the `./data` directory exists.
-   **Network**: This n8n instance connects to the `unicorn-network`, allowing it to interact with your UC-1 Pro services (e.g., sending requests to vLLM, Open-WebUI, etc.).
