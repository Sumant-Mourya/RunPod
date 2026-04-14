#!/bin/bash

set -e  # stop on error

echo "🚀 Starting RunPod Auto Setup..."

cd /workspace

# ==============================
# 1. SYSTEM SETUP
# ==============================

echo "📦 Installing system dependencies..."
apt-get update && apt-get install -y git wget curl python3-pip

# ==============================
# 2. CHECK HF TOKEN
# ==============================

if [ -z "$HF_TOKEN" ]; then
  echo "❌ ERROR: HF_TOKEN not set!"
  exit 1
fi

echo "🔐 Logging into HuggingFace..."

mkdir -p /root/.huggingface
echo "{\"token\":\"$HF_TOKEN\"}" > /root/.huggingface/token

# ==============================
# 3. INSTALL COMFYUI
# ==============================

if [ ! -d "ComfyUI" ]; then
  echo "📦 Cloning ComfyUI..."
  git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git
fi

cd ComfyUI

echo "📦 Installing Python requirements..."
pip install --upgrade pip
pip install -r requirements.txt

# ==============================
# 4. INSTALL CUSTOM NODES
# ==============================

cd custom_nodes

echo "📦 Installing custom nodes..."

git clone https://github.com/ltdrdata/ComfyUI-Manager.git || true
git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git || true
git clone https://github.com/WASasquatch/was-node-suite-comfyui.git || true

cd ..

echo "📦 Installing node dependencies..."
pip install -r custom_nodes/ComfyUI-Manager/requirements.txt || true
pip install -r custom_nodes/was-node-suite-comfyui/requirements.txt || true

# ==============================
# 5. MODEL DOWNLOAD
# ==============================

mkdir -p models/checkpoints
mkdir -p models/vae

MODEL_PATH="models/checkpoints/sdxl.safetensors"

if [ ! -f "$MODEL_PATH" ]; then
  echo "⬇️ Downloading SDXL model..."

  wget --progress=bar:force \
  --header="Authorization: Bearer $HF_TOKEN" \
  https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors \
  -O $MODEL_PATH
fi

# VAE (optional but recommended)
VAE_PATH="models/vae/sdxl_vae.safetensors"

if [ ! -f "$VAE_PATH" ]; then
  echo "⬇️ Downloading VAE..."

  wget --progress=bar:force \
  --header="Authorization: Bearer $HF_TOKEN" \
  https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors \
  -O $VAE_PATH
fi

# ==============================
# 6. START SERVER
# ==============================

echo "🚀 Starting ComfyUI..."

python main.py --listen 0.0.0.0 --port 8188
