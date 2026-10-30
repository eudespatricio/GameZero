#!/usr/bin/env python3
"""
Studio Pipeline: Geração de Modelos 3D de Alta Fidelidade para NPCs e Praça Central de Alagaësia (Padrão Dark Fantasy Diablo IV).
1. npc_blacksmith.glb: Horst o Ferreiro com avental de couro, bigorna de ferro forjado com brasas e martelo.
2. npc_herbalist.glb: Angela a Herborista com manto esmeralda escuro, capuz místico, poções e cajado com cristal.
3. npc_storyteller.glb: Brom o Contador de Histórias com túnica de mestre, manto de viagem, barba longa prateada, cachimbo e cajado.
4. elven_central_plaza.glb: Praça élfica em ardósia negra e basalto talhado (16 faces chanfradas, juntas radiais, bronze antigo e estrela de Brightsteel).
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

def make_sharp(obj, angle_deg=30.0):
    bpy.context.view_layer.objects.active = obj
    for p in obj.data.polygons:
        p.use_smooth = False
    mod = obj.modifiers.new("EdgeSplit", type="EDGE_SPLIT")
    mod.use_edge_angle = True
    mod.split_angle = math.radians(angle_deg)
    bpy.ops.object.modifier_apply(modifier="EdgeSplit")

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

# ==========================================================
# 1. HORST, O MESTRE FERREIRO
# ==========================================================
def build_horst():
    reset()
    mat_skin = mat("HorstSkin", (0.78, 0.60, 0.48, 1.0), rough=0.60)
    mat_apron = mat("HorstLeatherApron", (0.24, 0.14, 0.08, 1.0), rough=0.72, metal=0.05)
    mat_tunic = mat("HorstTunic", (0.14, 0.13, 0.12, 1.0), rough=0.85)
    mat_iron = mat("ForgedIron", (0.16, 0.17, 0.19, 1.0), rough=0.35, metal=0.88)
    mat_brass = mat("BrassBuckle", (0.78, 0.60, 0.20, 1.0), rough=0.28, metal=0.88)
    mat_beard = mat("HorstBeard", (0.16, 0.10, 0.06, 1.0), rough=0.88)
    mat_wood = mat("AnvilStump", (0.22, 0.14, 0.08, 1.0), rough=0.90)
    mat_ember = mat("ForgeBladeGlow", (1.0, 0.38, 0.05, 1.0), rough=0.2, emit=(1.0, 0.35, 0.05, 1.0), emit_str=3.0)

    # Torso robusto + Avental de ferreiro
    add_seg("HorstWaist", (0, 0, 0.72), (0, 0, 1.04), 0.22, 0.28, mat_apron, segs=12, scale_xy=(1.18, 0.85))
    add_seg("HorstChest", (0, 0, 1.02), (0, 0, 1.38), 0.28, 0.31, mat_apron, segs=12, scale_xy=(1.22, 0.88))
    add_seg("HorstApronSkirt", (0, -0.02, 0.74), (0, -0.03, 0.38), 0.23, 0.26, mat_apron, segs=10, scale_xy=(1.12, 0.78))
    add_seg("HorstBelt", (0, 0, 0.72), (0, 0, 0.80), 0.24, 0.24, mat_brass, segs=12, scale_xy=(1.18, 0.86))

    # Cabeça + Barba Trançada
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.17, location=(0, -0.02, 1.56))
    head = bpy.context.active_object
    smooth(head)
    head.data.materials.append(mat_skin)

    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.178, location=(0, 0.02, 1.60))
    hair = bpy.context.active_object
    smooth(hair)
    hair.data.materials.append(mat_beard)

    add_seg("HorstBeard", (0, -0.10, 1.48), (0, -0.18, 1.22), 0.13, 0.04, mat_beard, segs=8)

    # Pernas e Botas
    for mult in [-1, 1]:
        add_seg(f"HLeg_{mult}", (0.14 * mult, 0, 0.68), (0.15 * mult, 0, 0.08), 0.11, 0.09, mat_tunic, segs=10)
        add_seg(f"HBoot_{mult}", (0.15 * mult, 0.02, 0.08), (0.15 * mult, -0.18, 0.04), 0.09, 0.06, mat_iron, segs=8)

    # Braços Musculosos + Martelo na mão direita
    add_seg("HArmL", (-0.32, 0, 1.30), (-0.38, -0.22, 0.90), 0.10, 0.08, mat_skin, segs=10)
    add_seg("HArmR", (0.32, 0, 1.30), (0.42, -0.28, 0.94), 0.10, 0.08, mat_skin, segs=10)
    add_seg("HammerHandle", (0.42, -0.18, 0.78), (0.42, -0.45, 1.18), 0.024, 0.026, mat_wood, segs=8)
    add_seg("HammerHead", (0.34, -0.45, 1.18), (0.50, -0.45, 1.18), 0.07, 0.07, mat_iron, segs=6)

    # Bigorna de Ferro Forjado ao lado direito (com espada incandescente sendo forjada!)
    add_seg("AnvilStump", (0.68, -0.35, 0.0), (0.68, -0.35, 0.48), 0.32, 0.28, mat_wood, segs=10)
    add_seg("AnvilPedestal", (0.68, -0.35, 0.48), (0.68, -0.35, 0.72), 0.22, 0.26, mat_iron, segs=8, scale_xy=(1.2, 0.75))
    add_seg("AnvilHorn", (0.68, -0.35, 0.66), (1.06, -0.35, 0.68), 0.12, 0.015, mat_iron, segs=8)
    add_seg("GlowingIngot", (0.52, -0.35, 0.74), (0.88, -0.35, 0.74), 0.04, 0.01, mat_ember, segs=4, scale_xy=(0.3, 1.0))

    out = f"{MODELS_DIR}/npc_blacksmith.glb"
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print(f"Exportado com sucesso: {out}")

# ==========================================================
# 2. ANGELA, A HERBORISTA & VIDENTE
# ==========================================================
def build_angela():
    reset()
    mat_robe = mat("AngelaRobe", (0.06, 0.22, 0.15, 1.0), rough=0.78)
    mat_hood = mat("AngelaHood", (0.12, 0.09, 0.20, 1.0), rough=0.72)
    mat_gold = mat("AngelaGold", (0.82, 0.66, 0.22, 1.0), rough=0.28, metal=0.88)
    mat_skin = mat("AngelaSkin", (0.86, 0.72, 0.64, 1.0), rough=0.55)
    mat_wood = mat("StaffWood", (0.20, 0.13, 0.08, 1.0), rough=0.85)
    mat_gem = mat("CrystalTear", (0.15, 0.92, 0.82, 1.0), rough=0.1, emit=(0.15, 0.92, 0.82, 1.0), emit_str=2.8)
    mat_pot_r = mat("PotionRed", (0.95, 0.15, 0.2, 1.0), rough=0.15, emit=(0.95, 0.15, 0.2, 1.0), emit_str=1.8)
    mat_pot_b = mat("PotionBlue", (0.15, 0.45, 1.0, 1.0), rough=0.15, emit=(0.15, 0.45, 1.0, 1.0), emit_str=1.8)

    add_seg("AngelaSkirt", (0, 0, 0.02), (0, 0, 0.92), 0.42, 0.19, mat_robe, segs=14, scale_xy=(1.05, 0.88))
    add_seg("AngelaTorso", (0, 0, 0.90), (0, 0, 1.32), 0.19, 0.23, mat_robe, segs=12, scale_xy=(1.1, 0.82))
    add_seg("AngelaMantle", (0, 0, 1.18), (0, 0, 1.38), 0.28, 0.18, mat_hood, segs=12, scale_xy=(1.15, 0.88))
    add_seg("AngelaBelt", (0, 0, 0.88), (0, 0, 0.94), 0.21, 0.20, mat_gold, segs=12, scale_xy=(1.1, 0.85))

    # Rosto + Capuz Místico
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.145, location=(0, -0.03, 1.50))
    face = bpy.context.active_object
    smooth(face)
    face.data.materials.append(mat_skin)

    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.185, location=(0, 0.02, 1.53))
    hood = bpy.context.active_object
    hood.scale = (0.95, 1.08, 1.05)
    smooth(hood)
    hood.data.materials.append(mat_hood)

    # Frascos luminosos no cinto
    for px, pm in [(-0.21, mat_pot_r), (0.21, mat_pot_b)]:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.055, location=(px, -0.14, 0.86))
        pot = bpy.context.active_object
        smooth(pot)
        pot.data.materials.append(pm)

    # Braços + Cajado Místico
    add_seg("AArmL", (-0.24, 0, 1.26), (-0.30, -0.18, 0.92), 0.075, 0.095, mat_robe, segs=8)
    add_seg("AArmR", (0.24, 0, 1.26), (0.36, -0.26, 0.96), 0.075, 0.095, mat_robe, segs=8)

    add_seg("AStaff", (0.38, -0.28, 0.02), (0.42, -0.32, 1.78), 0.026, 0.032, mat_wood, segs=8)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.095, location=(0.42, -0.32, 1.90))
    gem = bpy.context.active_object
    gem.scale = (0.75, 0.75, 1.45)
    smooth(gem)
    gem.data.materials.append(mat_gem)

    out = f"{MODELS_DIR}/npc_herbalist.glb"
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print(f"Exportado com sucesso: {out}")

# ==========================================================
# 3. BROM, O CONTADOR DE HISTÓRIAS & MESTRE CAVALEIRO
# ==========================================================
def build_brom():
    reset()
    mat_tunic = mat("BromTunic", (0.22, 0.16, 0.11, 1.0), rough=0.82)
    mat_cloak = mat("BromTravelCloak", (0.12, 0.14, 0.18, 1.0), rough=0.85)
    mat_gold = mat("BromGoldTrim", (0.78, 0.62, 0.22, 1.0), rough=0.3, metal=0.85)
    mat_skin = mat("BromSkin", (0.82, 0.66, 0.56, 1.0), rough=0.62)
    mat_hair = mat("BromSilverBeard", (0.78, 0.80, 0.84, 1.0), rough=0.78)
    mat_wood = mat("BromAshStaff", (0.18, 0.11, 0.06, 1.0), rough=0.85)
    mat_glow = mat("BromRunicOrb", (0.25, 0.75, 1.0, 1.0), rough=0.15, emit=(0.25, 0.75, 1.0, 1.0), emit_str=2.2)

    # Túnica longa esculpida em A + Manto nas costas (SEM pneu cinza no pescoço!)
    add_seg("BromLowerRobe", (0, 0, 0.04), (0, 0, 0.88), 0.36, 0.21, mat_tunic, segs=12, scale_xy=(1.08, 0.85))
    add_seg("BromTorso", (0, 0, 0.86), (0, 0, 1.34), 0.21, 0.26, mat_tunic, segs=12, scale_xy=(1.15, 0.82))
    add_seg("BromBelt", (0, 0, 0.84), (0, 0, 0.91), 0.22, 0.22, mat_gold, segs=12, scale_xy=(1.15, 0.84))
    add_seg("BromCloakBack", (0, 0.12, 1.32), (0, 0.22, 0.08), 0.24, 0.36, mat_cloak, segs=10, scale_xy=(1.15, 0.22))
    add_seg("BromShoulderMantle", (0, 0.02, 1.22), (0, 0.02, 1.38), 0.29, 0.18, mat_cloak, segs=12, scale_xy=(1.18, 0.86))

    # Cabeça + Cabelo e Barba Longa de Sábio
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.16, location=(0, -0.02, 1.54))
    head = bpy.context.active_object
    smooth(head)
    head.data.materials.append(mat_skin)

    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.172, location=(0, 0.03, 1.58))
    hair = bpy.context.active_object
    smooth(hair)
    hair.data.materials.append(mat_hair)

    add_seg("BromBeard", (0, -0.10, 1.46), (0, -0.18, 1.08), 0.12, 0.025, mat_hair, segs=8)

    # Braços + Cajado de Freixo com Runa Azul
    add_seg("BArmL", (-0.28, 0, 1.28), (-0.34, -0.20, 0.92), 0.08, 0.07, mat_cloak, segs=8)
    add_seg("BArmR", (0.28, 0, 1.28), (0.38, -0.26, 0.96), 0.08, 0.07, mat_cloak, segs=8)
    add_seg("BStaff", (0.40, -0.28, 0.02), (0.42, -0.30, 1.75), 0.028, 0.035, mat_wood, segs=8)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.07, location=(0.42, -0.30, 1.82))
    orb = bpy.context.active_object
    orb.data.materials.append(mat_glow)

    out = f"{MODELS_DIR}/npc_storyteller.glb"
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print(f"Exportado com sucesso: {out}")

# ==========================================================
# 4. PRAÇA CENTRAL EM ARDÓSIA NEGRA E BRONZE ANTIGO (DIABLO IV SANCTUARY)
# ==========================================================
def build_elven_plaza():
    reset()
    mat_stone_rim = mat("PlazaDarkGraniteRim", (0.10, 0.11, 0.13, 1.0), rough=0.85, metal=0.08)
    mat_outer_floor = mat("PlazaDarkSlateTiles", (0.08, 0.09, 0.11, 1.0), rough=0.82, metal=0.05)
    mat_inner_mosaic = mat("PlazaObsidianSlate", (0.05, 0.07, 0.09, 1.0), rough=0.72, metal=0.12)
    mat_gold_rune = mat("PlazaAntiqueBronze", (0.58, 0.44, 0.18, 1.0), rough=0.38, metal=0.85,
                        emit=(0.45, 0.34, 0.12, 1.0), emit_str=0.22)
    mat_brightsteel = mat("PlazaRunicSteel", (0.22, 0.36, 0.48, 1.0), rough=0.35, metal=0.82,
                          emit=(0.12, 0.35, 0.55, 1.0), emit_str=0.25)

    # 1. Base octogonal/hexadecagonal chanfrada em 2 degraus de pedra escura (ZERO aparência de prato plástico!)
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=9.2, depth=0.10, location=(0, 0, 0.05))
    step_outer = bpy.context.active_object
    make_sharp(step_outer)
    step_outer.data.materials.append(mat_stone_rim)

    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=8.85, depth=0.12, location=(0, 0, 0.11))
    base = bpy.context.active_object
    make_sharp(base)
    base.data.materials.append(mat_outer_floor)

    # 2. Blocos de contenção perimetrais talhados (16 segmentos com frestas reais)
    for i in range(16):
        ang = (2.0 * math.pi * i) / 16.0
        bx = math.cos(ang) * 8.75
        by = math.sin(ang) * 8.75
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(bx, by, 0.19))
        curb = bpy.context.active_object
        curb.scale = (0.38, 3.15, 0.08)
        curb.rotation_euler = (0, 0, ang)
        make_sharp(curb)
        curb.data.materials.append(mat_stone_rim)

    # 3. Anel rúnico em bronze envelhecido (sem estourar o bloom)
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=6.15, depth=0.03, location=(0, 0, 0.175))
    ring_outer = bpy.context.active_object
    make_sharp(ring_outer)
    ring_outer.data.materials.append(mat_gold_rune)

    # 4. Piso interno de ardósia negra (raio 5.95m)
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=5.95, depth=0.04, location=(0, 0, 0.18))
    inner = bpy.context.active_object
    make_sharp(inner)
    inner.data.materials.append(mat_inner_mosaic)

    # 5. Rosa dos Ventos / Estrela de Brightsteel de 8 pontas incrustada na ardósia
    for i in range(4):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.205))
        blade = bpy.context.active_object
        blade.scale = (0.28, 4.2, 0.015)
        blade.rotation_euler = (0, 0, math.radians(i * 45))
        make_sharp(blade)
        blade.data.materials.append(mat_brightsteel)

    # 6. Medalhão central em bronze escuro e safira profunda
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.95, depth=0.025, location=(0, 0, 0.215))
    crest = bpy.context.active_object
    make_sharp(crest)
    crest.data.materials.append(mat_gold_rune)

    # 7. 8 Marcos Rúnicos de Pedra Talhada no perímetro
    for angle in range(0, 360, 45):
        rad = math.radians(angle + 22.5)
        px = math.cos(rad) * 7.85
        py = math.sin(rad) * 7.85
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.28, depth=0.42, location=(px, py, 0.32))
        marker = bpy.context.active_object
        make_sharp(marker)
        marker.data.materials.append(mat_stone_rim)

        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.09, location=(px, py, 0.56))
        lamp = bpy.context.active_object
        make_sharp(lamp)
        lamp.data.materials.append(mat_brightsteel)

    out = f"{MODELS_DIR}/elven_central_plaza.glb"
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print(f"Exportado com sucesso: {out}")

build_horst()
build_angela()
build_brom()
build_elven_plaza()
"""

script_path = "/tmp/generate_npcs_and_plaza.py"
with open(script_path, "w") as f:
    f.write(BLENDER_SCRIPT)

print("Iniciando geração de NPCs e Praça Dark Fantasy em Blender 4.2 LTS...")
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
    print("Todos os modelos de NPCs e Praça gerados com sucesso!")
