#!/usr/bin/env python3
"""
Studio Pipeline: Forja 3D de Flora Élfica Orgânica (Cogumelos Bioluminescentes e Samambaias)
Substitui esferas, cilindros e quads planos por modelos esculturais detalhados.
"""

import os
import subprocess
import sys

MODELS_DIR = "/home/eudespatricio/Games/GameZero/assets/models"
os.makedirs(MODELS_DIR, exist_ok=True)

BLENDER_SCRIPT = """
import bpy
import math

MODELS_DIR = "/home/eudespatricio/Games/GameZero/assets/models"

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def mat(name, color, rough=0.5, metal=0.0, emit=None, emit_str=0.0):
    m = bpy.data.materials.new(name=name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Metallic"].default_value = metal
        if emit and "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = emit
            bsdf.inputs["Emission Strength"].default_value = emit_str
    return m

def smooth(obj):
    for p in obj.data.polygons:
        p.use_smooth = True

# =======================================================
# 1. CLUSTER DE COGUMELOS BIOLUMINESCENTES ÉLFICOS
# =======================================================
def build_mushrooms():
    reset()
    mat_soil = mat("MushroomSoil", (0.12, 0.09, 0.07, 1.0), rough=0.95)
    mat_stem = mat("MushroomStem", (0.82, 0.86, 0.82, 1.0), rough=0.65)
    mat_cyan_cap = mat("BioluminescentCapCyan", (0.10, 0.75, 0.85, 1.0), rough=0.25,
                       emit=(0.15, 0.88, 0.95, 1.0), emit_str=1.6)
    mat_purple_cap = mat("BioluminescentCapViolet", (0.65, 0.20, 0.85, 1.0), rough=0.25,
                         emit=(0.75, 0.25, 0.95, 1.0), emit_str=1.6)
    mat_gills = mat("MushroomGills", (0.05, 0.25, 0.35, 1.0), rough=0.5)

    # Base orgânica de terra e musgo
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.65, depth=0.12, location=(0, 0, 0.06))
    base = bpy.context.active_object
    smooth(base)
    base.data.materials.append(mat_soil)

    # 4 cogumelos de tamanhos e ângulos orgânicos variados
    shrooms = [
        (0.0, 0.0, 0.12, 0.14, 0.75, 0.38, mat_cyan_cap, (math.radians(8), 0, 0)),
        (0.32, 0.20, 0.12, 0.10, 0.58, 0.28, mat_purple_cap, (math.radians(-12), math.radians(15), 0)),
        (-0.28, 0.18, 0.12, 0.09, 0.48, 0.24, mat_cyan_cap, (math.radians(15), math.radians(-10), 0)),
        (0.12, -0.32, 0.12, 0.08, 0.38, 0.20, mat_purple_cap, (math.radians(-18), math.radians(-8), 0))
    ]

    for sx, sy, sz, stem_rad, stem_h, cap_rad, cap_mat, rot in shrooms:
        # Haste curvada
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=stem_rad, depth=stem_h, location=(sx, sy, sz + stem_h * 0.5))
        stem = bpy.context.active_object
        stem.rotation_euler = rot
        smooth(stem)
        stem.data.materials.append(mat_stem)

        # Chapéu do cogumelo (cúpula cônica elegante)
        cap_z = sz + stem_h * 0.95
        bpy.ops.mesh.primitive_cone_add(vertices=12, radius1=cap_rad, radius2=0.03, depth=cap_rad * 0.85, location=(sx, sy, cap_z))
        cap = bpy.context.active_object
        cap.rotation_euler = rot
        smooth(cap)
        cap.data.materials.append(cap_mat)

        # Lamelas inferiores (gills) sob o chapéu
        bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=cap_rad * 0.88, depth=0.03, location=(sx, sy, cap_z - cap_rad * 0.35))
        gills = bpy.context.active_object
        gills.rotation_euler = rot
        smooth(gills)
        gills.data.materials.append(mat_gills)

        # Pequenas esferas de esporos brilhantes ao redor do chapéu
        for i in range(3):
            ang = i * 2.1
            ex = sx + math.cos(ang) * (cap_rad * 0.65)
            ey = sy + math.sin(ang) * (cap_rad * 0.65)
            bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.025, location=(ex, ey, cap_z + 0.04))
            spore = bpy.context.active_object
            spore.data.materials.append(cap_mat)

    out = f"{MODELS_DIR}/elven_mushrooms_cluster.glb"
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print(f"Exportado: {out}")

# =======================================================
# 2. SAMAMBAIA & FOLHAGEM ÉLFICA (FERN PATCH DELICADA)
# =======================================================
def build_ferns():
    reset()
    mat_frond_deep = mat("FernDeepGreen", (0.06, 0.22, 0.10, 1.0), rough=0.6)
    mat_frond_light = mat("FernLightGreen", (0.12, 0.42, 0.20, 1.0), rough=0.5)

    # Agrupamento delicado e compacto de 5 frondes finas (altura ~30cm)
    for i in range(5):
        ang = (i / 5.0) * math.pi * 2.0
        pitch = math.radians(40 + (i % 2) * 10)
        
        # Haste central fina
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.008, depth=0.45, location=(math.cos(ang) * 0.08, math.sin(ang) * 0.08, 0.20))
        stem = bpy.context.active_object
        stem.rotation_euler = (math.sin(ang) * pitch, -math.cos(ang) * pitch, ang)
        smooth(stem)
        stem.data.materials.append(mat_frond_deep)

        # Folíolos delicados
        bpy.ops.mesh.primitive_cone_add(vertices=5, radius1=0.06, radius2=0.005, depth=0.38, location=(math.cos(ang) * 0.14, math.sin(ang) * 0.14, 0.22))
        frond = bpy.context.active_object
        frond.scale = (0.2, 0.8, 0.8)
        frond.rotation_euler = (math.sin(ang) * (pitch + 0.12), -math.cos(ang) * (pitch + 0.12), ang)
        smooth(frond)
        frond.data.materials.append(mat_frond_light)

    out = f"{MODELS_DIR}/elven_fern_patch.glb"
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print(f"Exportado: {out}")

build_mushrooms()
build_ferns()
"""

script_path = "/tmp/generate_flora_props.py"
with open(script_path, "w") as f:
    f.write(BLENDER_SCRIPT)

print("Iniciando forja de flora élfica no Blender 4.2 LTS...")
res = subprocess.run([
    "/home/eudespatricio/.local/bin/blender",
    "--background",
    "--python", script_path
], capture_output=True, text=True)

print(res.stdout)
if res.returncode != 0:
    print("ERRO:", res.stderr, file=sys.stderr)
    sys.exit(res.returncode)
else:
    print("Flora élfica gerada com sucesso!")
