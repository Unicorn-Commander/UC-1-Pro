# WhisperX

WhisperX is a high-performance speech-to-text service that provides accurate transcriptions with word-level timestamps and speaker diarization.

## Key Features

- **Accurate Transcription**: Uses the Whisper model for high-quality speech recognition.
- **Word-Level Timestamps**: Provides timestamps for each word in the transcription.
- **Speaker Diarization**: Can identify and label different speakers in the audio (requires `HF_TOKEN`).

## Service Configuration

- **Build Context**: `services/whisperx`
- **Port**: `9000`

## API Endpoints

- `POST /v1/audio/transcriptions`: Transcribes an audio file.
- `GET /health`: A simple health check endpoint.

## Environment Variables

- `WHISPER_MODEL`: The size of the Whisper model to use.
- `DEVICE`: The device to run the model on (`cpu` or `cuda`).
- `COMPUTE_TYPE`: The computation type to use (`int8` or `float16`).
- `BATCH_SIZE`: The batch size for transcription.
- `HF_TOKEN`: The Hugging Face token for speaker diarization.
