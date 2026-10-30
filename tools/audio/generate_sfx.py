#!/usr/bin/env python3
"""
GameZero — gerador procedural de áudio (SFX, ambiências e trilhas) com numpy/scipy + ffmpeg.

Uso (venv fora do repositório):
    ~/.venvs/gamezero-audio/bin/python tools/audio/generate_sfx.py [filtro_de_nome]

Saída: assets/audio/{sfx,ambient,music}/*.ogg  (Vorbis, 44.1 kHz) — importados automaticamente pelo Godot.
Tudo é determinístico (semente fixa), então os arquivos podem ser regenerados a qualquer momento.
"""
import os
import subprocess
import sys
import tempfile

import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "audio")
rng = np.random.default_rng(1337)
ONLY = sys.argv[1] if len(sys.argv) > 1 else ""


# ----------------------------------------------------------------------------------------------
# Ferramentas de DSP
# ----------------------------------------------------------------------------------------------
def T(d):
    return np.arange(int(d * SR)) / SR


def noise(d):
    return rng.standard_normal(int(d * SR))


def pink(d):
    w = noise(d)
    b, a = signal.butter(1, 0.08)  # aproxima 1/f com low-pass suave misturado ao branco
    return 0.65 * signal.lfilter(b, a, w) * 4.0 + 0.35 * w


def sos(kind, fc, order=4):
    return signal.butter(order, fc, kind, fs=SR, output="sos")


def lp(x, fc, order=4):
    return signal.sosfilt(sos("low", min(fc, SR * 0.45), order), x)


def hp(x, fc, order=4):
    return signal.sosfilt(sos("high", fc, order), x)


def bp(x, lo, hi, order=3):
    return signal.sosfilt(sos("band", [lo, min(hi, SR * 0.45)], order), x)


def ar(t, a=0.005, tau=0.1):
    """Ataque linear curto + decaimento exponencial."""
    return np.minimum(t / max(a, 1e-4), 1.0) * np.exp(-t / tau)


def fade(x, fin=0.005, fout=0.02):
    n = len(x)
    fi, fo = int(fin * SR), int(fout * SR)
    if fi > 0:
        x[:fi] *= np.linspace(0, 1, fi)
    if fo > 0:
        x[-fo:] *= np.linspace(1, 0, fo)
    return x


def sine(f, d, phase=0.0):
    t = T(d)
    f = np.asarray(f) if np.ndim(f) else f
    ph = 2 * np.pi * np.cumsum(f * np.ones_like(t)) / SR if np.ndim(f) else 2 * np.pi * f * t
    return np.sin(ph + phase)


def saw(f, d):
    t = T(d)
    ph = np.cumsum(f * np.ones_like(t)) / SR
    return 2.0 * (ph - np.floor(ph + 0.5))


def glide(f0, f1, d, curve=1.0):
    u = np.linspace(0, 1, int(d * SR)) ** curve
    return f0 * (f1 / f0) ** u


def noise_sweep(d, f0, f1, width=0.7, bands=16, lo=80.0, hi=9000.0):
    """Ruído filtrado cujo centro espectral percorre f0->f1 (whooshes, rajadas)."""
    t = T(d)
    n = noise(d)
    centers = np.geomspace(lo, hi, bands)
    fc_t = f0 * (f1 / f0) ** (t / max(d, 1e-3))
    out = np.zeros_like(t)
    for c in centers:
        band = bp(n, c / 1.25, c * 1.25, 2)
        g = np.exp(-0.5 * ((np.log2(c) - np.log2(fc_t)) / width) ** 2)
        out += band * g
    return out / (np.max(np.abs(out)) + 1e-9)


def reverb(x, decay=1.2, wet=0.3, damp=4500.0, pre=0.012):
    """Reverb por convolução com resposta sintética (ruído com decaimento exponencial)."""
    n = int(decay * 3.0 * SR)
    t = np.arange(n) / SR
    ir = rng.standard_normal(n) * np.exp(-t * 6.9 / decay)
    ir = lp(ir, damp, 2)
    ir[: int(pre * SR)] = 0.0
    ir /= np.sqrt(np.sum(ir**2)) + 1e-9
    if x.ndim == 1:
        y = signal.fftconvolve(x, ir)
        dry = np.pad(x, (0, len(y) - len(x)))
        return dry * (1 - wet) + y * wet
    chans = []
    for c in range(x.shape[1]):
        ir_c = np.roll(ir, c * 37)
        y = signal.fftconvolve(x[:, c], ir_c)
        dry = np.pad(x[:, c], (0, len(y) - len(x)))
        chans.append(dry * (1 - wet) + y * wet)
    return np.stack(chans, axis=1)


def softclip(x, drive=1.5):
    return np.tanh(x * drive) / np.tanh(drive)


