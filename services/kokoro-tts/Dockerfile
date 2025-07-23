FROM python:3.10-slim

RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    libgomp1 \
    libtbb12 \
    ocl-icd-libopencl1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Create models directory
RUN mkdir -p models

# Download Kokoro model - try HuggingFace directly
RUN cd models && \
    curl -L -o kokoro-v0_19.onnx https://huggingface.co/hexgrad/Kokoro-82M/resolve/main/kokoro-v0_19.onnx

# Create voices.json file
RUN cd models && \
    echo '{"voices": ["af", "af_bella", "af_sarah", "am_adam", "am_michael", "bf_emma", "bf_isabella", "bm_george", "bm_lewis"]}' > voices.json

COPY . .

EXPOSE 8880

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8880"]
