FROM python:3.10-slim

RUN apt-get update && apt-get install -y \
    git \
    wget \
    libgomp1 \
    libtbb12 \
    ocl-icd-libopencl1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Download Kokoro models
RUN mkdir -p models && cd models && \
    wget -q https://github.com/thewh1teagle/kokoro-fastapi/releases/download/v0.1.0/kokoro-v0_19.onnx && \
    wget -q https://github.com/thewh1teagle/kokoro-fastapi/releases/download/v0.1.0/voices.json

COPY . .

EXPOSE 8880

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8880"]
