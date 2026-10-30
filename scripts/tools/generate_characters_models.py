#!/usr/bin/env python3
"""
Gerador de Modelos 3D de Personagens e Asas para GameZero via Blender 4.2 LTS (Padrão Diablo IV / Mu Online):
1. character_zero.glb: Cavaleiro de Dragão com armadura de placas esculpida, peitoral com relevo dourado,
   manoplas com Gedwëy Ignasia, grevas, espada Brisingr empunhada na mão direita com lâmina flamejante azul.
2. crystal_wings_detailed.glb: Asas de Arcanjo / Cristal contínuas com suporte dorsal dourado, arcos articulados
   e 18 lâminas de penas de cristal em leque radiante (ZERO triângulos soltos!).
3. urgal_warrior.glb: Kull / Batedor Urgal musculoso com chifres de carneiro segmentados contínuos, armadura de ferro
   espinhosa, olhos em brasa e machado de batalha duplo.
"""

import os
import subprocess
import sys

MODELS_DIR = "/home/eudespatricio/Games/GameZero/assets/models"
os.makedirs(MODELS_DIR, exist_ok=True)

BLENDER_SCRIPT = """
import bpy
import bmesh
import math
from mathutils import Vector

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def mat(name, color, rough=0.4, metal=0.0, emit=None, emit_str=0.0):
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
# 1. CAVALEIRO DE DRAGÃO (ZERO) - FRENTE EM -Y (GODOT +Z)
# ==========================================
def build_zero():
    reset()
    mat_steel = mat("ZeroDarkSteel", (0.14, 0.16, 0.20, 1.0), rough=0.28, metal=0.88)
    mat_blue_plate = mat("ZeroSapphirePlate", (0.06, 0.18, 0.36, 1.0), rough=0.32, metal=0.72)
    mat_gold = mat("ZeroRoyalGold", (0.85, 0.68, 0.22, 1.0), rough=0.22, metal=0.92)
    mat_skin = mat("ZeroElvenSkin", (0.86, 0.72, 0.62, 1.0), rough=0.55)
    mat_hair = mat("ZeroDarkHair", (0.12, 0.09, 0.07, 1.0), rough=0.75)
    mat_tunic = mat("ZeroLeatherTunic", (0.08, 0.10, 0.14, 1.0), rough=0.78)
    mat_blade = mat("BrisingrSapphireBlade", (0.15, 0.68, 1.0, 1.0), rough=0.12, metal=0.85,
                    emit=(0.18, 0.72, 1.0, 1.0), emit_str=2.2)
    mat_gedwey = mat("GedweySilverMark", (0.85, 0.96, 1.0, 1.0), rough=0.1, metal=0.6,
                     emit=(0.6, 0.92, 1.0, 1.0), emit_str=2.5)

    # Torso Anatômico em V (Cintura -> Peito)
    add_seg("TorsoLower", (0, 0, 0.76), (0, 0, 1.02), 0.18, 0.24, mat_blue_plate, segs=12, scale_xy=(1.15, 0.78))
    add_seg("TorsoUpper", (0, 0, 1.00), (0, 0, 1.34), 0.24, 0.28, mat_steel, segs=12, scale_xy=(1.22, 0.80))

    # Brasão Peitoral Dourado (Frente = -Y)
    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.16, depth=0.06, location=(0, -0.20, 1.16))
    crest = bpy.context.active_object
    crest.rotation_euler = (math.radians(90), 0, 0)
    crest.scale = (1.1, 1.0, 1.0)
    smooth(crest)
    crest.data.materials.append(mat_gold)

    # Gola Gorget Dourada e Pescoço
    add_seg("Gorget", (0, 0, 1.32), (0, 0, 1.40), 0.16, 0.13, mat_gold, segs=12)
    add_seg("Neck", (0, 0, 1.38), (0, 0, 1.48), 0.085, 0.08, mat_skin, segs=10)

    # Cabeça Esculpida + Orelhas Élficas + Cabelo
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.155, location=(0, -0.01, 1.56))
    head = bpy.context.active_object
    head.scale = (0.88, 0.96, 1.08)
    smooth(head)
    head.data.materials.append(mat_skin)

    for mult in [-1, 1]:
        add_seg(f"Ear_{mult}", (0.13 * mult, 0.0, 1.55), (0.22 * mult, 0.04, 1.62), 0.032, 0.004, mat_skin, segs=6)

    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.168, location=(0, 0.03, 1.60))
    hair = bpy.context.active_object
    hair.scale = (0.92, 1.02, 0.90)
    smooth(hair)
    hair.data.materials.append(mat_hair)

    # Cinto Real + Fivela + Faldão de Batalha (Tassets)
    add_seg("Belt", (0, 0, 0.72), (0, 0, 0.80), 0.20, 0.19, mat_gold, segs=12, scale_xy=(1.15, 0.82))
    add_seg("BattleSkirt", (0, 0, 0.74), (0, 0, 0.52), 0.20, 0.25, mat_tunic, segs=12, scale_xy=(1.12, 0.82))

    # Placas Laterais de Quadril (Tassets)
    for mult in [-1, 1]:
        add_seg(f"Tasset_{mult}", (0.21 * mult, -0.02, 0.74), (0.24 * mult, -0.02, 0.52), 0.08, 0.06, mat_steel, segs=6, scale_xy=(0.4, 1.2))

    # Pernas, Joelheiras Douradas, Grevas e Sabatões
    for mult in [-1, 1]:
        hip = (0.12 * mult, 0.0, 0.68)
        knee = (0.13 * mult, -0.03, 0.38)
        ankle = (0.13 * mult, 0.01, 0.08)
        add_seg(f"Thigh_{mult}", hip, knee, 0.095, 0.078, mat_tunic, segs=10)
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.072, location=(knee[0], knee[1] - 0.02, knee[2]))
        kp = bpy.context.active_object
        smooth(kp)
        kp.data.materials.append(mat_gold)
        add_seg(f"Greave_{mult}", knee, ankle, 0.082, 0.065, mat_steel, segs=10)
        add_seg(f"Sabaton_{mult}", (ankle[0], ankle[1] + 0.03, 0.06), (ankle[0], ankle[1] - 0.18, 0.03), 0.07, 0.045, mat_steel, segs=8)

    # Braço Esquerdo (Posição de guarda para o Escudo)
    sh_l = (-0.28, 0.0, 1.28)
    el_l = (-0.36, -0.04, 1.00)
    wr_l = (-0.34, -0.18, 0.86)
    add_seg("LeftUpperArm", sh_l, el_l, 0.078, 0.065, mat_blue_plate, segs=10)
    add_seg("LeftForearm", el_l, wr_l, 0.072, 0.060, mat_steel, segs=10)

    # Braço Direito (Empunhando a Espada Brisingr à frente!)
    sh_r = (0.28, 0.0, 1.28)
    el_r = (0.36, -0.06, 1.00)
    wr_r = (0.34, -0.26, 0.84)
    add_seg("RightUpperArm", sh_r, el_r, 0.078, 0.065, mat_blue_plate, segs=10)
    add_seg("RightForearm", el_r, wr_r, 0.072, 0.060, mat_steel, segs=10)

    # Mão Direita + Brilho da Gedwëy Ignasia
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.055, location=wr_r)
    hand_r = bpy.context.active_object
    smooth(hand_r)
    hand_r.data.materials.append(mat_steel)

    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.038, location=(wr_r[0] + 0.03, wr_r[1] - 0.03, wr_r[2]))
    gedwey = bpy.context.active_object
    smooth(gedwey)
    gedwey.data.materials.append(mat_gedwey)

    # --- ESPADA BRISINGR EMPUNHADA NA MÃO DIREITA ---
    pommel_pos = (0.34, -0.16, 0.74)
    hilt_pos   = (0.34, -0.34, 0.92)
    tip_pos    = (0.30, -0.98, 1.56)

    # Pomo de Safira + Punho + Guarda-Mão Alada Dourada + Lâmina de Fogo Azul
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.042, location=pommel_pos)
    pommel = bpy.context.active_object
    smooth(pommel)
    pommel.data.materials.append(mat_blade)

    add_seg("BrisingrGrip", pommel_pos, hilt_pos, 0.026, 0.028, mat_gold, segs=8)
    add_seg("BrisingrGuardL", hilt_pos, (hilt_pos[0] - 0.16, hilt_pos[1] - 0.04, hilt_pos[2] + 0.04), 0.032, 0.012, mat_gold, segs=6)
    add_seg("BrisingrGuardR", hilt_pos, (hilt_pos[0] + 0.16, hilt_pos[1] - 0.04, hilt_pos[2] + 0.04), 0.032, 0.012, mat_gold, segs=6)
    add_seg("BrisingrBlade", hilt_pos, tip_pos, 0.048, 0.004, mat_blade, segs=4, scale_xy=(0.28, 1.0))

    out = "/home/eudespatricio/Games/GameZero/assets/models/character_zero.glb"
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print(f"Exportado: {out}")

# ==========================================
# 2. ASAS DE ARCANJO / CRISTAL CONTÍNUAS (ESTILO MU ONLINE / DIABLO INARIUS)
# ==========================================
def build_wings():
    reset()
    mat_gold = mat("WingDivineGold", (0.88, 0.72, 0.24, 1.0), rough=0.22, metal=0.92)
    mat_crystal = mat("WingCrystalFeather", (0.15, 0.68, 1.0, 1.0), rough=0.14, metal=0.55,
                      emit=(0.12, 0.58, 0.98, 1.0), emit_str=1.35)
    mat_core = mat("WingCoreSapphire", (0.06, 0.28, 0.62, 1.0), rough=0.2, metal=0.8,
                   emit=(0.08, 0.42, 0.85, 1.0), emit_str=0.8)

    # Brasão Dorsal Central que conecta as duas asas às costas do herói
    add_seg("WingCenterClasp", (0, 0, -0.12), (0, 0.04, 0.18), 0.06, 0.11, mat_gold, segs=8)

    for mult in [-1, 1]:
        # Arco superior dourado articulado (Ombro -> Curva Alta -> Ponta Superior)
        p0 = (0.06 * mult, 0.02, 0.06)
        p1 = (0.38 * mult, 0.08, 0.34)
        p2 = (0.82 * mult, 0.14, 0.52)
        p3 = (1.28 * mult, 0.20, 0.44)
        add_seg(f"WingFrame1_{mult}", p0, p1, 0.055, 0.045, mat_gold, segs=8)
        add_seg(f"WingFrame2_{mult}", p1, p2, 0.045, 0.035, mat_gold, segs=8)
        add_seg(f"WingFrame3_{mult}", p2, p3, 0.035, 0.018, mat_gold, segs=8)

        # 9 Lâminas de Penas de Cristal irradiando continuamente do arco superior (sem espaços vazios!)
        num_feathers = 9
        for i in range(num_feathers):
            t = i / float(num_feathers - 1)
            # Ponto de origem ao longo do arco da asa
            if t < 0.5:
                st = t * 2.0
                root_x = (1.0 - st) * p1[0] + st * p2[0]
                root_y = (1.0 - st) * p1[1] + st * p2[1]
                root_z = (1.0 - st) * p1[2] + st * p2[2]
            else:
                st = (t - 0.5) * 2.0
                root_x = (1.0 - st) * p2[0] + st * p3[0]
                root_y = (1.0 - st) * p2[1] + st * p3[1]
                root_z = (1.0 - st) * p2[2] + st * p3[2]

            # Direção em leque abrindo para fora e para baixo
            feather_len = 0.65 + math.sin(t * math.pi) * 0.45
            angle_out = math.radians(15 + t * 52) * mult
            tip_x = root_x + math.sin(angle_out) * feather_len * 0.85
            tip_y = root_y + 0.08
            tip_z = root_z - math.cos(angle_out * mult) * feather_len * 0.72 + (t * 0.25)

            f_mat = mat_crystal if i % 2 == 0 else mat_core
            add_seg(f"CrystalFeather_{mult}_{i}", (root_x, root_y, root_z), (tip_x, tip_y, tip_z),
                    0.058, 0.006, f_mat, segs=4, scale_xy=(0.32, 1.1))

    out = "/home/eudespatricio/Games/GameZero/assets/models/crystal_wings_detailed.glb"
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print(f"Exportado: {out}")

# ==========================================
# 3. GUERREIRO KULL / URGAL BRUTAL (FRENTE EM -Y)
# ==========================================
def build_urgal():
    reset()
    mat_skin = mat("UrgalAshSkin", (0.26, 0.20, 0.17, 1.0), rough=0.82)
    mat_horn = mat("UrgalRamHorn", (0.12, 0.10, 0.09, 1.0), rough=0.45, metal=0.15)
    mat_iron = mat("UrgalBlackIron", (0.14, 0.15, 0.17, 1.0), rough=0.38, metal=0.88)
    mat_blood = mat("UrgalWarPaint", (0.55, 0.08, 0.06, 1.0), rough=0.6)
    mat_eye = mat("UrgalRageEye", (1.0, 0.22, 0.05, 1.0), rough=0.1, emit=(1.0, 0.2, 0.05, 1.0), emit_str=3.0)
    mat_steel = mat("UrgalAxeEdge", (0.52, 0.56, 0.60, 1.0), rough=0.25, metal=0.92)
    mat_wood = mat("UrgalAxeShaft", (0.20, 0.12, 0.07, 1.0), rough=0.88)

    # Torso Brutal em V
    add_seg("UrgalWaist", (0, 0, 0.78), (0, 0, 1.12), 0.26, 0.36, mat_skin, segs=12, scale_xy=(1.2, 0.85))
    add_seg("UrgalChest", (0, 0, 1.10), (0, 0, 1.52), 0.36, 0.42, mat_skin, segs=12, scale_xy=(1.25, 0.88))

    # Peitoral Cruzado de Ferro Negro
    add_seg("UrgalHarness1", (-0.32, -0.22, 1.48), (0.28, -0.22, 0.88), 0.06, 0.06, mat_iron, segs=6)
    add_seg("UrgalHarness2", (0.32, -0.22, 1.48), (-0.28, -0.22, 0.88), 0.06, 0.06, mat_iron, segs=6)
    add_seg("UrgalBelt", (0, 0, 0.72), (0, 0, 0.86), 0.30, 0.28, mat_iron, segs=12, scale_xy=(1.18, 0.88))
    add_seg("UrgalKilt", (0, 0, 0.76), (0, 0, 0.46), 0.29, 0.34, mat_blood, segs=12, scale_xy=(1.15, 0.85))

    # Cabeça + Mandíbula + Olhos em Brasa + Chifres de Carneiro Curvados em 3 Segmentos
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.22, location=(0, -0.04, 1.72))
    head = bpy.context.active_object
    head.scale = (0.95, 1.05, 1.0)
    smooth(head)
    head.data.materials.append(mat_skin)

    for mult in [-1, 1]:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.035, location=(0.08 * mult, -0.22, 1.74))
        eye = bpy.context.active_object
        eye.data.materials.append(mat_eye)

        # Chifres espiralados contínuos
        hb = (0.16 * mult, 0.0, 1.82)
        hm = (0.38 * mult, 0.12, 1.92)
        ht = (0.46 * mult, -0.14, 1.72)
        hp = (0.38 * mult, -0.32, 1.80)
        add_seg(f"UHorn1_{mult}", hb, hm, 0.085, 0.065, mat_horn, segs=8)
        add_seg(f"UHorn2_{mult}", hm, ht, 0.065, 0.040, mat_horn, segs=8)
        add_seg(f"UHorn3_{mult}", ht, hp, 0.040, 0.008, mat_horn, segs=8)

        # Ombreiras de Ferro com Espinhos
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.20, location=(0.46 * mult, 0, 1.48))
        sp = bpy.context.active_object
        sp.scale = (1.1, 0.9, 0.75)
        smooth(sp)
        sp.data.materials.append(mat_iron)
        add_seg(f"USpike_{mult}", (0.50 * mult, 0, 1.56), (0.68 * mult, 0, 1.85), 0.055, 0.005, mat_horn, segs=6)

        # Pernas Musculosas
        add_seg(f"UThigh_{mult}", (0.20 * mult, 0, 0.72), (0.22 * mult, -0.04, 0.38), 0.14, 0.11, mat_skin, segs=10)
        add_seg(f"UShin_{mult}", (0.22 * mult, -0.04, 0.38), (0.22 * mult, 0.0, 0.06), 0.11, 0.09, mat_iron, segs=10)

    # Braços Musculosos + Machado de Guerra Duplo
    add_seg("UArmL", (-0.44, 0, 1.42), (-0.50, -0.22, 0.92), 0.12, 0.095, mat_skin, segs=10)
    add_seg("UArmR", (0.44, 0, 1.42), (0.48, -0.32, 0.96), 0.12, 0.095, mat_skin, segs=10)

    # Machado de Batalha na mão direita
    s_bot = (0.48, -0.10, 0.45)
    s_top = (0.48, -0.62, 1.72)
    add_seg("AxeShaft", s_bot, s_top, 0.038, 0.042, mat_wood, segs=8)
    add_seg("AxeBladeF", (0.48, -0.52, 1.48), (0.48, -0.88, 1.62), 0.22, 0.32, mat_steel, segs=4, scale_xy=(0.18, 1.0))
    add_seg("AxeBladeB", (0.48, -0.52, 1.48), (0.48, -0.22, 1.36), 0.18, 0.26, mat_steel, segs=4, scale_xy=(0.18, 1.0))

    out = "/home/eudespatricio/Games/GameZero/assets/models/urgal_warrior.glb"
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print(f"Exportado: {out}")

build_zero()
build_wings()
build_urgal()
print("TODOS OS PERSONAGENS E ASAS GERADOS COM SUCESSO!")
"""

def main():
    print("[Pipeline 3D GameZero] Gerando modelos de Personagens e Asas com Blender 4.2...")
    cmd = ["/home/eudespatricio/.local/bin/blender", "--background", "--python-expr", BLENDER_SCRIPT]
    res = subprocess.run(cmd, capture_output=True, text=True)
    print(res.stdout)
    if res.returncode != 0:
        print("[Erro no Blender]:", res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
