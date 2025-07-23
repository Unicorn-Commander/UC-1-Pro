# Model Manager

The Model Manager is a simple web UI for viewing the status of the vLLM service and switching between pre-configured models.

## Key Features

- **Status Monitoring**: View the currently loaded model in vLLM.
- **Model Switching**: Provides instructions for switching to a different model.

## Service Configuration

- **Build Context**: `services/model-manager`
- **Port**: `8084`

## API Endpoints

- `GET /`: The main web interface.
- `GET /api/models`: Returns a list of available models.
- `GET /api/status`: Returns the current status of the vLLM service.
- `POST /api/switch`: Provides instructions for switching the model.
- `GET /health`: A simple health check endpoint.

## Environment Variables

- `VLLM_URL`: The URL of the vLLM service.
- `VLLM_API_KEY`: The API key for the vLLM service.
