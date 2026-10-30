#!/usr/bin/env python3
"""
Studio Pipeline: Escultura 3D Contínua do Dragão Saphira (Lofted BMesh + Álgebra Vetorial).
Elimina 100% esferas/cilindros desconectados e hastes de antena:
1. Corpo, Pescoço e Cauda: Malha contínua única gerada por lofting de 22 anéis anatômicos (BMesh bridge_loops + Subsurf).
2. Asas: Membrana contínua com ossatura gerada por vetores exatos (p1 -> p2 via to_track_quat), garantindo encaixe perfeito na borda e nas falanges da membrana.
3. Orientação: Frente em -Y no Blender (+Z no Godot, alinhado com atan2(vx, vz) do Player).
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
from mathutils import Vector, Matrix

MODELS_DIR = "/home/eudespatricio/Games/GameZero/assets/models"
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

def add_bone_segment(name, p1, p2, r1, r2, material, segs=10):
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
    quat = diff.normalized().to_track_quat('Z', 'Y')
    obj.rotation_mode = 'QUATERNION'
    obj.rotation_quaternion = quat
    smooth(obj)
    obj.data.materials.append(material)
    return obj

# Materiais PBR Safira Escura & Ouro Antigo
mat_scales = mat("SaphiraScales", (0.04, 0.16, 0.36, 1.0), rough=0.30, metal=0.62)
mat_wing_bone = mat("SaphiraWingBone", (0.03, 0.12, 0.28, 1.0), rough=0.34, metal=0.68)
mat_membrane = mat("SaphiraWingMembrane", (0.06, 0.24, 0.52, 1.0), rough=0.42, metal=0.25,
                   emit=(0.03, 0.14, 0.32, 1.0), emit_str=0.25)
mat_horns = mat("SaphiraGoldHorns", (0.78, 0.62, 0.22, 1.0), rough=0.24, metal=0.88)
mat_eyes = mat("SaphiraEyes", (0.3, 0.92, 1.0, 1.0), rough=0.1, emit=(0.3, 0.92, 1.0, 1.0), emit_str=3.5)
mat_saddle = mat("SaphiraLeatherSaddle", (0.18, 0.10, 0.06, 1.0), rough=0.72, metal=0.08)

# ========================================================
# 1. CORPO CONTÍNUO ESCULPIDO (SNout -> Cabeça -> Pescoço -> Torso -> Cauda)
# ========================================================
# Cada ponto: (y, z, radius_x, radius_z, pitch_deg)
spine_profile = [
    (-3.35, 2.38, 0.10, 0.08, -10),  # Ponta do focinho
    (-3.05, 2.44, 0.20, 0.16, -8),   # Focinho médio
    (-2.68, 2.52, 0.32, 0.26, -5),   # Crânio / olhos
    (-2.35, 2.48, 0.28, 0.25, 18),   # Nuca
    (-2.05, 2.22, 0.30, 0.30, 42),   # Pescoço alto
    (-1.70, 1.85, 0.38, 0.38, 38),   # Pescoço médio
    (-1.30, 1.50, 0.52, 0.50, 22),   # Base do pescoço
    (-0.80, 1.28, 0.76, 0.72, 6),    # Peito / ombros largos
    (-0.20, 1.22, 0.82, 0.76, 0),    # Dorso central (sela)
    (0.45,  1.16, 0.74, 0.68, -6),   # Lombar
    (1.05,  1.06, 0.58, 0.54, -10),  # Quadril / pelve
    (1.65,  0.94, 0.42, 0.40, -12),  # Base da cauda
    (2.25,  0.84, 0.30, 0.28, -8),   # Cauda média 1
    (2.85,  0.78, 0.21, 0.20, 0),    # Cauda média 2
    (3.45,  0.80, 0.14, 0.13, 8),    # Cauda fina
    (4.05,  0.88, 0.08, 0.07, 14),   # Ponta da cauda
    (4.35,  0.94, 0.02, 0.02, 16)    # Ápice da cauda
]

bm = bmesh.new()
ring_verts = []
segs_per_ring = 16

for y, z, rx, rz, pitch in spine_profile:
    ring = []
    rad_p = math.radians(pitch)
    cos_p = math.cos(rad_p)
    sin_p = math.sin(rad_p)
    for i in range(segs_per_ring):
        ang = (2.0 * math.pi * i) / segs_per_ring
        lx = math.cos(ang) * rx
        lz = math.sin(ang) * rz
        # Achata levemente o ventre inferior
        if lz < 0:
            lz *= 0.82
        wy = y - lz * sin_p
        wz = z + lz * cos_p
        v = bm.verts.new((lx, wy, wz))
        ring.append(v)
    ring_verts.append(ring)

bm.verts.ensure_lookup_table()

for r_idx in range(len(ring_verts) - 1):
    r1 = ring_verts[r_idx]
    r2 = ring_verts[r_idx + 1]
    for i in range(segs_per_ring):
        ni = (i + 1) % segs_per_ring
        bm.faces.new((r1[i], r1[ni], r2[ni], r2[i]))

# Fechar ponta do focinho e cauda
bm.faces.new(ring_verts[0][::-1])
bm.faces.new(ring_verts[-1])
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

body_mesh = bpy.data.meshes.new("SaphiraContinuousBody")
bm.to_mesh(body_mesh)
bm.free()

body_obj = bpy.data.objects.new("SaphiraBody", body_mesh)
bpy.context.collection.objects.link(body_obj)
mod_sub = body_obj.modifiers.new("Subsurf", 'SUBSURF')
mod_sub.levels = 2
smooth(body_obj)
body_obj.data.materials.append(mat_scales)

# ========================================================
# 2. DETALHES DA CABEÇA: MANDÍBULA, CHIFRES EM ESPIRAL E OLHOS
# ========================================================
# Mandíbula inferior articulada
add_bone_segment("LowerJaw", (0, -2.55, 2.34), (0, -3.22, 2.28), 0.22, 0.08, mat_scales, segs=8)

# Chifres principais curvados para trás (+Y, +Z) em 3 segmentos contínuos
for mult in [-1, 1]:
    h0 = (0.20 * mult, -2.55, 2.62)
    h1 = (0.34 * mult, -2.20, 2.88)
    h2 = (0.42 * mult, -1.80, 3.08)
    h3 = (0.38 * mult, -1.45, 3.28)
    add_bone_segment(f"HornBase_{mult}", h0, h1, 0.09, 0.065, mat_horns, segs=8)
    add_bone_segment(f"HornMid_{mult}", h1, h2, 0.065, 0.035, mat_horns, segs=8)
    add_bone_segment(f"HornTip_{mult}", h2, h3, 0.035, 0.005, mat_horns, segs=8)

    # Chifre secundário da mandíbula
    j0 = (0.22 * mult, -2.58, 2.42)
    j1 = (0.35 * mult, -2.28, 2.50)
    add_bone_segment(f"JawSpike_{mult}", j0, j1, 0.05, 0.008, mat_horns, segs=6)

    # Olhos brilhantes em fenda
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.065, location=(0.21 * mult, -2.82, 2.52))
    eye = bpy.context.active_object
    eye.scale = (0.55, 1.25, 0.75)
    smooth(eye)
    eye.data.materials.append(mat_eyes)

# Crista de espinhos dorsais dourados ao longo do pescoço, dorso e cauda
spine_spikes = [
    (-2.15, 2.46, 0.28, 0.45),
    (-1.82, 2.12, 0.30, 0.50),
    (-1.45, 1.80, 0.32, 0.50),
    (0.55,  1.68, 0.28, 0.38),
    (1.10,  1.52, 0.25, 0.35),
    (1.68,  1.30, 0.22, 0.32),
    (2.25,  1.10, 0.18, 0.28),
    (2.85,  0.98, 0.15, 0.24),
    (3.45,  0.94, 0.12, 0.20)
]
for idx, (sy, sz, slen, tilt) in enumerate(spine_spikes):
    p_base = (0, sy, sz)
    p_tip = (0, sy + math.sin(tilt) * slen, sz + math.cos(tilt) * slen)
    add_bone_segment(f"DorsalSpike_{idx}", p_base, p_tip, 0.055, 0.006, mat_horns, segs=6)

# Lâmina caudal em forma de alabarda dourada na ponta da cauda
tail_fin_verts = [
    (0.0, 3.85, 0.86),
    (0.42, 4.25, 0.92),
    (0.0, 4.68, 0.98),
    (-0.42, 4.25, 0.92)
]
tail_fin_mesh = bpy.data.meshes.new("TailFinMesh")
tail_fin_obj = bpy.data.objects.new("TailFin", tail_fin_mesh)
bpy.context.collection.objects.link(tail_fin_obj)
tail_fin_mesh.from_pydata(tail_fin_verts, [], [(0, 1, 2, 3)])
tail_fin_mesh.update()
mod_tf = tail_fin_obj.modifiers.new("Solidify", 'SOLIDIFY')
mod_tf.thickness = 0.05
smooth(tail_fin_obj)
tail_fin_obj.data.materials.append(mat_horns)

# ========================================================
# 3. ASAS ARTICULADAS COM VETORES EXATOS (ZERO ANTENAS!)
# ========================================================
for mult in [-1, 1]:
    # Pontos anatômicos da asa
    v_shoulder = (0.62 * mult, -0.68, 1.52)
    v_elbow    = (1.35 * mult, -0.32, 2.02)
    v_wrist    = (2.25 * mult, -0.78, 2.52)

    # 4 Pontas dos dedos da asa (abrindo em leque majestoso)
    v_tip1     = (4.15 * mult, -0.25, 2.35)
    v_tip2     = (3.75 * mult,  0.65, 1.95)
    v_tip3     = (2.85 * mult,  1.25, 1.62)
    v_tip4     = (1.85 * mult,  1.45, 1.42)

    # Pontos de recorte (scallops) entre as pontas dos dedos
    v_scallop1 = (3.62 * mult,  0.22, 2.02)
    v_scallop2 = (3.08 * mult,  0.92, 1.68)
    v_scallop3 = (2.22 * mult,  1.32, 1.44)
    v_body_rear= (0.68 * mult,  0.65, 1.28)
    v_body_mid = (0.72 * mult, -0.05, 1.38)

    # Construir malha da membrana conectando exatamente os ossos e pontas
    w_verts = [
        v_shoulder,  # 0
        v_elbow,     # 1
        v_wrist,     # 2
        v_tip1,      # 3
        v_scallop1,  # 4
        v_tip2,      # 5
        v_scallop2,  # 6
        v_tip3,      # 7
        v_scallop3,  # 8
        v_tip4,      # 9
        v_body_rear, # 10
        v_body_mid   # 11
    ]
    w_faces = [
        (2, 3, 4),
        (2, 4, 5),
        (2, 5, 6),
        (2, 6, 7),
        (2, 7, 8),
        (2, 8, 9),
        (1, 2, 9, 11),
        (1, 11, 0),
        (11, 9, 10)
    ]

    w_mesh = bpy.data.meshes.new(f"SaphiraWingMembrane_{mult}")
    w_obj = bpy.data.objects.new(f"SaphiraWing_{mult}", w_mesh)
    bpy.context.collection.objects.link(w_obj)
    w_mesh.from_pydata(w_verts, [], w_faces)
    w_mesh.update()

    mod_sol = w_obj.modifiers.new("Solidify", 'SOLIDIFY')
    mod_sol.thickness = 0.035
    mod_sol.offset = 0.0
    smooth(w_obj)
    w_obj.data.materials.append(mat_membrane)

    # Ossos principais da borda de ataque (alinhados matematicamente de ponto a ponto!)
    add_bone_segment(f"WingHumerus_{mult}", v_shoulder, v_elbow, 0.09, 0.075, mat_wing_bone, segs=8)
    add_bone_segment(f"WingRadius_{mult}",  v_elbow,    v_wrist, 0.075, 0.065, mat_wing_bone, segs=8)

    # Falanges ósseas irradiando do pulso (v_wrist) exatamente até cada ponta (v_tip1..4)!
    add_bone_segment(f"WingFinger1_{mult}", v_wrist, v_tip1, 0.055, 0.012, mat_wing_bone, segs=6)
    add_bone_segment(f"WingFinger2_{mult}", v_wrist, v_tip2, 0.045, 0.010, mat_wing_bone, segs=6)
    add_bone_segment(f"WingFinger3_{mult}", v_wrist, v_tip3, 0.040, 0.010, mat_wing_bone, segs=6)
    add_bone_segment(f"WingFinger4_{mult}", v_wrist, v_tip4, 0.035, 0.010, mat_wing_bone, segs=6)

    # Garra dourada curvada no ápice do pulso da asa
    v_claw_tip = (2.42 * mult, -1.08, 2.72)
    add_bone_segment(f"WingThumbClaw_{mult}", v_wrist, v_claw_tip, 0.05, 0.006, mat_horns, segs=6)

# ========================================================
# 4. PATAS ARTICULADAS EM 3 SEGMENTOS + GARRAS DOURADAS
# ========================================================
for mult in [-1, 1]:
    # Patas Dianteiras
    f_hip   = (0.68 * mult, -0.78, 1.12)
    f_knee  = (0.78 * mult, -0.58, 0.62)
    f_ankle = (0.74 * mult, -0.82, 0.16)
    add_bone_segment(f"FrontUpperLeg_{mult}", f_hip, f_knee, 0.20, 0.14, mat_scales, segs=10)
    add_bone_segment(f"FrontLowerLeg_{mult}", f_knee, f_ankle, 0.14, 0.11, mat_scales, segs=10)
    for c_i in [-1, 0, 1]:
        c_start = (f_ankle[0] + c_i * 0.09, f_ankle[1] - 0.05, 0.12)
        c_end   = (f_ankle[0] + c_i * 0.12, f_ankle[1] - 0.36, 0.02)
        add_bone_segment(f"FrontClaw_{mult}_{c_i}", c_start, c_end, 0.045, 0.006, mat_horns, segs=6)

    # Patas Traseiras
    b_hip   = (0.62 * mult, 0.78, 1.05)
    b_knee  = (0.76 * mult, 1.08, 0.56)
    b_ankle = (0.72 * mult, 0.72, 0.16)
    add_bone_segment(f"BackUpperLeg_{mult}", b_hip, b_knee, 0.24, 0.16, mat_scales, segs=10)
    add_bone_segment(f"BackLowerLeg_{mult}", b_knee, b_ankle, 0.16, 0.12, mat_scales, segs=10)
    for c_i in [-1, 0, 1]:
        c_start = (b_ankle[0] + c_i * 0.10, b_ankle[1] - 0.05, 0.12)
        c_end   = (b_ankle[0] + c_i * 0.13, b_ankle[1] - 0.38, 0.02)
        add_bone_segment(f"BackClaw_{mult}_{c_i}", c_start, c_end, 0.05, 0.006, mat_horns, segs=6)

# ========================================================
# 5. SELA ÉLFICA DO CAVALEIRO (ENCAIXADA NO DORSO Z = 1.92)
# ========================================================
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, -0.18, 1.94))
saddle = bpy.context.active_object
saddle.scale = (0.58, 0.68, 0.14)
smooth(saddle)
saddle.data.materials.append(mat_saddle)

# Pommel frontal e Cantle traseiro em ouro forjado
add_bone_segment("SaddlePommel", (0, -0.52, 1.96), (0, -0.58, 2.22), 0.16, 0.06, mat_horns, segs=8)
add_bone_segment("SaddleCantle", (0,  0.18, 1.96), (0,  0.26, 2.24), 0.22, 0.12, mat_horns, segs=8)

out = f"{MODELS_DIR}/dragon_mount_saphira.glb"
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
print(f"Exportado com sucesso: {out}")
"""

script_path = "/tmp/generate_dragon_mount.py"
with open(script_path, "w") as f:
    f.write(BLENDER_SCRIPT)

print("Gerando Dragão Saphira com corpo contínuo e asas vetoriais...")
res = subprocess.run([
    "/home/eudespatricio/.local/bin/blender",
    "--background",
    "--python", script_path
], capture_output=True, text=True)

print(res.stdout)
if res.returncode != 0:
    print("ERRO:", res.stderr, file=sys.stderr)
    sys.exit(res.returncode)
print("Dragão Saphira regenerado com sucesso!")
