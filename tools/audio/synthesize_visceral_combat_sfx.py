#!/usr/bin/env python3
"""
GameZero — Síntese Acústica Visceral de Alta Fidelidade (Combate + Mobs Orgânicos).
Substitui modelos sintéticos e convoluções de ruído branco por:
1. Modelo Glótico de Rosenberg com Period-Doubling sub-harmônico (ventricular folds).
2. Trato vocal acústico com ressonadores de formantes (F1, F2, F3, F4) e saturação assimétrica.
3. Transientes de impacto e cortes físicos ultra-nítidos sem ruído estático de fase.
4. Reflexões iniciais discretas (multi-tap delay) sem convolução com ruído branco.
"""
import os
import subprocess
import tempfile
import numpy as np
from scipy import signal
from scipy.io import wavfile

SR = 44100
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "audio", "sfx")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(1337)

def T(d):
    return np.arange(int(d * SR)) / SR

def noise(d):
    return rng.standard_normal(int(d * SR))

def pink(d):
    w = noise(d)
    b, a = signal.butter(1, 0.04)
    return 0.85 * signal.lfilter(b, a, w) * 3.8 + 0.15 * w

def brown(d):
    w = noise(d)
    b, a = signal.butter(2, 0.015)
    return signal.lfilter(b, a, w) * 6.0

def lp(x, fc, order=3):
    return signal.sosfilt(signal.butter(order, min(fc, SR * 0.46), 'low', fs=SR, output='sos'), x)

def hp(x, fc, order=3):
    return signal.sosfilt(signal.butter(order, max(fc, 20.0), 'high', fs=SR, output='sos'), x)

def bp(x, lo, hi, order=2):
    return signal.sosfilt(signal.butter(order, [max(lo, 20.0), min(hi, SR * 0.46)], 'band', fs=SR, output='sos'), x)

def bp_reson(x, fc, q=3.5):
    bw = max(fc / q, 25.0)
    lo = max(fc - bw * 0.5, 20.0)
    hi = min(fc + bw * 0.5, SR * 0.46)
    return bp(x, lo, hi, order=2)

def ar_env(t, attack=0.005, decay=0.10):
    return np.minimum(t / max(attack, 1e-4), 1.0) * np.exp(-t / max(decay, 1e-4))

def swell_env(t, d, atk=0.10, rel=0.25):
    return np.minimum(t / max(atk, 1e-4), 1.0) * np.minimum((d - t) / max(rel, 1e-4), 1.0)

def fade(x, fin=0.004, fout=0.03):
    fi = int(fin * SR)
    fo = int(fout * SR)
    if fi > 0 and fi < len(x):
        x[:fi] *= np.linspace(0.0, 1.0, fi)
    if fo > 0 and fo < len(x):
        x[-fo:] *= np.linspace(1.0, 0.0, fo)
    return x

def asymmetric_distort(x, drive_pos=2.2, drive_neg=1.4):
    """Saturação não-linear assimétrica: modela tecidos de laringe animal sem chiado."""
    return np.where(x > 0, np.tanh(x * drive_pos), np.tanh(x * drive_neg) * 0.85)

def discrete_spatial_early_reflections(x, wet=0.16, decay_profile="dungeon"):
    """
    Reflexões espaciais discretas (multi-tap delay) com amortecimento acústico de altas frequências.
    Elimina COMPLETAMENTE a lama e chiado causados por convoluções FFT com ruído gaussiano.
    """
    if decay_profile == "subtle":
        taps_ms = [11, 22, 38]
        gains = [0.22, 0.14, 0.08]
    elif decay_profile == "boss":
        taps_ms = [16, 32, 54, 82, 115]
        gains = [0.30, 0.22, 0.15, 0.10, 0.06]
    else: # "dungeon"
        taps_ms = [13, 26, 44, 68]
        gains = [0.26, 0.18, 0.12, 0.07]

    max_delay = int((taps_ms[-1] / 1000.0) * SR) + 100
    out_len = len(x) + max_delay
    dry = np.pad(x, (0, out_len - len(x)))
    tail = np.zeros(out_len, dtype=np.float64)

    for tap_ms, gain in zip(taps_ms, gains):
        samp = int((tap_ms / 1000.0) * SR)
        if samp < out_len:
            tap_sig = np.zeros(out_len, dtype=np.float64)
            tap_sig[samp:samp + len(x)] = x
            # Absorção de altas frequências pelas paredes de rocha da masmorra
            filtered_tap = lp(tap_sig, 2800.0, order=2)
            tail += filtered_tap * gain

    return dry * (1.0 - wet) + tail * wet

