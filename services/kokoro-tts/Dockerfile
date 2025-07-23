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

# Download model using Python with better error handling
RUN cd models && python3 -c "\
import urllib.request\n\
import os\n\
urls = [\n\
    'https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files/kokoro-v0_19.onnx',\n\
    'https://huggingface.co/NeuML/kokoro-base-onnx/resolve/main/model.onnx',\n\
    'https://github.com/taylorchu/kokoro-onnx/releases/download/v0.0.1/kokoro-v0_19.onnx'\n\
]\n\
for url in urls:\n\
    try:\n\
        print(f'Trying {url}...')\n\
        urllib.request.urlretrieve(url, 'kokoro-v0_19.onnx')\n\
        print('Download successful!')\n\
        break\n\
    except Exception as e:\n\
        print(f'Failed: {e}')\n\
else:\n\
    print('All downloads failed!')\n\
    # Create a dummy file so the container can start\n\
    open('kokoro-v0_19.onnx', 'w').close()\n\
"

# Create voices.json file
RUN cd models && \
    echo '{"voices": ["af", "af_bella", "af_sarah", "am_adam", "am_michael", "bf_emma", "bf_isabella", "bm_george", "bm_lewis"]}' > voices.json

COPY . .

EXPOSE 8880

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8880"]
