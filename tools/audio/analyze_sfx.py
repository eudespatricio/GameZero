#!/usr/bin/env python3
"""Analisa a biblioteca de SFX: duração, canais, loudness integrada (LUFS) e pico real.

Uso:
    python tools/audio/analyze_sfx.py [--csv /tmp/sfx_analysis.csv]

Usa apenas `ffmpeg` (o ambiente do projeto não tem `ffprobe`).
"""
import argparse
import concurrent.futures
import json
import os
import re
import statistics
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")

RE_I = re.compile(r"I:\s+(-?\d+\.\d+)\s+LUFS")
RE_PEAK = re.compile(r"Peak:\s+(-?\d+\.\d+)\s+dBFS")
RE_LRA = re.compile(r"LRA:\s+(-?\d+\.\d+)\s+LU")
RE_STREAM = re.compile(r"Stream #0:0.*?Audio:\s*(\w+).*?(\d+) Hz,\s*(\w+)")
RE_DURATION = re.compile(r"Duration:\s*(\d+):(\d+):(\d+\.\d+)")


def _ffmpeg_info(path):
    proc = subprocess.run(["ffmpeg", "-hide_banner", "-i", path],
                          capture_output=True, text=True)
    err = proc.stderr
    codec, rate, channels = "?", 0, 0
    m = RE_STREAM.search(err)
    if m:
        codec = m.group(1)
        rate = int(m.group(2))
        ch = m.group(3).lower()
        channels = 1 if ch in ("mono", "1.0") else (2 if ch in ("stereo", "2.0") else 2)
    duration = 0.0
    d = RE_DURATION.search(err)
    if d:
        duration = int(d.group(1)) * 3600 + int(d.group(2)) * 60 + float(d.group(3))
    return {"codec": codec, "rate": rate, "channels": channels, "duration": duration}


def _loudness(path):
    proc = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostats", "-i", path,
         "-af", "ebur128=peak=true", "-f", "null", "-"],
        capture_output=True, text=True,
    )
    err = proc.stderr
    i_match = RE_I.findall(err)
    p_match = RE_PEAK.findall(err)
    lra_match = RE_LRA.findall(err)
    return {
        "lufs": float(i_match[-1]) if i_match else None,
        "peak": float(p_match[-1]) if p_match else None,
        "lra": float(lra_match[-1]) if lra_match else None,
    }


def analyze(name):
    path = os.path.join(SFX_DIR, name)
    info = _ffmpeg_info(path)
    info.update(_loudness(path))
    info["file"] = name
    info["kb"] = round(os.path.getsize(path) / 1024.0, 1)
    return info


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", default="/tmp/sfx_analysis.csv")
    args = ap.parse_args()

    files = sorted(f for f in os.listdir(SFX_DIR) if f.endswith(".ogg"))
    if not files:
        print("Nenhum .ogg encontrado em", SFX_DIR)
        return 1

    rows = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
        for row in pool.map(analyze, files):
            if row:
                rows.append(row)

    rows.sort(key=lambda r: (r["lufs"] if r["lufs"] is not None else -99))

    with open(args.csv, "w", encoding="utf-8") as fh:
        fh.write("file,codec,rate,channels,duration,kb,lufs,peak,lra\n")
        for r in rows:
            fh.write("{file},{codec},{rate},{channels},{duration:.3f},{kb},{lufs},{peak},{lra}\n".format(**r))

    lufs_values = [r["lufs"] for r in rows if r["lufs"] is not None]
    peaks = [r["peak"] for r in rows if r["peak"] is not None]
    stereo = [r for r in rows if r["channels"] > 1]
    clipped = [r for r in rows if r["peak"] is not None and r["peak"] > -0.2]
    quiet = [r for r in rows if r["lufs"] is not None and r["lufs"] < -24.0]
    loud = [r for r in rows if r["lufs"] is not None and r["lufs"] > -12.0]
    short = [r for r in rows if r["duration"] < 0.08]

    print(f"Arquivos analisados: {len(rows)}")
    print(f"  Loudness  : min {min(lufs_values):.1f} | mediana {statistics.median(lufs_values):.1f} | max {max(lufs_values):.1f} LUFS")
    print(f"  Pico real : min {min(peaks):.1f} | max {max(peaks):.1f} dBFS")
    print(f"  Duração   : min {min(r['duration'] for r in rows):.2f}s | max {max(r['duration'] for r in rows):.2f}s")
    print(f"  Estéreo   : {len(stereo)}")
    print(f"  Clipping  : {len(clipped)}")
    print(f"  Muito baixo (< -24 LUFS): {len(quiet)}")
    print(f"  Muito alto  (> -12 LUFS): {len(loud)}")
    print(f"  Curtíssimos (< 80 ms)   : {len(short)}")
    print(f"\nPlanilha: {args.csv}")

    print("\n--- 12 mais baixos ---")
    for r in rows[:12]:
        print(f"  {r['file']:<32} {r['lufs']:>7.1f} LUFS  pico {r['peak']:>6.1f} dB  {r['duration']:.2f}s  {r['channels']}ch")
    print("\n--- 12 mais altos ---")
    for r in rows[-12:]:
        print(f"  {r['file']:<32} {r['lufs']:>7.1f} LUFS  pico {r['peak']:>6.1f} dB  {r['duration']:.2f}s  {r['channels']}ch")
    if clipped:
        print("\n--- clipping ---")
        for r in clipped[:10]:
            print(f"  {r['file']:<32} pico {r['peak']:.1f} dBFS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
