#!/usr/bin/env python3
"""Masteriza a biblioteca de SFX do GameZero (mixagem por categoria).

Problema medido: a biblioteca variava de ~-41 dB RMS (passos) a ~-9 dB RMS
(slash) — alguns efeitos ensurdeciam o combate e outros desapareciam.

Solução: cada categoria tem seu alvo de RMS (mixagem, não normalização cega),
e o ganho é limitado pelo pico para nunca clipar. Assim o combate fica à
frente, a interface atrás e os passos viram detalhe sutil.

Cadeia por arquivo:
    highpass 30 Hz  →  ganho (alvo RMS, limitado pelo pico em -1.5 dBTP)

Uso:
    python tools/audio/master_sfx.py --dry-run
    python tools/audio/master_sfx.py
    python tools/audio/master_sfx.py --restore      # volta aos originais
    python tools/audio/master_sfx.py --only slash
"""
import argparse
import concurrent.futures
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")
BACKUP_DIR = os.path.join(ROOT, "assets", "audio", "sfx_raw")

TRUE_PEAK_CEILING_DB = -1.5
MAX_GAIN_DB = 14.0
SKIP_WINDOW_DB = 0.75
OGG_QUALITY = "6"

# Alvo de RMS (dBFS) por categoria — define a hierarquia da mixagem.
CATEGORY_TARGETS = [
    (("step_",), -26.0, "passos"),
    (("ui_",), -24.0, "interface"),
    (("amb_", "music_"), None, "ambiente/musica"),
    (("voice_", "boss_", "growl", "miniboss", "roar"), -15.0, "vozes/chefes"),
    (("slash", "hit_", "attack", "exert", "spell", "cast", "slam", "wing"), -16.0, "combate"),
    (("coin", "loot", "jewel", "gather", "anvil", "craft", "teleport"), -20.0, "loot/oficina"),
]

RE_RMS = re.compile(r"RMS level dB:\s*(-?\d+\.?\d*)")
RE_PEAK = re.compile(r"Peak:\s+(-?\d+\.\d+)\s+dBFS")


def target_for(name):
    for prefixes, target, label in CATEGORY_TARGETS:
        if name.startswith(prefixes):
            return target, label
    return -18.0, "geral"


def measure(path):
    """Retorna (rms_db, true_peak_db)."""
    proc = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostats", "-i", path,
         "-af", "astats=metadata=1:reset=0,ebur128=peak=true", "-f", "null", "-"],
        capture_output=True, text=True,
    )
    rms_vals = RE_RMS.findall(proc.stderr)
    peak_vals = RE_PEAK.findall(proc.stderr)
    rms = float(rms_vals[-1]) if rms_vals else None
    peak = float(peak_vals[-1]) if peak_vals else -1.0
    return rms, peak


def master_one(name, dry_run):
    path = os.path.join(SFX_DIR, name)
    target, label = target_for(name)
    if target is None:
        return (name, None, 0.0, f"ignorado ({label})")

    rms, peak = measure(path)
    if rms is None:
        return (name, None, 0.0, "sem medicao")

    desired = target - rms
    headroom = TRUE_PEAK_CEILING_DB - peak
    gain = min(desired, headroom, MAX_GAIN_DB)
    gain = max(gain, -MAX_GAIN_DB)

    if abs(gain) < SKIP_WINDOW_DB:
        return (name, rms, 0.0, "no alvo")

    if dry_run:
        return (name, rms, gain, f"simulado ({label} {target:.0f})")

    backup = os.path.join(BACKUP_DIR, name)
    if not os.path.exists(backup):
        shutil.copy2(path, backup)

    fd, tmp = tempfile.mkstemp(suffix=".ogg", dir=SFX_DIR)
    os.close(fd)
    proc = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostats", "-y", "-i", backup,
         "-af", f"highpass=f=30,volume={gain:.2f}dB",
         "-c:a", "libvorbis", "-q:a", OGG_QUALITY, tmp],
        capture_output=True, text=True,
    )
    if proc.returncode != 0:
        os.unlink(tmp)
        return (name, rms, gain, "erro ffmpeg")

    os.replace(tmp, path)
    new_rms, new_peak = measure(path)
    return (name, rms, gain, f"ok -> {new_rms:.1f} dB RMS / {new_peak:.1f} dBTP")


def restore():
    if not os.path.isdir(BACKUP_DIR):
        print("Sem backups para restaurar.")
        return 0
    count = 0
    for name in sorted(os.listdir(BACKUP_DIR)):
        if not name.endswith(".ogg"):
            continue
        shutil.copy2(os.path.join(BACKUP_DIR, name), os.path.join(SFX_DIR, name))
        count += 1
    print(f"{count} arquivo(s) restaurado(s) a partir de {os.path.relpath(BACKUP_DIR, ROOT)}/")
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--restore", action="store_true")
    ap.add_argument("--only", default="")
    args = ap.parse_args()

    if args.restore:
        return restore()

    files = sorted(f for f in os.listdir(SFX_DIR) if f.endswith(".ogg"))
    if args.only:
        files = [f for f in files if args.only in f]
    if not files:
        print("Nada a fazer.")
        return 0

    os.makedirs(BACKUP_DIR, exist_ok=True)
    print(f"{'arquivo':<32} {'RMS':>8} {'ganho':>7}  resultado")

    changed = 0
    errors = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        futures = [pool.submit(master_one, f, args.dry_run) for f in files]
        for fut in futures:
            name, rms, gain, status = fut.result()
            if rms is None:
                print(f"  {name:<30} {'-':>8} {'-':>7}  {status}")
                continue
            if not status.startswith("no alvo"):
                changed += 1
            if status.startswith("erro"):
                errors += 1
            print(f"  {name:<30} {rms:>7.1f} {gain:>+6.1f}  {status}")

    print(f"\n{changed} de {len(files)} arquivos ajustados · {errors} erro(s).")
    if not args.dry_run and changed:
        print(f"Originais preservados em {os.path.relpath(BACKUP_DIR, ROOT)}/")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
