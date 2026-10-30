#!/usr/bin/env python3
"""
Prepara todos os modelos CC0 para o GameZero (escala automática + limpeza).

Lê o bbox real de cada GLB de origem, calcula a escala para a altura desejada
e chama o prep_cc0_model.py no Blender.

Uso: python tools/studio/prep_all_cc0.py
"""
import json
import os
import struct
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PACKS = "/tmp/gz/packs"
OUT = os.path.join(ROOT, "assets", "models", "cc0")
PREP = os.path.join(ROOT, "tools", "studio", "prep_cc0_model.py")
BLENDER = "blender"

# (origem, destino, altura alvo em metros, dessaturar?, animações a manter)
JOBS = [
    ("beasts/Fox.glb", "wolf_cc0.glb", 1.25, 1.0, ""),
    ("skeletons/Skeleton_Warrior.glb", "skeleton_warrior.glb", 2.05, 0.0, ""),
    ("skeletons/Skeleton_Minion.glb", "skeleton_minion.glb", 2.20, 0.0, ""),
    ("skeletons/Skeleton_Rogue.glb", "skeleton_rogue.glb", 2.00, 0.0, ""),
    ("adventures/Knight.glb", "hero_knight.glb", 1.85, 0.0, ""),
]


def bbox(path):
    d = open(path, "rb").read()
    n = struct.unpack("<I", d[12:16])[0]
    js = json.loads(d[20:20 + n])
    lo = [1e9] * 3
    hi = [-1e9] * 3
    for m in js.get("meshes", []):
        for prim in m["primitives"]:
            acc = js["accessors"][prim["attributes"]["POSITION"]]
            mn, mx = acc.get("min"), acc.get("max")
            if not mn:
                continue
            for i in range(3):
                lo[i] = min(lo[i], mn[i])
                hi[i] = max(hi[i], mx[i])
    return [hi[i] - lo[i] for i in range(3)]


def main():
    os.makedirs(OUT, exist_ok=True)
    for src, dst, height, desat, anims in JOBS:
        src_path = os.path.join(PACKS, src)
        if not os.path.exists(src_path):
            print(f"  ! ausente: {src}")
            continue
        size = bbox(src_path)
        # o eixo "altura" do glTF é Y
        scale = height / max(size[1], 1e-6)
        cmd = [BLENDER, "-b", "--python", PREP, "--", src_path,
               os.path.join(OUT, dst), "--scale", f"{scale:.6f}",
               "--desaturate", str(desat)]
        if anims:
            cmd += ["--anims", anims]
        res = subprocess.run(cmd, capture_output=True, text=True)
        ok = "exportado" in res.stdout
        new = bbox(os.path.join(OUT, dst)) if ok else [0, 0, 0]
        print(f"  {'ok ' if ok else 'ERRO'} {dst:<26} {size[1]:8.2f} -> {new[1]:5.2f} m  (escala {scale:.5f})")
        if not ok:
            print("      ", res.stderr.strip().splitlines()[-1] if res.stderr else "")


if __name__ == "__main__":
    main()