def export(name, x, peak_db=-3.0):
    x = np.asarray(x, dtype=np.float64)
    x = x - np.mean(x)
    m = np.max(np.abs(x)) + 1e-9
    x = (x / m) * (10 ** (peak_db / 20.0))
    pcm = (np.clip(x, -1.0, 1.0) * 32767.0).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tf:
        tmp = tf.name
    wavfile.write(tmp, SR, pcm)
    out_file = os.path.join(OUT, name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "5", "-ar", str(SR), out_file], check=True)
    os.remove(tmp)
    print(f"  🔊 SFX Gerado: sfx/{name}.ogg ({len(x) / SR:.2f}s | pico: {peak_db} dB)")

def rosenberg_vocal_growl(d, f0_start, f0_end, formants, rasp=0.45, breath_gain=0.12, pitch_curve=0.85):
    """
    Sintetizador fisiológico de rosnado orgânico:
    - Tremor muscular realista (LFO 7Hz irregular)
    - Pulso glótico assimétrico (Rosenberg Glottal Waveform)
    - Period-doubling sub-harmônico (ventricular folds) para rugosidade gutural
    - Formantes de garganta/peito/focinho
    - Saturação assimétrica sem estalos
    """
    t = T(d)
    n = len(t)
    jitter = lp(noise(d), 9.0) * 0.06
    u_curve = (t / d) ** pitch_curve
    f_arr = (f0_start + (f0_end - f0_start) * u_curve) * (1.0 + jitter)
    f_arr = np.maximum(f_arr, 25.0)

    # Fase integrada
    phase = np.cumsum(f_arr) / SR
    p = phase % 1.0
    duty = 0.44

    # Pulso fundamental de Rosenberg
    pulse = np.zeros_like(p)
    open_mask = p < duty
    u = p[open_mask] / duty
    pulse[open_mask] = 3.0 * (u**2) - 2.0 * (u**3)

    # Pulso sub-harmônico das cordas vocais falsas (ventriculares, F0 / 2)
    sub_p = (phase * 0.5) % 1.0
    sub_pulse = np.zeros_like(sub_p)
    sub_mask = sub_p < duty
    su = sub_p[sub_mask] / duty
    sub_pulse[sub_mask] = 3.0 * (su**2) - 2.0 * (su**3)

    # Modulação de garganta dinâmica
    rattle_lfo = 0.65 + 0.35 * np.sin(2.0 * np.pi * 18.0 * t + lp(noise(d), 12.0) * 3.0)
    glottal_source = (pulse * (1.0 - rasp * 0.4) + sub_pulse * rasp) * rattle_lfo

    # Passagem pelos formantes do trato vocal
    vocal = np.zeros_like(t)
    for fc, gain, q in formants:
        vocal += bp_reson(glottal_source, fc, q) * gain

    # Respiração / sopro sibilante orgânico suave (não predominante)
    breath = bp(pink(d), formants[0][0], min(formants[-1][0] * 1.5, SR * 0.45), 2) * breath_gain

    # Envelope anatômico
    raw = (vocal + breath) * swell_env(t, d, d * 0.12, d * 0.28)
    # Saturação de carne / garganta
    saturated = asymmetric_distort(raw, 2.4, 1.5)
    return fade(saturated, 0.005, 0.04)

