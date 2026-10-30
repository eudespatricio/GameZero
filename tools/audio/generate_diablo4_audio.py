#!/usr/bin/env python3
"""
GameZero — Gerador de Efeitos Sonoros Viscerais (Diablo IV) e Vozes Intimidantes de Bosses.
Sintetiza áudios profissionais .ogg com numpy, scipy e ffmpeg para a pasta assets/audio/sfx/.
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
OUT = os.path.join(ROOT, "assets", "audio", "sfx")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(42)

def T(d):
    return np.arange(int(d * SR)) / SR

def noise(d):
    return rng.standard_normal(int(d * SR))

def lp(x, fc, order=4):
    return signal.sosfilt(signal.butter(order, min(fc, SR * 0.45), 'low', fs=SR, output='sos'), x)

def hp(x, fc, order=4):
    return signal.sosfilt(signal.butter(order, fc, 'high', fs=SR, output='sos'), x)

def bp(x, lo, hi, order=3):
    return signal.sosfilt(signal.butter(order, [lo, min(hi, SR * 0.45)], 'band', fs=SR, output='sos'), x)

def ar(t, a=0.005, tau=0.1):
    return np.minimum(t / max(a, 1e-4), 1.0) * np.exp(-t / tau)

def fade(x, fin=0.005, fout=0.02):
    n = len(x)
    fi, fo = int(fin * SR), int(fout * SR)
    if fi > 0:
        x[:fi] *= np.linspace(0, 1, fi)
    if fo > 0:
        x[-fo:] *= np.linspace(1, 0, fo)
    return x

def sine(f, d):
    t = T(d)
    ph = 2 * np.pi * np.cumsum(f * np.ones_like(t)) / SR if np.ndim(f) else 2 * np.pi * f * t
    return np.sin(ph)

def saw(f, d):
    t = T(d)
    ph = np.cumsum(f * np.ones_like(t)) / SR
    return 2.0 * (ph - np.floor(ph + 0.5))

def glide(f0, f1, d, curve=1.0):
    u = np.linspace(0, 1, int(d * SR)) ** curve
    return f0 * (f1 / f0) ** u

def softclip(x, drive=1.5):
    return np.tanh(x * drive) / np.tanh(drive)

def reverb(x, decay=1.2, wet=0.3, damp=4500.0, pre=0.012):
    n = int(decay * 2.5 * SR)
    t = np.arange(n) / SR
    ir = rng.standard_normal(n) * np.exp(-t * 6.5 / decay)
    ir = lp(ir, damp, 2)
    ir[: int(pre * SR)] = 0.0
    ir /= np.sqrt(np.sum(ir**2)) + 1e-9
    y = signal.fftconvolve(x, ir)
    dry = np.pad(x, (0, len(y) - len(x)))
    return dry * (1 - wet) + y * wet

def export(name, x, peak_db=-1.5):
    x = np.asarray(x, dtype=np.float64)
    x = x - np.mean(x)
    m = np.max(np.abs(x)) + 1e-9
    x = x / m
    x = x * (10 ** (peak_db / 20))
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tf:
        tmp = tf.name
    wavfile.write(tmp, SR, pcm)
    out_file = os.path.join(OUT, name + ".ogg")
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "5", "-ar", str(SR), out_file]
    subprocess.run(cmd, check=True)
    os.remove(tmp)
    print(f"  ✅ sfx/{name}.ogg  ({len(x) / SR:.2f}s)")

# ----------------------------------------------------------------------------------------------
# 1. ATAQUES VISCERAIS DE MOBS (DIABLO IV IMPACT)
# ----------------------------------------------------------------------------------------------
def generate_mob_attacks():
    print("[Audio] Gerando Efeitos Sonoros Viscerais de Ataque...")
    
    # Ataque Pesado 1 (Machado / Espadão Urgal / Kull): swoosh cortante + pancada no ar + impacto
    d = 0.48
    t = T(d)
    whoosh = bp(noise(d), 200, 2200) * ar(t, 0.04, 0.16) * 1.4
    sub_punch = sine(glide(95, 38, d, 0.6), d) * ar(t, 0.015, 0.18) * 1.8
    steel_whistle = sine(glide(1600, 480, d, 1.4), d) * ar(t, 0.03, 0.10) * 0.35
    heavy_1 = softclip(whoosh + sub_punch + steel_whistle, 2.2)
    export("mob_attack_heavy_1", reverb(fade(heavy_1, 0.005, 0.04), 0.45, 0.18))
    
    # Ataque Pesado 2 (Variação com gume afiado e rasgo violento)
    d = 0.52
    t = T(d)
    whoosh2 = bp(noise(d), 320, 3100) * ar(t, 0.03, 0.15) * 1.5
    sub_punch2 = sine(glide(115, 42, d, 0.5), d) * ar(t, 0.01, 0.20) * 1.9
    flesh_rip = hp(noise(d), 1400) * ar(t, 0.08, 0.06) * 0.4
    heavy_2 = softclip(whoosh2 + sub_punch2 + flesh_rip, 2.4)
    export("mob_attack_heavy_2", reverb(fade(heavy_2, 0.005, 0.04), 0.50, 0.20))
    
    # Atualizar o mob_attack.ogg legado para uma versão também visceral (mantém retrocompatibilidade)
    export("mob_attack", reverb(fade(heavy_1, 0.005, 0.04), 0.45, 0.18))

    # Ataque Fera / Lobo da Espinha (Mandíbula feroz, estalo de presas e rasgo de garras)
    d = 0.42
    t = T(d)
    snarl = saw(glide(160, 85, d), d) * bp(noise(d), 300, 1800) * ar(t, 0.02, 0.14) * 1.2
    snap = hp(noise(d), 2200) * ar(t, 0.008, 0.04) * 1.5
    jaw_thump = sine(glide(140, 45, d), d) * ar(t, 0.005, 0.12) * 1.3
    beast_1 = softclip(snarl + snap + jaw_thump, 2.0)
    export("mob_attack_beast_1", reverb(fade(beast_1, 0.003, 0.03), 0.35, 0.15))

    # Ataque Fera 2 (Estocada de garras)
    d = 0.38
    t = T(d)
    claw = bp(noise(d), 800, 3600) * ar(t, 0.015, 0.10) * 1.4
    growl = saw(glide(130, 70, d), d) * ar(t, 0.01, 0.15) * 0.9
    beast_2 = softclip(claw + growl, 1.8)
    export("mob_attack_beast_2", reverb(fade(beast_2, 0.003, 0.03), 0.38, 0.16))

    # Ataque Contundente / Golem de Raiz (Impacto sísmico esmagador)
    d = 0.65
    t = T(d)
    sub_quake = sine(glide(65, 26, d, 0.4), d) * ar(t, 0.005, 0.35) * 2.2
    stone_crack = lp(noise(d), 900) * ar(t, 0.002, 0.12) * 1.8
    rubble = bp(noise(d), 150, 800) * ar(t, 0.05, 0.25) * 0.9
    golem_atk = softclip(sub_quake + stone_crack + rubble, 2.5)
    export("mob_attack_blunt_1", reverb(fade(golem_atk, 0.002, 0.06), 0.9, 0.32, 2800))

    # Ataque Espectral / Shade Wraith (Foice sombria do vazio)
    d = 0.58
    t = T(d)
    void_whoosh = bp(noise(d), 450, 4200) * ar(t, 0.03, 0.22) * 1.5
    spectral_drone = sine(glide(420, 180, d), d) * ar(t, 0.01, 0.28) * 0.6
    curse_hiss = hp(noise(d), 3200) * ar(t, 0.06, 0.18) * 0.7
    wraith_atk = softclip(void_whoosh + spectral_drone + curse_hiss, 2.0)
    export("mob_attack_spectral_1", reverb(fade(wraith_atk, 0.005, 0.08), 1.2, 0.40, 5000))

# ----------------------------------------------------------------------------------------------
# 2. VOZES E BRADOS INTIMIDANTES DE BOSSES
# ----------------------------------------------------------------------------------------------
def formant_vocal(f0, d, formants):
    """Sintetiza trato vocal humanoide monstruoso através de formantes acústicos (F1, F2, F3)."""
    t = T(d)
    # Fonte glótica gutural com modulação e harmônicos ásperos
    jitter = noise(d) * 0.08
    glot = saw(f0 * (1.0 + jitter), d) + sine(f0 * 0.5, d) * 0.45
    vocal = np.zeros_like(t)
    for fc, bw, gain in formants:
        vocal += bp(glot, max(fc - bw*0.5, 40), min(fc + bw*0.5, SR*0.45), 2) * gain
    return vocal

def generate_boss_voices():
    print("[Audio] Gerando Falas e Rugidos Intimidantes de Bosses...")

    # 1. Chefe do Clã Gromk - Rugido de Batalha Intimidante ("VOU ESMAGAR SEUS OSSOS!")
    d = 1.65
    t = T(d)
    # Formantes para vogal gutural aberta /a-o/ cavernosa (Urgals / Orc Warlords)
    formants_gromk = [(420, 90, 1.6), (980, 140, 1.3), (2100, 250, 0.9), (3200, 400, 0.6)]
    f0_curve = glide(85, 52, d, 0.7)
    roar = formant_vocal(f0_curve, d, formants_gromk)
    sub_rumble = sine(glide(55, 30, d), d) * ar(t, 0.01, 0.7) * 1.5
    breath = bp(noise(d), 200, 1800) * ar(t, 0.05, 0.5) * 0.8
    growl_gromk = softclip((roar + sub_rumble + breath) * ar(t, 0.08, 0.8), 2.8)
    export("voice_boss_gromk_aggro", reverb(fade(growl_gromk, 0.01, 0.15), 1.4, 0.35, 3500))

    # 2. Chefe Gromk - Brado de Golpe Sísmico ("MORRA SOB MEU MACHADO!")
    d = 1.20
    t = T(d)
    formants_slam = [(520, 110, 1.8), (1150, 160, 1.4), (2400, 300, 1.0)]
    f0_slam = glide(105, 62, d, 0.5)
    slam_vocal = formant_vocal(f0_slam, d, formants_slam)
    slam_sub = sine(glide(75, 28, d), d) * ar(t, 0.01, 0.5) * 1.8
    slam_shout = softclip((slam_vocal + slam_sub) * ar(t, 0.04, 0.65), 3.0)
    export("voice_boss_gromk_slam", reverb(fade(slam_shout, 0.005, 0.12), 1.3, 0.32, 4000))

    # 3. Chefe Gromk - Provocação Intimidante ("CARNE PARA OS KULLS!")
    d = 1.35
    t = T(d)
    f0_taunt = glide(78, 58, d, 1.2)
    taunt_vocal = formant_vocal(f0_taunt, d, formants_gromk)
    taunt_shout = softclip(taunt_vocal * ar(t, 0.06, 0.7), 2.4)
    export("voice_boss_gromk_taunt", reverb(fade(taunt_shout, 0.01, 0.10), 1.1, 0.28, 3800))

    # 4. Durza / Shade Wraith - Sussurro Glacial do Abismo ("SUA ALMA ME PERTENCE...")
    d = 1.85
    t = T(d)
    formants_wraith = [(350, 70, 1.2), (1800, 220, 1.8), (3400, 450, 1.4)]
    f0_wraith = glide(140, 95, d, 1.5)
    wraith_v = formant_vocal(f0_wraith, d, formants_wraith)
    whisper_noise = bp(noise(d), 1200, 5200) * ar(t, 0.15, 0.9) * 1.3
    spectral_shiver = sine(glide(650, 220, d), d) * ar(t, 0.05, 0.8) * 0.4
    durza_voice = softclip((wraith_v + whisper_noise + spectral_shiver) * ar(t, 0.10, 1.1), 2.0)
    export("voice_boss_durza_aggro", reverb(fade(durza_voice, 0.02, 0.20), 2.2, 0.50, 6000))

    # 5. Cavaleiro Juramentado / Boss Imperial - Decreto Fanático ("PELA GLÓRIA DE GALBATORIX!")
    d = 1.45
    t = T(d)
    formants_knight = [(480, 100, 1.4), (1280, 180, 1.5), (2600, 280, 1.1)]
    f0_knight = glide(125, 82, d, 0.8)
    knight_v = formant_vocal(f0_knight, d, formants_knight)
    armor_clank = hp(noise(d), 2800) * ar(t, 0.02, 0.08) * 0.9
    knight_voice = softclip((knight_v + armor_clank) * ar(t, 0.05, 0.75), 2.2)
    export("voice_boss_knight_aggro", reverb(fade(knight_voice, 0.01, 0.12), 1.2, 0.25, 4200))

if __name__ == "__main__":
    print("[Audio] Gerador legado desativado. Use tools/audio/synthesize_visceral_combat_sfx.py para síntese orgânica.")
    # generate_mob_attacks()
    # generate_boss_voices()
    # print("=== Todos os Áudios Viscerais e Vozes Intimidantes Exportados com Sucesso! ===")
