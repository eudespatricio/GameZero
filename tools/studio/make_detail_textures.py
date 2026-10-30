#!/usr/bin/env python3
"""Gera texturas tileáveis de detalhe (albedo neutro + normal map) para os modelos.

Sem UV: o Godot aplica com `uv1_triplanar`, então a mesma textura serve para
qualquer criatura (pelo, casca, pedra, tecido) sem trabalho de mapeamento.

Saída: assets/textures/detail_albedo.png, detail_normal.png
"""
import os

import numpy as np
from PIL import Image

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(
    os.path.abspath(__file__)))), "assets", "textures")
SIZE = 512


def value_noise(size, freq, rng):
    """Ruído de valor tileável (grade periódica + interpolação suave)."""
    grid = rng.random((freq, freq)).astype(np.float32)
    grid = np.pad(grid, ((0, 1), (0, 1)), mode="wrap")
    ys = np.linspace(0, freq, size, endpoint=False)
    xs = np.linspace(0, freq, size, endpoint=False)
    y0 = np.floor(ys).astype(int)
    x0 = np.floor(xs).astype(int)
    fy = (ys - y0)[:, None]
    fx = (xs - x0)[None, :]
    fy = fy * fy * fy * (fy * (fy * 6 - 15) + 10)
    fx = fx * fx * fx * (fx * (fx * 6 - 15) + 10)

    a = grid[y0][:, x0]
    b = grid[y0][:, x0 + 1]
    c = grid[y0 + 1][:, x0]
    d = grid[y0 + 1][:, x0 + 1]
    top = a + (b - a) * fx
    bot = c + (d - c) * fx
    return top + (bot - top) * fy


def fbm(size, rng, octaves=(4, 8, 16, 32, 64), weights=(0.5, 0.26, 0.14, 0.07, 0.03)):
    acc = np.zeros((size, size), dtype=np.float32)
    for freq, w in zip(octaves, weights):
        acc += value_noise(size, freq, rng) * w
    acc -= acc.min()
    acc /= max(acc.max(), 1e-6)
    return acc


def normal_from_height(h, strength=2.2):
    dx = np.roll(h, -1, axis=1) - np.roll(h, 1, axis=1)
    dy = np.roll(h, -1, axis=0) - np.roll(h, 1, axis=0)
    nx = -dx * strength
    ny = -dy * strength
    nz = np.ones_like(h)
    ln = np.sqrt(nx * nx + ny * ny + nz * nz)
    out = np.stack([nx / ln, ny / ln, nz / ln], axis=-1)
    return ((out * 0.5 + 0.5) * 255.0).astype(np.uint8)


def main():
    os.makedirs(OUT, exist_ok=True)
    rng = np.random.default_rng(7)

    height = fbm(SIZE, rng)
    # fibra fina (direção Y) — lê como pelo/pelagem
    fiber = fbm(SIZE, rng, octaves=(48, 96), weights=(0.6, 0.4))
    height = np.clip(height * 0.72 + fiber * 0.28, 0.0, 1.0)

    # albedo neutro: 0.72..1.0 (multiplica a cor base sem escurecer demais)
    albedo = (0.72 + height * 0.28) * 255.0
    rgb = np.stack([albedo, albedo, albedo], axis=-1).astype(np.uint8)
    Image.fromarray(rgb).save(os.path.join(OUT, "detail_albedo.png"))

    Image.fromarray(normal_from_height(height, 2.6)).save(
        os.path.join(OUT, "detail_normal.png"))
    print("texturas geradas em", OUT)


if __name__ == "__main__":
    main()
