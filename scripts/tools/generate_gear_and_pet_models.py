#!/usr/bin/env python3
"""
Gera modelos 3D PBR de alta fidelidade dos equipamentos e Pet via Blender 4.2 LTS:
1. dragon_pet.glb: Dragãozinho Filhote (Nieda) com corpo contínuo e asas de membrana real.
2. dragon_shield.glb: Escudo Heráldico Kite de Escamas de Safira e Ouro.
3. elven_helm.glb: Elmo Coroado Élfico com guarda-faces alados e gema frontal.
4. dragon_pauldrons.glb: Ombreiras em camadas com garras douradas.
5. dragon_cape.glb: Manto Real de Cavaleiro (sem colar toroidal desproporcional).
6. dragon_gloves.glb & dragon_boots.glb: Manoplas e Grevas de Placas.
"""

import os
import subprocess
import sys

MODELS_DIR = "/home/eudespatricio/Games/GameZero/assets/models"
os.makedirs(MODELS_DIR, exist_ok=True)

BLENDER_SCRIPT = """
import bpy
import math
from mathutils import Vector

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def mat(name, color, rough=0.35, metal=0.0, emit=None, emit_str=0.0):
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

def add_seg(name, p1, p2, r1, r2, material, segs=10, scale_xy=(1.0, 1.0)):
    v1 = Vector(p1)
    v2 = Vector(p2)
    diff = v2 - v1
    length = diff.length
    if length < 0.001:
        return None
    mid = (v1 + v2) * 0.5
    bpy.ops.mesh.primitive_cone_add(vertices=segs, radius1=r1, radius2=r2, depth=length, location=mid)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = (scale_xy[0], scale_xy[1], 1.0)
    quat = diff.normalized().to_track_quat('Z', 'Y')
    obj.rotation_mode = 'QUATERNION'
    obj.rotation_quaternion = quat
    smooth(obj)
    obj.data.materials.append(material)
    return obj

# ==========================================
# 1. PET: DRAGÃOZINHO FILHOTE (NIEDA)
# ==========================================
def build_dragon_pet():
    reset()
    mat_scale = mat("BabyDragonScale", (0.08, 0.36, 0.78, 1.0), rough=0.32, metal=0.55)
    mat_wing = mat("BabyDragonWing", (0.14, 0.58, 0.95, 1.0), rough=0.35, metal=0.3,
                   emit=(0.08, 0.38, 0.82, 1.0), emit_str=0.45)
    mat_gold = mat("BabyDragonGold", (0.90, 0.74, 0.25, 1.0), rough=0.22, metal=0.88)
    mat_eye = mat("BabyDragonEye", (0.3, 0.95, 1.0, 1.0), rough=0.1, emit=(0.3, 0.95, 1.0, 1.0), emit_str=3.0)

    # Corpo contínuo do filhote
    add_seg("PetTail2", (0, 0.65, 0.42), (0, 0.32, 0.46), 0.015, 0.09, mat_scale, segs=10)
    add_seg("PetTorso", (0, 0.32, 0.46), (0, -0.18, 0.54), 0.09, 0.18, mat_scale, segs=12)
    add_seg("PetNeck", (0, -0.15, 0.54), (0, -0.34, 0.72), 0.14, 0.11, mat_scale, segs=10)
    add_seg("PetHead", (0, -0.30, 0.72), (0, -0.56, 0.68), 0.13, 0.05, mat_scale, segs=10)

    for mult in [-1, 1]:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.032, location=(0.085 * mult, -0.40, 0.74))
        eye = bpy.context.active_object
        eye.data.materials.append(mat_eye)

        add_seg(f"PetHorn_{mult}", (0.07 * mult, -0.28, 0.76), (0.14 * mult, -0.08, 0.92), 0.035, 0.005, mat_gold, segs=6)

        # Asas de membrana real para o filhote
        w_verts = [
            (0.12 * mult, -0.08, 0.58),
            (0.42 * mult, -0.18, 0.78),
            (0.68 * mult,  0.02, 0.72),
            (0.48 * mult,  0.18, 0.58),
            (0.14 * mult,  0.15, 0.52)
        ]
        w_mesh = bpy.data.meshes.new(f"PetWingMesh_{mult}")
        w_obj = bpy.data.objects.new(f"PetWing_{mult}", w_mesh)
        bpy.context.collection.objects.link(w_obj)
        w_mesh.from_pydata(w_verts, [], [(0, 1, 2, 3, 4)])
        w_mesh.update()
        mod_s = w_obj.modifiers.new("Sol", 'SOLIDIFY')
        mod_s.thickness = 0.02
        smooth(w_obj)
        w_obj.data.materials.append(mat_wing)

    out = "/home/eudespatricio/Games/GameZero/assets/models/dragon_pet.glb"
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print(f"Exportado: {out}")

# ==========================================
# 2. ESCUDO HERÁLDICO DE DRAGÃO (KITE SHIELD)
# ==========================================
def build_dragon_shield():
    reset()
    mat_steel = mat("ShieldDarkSteel", (0.14, 0.16, 0.20, 1.0), rough=0.28, metal=0.88)
    mat_gold = mat("ShieldRoyalGold", (0.88, 0.70, 0.22, 1.0), rough=0.22, metal=0.92)
    mat_scale = mat("ShieldSapphireScale", (0.06, 0.28, 0.58, 1.0), rough=0.32, metal=0.65)
    mat_gem = mat("ShieldCoreGem", (0.2, 0.85, 1.0, 1.0), rough=0.1, emit=(0.2, 0.85, 1.0, 1.0), emit_str=2.2)

    # Corpo Kite Shield (topo largo chanfrado, ponta inferior afilada)
    add_seg("ShieldUpper", (0, 0, 0.0), (0, 0, 0.42), 0.34, 0.38, mat_steel, segs=6, scale_xy=(1.0, 0.18))
    add_seg("ShieldLower", (0, 0, 0.0), (0, 0, -0.58), 0.34, 0.03, mat_steel, segs=6, scale_xy=(1.0, 0.18))

    # Placa Interna de Escamas de Safira
    add_seg("InnerUpper", (0, -0.02, 0.0), (0, -0.02, 0.35), 0.26, 0.30, mat_scale, segs=6, scale_xy=(1.0, 0.16))
    add_seg("InnerLower", (0, -0.02, 0.0), (0, -0.02, -0.46), 0.26, 0.02, mat_scale, segs=6, scale_xy=(1.0, 0.16))

    # Moldura Dourada & Brasão Central com Gema de Safira
    for mult in [-1, 1]:
        add_seg(f"RimTop_{mult}", (0, -0.03, 0.42), (0.36 * mult, -0.03, 0.34), 0.035, 0.035, mat_gold, segs=6)
        add_seg(f"RimMid_{mult}", (0.36 * mult, -0.03, 0.34), (0.32 * mult, -0.03, 0.0), 0.035, 0.032, mat_gold, segs=6)
        add_seg(f"RimBot_{mult}", (0.32 * mult, -0.03, 0.0), (0, -0.03, -0.58), 0.032, 0.025, mat_gold, segs=6)

    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.14, depth=0.06, location=(0, -0.05, 0.08))
    boss = bpy.context.active_object
    boss.rotation_euler = (math.radians(90), 0, 0)
    smooth(boss)
    boss.data.materials.append(mat_gold)

    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.065, location=(0, -0.08, 0.08))
    gem = bpy.context.active_object
    smooth(gem)
    gem.data.materials.append(mat_gem)

    out = "/home/eudespatricio/Games/GameZero/assets/models/dragon_shield.glb"
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print(f"Exportado: {out}")

# ==========================================
# 3. ELMO COROADO ÉLFICO (CROWN-HELM)
# ==========================================
def build_elven_helm():
    reset()
    mat_steel = mat("HelmDarkSteel", (0.15, 0.17, 0.22, 1.0), rough=0.28, metal=0.88)
    mat_gold = mat("HelmCrownGold", (0.88, 0.72, 0.24, 1.0), rough=0.22, metal=0.92)
    mat_gem = mat("HelmSapphireGem", (0.18, 0.78, 1.0, 1.0), rough=0.1, emit=(0.18, 0.78, 1.0, 1.0), emit_str=2.0)

    # Diadema / Coroa de Batalha + Protetor de Nuca (deixa o rosto nobre visível na frente -Y)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.165, minor_radius=0.024, location=(0, 0, 0.05))
    crown = bpy.context.active_object
    crown.scale = (0.92, 1.0, 1.0)
    smooth(crown)
    crown.data.materials.append(mat_gold)

    # Crista Frontal + Gema de Safira
    add_seg("BrowCrest", (0, -0.165, 0.03), (0, -0.14, 0.22), 0.035, 0.008, mat_gold, segs=6)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.028, location=(0, -0.175, 0.06))
    gem = bpy.context.active_object
    gem.data.materials.append(mat_gem)

    # Asas Valquírias / Élficas nas laterais do Elmo
    for mult in [-1, 1]:
        add_seg(f"HelmWing1_{mult}", (0.15 * mult, -0.04, 0.04), (0.24 * mult, 0.14, 0.24), 0.035, 0.006, mat_gold, segs=6)
        add_seg(f"HelmWing2_{mult}", (0.15 * mult, 0.02, 0.02), (0.22 * mult, 0.18, 0.14), 0.028, 0.005, mat_steel, segs=6)

    out = "/home/eudespatricio/Games/GameZero/assets/models/elven_helm.glb"
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print(f"Exportado: {out}")

# ==========================================
# 4. OMBREIRAS DE DRAGÃO (PAULDRONS)
# ==========================================
def build_dragon_pauldrons():
    reset()
    mat_steel = mat("PauldronSteel", (0.14, 0.16, 0.21, 1.0), rough=0.28, metal=0.88)
    mat_gold = mat("PauldronGold", (0.88, 0.70, 0.22, 1.0), rough=0.22, metal=0.92)

    for mult in [-1, 1]:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.14, location=(mult * 0.31, 0, 0.12))
        plate = bpy.context.active_object
        plate.scale = (1.15, 0.88, 0.72)
        smooth(plate)
        plate.data.materials.append(mat_steel)

        # Garra dourada curvada para cima e para fora
        add_seg(f"PauldronHorn_{mult}", (mult * 0.30, 0, 0.16), (mult * 0.46, 0.04, 0.28), 0.045, 0.006, mat_gold, segs=6)

        bpy.ops.mesh.primitive_torus_add(major_radius=0.13, minor_radius=0.018, location=(mult * 0.31, 0, 0.10))
        trim = bpy.context.active_object
        trim.scale = (1.15, 0.88, 0.72)
        smooth(trim)
        trim.data.materials.append(mat_gold)

    out = "/home/eudespatricio/Games/GameZero/assets/models/dragon_pauldrons.glb"
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print(f"Exportado: {out}")

# ==========================================
# 5. CAPA REAL DE CAVALEIRO (SEM TORO GIGANTE NA CABEÇA!)
# ==========================================
def build_dragon_cape():
    reset()
    mat_velvet = mat("RoyalCapeVelvet", (0.05, 0.10, 0.22, 1.0), rough=0.82)
    mat_gold = mat("RoyalCapeGold", (0.86, 0.70, 0.22, 1.0), rough=0.25, metal=0.9)

    # Broches dourados discretos nas costas dos ombros (Z = 1.00 + offset 0.25 = 1.25m)
    for mult in [-1, 1]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.055, depth=0.03, location=(0.20 * mult, 0.14, 1.02))
        clasp = bpy.context.active_object
        clasp.rotation_euler = (math.radians(80), 0, 0)
        smooth(clasp)
        clasp.data.materials.append(mat_gold)

    # Tecido da capa fluindo das costas (Z = 1.02) até os tornozelos (Z = -0.10)
    add_seg("CapeCloth", (0, 0.16, 1.02), (0, 0.26, -0.08), 0.22, 0.36, mat_velvet, segs=10, scale_xy=(1.2, 0.14))
    add_seg("CapeGoldHem", (0, 0.26, -0.06), (0, 0.27, -0.11), 0.36, 0.37, mat_gold, segs=10, scale_xy=(1.2, 0.15))

    out = "/home/eudespatricio/Games/GameZero/assets/models/dragon_cape.glb"
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print(f"Exportado: {out}")

# ==========================================
# 6. MANOPLAS & GREVAS DE PLACAS
# ==========================================
def build_dragon_gloves():
    reset()
    mat_steel = mat("GloveSteel", (0.16, 0.18, 0.22, 1.0), rough=0.3, metal=0.88)
    mat_gold = mat("GloveGold", (0.86, 0.70, 0.22, 1.0), rough=0.22, metal=0.9)
    for mult in [-1, 1]:
        add_seg(f"Gauntlet_{mult}", (mult * 0.22, 0, 0.22), (mult * 0.22, 0, 0.0), 0.085, 0.065, mat_steel, segs=8)
        add_seg(f"GauntletTrim_{mult}", (mult * 0.22, 0, 0.22), (mult * 0.22, 0, 0.19), 0.09, 0.088, mat_gold, segs=8)
    out = "/home/eudespatricio/Games/GameZero/assets/models/dragon_gloves.glb"
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print(f"Exportado: {out}")

def build_dragon_boots():
    reset()
    mat_steel = mat("BootSteel", (0.16, 0.18, 0.22, 1.0), rough=0.3, metal=0.88)
    mat_gold = mat("BootGold", (0.86, 0.70, 0.22, 1.0), rough=0.22, metal=0.9)
    for mult in [-1, 1]:
        add_seg(f"BootShin_{mult}", (mult * 0.16, 0, 0.42), (mult * 0.16, 0, 0.06), 0.09, 0.075, mat_steel, segs=8)
        add_seg(f"BootFoot_{mult}", (mult * 0.16, 0.02, 0.06), (mult * 0.16, -0.18, 0.03), 0.075, 0.045, mat_gold, segs=8)
    out = "/home/eudespatricio/Games/GameZero/assets/models/dragon_boots.glb"
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print(f"Exportado: {out}")

build_dragon_pet()
build_dragon_shield()
build_elven_helm()
build_dragon_pauldrons()
build_dragon_cape()
build_dragon_gloves()
build_dragon_boots()
print("TODOS OS EQUIPAMENTOS E PET EXPORTADOS COM SUCESSO!")
"""

def main():
    print("[Pipeline 3D GameZero] Gerando modelos de Equipamentos e Pet no Blender...")
    cmd = ["/home/eudespatricio/.local/bin/blender", "--background", "--python-expr", BLENDER_SCRIPT]
    res = subprocess.run(cmd, capture_output=True, text=True)
    print(res.stdout)
    if res.returncode != 0:
        print("[Erro no Blender]:", res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
