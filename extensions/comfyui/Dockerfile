FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    wget \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgoogle-perftools4 \
    libtcmalloc-minimal4 \
    && ln -s /usr/bin/python3 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git . && \
    git checkout master

# Install PyTorch with CUDA support
RUN pip3 install --no-cache-dir \
    torch==2.1.2 torchvision==0.16.2 torchaudio==2.1.2 \
    --index-url https://download.pytorch.org/whl/cu121

# Install ComfyUI requirements
RUN pip3 install --no-cache-dir -r requirements.txt

# Install additional packages for Flux support
RUN pip3 install --no-cache-dir \
    diffusers>=0.25.0 \
    transformers>=4.36.0 \
    accelerate>=0.25.0 \
    sentencepiece \
    protobuf \
    safetensors \
    omegaconf \
    einops

# Create necessary directories
RUN mkdir -p \
    models/checkpoints \
    models/vae \
    models/loras \
    models/controlnet \
    models/clip \
    models/unet \
    models/diffusers \
    custom_nodes \
    input \
    output \
    temp \
    workflows

# Install ComfyUI Manager
RUN cd custom_nodes && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git && \
    cd ComfyUI-Manager && \
    pip3 install -r requirements.txt

# Create a simple startup script
RUN echo '#!/bin/bash\n\
echo "Starting ComfyUI..."\n\
python main.py --listen 0.0.0.0 --port 8188 $COMMANDLINE_ARGS\n\
' > /app/start.sh && chmod +x /app/start.sh

# Expose port
EXPOSE 8188

# Use tcmalloc for better memory management
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libtcmalloc_minimal.so.4

# Start ComfyUI
CMD ["/app/start.sh"]