def bell(f, d, partials=((1, 1.0, 1.0), (2.76, 0.5, 0.7), (5.4, 0.28, 0.45), (8.93, 0.14, 0.3))):
    t = T(d)
    out = np.zeros_like(t)
    for ratio, amp, dec in partials:
        out += amp * np.sin(2 * np.pi * f * ratio * t) * ar(t, 0.002, d * 0.45 * dec)
    return out


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p
    return out


def place(buf, x, at):
    i = int(at * SR)
    end = min(len(buf), i + len(x))
    if end > i:
        buf[i:end] += x[: end - i]
    return buf


def seamless(x, tail):
    """Torna um sinal (n,) ou (n,2) cíclico somando a cauda extra (tail s) ao início."""
    k = int(tail * SR)
    body, extra = x[:-k], x[-k:]
    out = body.copy()
    out[:k] = out[:k] + extra
    return out


# ----------------------------------------------------------------------------------------------
# Exportação
# ----------------------------------------------------------------------------------------------
# Ganho relativo por prefixo de nome (dB abaixo do pico) para equilibrar a mixagem entre efeitos
GAIN_DB = {
    "step_": -17, "ui_click": -11, "ui_open": -9, "ui_close": -10, "ui_confirm": -8, "coin_": -9, "loot_item": -8,
    "loot_rare": -5, "gather": -9, "jump": -12, "land": -9, "dash": -7, "slash_": -5, "hit_flesh": -3, "hit_crit": -2,
    "player_hurt": -4, "spell_charge": -10, "no_mana": -10, "potion": -8, "wing_flap": -8, "growl_small": -6,
    "growl_beast": -5, "growl_large": -3, "growl_wraith": -5, "mob_death": -5, "mob_attack": -9, "anvil_": -6,
    "craft_": -5, "portal_hum": -14, "portal_open": -4, "teleport": -3, "level_up": -4, "brisingr": -3, "vortex": -4,
}


def trim_tail(x, thresh=0.002):
    mono = np.max(np.abs(x), axis=1) if x.ndim == 2 else np.abs(x)
    idx = np.where(mono > thresh)[0]
    if len(idx) == 0:
        return x
    end = min(len(x), idx[-1] + int(0.06 * SR))
    y = x[:end].copy()
    k = min(int(0.05 * SR), len(y))
    ramp = np.linspace(1, 0, k)
    if y.ndim == 2:
        ramp = ramp[:, None]
    y[-k:] *= ramp
    return y


