#!/usr/bin/env python3
"""Analisa o espectro dos SFX para separar "impacto" de "bip".

Um bom som de impacto é broadband: muito grave (<200 Hz) + ruído distribuído,
sem picos tonais estreitos. Um "bip" tem um pico tonal dominante e pouca
energia grave.

Uso: python tools/audio/analyze_spectrum.py [filtro]
"""
import os
import subprocess
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")
SR = 44100


def load(path):
    proc = subprocess.run(
        ["ffmpeg", "-v", "quiet", "-i", path, "-f", "f32le", "-ac", "1", "-ar", str(SR), "-"],
        capture_output=True,
    )
    return np.frombuffer(proc.stdout, dtype=np.float32)


def analyze(path):
    x = load(path)
    if x.size < 1024:
        return None
    # janela mais energética (256 ms)
    win = int(SR * 0.256)
    if x.size > win:
        energy = np.convolve(x * x, np.ones(win) / win, mode="valid")
        start = int(np.argmax(energy))
        seg = x[start:start + win]
    else:
        seg = x
    seg = seg * np.hanning(seg.size)
    spec = np.abs(np.fft.rfft(seg))
    freqs = np.fft.rfftfreq(seg.size, 1.0 / SR)
    total = spec.sum() + 1e-12

    centroid = float((spec * freqs).sum() / total)
    geo = np.exp(np.mean(np.log(spec + 1e-12)))
    arith = np.mean(spec) + 1e-12
    flatness = float(geo / arith)

    low = float(spec[freqs < 200].sum() / total)
    high = float(spec[freqs > 4000].sum() / total)
    mid = 1.0 - low - high

    # pico tonal dominante e quanto ele concentra
    band = spec.copy()
    band[freqs < 60] = 0
    pk = int(np.argmax(band))
    peak_f = float(freqs[pk])
    # energia em ±3 bins do pico vs total
    lo, hi = max(pk - 3, 0), min(pk + 4, spec.size)
    peak_share = float(spec[lo:hi].sum() / total)

    return {
        "dur": x.size / SR,
        "centroid": centroid,
        "flat": flatness,
        "low": low, "mid": mid, "high": high,
        "peak_f": peak_f, "peak_share": peak_share,
    }


def verdict(m):
    if m["peak_share"] > 0.18 and m["flat"] < 0.10:
        return "BIP/TONAL"
    if m["low"] < 0.12:
        return "SEM CORPO"
    if m["high"] > 0.45:
        return "ESTRIDENTE"
    return "ok"


def main():
    flt = sys.argv[1] if len(sys.argv) > 1 else ""
    files = sorted(f for f in os.listdir(SFX_DIR) if f.endswith(".ogg") and flt in f)
    print(f"{'arquivo':<30} {'dur':>5} {'centro':>7} {'tons':>6} {'<200':>6} {'>4k':>6} {'pico':>7} {'%':>6}  veredito")
    for f in files:
        m = analyze(os.path.join(SFX_DIR, f))
        if not m:
            continue
        print(f"{f:<30} {m['dur']:>5.2f} {m['centroid']:>7.0f} {m['flat']:>6.3f} "
              f"{m['low']:>6.2f} {m['high']:>6.2f} {m['peak_f']:>7.0f} {m['peak_share']*100:>5.1f}%  {verdict(m)}")


if __name__ == "__main__":
    main()
