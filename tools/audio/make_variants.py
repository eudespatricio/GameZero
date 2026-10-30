#!/usr/bin/env python3
"""Gera variações extras dos SFX mais repetidos (pitch/timbre), por DSP.

O AudioManager já carrega automaticamente `nome.ogg` + `nome_1..8.ogg`, então
basta criar os arquivos: o combate deixa de soar "metralhado" com o mesmo
sample em todos os golpes.

Uso:
    python tools/audio/make_variants.py
    python tools/audio/make_variants.py --dry-run
"""
import argparse
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")

# base -> quantas variações criar (são criadas base_1..N já existentes + estas)
JOBS = {
    "slash": 5,              # 3 existentes -> 8 no total
    "hit_flesh": 3,
    "hit_crit": 2,
    "mob_attack_heavy": 3,
    "mob_attack_beast": 2,
    "step_grass": 2,
    "step_stone": 2,
    "loot_item": 2,
}

# (taxa de pitch, ganho do corpo 180 Hz, ganho do brilho 3.2 kHz)
TRANSFORMS = [
    (0.92, 2.0, -1.5),
    (0.96, 1.0, 1.0),
    (1.04, -1.0, 1.5),
    (1.08, -2.0, 2.5),
    (0.89, 2.5, -2.0),
]


def existing_variants(base):
    out = []
    if os.path.exists(os.path.join(SFX_DIR, base + ".ogg")):
        out.append(base + ".ogg")
    for i in range(1, 9):
        name = f"{base}_{i}.ogg"
        if os.path.exists(os.path.join(SFX_DIR, name)):
            out.append(name)
    return out


def duration_of(path):
    proc = subprocess.run(["ffmpeg", "-hide_banner", "-i", path],
                          capture_output=True, text=True)
    for line in proc.stderr.splitlines():
        if "Duration:" in line:
            part = line.split("Duration:")[1].split(",")[0].strip()
            h, m, s = part.split(":")
            return int(h) * 3600 + int(m) * 60 + float(s)
    return 1.0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    created = 0
    for base, extra in JOBS.items():
        sources = existing_variants(base)
        if not sources:
            print(f"  ! {base}: sem arquivo base, ignorado")
            continue
        start = len(sources)
        for k in range(extra):
            idx = start + k
            out_name = f"{base}_{idx}.ogg"
            out_path = os.path.join(SFX_DIR, out_name)
            if os.path.exists(out_path):
                continue
            src = os.path.join(SFX_DIR, sources[k % len(sources)])
            rate, body, air = TRANSFORMS[k % len(TRANSFORMS)]
            dur = duration_of(src)
            fade_start = max(0.0, dur * 0.72)
            filters = ",".join([
                f"asetrate=44100*{rate}",
                "aresample=44100",
                f"equalizer=f=180:t=q:w=1:g={body}",
                f"equalizer=f=3200:t=q:w=1:g={air}",
                f"afade=t=out:st={fade_start:.3f}:d={max(dur - fade_start, 0.02):.3f}",
            ])
            if args.dry_run:
                print(f"  {out_name:<28} <- {sources[k % len(sources)]}  ({filters})")
                continue
            proc = subprocess.run(
                ["ffmpeg", "-hide_banner", "-nostats", "-y", "-i", src,
                 "-af", filters, "-c:a", "libvorbis", "-q:a", "6", out_path],
                capture_output=True, text=True,
            )
            if proc.returncode == 0:
                created += 1
                print(f"  ok {out_name:<24} <- {os.path.basename(src)}  pitch x{rate}")
            else:
                print(f"  ! falha em {out_name}: {proc.stderr.strip().splitlines()[-1][:70]}")

    print(f"\n{created} variação(ões) criada(s).")
    if created:
        print("Rode tools/audio/master_sfx.py para equalizar o volume das novas variações.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