def generate_combat_impacts():
    print("[1/3] Sintetizando Golpes e Cortes Físicos de Alta Definição...")

    # Slashes (Lâmina cortando o ar em alta velocidade)
    for i in range(1, 4):
        dur = 0.28 + i * 0.03
        t = T(dur)
        # Deslocamento de ar: ruído rosa com curva rápida exponencial
        env_cleave = np.sin(np.pi * (t / dur)) ** 2.4
        air_whoosh = bp(pink(dur), 110 + i * 20, 680 + i * 60) * env_cleave * 3.2
        # Fio de aço cortando ar (transiente metálico rápido)
        env_steel = np.minimum(t / 0.025, 1.0) * np.exp(-t / 0.07)
        steel_edge = bp(pink(dur), 1600 + i * 200, 4200) * env_steel * 0.85
        # Impacto suave de ar no fim
        blade_swing = asymmetric_distort(air_whoosh + steel_edge, 1.8, 1.4)
        out = discrete_spatial_early_reflections(fade(blade_swing, 0.003, 0.03), wet=0.12, decay_profile="subtle")
        export(f"slash_{i}", out, peak_db=-4.0)
        if i == 1:
            export("slash", out, peak_db=-4.0)

    # Impacto de Carne (Hit Flesh)
    d = 0.24
    t = T(d)
    # Sub-punch transiente rápido (sem glide de laser longo)
    punch_body = np.sin(2.0 * np.pi * 95.0 * t * np.exp(-t * 22.0)) * ar_env(t, 0.001, 0.06) * 2.8
    flesh_splat = lp(brown(d), 550) * ar_env(t, 0.002, 0.05) * 2.2
    bone_crack = bp(pink(d), 380, 2400) * ar_env(t, 0.001, 0.028) * 1.9
    hit_flesh = asymmetric_distort(punch_body + flesh_splat + bone_crack, 2.0, 1.6)
    export("hit_flesh", fade(hit_flesh, 0.001, 0.03), peak_db=-2.5)

    # Impacto Crítico (Hit Crit)
    d = 0.44
    t = T(d)
    crit_sub = np.sin(2.0 * np.pi * 78.0 * t * np.exp(-t * 14.0)) * ar_env(t, 0.001, 0.16) * 3.2
    crit_bone = bp(pink(d), 650, 4800) * ar_env(t, 0.001, 0.035) * 2.5
    crit_body = bp(pink(d), 160, 920) * ar_env(t, 0.002, 0.10) * 2.2
    crit_sound = asymmetric_distort(crit_sub + crit_bone + crit_body, 2.2, 1.8)
    crit_out = discrete_spatial_early_reflections(fade(crit_sound, 0.001, 0.04), wet=0.18, decay_profile="dungeon")
    export("hit_crit", crit_out, peak_db=-1.5)

