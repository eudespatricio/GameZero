#!/usr/bin/env python3
"""Baixa os packs CC0 do KayKit + Fox e inspeciona animações de cada GLB.

Uso: python tools/studio/fetch_cc0_assets.py [destino]
"""
import json
import os
import struct
import sys
import urllib.request

UA = {"User-Agent": "GameZero-asset-fetch"}
DEST = sys.argv[1] if len(sys.argv) > 1 else "/tmp/gz/packs"

REPOS = [
    ("KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0", "adventures"),
    ("KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0", "skeletons"),
]
EXTRA = [
    ("https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Fox/glTF-Binary/Fox.glb",
     "beasts/Fox.glb"),
    ("https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Fox/README.md",
     "beasts/Fox_README.md"),
]


def fetch(url, binary=False):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=60) as r:
        data = r.read()
    return data if binary else json.loads(data)


def glb_info(path):
    data = open(path, "rb").read()
    n = struct.unpack("<I", data[12:16])[0]
    js = json.loads(data[20:20 + n])
    anims = [a.get("name", "?") for a in js.get("animations", [])]
    tris = 0
    for m in js.get("meshes", []):
        for p in m.get("primitives", []):
            if "indices" in p:
                tris += js["accessors"][p["indices"]]["count"] // 3
    return {
        "anims": anims,
        "tris": tris,
        "nodes": len(js.get("nodes", [])),
        "skins": len(js.get("skins", [])),
        "size": len(data),
    }


def main():
    os.makedirs(DEST, exist_ok=True)
    downloaded = []

    for repo, folder in REPOS:
        tree = fetch(f"https://api.github.com/repos/{repo}/git/trees/main?recursive=1")
        for item in tree.get("tree", []):
            p = item["path"]
            if not p.lower().endswith(".glb"):
                continue
            url = f"https://raw.githubusercontent.com/{repo}/main/{p}"
            out = os.path.join(DEST, folder, os.path.basename(p))
            os.makedirs(os.path.dirname(out), exist_ok=True)
            open(out, "wb").write(fetch(url, binary=True))
            downloaded.append(out)
        # licença / readme
        for extra in ("LICENSE", "README.md", "License.txt", "LICENSE.txt"):
            try:
                body = fetch(f"https://raw.githubusercontent.com/{repo}/main/{extra}", binary=True)
                open(os.path.join(DEST, folder, f"_{extra}"), "wb").write(body)
                break
            except Exception:
                continue

    for url, rel in EXTRA:
        out = os.path.join(DEST, rel)
        os.makedirs(os.path.dirname(out), exist_ok=True)
        open(out, "wb").write(fetch(url, binary=True))
        downloaded.append(out)

    print(f"{len(downloaded)} arquivo(s) em {DEST}\n")
    print(f"{'modelo':<44} {'KB':>6} {'tris':>6} {'skins':>6}  animações")
    for path in sorted(downloaded):
        if not path.endswith(".glb"):
            continue
        info = glb_info(path)
        rel = os.path.relpath(path, DEST)
        print(f"{rel:<44} {info['size']/1024:>6.0f} {info['tris']:>6} {info['skins']:>6}  {', '.join(info['anims'])[:70]}")


if __name__ == "__main__":
    main()
