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

# Upgrade pip first
RUN pip install --upgrade pip

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Create models directory
RUN mkdir -p models

# Download Kokoro model from onnx-community
RUN cd models && \
    wget -O kokoro-v0_19.onnx https://huggingface.co/onnx-community/Kokoro-82M-ONNX/resolve/main/onnx/model.onnx || \
    (echo "Download failed!" && exit 1)

# Create voices.json file
RUN cd models && \
    echo '{"voices": ["af", "af_bella", "af_sarah", "am_adam", "am_michael", "bf_emma", "bf_isabella", "bm_george", "bm_lewis"]}' > voices.json

COPY . .

EXPOSE 8880

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8880"]
