#!/bin/bash

# Script to download Kokoro TTS model manually

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Kokoro TTS Model Downloader${NC}"
echo "============================"
echo ""

# Create model directory
MODEL_DIR="volumes/kokoro_models"
mkdir -p "$MODEL_DIR"

echo "Attempting to download Kokoro v0.19 ONNX model..."
echo ""

# Try different sources
URLS=(
    "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files/kokoro-v0_19.onnx"
    "https://huggingface.co/NeuML/kokoro-base-onnx/resolve/main/model.onnx"
    "https://github.com/remsky/Kokoro-FastAPI/releases/download/v0.1.0/kokoro-v0_19.onnx"
)

for url in "${URLS[@]}"; do
    echo -e "${YELLOW}Trying: $url${NC}"
    if wget -O "$MODEL_DIR/kokoro-v0_19.onnx" "$url" 2>/dev/null; then
        echo -e "${GREEN}✓ Download successful!${NC}"
        
        # Verify file size (should be ~310MB)
        SIZE=$(du -m "$MODEL_DIR/kokoro-v0_19.onnx" | cut -f1)
        if [ "$SIZE" -gt 100 ]; then
            echo -e "${GREEN}✓ Model size verified: ${SIZE}MB${NC}"
            
            # Create voices.json
            echo '{"voices": ["af", "af_bella", "af_sarah", "am_adam", "am_michael", "bf_emma", "bf_isabella", "bm_george", "bm_lewis"]}' > "$MODEL_DIR/voices.json"
            
            echo ""
            echo -e "${GREEN}Model downloaded successfully!${NC}"
            echo ""
            echo "Next steps:"
            echo "1. Update docker-compose.yml to mount the model:"
            echo "   Add to kokoro-tts service volumes:"
            echo "     - ./volumes/kokoro_models:/app/models"
            echo ""
            echo "2. Restart Kokoro service:"
            echo "   docker compose restart kokoro-tts"
            
            exit 0
        else
            echo -e "${RED}✗ File too small (${SIZE}MB), download may have failed${NC}"
            rm -f "$MODEL_DIR/kokoro-v0_19.onnx"
        fi
    else
        echo -e "${RED}✗ Download failed${NC}"
    fi
done

echo ""
echo -e "${RED}All download attempts failed!${NC}"
echo ""
echo "Manual download instructions:"
echo "1. Visit: https://github.com/thewh1teagle/kokoro-onnx/releases"
echo "2. Download kokoro-v0_19.onnx (310MB)"
echo "3. Place it in: $MODEL_DIR/"
echo ""
exit 1