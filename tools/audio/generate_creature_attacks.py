#!/usr/bin/env python3
"""
Gera os SFX de ataque das criaturas (substitui os "bips" tonais).

Diagnóstico do que existia: os ataques de fera tinham só ~5% de energia abaixo
de 200 Hz e um pico tonal estreito em ~220 Hz — na prática, um bip fino. Somado
ao pitch aleatório de ±12% no jogo, virava "bip distorcido".

Princípios usados aqui:
  - impacto é BROADBAND: corpo grave (55–150 Hz) + ruído filtrado + transiente
  - nada de senoide varrendo para cima (isso lê como "bip"/laser)
  - envelope com ataque < 8 ms e cauda de 150–400 ms
  - pico normalizado em -3 dBFS (a masterização ajusta o RMS depois)

Uso: python tools/audio/generate_creature_attacks.py
"""
import os
import subprocess
import tempfile

import numpy as np
from scipy import signal

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")
SR = 44100
rng = np.random.default_rng(2026)


def t(dur):
    return np.linspace(0, dur, int(SR * dur), endpoint=False)


def env(dur, attack=0.004, decay=None, curve=3.0):
    """Envelope ataque-curto + decaimento exponencial."""
    n = int(SR * dur)
    a = max(int(SR * attack), 1)
    e = np.ones(n)
    e[:a] = np.linspace(0, 1, a)
    d = n - a
    if decay is None:
        decay = dur - attack
    e[a:] = np.exp(-np.linspace(0, curve, d) * (dur / max(decay, 0.01)) ** 0.35)
    return e


def noise(dur):
    return rng.standard_normal(int(SR * dur))


def bp(x, lo, hi, order=2):
    b, a = signal.butter(order, [lo / (SR / 2), min(hi, SR / 2 - 100) / (SR / 2)], "band")
    return signal.lfilter(b, a, x)


def lp(x, f, order=2):
    b, a = signal.butter(order, min(f, SR / 2 - 100) / (SR / 2), "low")
    return signal.lfilter(b, a, x)


def thump(dur, f_start=180.0, f_end=58.0, drop=0.075):
    """Corpo grave com queda de pitch (impacto), nunca subindo."""
    tt = t(dur)
    sweep = np.where(tt < drop, f_start * (f_end / f_start) ** (tt / drop), f_end)
    phase = 2 * np.pi * np.cumsum(sweep) / SR
    x = np.sin(phase)
    x += 0.35 * np.sin(2 * phase)          # 2º harmônico dá corpo
    return x * env(dur, 0.003, dur * 0.6, 4.0)


def finish(x, peak_db=-3.0, fade=0.02):
    x = x - np.mean(x)
    n = int(SR * fade)
    if n > 1 and x.size > n:
        x[-n:] *= np.linspace(1, 0, n)
    peak = np.max(np.abs(x)) or 1.0
    return x / peak * (10 ** (peak_db / 20.0))


def write(name, x):
    x = finish(x)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as fh:
        wav = fh.name
    import wave
    with wave.open(wav, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((np.clip(x, -1, 1) * 32767).astype("<i2").tobytes())
    out = os.path.join(SFX_DIR, name)
    subprocess.run(["ffmpeg", "-y", "-v", "quiet", "-i", wav,
                    "-c:a", "libvorbis", "-q:a", "6", out], check=True)
    os.unlink(wav)
    print("  ", name, f"{x.size / SR:.2f}s")


# --------------------------------------------------------------------------
def beast_attack(seed=0):
    """Rosnado + mordida: ruído em formante médio + corpo grave + sopro."""
    dur = 0.42
    bite = bp(noise(dur), 350, 2600) * env(dur, 0.002, 0.10, 5.0)
    growl_f = 78.0 + seed * 6.0
    tt = t(dur)
    growl = np.sin(2 * np.pi * growl_f * tt * (1 + 0.06 * np.sin(2 * np.pi * 22 * tt)))
    growl = lp(growl, 420) * env(dur, 0.02, 0.22, 2.5) * 0.55
    breath = lp(noise(dur), 900) * env(dur, 0.03, 0.30, 1.8) * 0.35
    body = thump(0.16, 160, 62) * 0.5
    x = np.zeros(int(SR * dur))
    x[:bite.size] += bite
    x[:growl.size] += growl
    x[:breath.size] += breath
    x[:body.size] += body
    return x


def heavy_attack(seed=0):
    """Golpe pesado: whoosh curto + baque grave + cauda de poeira."""
    dur = 0.50
    whoosh = bp(noise(dur), 500, 2400) * env(dur, 0.06, 0.12, 3.0) * 0.5
    impact = thump(0.22, 150, 52) * 0.9
    dust = bp(noise(dur), 120, 700) * env(dur, 0.004, 0.28, 3.2) * 0.45
    x = whoosh + dust
    x[:impact.size] += impact
    return x


def blunt_attack():
    """Pedra/punho: transiente seco + ressonância curta."""
    dur = 0.55
    hit = bp(noise(dur), 120, 1600) * env(dur, 0.001, 0.05, 6.0)
    body = thump(0.18, 130, 48)
    ring = np.sin(2 * np.pi * 720 * t(dur)) * env(dur, 0.005, 0.09, 5.0) * 0.12
    x = hit * 0.8 + ring
    x[:body.size] += body * 0.7
    return x


def spectral_attack():
    """Espectro: sussurro/grito etéreo, sem assobio agudo."""
    dur = 0.65
    core = bp(noise(dur), 600, 2800) * env(dur, 0.05, 0.35, 2.2)
    # leve modulação de amplitude (ar de criatura), não pitch
    mod = 1.0 + 0.35 * np.sin(2 * np.pi * 7.5 * t(dur))
    air = core * mod
    sub = lp(np.sin(2 * np.pi * 92 * t(dur)), 200) * env(dur, 0.03, 0.25, 2.0) * 0.35
    return air * 0.8 + sub


def main():
    print("gerando ataques de criatura:")
    for i in range(3):
        write(f"mob_attack_beast_{i + 1}.ogg", beast_attack(i))
    for i in range(3):
        write(f"mob_attack_heavy_{i + 1}.ogg", heavy_attack(i))
    write("mob_attack_blunt_1.ogg", blunt_attack())
    write("mob_attack_spectral_1.ogg", spectral_attack())
    # o jogo também usa "mob_attack" como base
    write("mob_attack.ogg", heavy_attack(1))
    print("pronto — rode tools/audio/master_sfx.py para equalizar o volume")


if __name__ == "__main__":
    main()