def export(folder, name, x, peak_db=-1.5, lufs=None, trim=None):
    if ONLY and ONLY not in name:
        return
    x = np.asarray(x, dtype=np.float64)
    x = x - np.mean(x, axis=0)
    if trim is None:
        trim = folder == "sfx"
    m = np.max(np.abs(x)) + 1e-9
    x = x / m
    if trim:
        x = trim_tail(x)
    for prefix, g in GAIN_DB.items():
        if name.startswith(prefix):
            peak_db += g
            break
    x = x * (10 ** (peak_db / 20))
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    out_dir = os.path.join(OUT, folder)
    os.makedirs(out_dir, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tf:
        tmp = tf.name
    wavfile.write(tmp, SR, pcm)
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-i", tmp]
    if lufs is not None:
        cmd += ["-af", f"loudnorm=I={lufs}:TP=-1.5:LRA=9"]
    cmd += ["-c:a", "libvorbis", "-q:a", "5", "-ar", str(SR), os.path.join(out_dir, name + ".ogg")]
    subprocess.run(cmd, check=True)
    os.remove(tmp)
    print(f"  {folder}/{name}.ogg  {len(x) / SR:5.2f}s")


# ----------------------------------------------------------------------------------------------
# EFEITOS SONOROS (SFX)
# ----------------------------------------------------------------------------------------------
def make_sfx():
    # --- Espada: três cortes (pitch cresce no finalizador) ---
    for i, (f0, f1, ring) in enumerate([(1800, 5200, 2300), (2200, 6200, 2700), (1100, 7200, 3300)], start=1):
        d = 0.34 if i < 3 else 0.5
        w = noise_sweep(d, f0, f1, 0.6) * ar(T(d), 0.01, d * 0.35)
        metal = bell(ring, d, ((1, 1, 1), (2.4, 0.4, 0.7), (4.1, 0.2, 0.5))) * 0.25 * ar(T(d), 0.03, d * 0.4)
        x = fade(mix(w, metal), 0.002, 0.04)
        export("sfx", f"slash_{i}", reverb(x, 0.35, 0.12))

    # --- Impactos ---
    t = T(0.3)
    thump = sine(glide(190, 48, 0.3, 0.6), 0.3) * ar(t, 0.002, 0.07)
    crunch = lp(noise(0.3), 2600) * ar(t, 0.001, 0.045)
    export("sfx", "hit_flesh", fade(softclip(thump * 1.1 + crunch * 0.7, 1.4), 0.001, 0.05))

    t = T(0.6)
    heavy = sine(glide(240, 40, 0.6, 0.5), 0.6) * ar(t, 0.002, 0.13)
    ring = bell(1760, 0.6) * 0.35 * ar(t, 0.004, 0.25)
    spark = hp(noise(0.6), 5000) * ar(t, 0.001, 0.07) * 0.5
    export("sfx", "hit_crit", reverb(softclip(heavy + ring + spark, 1.3), 0.5, 0.2))

    t = T(0.45)
    hurt = lp(saw(glide(260, 130, 0.45), 0.45) * ar(t, 0.003, 0.12), 1800) + lp(noise(0.45), 900) * ar(t, 0.001, 0.05) * 0.5
    export("sfx", "player_hurt", fade(softclip(hurt, 1.5), 0.002, 0.06))

    # --- Magias ---
    d = 1.0
    t = T(d)
    whoosh = noise_sweep(d, 300, 3600, 0.9) * (np.minimum(t / 0.25, 1) * np.exp(-np.maximum(t - 0.25, 0) / 0.35))
    roar = lp(noise(d), 900) * (1 + 0.5 * np.sin(2 * np.pi * 23 * t)) * ar(t, 0.05, 0.4)
    shimmer = sum(sine(f * (1 + 0.003 * k), d) * 0.12 for k, f in enumerate([1320, 1760, 2349, 3135])) * ar(t, 0.04, 0.5)
    export("sfx", "brisingr_cast", reverb(softclip(whoosh * 1.0 + roar * 0.55 + shimmer, 1.3), 0.9, 0.22))

    d = 1.5
    t = T(d)
    boom = sine(glide(78, 26, d, 0.35), d) * ar(t, 0.003, 0.32)
    sub = sine(42, d) * ar(t, 0.01, 0.5) * 0.6
    rocks = hp(noise(d), 300) * ar(t, 0.004, 0.12) * 0.7
    cracks = np.zeros_like(t)
    for k in range(7):
        c = bp(noise(0.12), 800 + 500 * k, 3000 + 800 * k) * ar(T(0.12), 0.001, 0.02)
        place(cracks, c * (0.7 - 0.07 * k), 0.04 + k * rng.uniform(0.05, 0.11))
    export("sfx", "jierda_cast", reverb(softclip(boom * 1.2 + sub + rocks + cracks * 0.6, 1.4), 1.2, 0.28, 3500))

    d = 2.8
    t = T(d)
    base = sine(glide(110, 220, d, 1.4), d) * 0.6 + sine(glide(112, 224, d, 1.4), d) * 0.5
    trem = 0.6 + 0.4 * np.sin(2 * np.pi * glide(3, 11, d) * t)
    sweep = noise_sweep(d, 600, 2600, 0.7) * 0.5
    shimmer = (sine(880, d) + sine(1318, d) * 0.7 + sine(1760, d) * 0.4) * 0.12 * (0.5 + 0.5 * np.sin(2 * np.pi * 6 * t))
    env = np.minimum(t / 0.3, 1) * np.minimum((d - t) / 0.5, 1)
    export("sfx", "vortex_cast", reverb(softclip((base * trem + sweep + shimmer) * env, 1.2), 1.0, 0.25))

    d = 0.55
    t = T(d)
    charge = noise_sweep(d, 500, 4000, 0.8) * np.minimum(t / d, 1) ** 2 * 0.6 + sine(glide(300, 1200, d), d) * 0.2 * np.minimum(t / d, 1)
    export("sfx", "spell_charge", fade(charge, 0.01, 0.06))

    t = T(0.4)
    dull = lp(noise(0.4), 500) * ar(t, 0.002, 0.04) + sine(120, 0.4) * ar(t, 0.002, 0.05) * 0.5
    export("sfx", "no_mana", fade(dull, 0.001, 0.04))

    # --- Movimento ---
    t = T(0.35)
    export("sfx", "dash", fade(noise_sweep(0.35, 800, 5200, 0.8) * ar(t, 0.03, 0.12), 0.002, 0.08))
    t = T(0.3)
    export("sfx", "land", fade(lp(noise(0.3), 700) * ar(t, 0.002, 0.07) + sine(glide(110, 50, 0.3), 0.3) * ar(t, 0.002, 0.06) * 0.8, 0.001, 0.05))
    t = T(0.25)
    export("sfx", "jump", fade(noise_sweep(0.25, 400, 1800, 0.7) * ar(t, 0.02, 0.1) * 0.5, 0.002, 0.05))

    for i in range(4):  # grama
        t = T(0.16)
        x = bp(noise(0.16), 1500 + 300 * i, 6500, 2) * ar(t, 0.004, 0.035) + lp(noise(0.16), 400) * ar(t, 0.001, 0.03) * 0.4
        export("sfx", f"step_grass_{i + 1}", fade(x, 0.001, 0.03))
    for i in range(3):  # pedra
        t = T(0.2)
        x = hp(noise(0.2), 1800) * ar(t, 0.0005, 0.018) * 0.7 + sine(rng.uniform(180, 260), 0.2) * ar(t, 0.001, 0.03) * 0.4 + bell(rng.uniform(1900, 2600), 0.2) * 0.07
        export("sfx", f"step_stone_{i + 1}", fade(x, 0.0005, 0.04))
    for i in range(3):  # terra/areia
        t = T(0.18)
        x = lp(noise(0.18), 2200) * ar(t, 0.003, 0.04) + lp(noise(0.18), 300) * ar(t, 0.001, 0.03) * 0.5
        export("sfx", f"step_dirt_{i + 1}", fade(x, 0.001, 0.04))

    # --- Itens / UI ---
    for i, base in enumerate([1568, 2093], start=1):
        x = np.zeros(int(0.6 * SR))
        place(x, bell(base, 0.5), 0.0)
        place(x, bell(base * 1.5, 0.5), 0.07)
        export("sfx", f"coin_{i}", reverb(x * 0.7, 0.4, 0.15))
    x = np.zeros(int(0.7 * SR))
    for k, f in enumerate([880, 1175, 1568]):
        place(x, bell(f, 0.5), k * 0.06)
    export("sfx", "loot_item", reverb(x * 0.6, 0.5, 0.2))

    x = np.zeros(int(0.9 * SR))
    for k, f in enumerate([1320, 1760, 2349, 3136, 2349]):
        place(x, bell(f, 0.5), k * 0.05)
    export("sfx", "loot_rare", reverb(x * 0.5, 0.8, 0.28))

    x = np.zeros(int(0.7 * SR))
    for k in range(3):
        g = sine(glide(220, 90, 0.09), 0.09) * ar(T(0.09), 0.004, 0.03)
        place(x, g, k * 0.13)
    place(x, bell(2600, 0.35) * 0.18, 0.4)
    export("sfx", "potion", reverb(x, 0.4, 0.15))

    t = T(0.14)
    export("sfx", "ui_click", fade(bell(1900, 0.14) * ar(t, 0.001, 0.03) + hp(noise(0.14), 4000) * ar(t, 0.0005, 0.01) * 0.2, 0.0005, 0.02))
    t = T(0.3)
    export("sfx", "ui_open", fade(noise_sweep(0.3, 500, 3000, 0.7) * ar(t, 0.04, 0.1) * 0.45 + bell(1320, 0.3) * 0.25, 0.002, 0.06))
    export("sfx", "ui_close", fade(noise_sweep(0.25, 3000, 600, 0.7) * ar(T(0.25), 0.02, 0.08) * 0.45 + bell(990, 0.25) * 0.2, 0.002, 0.05))
    x = np.zeros(int(1.0 * SR))
    for k, f in enumerate([523, 659, 784, 1047]):
        place(x, bell(f, 0.8), k * 0.09)
    export("sfx", "ui_confirm", reverb(x * 0.5, 0.7, 0.25))

    # --- Level up / refino / forja ---
    d = 2.4
    x = np.zeros(int(d * SR))
    for k, f in enumerate([523, 659, 784, 1047, 1319, 1568]):
        place(x, bell(f, 1.2) * 0.8, k * 0.11)
    pad = sum(sine(f, d) * 0.12 for f in [262, 330, 392, 523]) * np.minimum(T(d) / 0.4, 1) * np.exp(-np.maximum(T(d) - 0.8, 0) / 0.7)
    export("sfx", "level_up", reverb(x + pad, 1.6, 0.35))

    d = 1.0
    x = np.zeros(int(d * SR))
    for k, f in enumerate([784, 988, 1175, 1568]):
        place(x, bell(f, 0.7), k * 0.07)
    place(x, noise_sweep(0.5, 800, 6000, 0.8) * 0.2 * ar(T(0.5), 0.02, 0.2), 0.0)
    export("sfx", "craft_success", reverb(x, 0.9, 0.3))

    d = 0.9
    t = T(d)
    x = sine(glide(220, 70, d), d) * ar(t, 0.01, 0.3) * 0.7 + lp(noise(d), 800) * ar(t, 0.003, 0.12) * 0.5
    export("sfx", "craft_fail", reverb(softclip(x, 1.4), 0.5, 0.2))

    for i in range(3):  # martelo na bigorna
        t = T(0.7)
        clang = bell(rng.uniform(640, 820), 0.7, ((1, 1, 1), (2.32, 0.7, 0.8), (4.0, 0.5, 0.6), (6.7, 0.3, 0.4))) * ar(t, 0.001, 0.2)
        hit = hp(noise(0.7), 1500) * ar(t, 0.0005, 0.012) * 0.6
        export("sfx", f"anvil_{i + 1}", reverb(clang + hit, 0.4, 0.15))

    t = T(0.55)
    export("sfx", "gather", fade(bell(2200, 0.55) * 0.3 + noise_sweep(0.55, 1200, 4000, 0.7) * ar(t, 0.03, 0.15) * 0.4, 0.002, 0.08))

    # --- Portais ---
    d = 1.6
    t = T(d)
    rise = noise_sweep(d, 300, 5200, 0.85) * np.minimum(t / d, 1) * 0.6
    chord = sum(sine(f, d) * 0.15 for f in [220, 330, 440, 660]) * np.minimum(t / 0.6, 1) * np.minimum((d - t) / 0.4, 1)
    hit = bell(1760, 1.0) * 0.4
    x = mix(rise * np.minimum((d - t) / 0.2, 1), chord, place(np.zeros(int(d * SR)), hit, 1.0))
    export("sfx", "portal_open", reverb(x, 1.2, 0.35))

    d = 1.1
    t = T(d)
    whoosh = noise_sweep(d, 4000, 300, 0.8) * ar(t, 0.05, 0.4)
    boom = sine(glide(160, 40, d), d) * ar(t, 0.002, 0.3)
    export("sfx", "teleport", reverb(softclip(whoosh * 0.8 + boom * 0.9, 1.3), 0.9, 0.3))

    # --- Zumbido contínuo do portal (loop sem emendas) ---
    d, tail = 4.0, 0.8
    tt = T(d + tail)
    hum = sum(sine(f, d + tail) * a * (0.7 + 0.3 * np.sin(2 * np.pi * r * tt + ph))
              for f, a, r, ph in [(110, 0.6, 0.5, 0.0), (165, 0.35, 0.75, 1.0), (220, 0.3, 0.25, 2.0), (330, 0.15, 1.0, 0.5)])
    shim = lp(hp(noise(d + tail), 2500), 7000) * (0.4 + 0.6 * np.abs(np.sin(2 * np.pi * 0.5 * tt))) * 0.12
    export("sfx", "portal_hum", seamless(reverb(hum + shim, 0.8, 0.2)[: len(tt)], tail), trim=False)

    # --- Montaria / dragão ---
    d = 1.6
    t = T(d)
    f = glide(120, 55, d, 0.6) * (1 + 0.04 * np.sin(2 * np.pi * 7 * t))
    voice = saw(f, d) * (0.6 + 0.4 * np.sin(2 * np.pi * 26 * t))
    voice = bp(voice, 200, 700, 2) + 0.6 * bp(voice, 800, 1600, 2) + 0.3 * hp(noise(d), 1500) * ar(t, 0.05, 0.3)
    voice *= np.minimum(t / 0.1, 1) * np.exp(-np.maximum(t - 0.5, 0) / 0.6)
    export("sfx", "dragon_roar", reverb(softclip(voice * 1.4, 1.5), 1.1, 0.3, 3000))

    d = 0.7
    t = T(d)
    flap = lp(noise(d), 450) * (0.5 - 0.5 * np.cos(2 * np.pi * 3.0 * t)) ** 2 + noise_sweep(d, 300, 900, 0.6) * 0.3 * (0.5 - 0.5 * np.cos(2 * np.pi * 3.0 * t)) ** 2
    export("sfx", "wing_flap", fade(flap, 0.01, 0.06))

    # --- Monstros ---
    def growl(name, f0, f1, d, am=26, formants=((220, 600), (700, 1500)), roughness=0.5, gain=1.0):
        t = T(d)
        f = glide(f0, f1, d) * (1 + 0.03 * np.sin(2 * np.pi * 6 * t))
        v = saw(f, d) * (1 - roughness * 0.5 + roughness * 0.5 * np.sin(2 * np.pi * am * t))
        v = sum(bp(v, lo, hi, 2) for lo, hi in formants) + 0.25 * lp(noise(d), 1200) * ar(t, 0.02, d * 0.4)
        v *= np.minimum(t / 0.05, 1) * np.minimum((d - t) / 0.15, 1)
        export("sfx", name, reverb(softclip(v * gain, 1.5), 0.5, 0.15, 3000))

    # NOTA: Rosnados e rugidos agora são gerados exclusivamente por synthesize_visceral_combat_sfx.py
    # (Modelagem acústica orgânica por ruído rosa + impulsos glóticos sem ondas dente-de-serra sintéticas)
    # growl("growl_small", 210, 120, 0.7, am=32, formants=((300, 800), (1100, 2200)))
    # growl("growl_beast", 130, 70, 1.0, am=22)
    # growl("growl_large", 85, 48, 1.3, am=18, formants=((120, 420), (500, 1000)), roughness=0.7)
    # growl("growl_wraith", 360, 160, 1.4, am=9, formants=((500, 1200), (1500, 3200)), roughness=0.6)
    # growl("boss_roar", 70, 38, 2.4, am=14, formants=((90, 300), (400, 900), (1200, 2400)), roughness=0.8, gain=1.2)

    # --- Sons Intimidadores de Bosses e Minibosses ---
    d = 3.2
    t = T(d)
    f_sub = glide(68, 28, d, 0.45) * (1 + 0.05 * np.sin(2 * np.pi * 5 * t))
    sub_layer = sine(f_sub, d) * ar(t, 0.05, 1.2) * 0.9
    throat = saw(f_sub * 2.0, d) * (0.6 + 0.4 * np.sin(2 * np.pi * 14 * t))
    throat = bp(throat, 120, 600, 3) * 1.2 + bp(throat, 700, 1800, 2) * 0.7
    snarl = lp(noise(d), 2800) * (0.5 + 0.5 * np.sin(2 * np.pi * 18 * t)) * ar(t, 0.08, 0.9) * 0.65
    roar_mix = softclip(sub_layer + throat + snarl, 1.4)
    # Subistituído por synthesize_visceral_combat_sfx.py
    # export("sfx", "boss_roar_intimidating", reverb(roar_mix, 1.8, 0.38, 2400))
    # export("sfx", "boss_roar", reverb(roar_mix, 1.8, 0.38, 2400))

    d = 1.6
    t = T(d)
    sub_drop = sine(glide(95, 22, d, 0.28), d) * ar(t, 0.002, 0.5) * 1.3
    impact_thud = lp(noise(d), 450) * ar(t, 0.001, 0.18) * 1.1
    earth_crack = hp(noise(d), 1800) * ar(t, 0.0008, 0.04) * 0.8
    for k in range(5):
        c = bp(noise(0.18), 600 + 400 * k, 2400 + 600 * k) * ar(T(0.18), 0.001, 0.025)
        place(earth_crack, c * 0.5, 0.03 + k * 0.04)
    shockwave = noise_sweep(d, 800, 150, 0.7) * ar(t, 0.01, 0.35) * 0.5
    slam_heavy = softclip(sub_drop + impact_thud + earth_crack + shockwave, 1.5)
    export("sfx", "boss_slam_heavy", reverb(slam_heavy, 1.4, 0.32, 2800))
    export("sfx", "boss_slam", reverb(slam_heavy, 1.4, 0.32, 2800))

    d = 1.4
    t = T(d)
    f_mini = glide(115, 52, d, 0.5) * (1 + 0.04 * np.sin(2 * np.pi * 8 * t))
    mini_v = saw(f_mini, d) * (0.6 + 0.4 * np.sin(2 * np.pi * 20 * t))
    mini_v = bp(mini_v, 180, 800, 2) + bp(mini_v, 900, 2200, 2) * 0.6 + lp(noise(d), 1600) * ar(t, 0.03, 0.5) * 0.4
    # Substituído por synthesize_visceral_combat_sfx.py
    # export("sfx", "miniboss_growl", reverb(softclip(mini_v * 1.3, 1.4), 0.9, 0.22, 3200))

    # --- Barks Vocais dos NPCs ---
    # Horst: Ferreiro robusto (grunt grave de ferreiro)
    d = 0.55
    t = T(d)
    horst = saw(glide(110, 75, d), d) * ar(t, 0.01, 0.2)
    horst = bp(horst, 140, 500, 2) * 1.2 + bp(horst, 600, 1200, 2) * 0.5 + lp(noise(d), 800) * ar(t, 0.005, 0.08) * 0.3
    export("sfx", "npc_horst", reverb(softclip(horst * 1.2, 1.3), 0.4, 0.15))

    # Angela: Herbalista mística (harmônicos sutis)
    d = 0.8
    t = T(d)
    angela = sum(sine(f, d) * 0.15 for f in [587, 880, 1175, 1480]) * ar(t, 0.04, 0.35)
    angela_breath = bp(noise(d), 1200, 3600, 2) * ar(t, 0.03, 0.25) * 0.25
    export("sfx", "npc_angela", reverb(angela + angela_breath, 1.0, 0.3))

    # Brom: Velho contador de histórias sábio
    d = 0.7
    t = T(d)
    brom = saw(glide(130, 92, d), d) * ar(t, 0.02, 0.3)
    brom = bp(brom, 180, 650, 2) * 1.0 + bp(brom, 800, 1400, 2) * 0.4 + lp(noise(d), 600) * ar(t, 0.01, 0.12) * 0.2
    export("sfx", "npc_brom", reverb(softclip(brom * 1.1, 1.3), 0.6, 0.2))

    # --- Reações Vocais do Jogador ---
    d = 0.32
    t = T(d)
    exert1 = saw(glide(210, 130, d), d) * ar(t, 0.005, 0.12)
    exert1 = bp(exert1, 300, 1200, 2) * 0.9 + lp(noise(d), 1500) * ar(t, 0.005, 0.08) * 0.4
    export("sfx", "player_exert_1", fade(exert1, 0.002, 0.04))

    d = 0.4
    t = T(d)
    exert2 = saw(glide(175, 95, d), d) * ar(t, 0.008, 0.16)
    exert2 = bp(exert2, 220, 950, 2) * 1.1 + lp(noise(d), 1200) * ar(t, 0.005, 0.1) * 0.4
    export("sfx", "player_exert_2", fade(exert2, 0.002, 0.05))

    d = 1.2
    t = T(d)
    vic = sum(sine(f, d) * 0.2 for f in [440, 554, 659, 880]) * ar(t, 0.02, 0.5)
    export("sfx", "player_victory", reverb(vic, 1.2, 0.3))

    for i in range(2):
        d = 0.5
        t = T(d)
        x = sine(glide(140, 40, d), d) * ar(t, 0.003, 0.14) + lp(noise(d), 1200) * ar(t, 0.001, 0.08) * 0.5
        export("sfx", f"mob_death_{i + 1}", reverb(softclip(x * (1 + 0.2 * i), 1.3), 0.4, 0.15))

    t = T(0.3)
    export("sfx", "mob_attack", fade(noise_sweep(0.3, 500, 2500, 0.7) * ar(t, 0.02, 0.08) * 0.7 + sine(glide(180, 90, 0.3), 0.3) * ar(t, 0.003, 0.07) * 0.4, 0.002, 0.05))

    t = T(1.0)
    slam = sine(glide(90, 25, 1.0, 0.4), 1.0) * ar(t, 0.003, 0.25) + lp(noise(1.0), 1000) * ar(t, 0.002, 0.15) * 0.6
    export("sfx", "boss_slam", reverb(softclip(slam * 1.3, 1.5), 1.1, 0.28, 3000))


# ----------------------------------------------------------------------------------------------
# AMBIÊNCIAS (loops estéreo)
# ----------------------------------------------------------------------------------------------
def stereo(x, pan=0.0):
    l = np.sqrt(0.5 * (1 - pan))
    r = np.sqrt(0.5 * (1 + pan))
    return np.stack([x * l, x * r], axis=1)


def make_ambient():
    d, tail = 40.0, 3.0
    total = d + tail
    t = T(total)

    def wind(lo, hi, rate, depth):
        n = noise(total)
        w = lp(n, hi) - lp(n, lo)
        lfo = 0.55 + 0.45 * np.sin(2 * np.pi * rate * t + rng.uniform(0, 6.28)) * np.sin(2 * np.pi * rate * 0.37 * t + rng.uniform(0, 6.28))
        return w * (1 - depth + depth * lfo)

    def cricket(fc, pan, period, start):
        x = np.zeros_like(t)
        k = start
        while k < total - 1.0:
            for p in range(3):
                dd = 0.045
                tt = T(dd)
                pulse = np.sin(2 * np.pi * fc * tt) * np.sin(np.pi * tt / dd) ** 2
                place(x, pulse, k + p * 0.075)
            k += period * rng.uniform(0.8, 1.2)
        return stereo(x, pan)

    def owl(at, pan, f=390):
        x = np.zeros_like(t)
        for h, off in enumerate([0.0, 0.55]):
            dd = 0.42
            tt = T(dd)
            fr = glide(f * 1.08, f * 0.9, dd) * (1 + 0.012 * np.sin(2 * np.pi * 14 * tt))
            hoot = np.sin(2 * np.pi * np.cumsum(fr) / SR) * np.sin(np.pi * tt / dd) ** 1.5
            place(x, lp(hoot, 900) * 0.8, at + off)
        return stereo(x, pan)

    base = np.stack([wind(60, 700, 0.07, 0.8), wind(60, 700, 0.06, 0.8)], axis=1) * 1.0
    base += np.stack([wind(900, 2800, 0.11, 0.9), wind(900, 2800, 0.09, 0.9)], axis=1) * 0.28
    cr = cricket(4300, -0.6, 0.9, 0.2) + cricket(4700, 0.5, 1.1, 0.7) + cricket(3900, 0.1, 1.3, 1.3)
    layers = base * 0.55 + cr * 0.045
    layers += owl(11.0, -0.4) * 0.12 + owl(29.0, 0.55, 360) * 0.1
    # farfalhar de folhas
    leaves = np.zeros_like(t)
    for _ in range(26):
        dd = rng.uniform(0.3, 0.9)
        b = hp(noise(dd), 3500) * np.sin(np.pi * T(dd) / dd) ** 2 * rng.uniform(0.05, 0.12)
        place(leaves, b, rng.uniform(0, total - 1))
    layers += stereo(leaves, rng.uniform(-0.5, 0.5))
    out = reverb(layers, 1.5, 0.18, 4000)[: len(t)]
    export("ambient", "amb_forest_night", seamless(out, tail), peak_db=-6, lufs=-30)

    # Terras devastadas: vento seco e grave, sem grilos
    d2, tail2 = 36.0, 3.0
    total2 = d2 + tail2
    t2 = T(total2)
    n = noise(total2)
    lowwind = lp(n, 420) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.05 * t2) * np.sin(2 * np.pi * 0.021 * t2 + 1))
    grit = hp(lp(noise(total2), 3800), 900) * (0.4 + 0.6 * np.abs(np.sin(2 * np.pi * 0.13 * t2 + 0.5)))
    arid = np.stack([lowwind + grit * 0.25, np.roll(lowwind, 900) + np.roll(grit, 1700) * 0.25], axis=1)
    export("ambient", "amb_wasteland", seamless(reverb(arid, 2.0, 0.15)[: len(t2)], tail2), peak_db=-6, lufs=-30)

    # Santuário: brisa suave e sinos distantes
    d3, tail3 = 36.0, 3.0
    total3 = d3 + tail3
    t3 = T(total3)
    soft = np.stack([lp(noise(total3), 500) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.05 * t3)), lp(noise(total3), 500) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.047 * t3 + 1))], axis=1) * 0.5
    chimes = np.zeros((len(t3), 2))
    for _ in range(11):
        f = float(rng.choice([784, 880, 1047, 1175, 1319, 1568]))
        b = bell(f, 2.5) * rng.uniform(0.04, 0.09)
        st = stereo(np.pad(b, (0, 0)), rng.uniform(-0.7, 0.7))
        i = int(rng.uniform(0, total3 - 3) * SR)
        chimes[i : i + len(st)] += st[: len(chimes) - i]
    out3 = reverb(soft + chimes, 2.2, 0.35)[: len(t3)]
    export("ambient", "amb_sanctuary", seamless(out3, tail3), peak_db=-6, lufs=-32)


