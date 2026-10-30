#!/usr/bin/env python3
"""
Pipeline de Modelagem e Exportação 3D para GameZero (Blender 4.2 -> Godot 4 GLB)
Permite criar ou converter modelos 3D com Smooth Shading e exportar diretamente para res://assets/models/
"""

import os
import subprocess
import sys

MODELS_DIR = "/home/eudespatricio/Games/GameZero/assets/models"

def run_blender_script(python_code: str):
    os.makedirs(MODELS_DIR, exist_ok=True)
    cmd = [
        "blender",
        "--background",
        "--python-expr",
        python_code
    ]
    print("[Pipeline 3D] Executando Blender no WSL...")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        print("[Pipeline 3D] Sucesso!")
        print(result.stdout)
    else:
        print("[Pipeline 3D] Erro na execução do Blender:")
        print(result.stderr)

if __name__ == "__main__":
    test_script = """
import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=24, radius=0.5, location=(0,0,0))
sphere = bpy.context.active_object
for p in sphere.data.polygons:
    p.use_smooth = True
bpy.ops.export_scene.gltf(filepath='/home/eudespatricio/Games/GameZero/assets/models/crystal_orb.glb', export_format='GLB')
print('Orbe de Cristal exportado!')
"""
    run_blender_script(test_script)
