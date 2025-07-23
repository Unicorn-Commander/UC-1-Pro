# Kokoro TTS

Kokoro TTS is a text-to-speech service that generates natural-sounding speech from text.

## Key Features

- **High-Quality Speech**: Produces clear and natural-sounding speech.
- **Low Latency**: Optimized for low-latency synthesis.
- **Multiple Voices**: Supports multiple voice options.

## Service Configuration

- **Build Context**: `services/kokoro-tts`
- **Port**: `8880`
- **Hardware**: Intel iGPU (via OpenVINO)
- **Model**: kokoro-v0_19.onnx (~300MB)

## Model Management

The Kokoro TTS model can be pre-downloaded for faster startup:

```bash
./scripts/download-models.sh
```

The model is stored in `./volumes/kokoro_models/` and mounted into the container. If the model is not present, the service will attempt to download it on startup, though this may fail due to rate limits.

## API Endpoints

- `POST /v1/audio/speech`: Generates speech from text.
- `GET /voices`: Returns a list of available voices.
- `GET /health`: A simple health check endpoint.

## Environment Variables

- `DEVICE`: The device to run the model on (`CPU` or `GPU`).
- `DEFAULT_VOICE`: The default voice to use.