# ----------------------------------------------------------------------------------------------
# MÚSICA (loops estéreo gerados por síntese aditiva)
# ----------------------------------------------------------------------------------------------
def note(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def pad_voice(freq, d, bright=1800.0):
    t = T(d)
    v = np.zeros_like(t)
    for det in (-7, 0, 6):  # supersaw suave com desafinação em cents
        v += saw(freq * 2 ** (det / 1200), d)
    v = lp(v, bright, 2) * 0.3
    env = np.minimum(t / (d * 0.28), 1) * np.minimum((d - t) / (d * 0.4), 1)
    return v * np.sin(np.pi * np.minimum(t / d, 1)) ** 0.5 * env


def make_music():
    def track(name, chords, bpm_len, bright, bells, seed, bass=True, lufs=-26):
        r = np.random.default_rng(seed)
        chord_d = bpm_len
        tail = chord_d * 0.8
        total = chord_d * len(chords) + tail
        out = np.zeros((int(total * SR), 2))
        for ci, ch in enumerate(chords):
            at = ci * chord_d
            for vi, m in enumerate(ch):
                v = pad_voice(note(m), chord_d * 1.6, bright)
                v2 = pad_voice(note(m) * 1.002, chord_d * 1.6, bright)
                i = int(at * SR)
                end = min(len(out), i + len(v))
                out[i:end, 0] += v[: end - i] * 0.8 + v2[: end - i] * 0.2
                out[i:end, 1] += v[: end - i] * 0.2 + v2[: end - i] * 0.8
            if bass:
                b = sine(note(ch[0] - 12), chord_d * 1.2) * np.sin(np.pi * T(chord_d * 1.2) / (chord_d * 1.2)) * 0.5
                i = int(at * SR)
                end = min(len(out), i + len(b))
                out[i:end] += b[: end - i, None]
            # arpejos/sinos esparsos
            for _ in range(bells):
                m = int(r.choice(ch)) + 12 * int(r.choice([1, 1, 2]))
                bb = bell(note(m), 2.2) * r.uniform(0.05, 0.12)
                st = stereo(bb, r.uniform(-0.6, 0.6))
                i = int((at + r.uniform(0, chord_d * 0.85)) * SR)
                end = min(len(out), i + len(st))
                out[i:end] += st[: end - i]
        out = reverb(out, 3.2, 0.4, 5000)[: len(out)]
        export("music", name, seamless(out, tail), peak_db=-4, lufs=lufs)

    # Santuário de Sylveria: Lá menor / Fá / Dó / Sol (serena, élfica)
    track("music_sanctuary", [[57, 60, 64, 69], [53, 57, 60, 65], [48, 55, 60, 64], [55, 59, 62, 67]] * 2, 6.0, 2000, 4, 11)
    # Terras selvagens: Ré menor / Sib / Fá / Dó (tensa, ritmo lento)
    track("music_wilds", [[50, 57, 62, 65], [46, 53, 58, 62], [53, 57, 60, 65], [48, 55, 60, 64]] * 2, 6.5, 1300, 2, 23, lufs=-27)
    # Combate/boss: Mi frígio, mais grave e pulsante
    track("music_boss", [[40, 47, 52, 55], [41, 48, 53, 56], [40, 47, 52, 55], [38, 45, 50, 53]] * 2, 4.0, 900, 5, 37, lufs=-24)


if __name__ == "__main__":
    print("Gerando áudio do GameZero ->", OUT)
    make_sfx()
    make_ambient()
    make_music()
    print("Concluído.")