def generate_monsters_and_boss_voices():
    print("[2/3] Sintetizando Rosnados, Rugidos e Falas Intimidantes dos Monstros...")

    # Growl Small (Goblins, Pequenos Carniçais): F0 160 -> 110 Hz
    formants_small = [(280, 2.0, 3.5), (920, 1.4, 4.0), (2400, 0.8, 3.0)]
    g_small = rosenberg_vocal_growl(0.55, 160, 105, formants_small, rasp=0.40, breath_gain=0.10)
    export("growl_small", discrete_spatial_early_reflections(g_small, wet=0.12, decay_profile="subtle"), peak_db=-6.5)

    # Growl Beast (Lobo da Espinha / Fera Predadora): F0 115 -> 68 Hz
    formants_beast = [(180, 2.4, 3.8), (680, 1.6, 4.2), (1850, 1.0, 3.2)]
    g_beast = rosenberg_vocal_growl(0.75, 115, 68, formants_beast, rasp=0.52, breath_gain=0.12)
    export("growl_beast", discrete_spatial_early_reflections(g_beast, wet=0.14, decay_profile="dungeon"), peak_db=-5.5)

    # Growl Large (Urgal / Ogro / Colosso): F0 76 -> 42 Hz
    formants_large = [(120, 2.8, 4.0), (440, 1.8, 4.5), (1200, 0.9, 3.0)]
    g_large = rosenberg_vocal_growl(0.95, 76, 42, formants_large, rasp=0.58, breath_gain=0.10)
    export("growl_large", discrete_spatial_early_reflections(g_large, wet=0.18, decay_profile="dungeon"), peak_db=-5.0)

    # Growl Wraith (Espectro / Sombra de Durza): Uivo espectral do vazio sem chiado
    d_wr = 1.15
    t_wr = T(d_wr)
    lfo_void = np.sin(2.0 * np.pi * 5.5 * t_wr) * 0.4 + 0.6
    whisper_low = bp(pink(d_wr), 240, 950) * lfo_void * 1.8
    whisper_high = bp(noise(d_wr), 1400, 3200) * (0.8 + 0.2 * np.sin(2.0 * np.pi * 8.0 * t_wr)) * 0.6
    wraith_resonance = bp_reson(pink(d_wr), 620, q=6.0) * 1.4
    wraith = (whisper_low + whisper_high + wraith_resonance) * swell_env(t_wr, d_wr, 0.22, 0.35)
    wraith_out = discrete_spatial_early_reflections(fade(asymmetric_distort(wraith, 1.8, 1.4), 0.01, 0.06), wet=0.25, decay_profile="boss")
    export("growl_wraith", wraith_out, peak_db=-6.0)

    # Miniboss Growl
    formants_mini = [(140, 2.6, 4.0), (520, 1.8, 4.2), (1450, 1.1, 3.2)]
    g_mini = rosenberg_vocal_growl(1.10, 88, 46, formants_mini, rasp=0.55, breath_gain=0.12)
    export("miniboss_growl", discrete_spatial_early_reflections(g_mini, wet=0.20, decay_profile="boss"), peak_db=-4.5)

    # Boss Roar Intimidating (Rugido de Trovão do Colosso / Chefe Supremo)
    formants_boss = [(85, 3.2, 4.5), (320, 2.2, 4.8), (980, 1.4, 3.5), (2200, 0.7, 2.8)]
    g_boss = rosenberg_vocal_growl(1.85, 62, 32, formants_boss, rasp=0.62, breath_gain=0.14)
    # Adicionar sub-grave visceral profundo (42Hz)
    sub_roar = np.sin(2.0 * np.pi * 42.0 * T(1.85)) * swell_env(T(1.85), 1.85, 0.15, 0.35) * 1.2
    boss_sound = discrete_spatial_early_reflections(asymmetric_distort(g_boss + sub_roar, 2.2, 1.6), wet=0.24, decay_profile="boss")
    export("boss_roar", boss_sound, peak_db=-2.8)
    export("boss_roar_intimidating", boss_sound, peak_db=-2.8)

    # Morte dos Mobs (Expiração pesada + queda física no solo)
    for i in range(1, 3):
        d_m = 0.52
        t_m = T(d_m)
        v_death = rosenberg_vocal_growl(d_m, 110 - i * 18, 38, [(160, 2.2, 3.5), (650, 1.2, 3.8)], rasp=0.50, breath_gain=0.16)
        thud = np.sin(2.0 * np.pi * 65.0 * t_m * np.exp(-t_m * 18.0)) * ar_env(t_m, 0.08, 0.14) * 1.8
        death_mix = asymmetric_distort(v_death + thud, 1.8, 1.5)
        death_out = discrete_spatial_early_reflections(fade(death_mix, 0.005, 0.04), wet=0.14, decay_profile="dungeon")
        export(f"mob_death_{i}", death_out, peak_db=-5.0)
        if i == 1:
            export("mob_death", death_out, peak_db=-5.0)

    # Falas e Barks Intimidantes de Bosses (Gromk, Durza, Cavaleiro)
    # Gromk: Urgal Tribal Warlord
    v_gromk_aggro = rosenberg_vocal_growl(1.35, 78, 44, [(110, 2.8, 4.0), (380, 2.0, 4.2), (1150, 1.2, 3.2)], rasp=0.60, breath_gain=0.14)
    export("voice_boss_gromk_aggro", discrete_spatial_early_reflections(v_gromk_aggro, wet=0.22, decay_profile="boss"), peak_db=-3.0)
    v_gromk_slam = rosenberg_vocal_growl(1.45, 92, 38, [(95, 3.0, 4.2), (340, 2.2, 4.5), (1050, 1.3, 3.4)], rasp=0.65, breath_gain=0.15)
    export("voice_boss_gromk_slam", discrete_spatial_early_reflections(v_gromk_slam, wet=0.25, decay_profile="boss"), peak_db=-2.5)

    # Durza: The Spectral Shade
    v_durza = rosenberg_vocal_growl(1.50, 145, 75, [(260, 2.5, 4.5), (880, 2.0, 4.8), (2400, 1.4, 3.5)], rasp=0.48, breath_gain=0.20)
    export("voice_boss_durza_aggro", discrete_spatial_early_reflections(v_durza, wet=0.28, decay_profile="boss"), peak_db=-3.2)

    # Knight: Urû'baen Oathsworn Commander (Ressonância de armadura e voz marcial)
    v_knight = rosenberg_vocal_growl(1.25, 95, 52, [(150, 2.6, 3.8), (560, 2.2, 4.2), (1600, 1.2, 3.5)], rasp=0.42, breath_gain=0.10)
    export("voice_boss_knight_aggro", discrete_spatial_early_reflections(v_knight, wet=0.20, decay_profile="boss"), peak_db=-3.0)

