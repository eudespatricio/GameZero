#!/usr/bin/env bash
# GameZero Beta - Lançador com Aceleração Nativa na GPU (Vulkan Forward+)
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=================================================="
echo "🐉 INICIANDO GAMEZERO BETA COM VULKAN FORWARD+"
echo "GPU Detectada: NVIDIA GeForce RTX 3060"
echo "=================================================="

godot --rendering-driver vulkan
