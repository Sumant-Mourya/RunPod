#!/bin/bash

echo "🚀 Starting RunPod Auto Setup..."

cd /workspace

# ==============================
# 1. BASIC SETUP
# ==============================

apt-get update && apt-get install -y git wget python3-pip

# Check HF token
if [ -z "$HF_TOKEN" ]; then
  echo "❌ ERROR: HF_TOKEN not set!"
  exit 1
fi

# HuggingFace login
mkdir -p /root/.huggingface
echo "{\"token\":\"$HF_TOKEN\"}" > /root/.huggingface/token

echo "✅ HuggingFace login configured"

# ==============================
# 2. INSTALL COMFYUI
# ==============================

if [ ! -d "ComfyUI" ]; then
  echo "📦 Cloning ComfyUI..."
  git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git
fi

cd ComfyUI

# Install requirements
echo "📦 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# ==============================
# 3. INSTALL CUSTOM NODES (IMPORTANT)
# ==============================

cd custom_nodes

# Manager (very useful)
if [ ! -d "ComfyUI-Manager" ]; then
  git clone https://github.com/ltdrdata/ComfyUI-Manager.git
fi

# Impact Pack (image tools)
if [ ! -d "ComfyUI-Impact-Pack" ]; then
  git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git
fi

# WAS Node Suite (extra utilities)
if [ ! -d "was-node-suite-comfyui" ]; then
  git clone https://github.com/WASasquatch/was-node-suite-comfyui.git
fi

cd ..

# Install node dependencies
echo "📦 Installing custom node dependencies..."
pip install -r custom_nodes/ComfyUI-Manager/requirements.txt || true
pip install -r custom_nodes/was-node-suite-comfyui/requirements.txt || true

# ==============================
# 4. DOWNLOAD MODELS
# ==============================

mkdir -p models/checkpoints
mkdir -p models/vae
mkdir -p models/clip

MODEL_PATH="models/checkpoints/sdxl.safetensors"

if [ ! -f "$MODEL_PATH" ]; then
  echo "⬇️ Downloading SDXL model..."

  wget --header="Authorization: Bearer $HF_TOKEN" \
  https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors \
  -O $MODEL_PATH
fi

# Optional: VAE (better quality)
VAE_PATH="models/vae/sdxl_vae.safetensors"

if [ ! -f "$VAE_PATH" ]; then
  echo "⬇️ Downloading VAE..."

  wget --header="Authorization: Bearer $HF_TOKEN" \
  https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors \
  -O $VAE_PATH
fi

# ==============================
# 5. START SERVER
# ==============================

echo "🚀 Starting ComfyUI API Server..."

python main.py --listen 0.0.0.0 --port 8188