def generate_attacks_and_slams():
    print("[3/3] Sintetizando Ataques Físicos e Esmagamentos de Solo (Slams)...")

    # Machado Pesado Urgal (mob_attack_heavy_1, mob_attack_heavy_2)
    for idx, (dur, p_whoosh) in enumerate([(0.38, 280), (0.42, 320)], start=1):
        t = T(dur)
        # Deslocamento de ar massivo
        env_whoosh = np.sin(np.pi * (t / dur)) ** 2.2
        axe_wind = bp(pink(dur), 80, 520) * env_whoosh * 3.4
        # Lâmina pesada rasgando ar
        axe_edge = bp(pink(dur), 1200, 3600) * ar_env(t, 0.015, 0.08) * 1.2
        # Impacto do punho no ar
        axe_haft = np.sin(2.0 * np.pi * 85.0 * t * np.exp(-t * 20.0)) * ar_env(t, 0.005, 0.08) * 1.6
        axe_atk = asymmetric_distort(axe_wind + axe_edge + axe_haft, 2.0, 1.5)
        out = discrete_spatial_early_reflections(fade(axe_atk, 0.003, 0.03), wet=0.14, decay_profile="dungeon")
        export(f"mob_attack_heavy_{idx}", out, peak_db=-4.5)
        if idx == 1:
            export("mob_attack", out, peak_db=-4.5)

    # Ataque de Fera (Mordida / Patada com Garras: mob_attack_beast_1, 2)
    for idx in (1, 2):
        d_b = 0.35
        t_b = T(d_b)
        snarl_transient = rosenberg_vocal_growl(d_b, 140, 75, [(220, 2.0, 3.5), (850, 1.4, 4.0)], rasp=0.55, breath_gain=0.14)
        claw_swipe = bp(pink(d_b), 900, 3800) * ar_env(t_b, 0.005, 0.055) * 1.8
        jaw_snap = bp(pink(d_b), 350, 1800) * ar_env(t_b, 0.001, 0.02) * 2.2
        beast_mix = asymmetric_distort(snarl_transient + claw_swipe + jaw_snap, 2.2, 1.6)
        out = discrete_spatial_early_reflections(fade(beast_mix, 0.002, 0.03), wet=0.12, decay_profile="subtle")
        export(f"mob_attack_beast_{idx}", out, peak_db=-4.8)

    # Pancada Contundente do Golem (mob_attack_blunt_1)
    d_g = 0.58
    t_g = T(d_g)
    # Impacto de bloco de rocha (sem laser sine drop)
    fist_crack = bp(pink(d_g), 180, 2600) * ar_env(t_g, 0.001, 0.04) * 3.2
    ground_thud = np.sin(2.0 * np.pi * 58.0 * t_g * np.exp(-t_g * 14.0)) * ar_env(t_g, 0.002, 0.18) * 3.4
    rock_crumble = lp(brown(d_g), 450) * ar_env(t_g, 0.03, 0.22) * 1.8
    golem_sound = asymmetric_distort(fist_crack + ground_thud + rock_crumble, 2.4, 1.8)
    out_golem = discrete_spatial_early_reflections(fade(golem_sound, 0.002, 0.05), wet=0.22, decay_profile="dungeon")
    export("mob_attack_blunt_1", out_golem, peak_db=-3.2)

    # Ataque Espectral (mob_attack_spectral_1)
    d_sp = 0.52
    t_sp = T(d_sp)
    scythe_whistle = bp_reson(pink(d_sp), 920, q=4.5) * ar_env(t_sp, 0.03, 0.18) * 2.2
    void_chill = bp(noise(d_sp), 1800, 4400) * ar_env(t_sp, 0.02, 0.12) * 1.2
    spectral_sound = asymmetric_distort(scythe_whistle + void_chill, 1.8, 1.4)
    out_spectral = discrete_spatial_early_reflections(fade(spectral_sound, 0.005, 0.05), wet=0.24, decay_profile="boss")
    export("mob_attack_spectral_1", out_spectral, peak_db=-4.5)

    # Boss Slam Heavy / Boss Slam (Onda de Choque Sísmica Cataclísmica)
    d_sl = 0.88
    t_sl = T(d_sl)
    shockwave_sub = np.sin(2.0 * np.pi * 48.0 * t_sl * np.exp(-t_sl * 10.0)) * ar_env(t_sl, 0.002, 0.35) * 3.8
    crater_crack = bp(pink(d_sl), 120, 1800) * ar_env(t_sl, 0.001, 0.06) * 3.5
    debris_rumble = lp(brown(d_sl), 380) * ar_env(t_sl, 0.02, 0.32) * 2.6
    slam_raw = asymmetric_distort(shockwave_sub + crater_crack + debris_rumble, 2.5, 1.8)
    slam_out = discrete_spatial_early_reflections(fade(slam_raw, 0.002, 0.06), wet=0.28, decay_profile="boss")
    export("boss_slam_heavy", slam_out, peak_db=-1.8)
    export("boss_slam", slam_out, peak_db=-1.8)

if __name__ == "__main__":
    generate_combat_impacts()
    generate_monsters_and_boss_voices()
    generate_attacks_and_slams()
    print("=== TODOS OS 29 EFEITOS SONOROS VISCERAIS REGENERADOS COM SUCESSO! ===")
