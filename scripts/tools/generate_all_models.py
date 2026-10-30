#!/usr/bin/env python3
"""
Gerador de Modelos 3D de Alta Qualidade para GameZero (Padrão Dark Fantasy Diablo IV)
Utiliza Blender 4.2 LTS headless via Python.
Convenção estrita Blender -> Godot glTF:
  Blender +X = Godot +X (Largura Leste-Oeste)
  Blender +Y = Godot -Z (Norte / Profundidade)
  Blender +Z = Godot +Y (Altura Vertical UP)
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

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_material(name, base_color, roughness=0.7, metallic=0.0, emission_color=None, emission_strength=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = base_color
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Metallic"].default_value = metallic
        if emission_color and "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = emission_color
            bsdf.inputs["Emission Strength"].default_value = emission_strength
    return mat

def make_faceted(obj, disp_strength=0.35, decimate_ratio=0.45):
    bpy.context.view_layer.objects.active = obj
    if disp_strength > 0:
        mod_disp = obj.modifiers.new("Disp", type="DISPLACE")
        tex_noise = bpy.data.textures.new(f"Noise_{obj.name}", type="VORONOI")
        tex_noise.noise_scale = 0.85
        mod_disp.texture = tex_noise
        mod_disp.strength = disp_strength
        bpy.ops.object.modifier_apply(modifier="Disp")
    if decimate_ratio < 1.0:
        mod_dec = obj.modifiers.new("Decimate", type="DECIMATE")
        mod_dec.ratio = decimate_ratio
        bpy.ops.object.modifier_apply(modifier="Decimate")
    for p in obj.data.polygons:
        p.use_smooth = False
    mod_split = obj.modifiers.new("EdgeSplit", type="EDGE_SPLIT")
    mod_split.use_edge_angle = True
    mod_split.split_angle = math.radians(15.0)
    bpy.ops.object.modifier_apply(modifier="EdgeSplit")

def make_sharp(obj, angle_deg=35.0):
    bpy.context.view_layer.objects.active = obj
    for p in obj.data.polygons:
        p.use_smooth = False
    mod_split = obj.modifiers.new("EdgeSplit", type="EDGE_SPLIT")
    mod_split.use_edge_angle = True
    mod_split.split_angle = math.radians(angle_deg)
    bpy.ops.object.modifier_apply(modifier="EdgeSplit")

# ==========================================
# 1. FORMAÇÃO ROCHOSA DE BASALTO ESCURO (SCOSGLEN CRAGS)
# ==========================================
def generate_rock_formation():
    reset_scene()
    mat_stone = create_material("DarkSlateCragPBR", (0.10, 0.11, 0.13, 1.0), roughness=0.92, metallic=0.05)
    mat_stone_dark = create_material("DeepBasaltPBR", (0.07, 0.08, 0.09, 1.0), roughness=0.95, metallic=0.05)
    mat_moss = create_material("ForestMossPBR", (0.06, 0.15, 0.07, 1.0), roughness=0.94)

    # Penhasco principal chanfrado
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=1.55, location=(0, 0, 1.05))
    main_rock = bpy.context.active_object
    main_rock.name = "MainCrag"
    main_rock.scale = (1.35, 1.05, 0.92)
    make_faceted(main_rock, disp_strength=0.45, decimate_ratio=0.32)
    main_rock.data.materials.append(mat_stone)

    # Penhasco lateral esquerdo angular
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=1.0, location=(-1.35, 0.35, 0.62))
    rock_l = bpy.context.active_object
    rock_l.name = "LeftCrag"
    rock_l.scale = (1.15, 0.85, 0.72)
    rock_l.rotation_euler = (0.2, -0.3, 0.5)
    make_faceted(rock_l, disp_strength=0.38, decimate_ratio=0.35)
    rock_l.data.materials.append(mat_stone_dark)

    # Penhasco lateral direito
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.85, location=(1.25, -0.35, 0.52))
    rock_r = bpy.context.active_object
    rock_r.name = "RightCrag"
    rock_r.scale = (0.95, 1.2, 0.68)
    rock_r.rotation_euler = (-0.25, 0.2, -0.4)
    make_faceted(rock_r, disp_strength=0.35, decimate_ratio=0.35)
    rock_r.data.materials.append(mat_stone)

    # Laje de ardósia frontal baixa
    bpy.ops.mesh.primitive_cube_add(size=1.2, location=(0.2, -1.1, 0.25))
    slab = bpy.context.active_object
    slab.scale = (1.4, 0.8, 0.35)
    slab.rotation_euler = (0.15, 0.08, 0.3)
    make_sharp(slab, 25.0)
    slab.data.materials.append(mat_stone_dark)

    # Camada orgânica de musgo escuro no topo
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.95, location=(-0.1, 0.05, 1.58))
    moss_cap = bpy.context.active_object
    moss_cap.scale = (1.15, 0.85, 0.28)
    make_faceted(moss_cap, disp_strength=0.18, decimate_ratio=0.55)
    moss_cap.data.materials.append(mat_moss)

    export_path = "/home/eudespatricio/Games/GameZero/assets/models/rock_formation_detailed.glb"
    bpy.ops.export_scene.gltf(filepath=export_path, export_format="GLB")
    print(f"Exportado: {export_path}")

# ==========================================
# 2. PONTE ÉLFICA DE PEDRA E CARVALHO ESCURO (Z = UP, Y = COMPRIMENTO, X = LARGURA)
# ==========================================
def generate_wooden_bridge():
    reset_scene()
    mat_wood = create_material("AgedOakPBR", (0.18, 0.11, 0.07, 1.0), roughness=0.86)
    mat_wood_plank = create_material("WeatheredPlankPBR", (0.22, 0.14, 0.09, 1.0), roughness=0.82)
    mat_stone = create_material("BridgeStonePillarPBR", (0.14, 0.15, 0.17, 1.0), roughness=0.88)
    mat_metal = create_material("DarkIronBandsPBR", (0.12, 0.13, 0.15, 1.0), roughness=0.42, metallic=0.85)
    mat_lantern = create_material("ElvenBridgeLantern", (0.2, 0.88, 0.95, 1.0), roughness=0.15,
                                  emission_color=(0.2, 0.88, 0.95, 1.0), emission_strength=3.0)

    bridge_len = 8.6  # Ao longo de Y (atravessa o rio de 8m no eixo Z do Godot)
    bridge_w = 4.0    # Ao longo de X (alinha com a estrada de 4m no eixo X do Godot)

    # Vigas principais arqueadas ao longo de Y, nas laterais X = -1.85 e +1.85
    num_segs = 16
    step_y = bridge_len / num_segs
    for side_x in [-1.85, 1.85]:
        for i in range(num_segs):
            y = -bridge_len * 0.5 + (i + 0.5) * step_y
            norm_y = y / (bridge_len * 0.5)
            arch_z = 0.42 * (1.0 - norm_y * norm_y) + 0.15
            slope_angle = math.atan2(-0.84 * norm_y / (bridge_len * 0.5), 1.0)
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(side_x, y, arch_z))
            beam = bpy.context.active_object
            beam.scale = (0.26, step_y * 1.08, 0.28)
            beam.rotation_euler = (slope_angle, 0, 0)
            make_sharp(beam)
            beam.data.materials.append(mat_wood)

    # Pranchas de carvalho transversais (largura X = 4.0m, espessura Z = 0.12m)
    num_planks = 22
    plank_step = bridge_len / num_planks
    for i in range(num_planks):
        y = -bridge_len * 0.5 + (i + 0.5) * plank_step
        norm_y = y / (bridge_len * 0.5)
        arch_z = 0.42 * (1.0 - norm_y * norm_y) + 0.30
        slope_angle = math.atan2(-0.84 * norm_y / (bridge_len * 0.5), 1.0)
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, y, arch_z))
        plank = bpy.context.active_object
        plank.scale = (bridge_w, plank_step * 0.86, 0.11)
        plank.rotation_euler = (slope_angle, 0, 0)
        make_sharp(plank)
        plank.data.materials.append(mat_wood_plank)

        # Cravos de ferro nas extremidades de cada prancha
        for sx in [-1.75, 1.75]:
            bpy.ops.mesh.primitive_cube_add(size=1.0, location=(sx, y, arch_z + 0.06))
            stud = bpy.context.active_object
            stud.scale = (0.12, 0.08, 0.03)
            stud.rotation_euler = (slope_angle, 0, 0)
            stud.data.materials.append(mat_metal)

    # 4 Pilares de pedra maciça nas cabeceiras e 4 postes intermediários de madeira
    post_y_coords = [-4.0, -2.0, 0.0, 2.0, 4.0]
    for py in post_y_coords:
        norm_y = py / (bridge_len * 0.5)
        arch_z = 0.42 * (1.0 - norm_y * norm_y) + 0.30
        is_end = abs(py) > 3.5
        for px in [-1.95, 1.95]:
            if is_end:
                # Pilar de pedra talhada nas pontas da ponte
                bpy.ops.mesh.primitive_cube_add(size=1.0, location=(px, py, arch_z + 0.55))
                pillar = bpy.context.active_object
                pillar.scale = (0.42, 0.42, 1.25)
                make_sharp(pillar)
                pillar.data.materials.append(mat_stone)

                # Lanterna rúnica no topo das cabeceiras
                bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.14, location=(px, py, arch_z + 1.28))
                lant = bpy.context.active_object
                lant.data.materials.append(mat_lantern)
            else:
                # Poste vertical de madeira com anel de ferro (eixo Z = vertical!)
                bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.11, depth=1.05, location=(px, py, arch_z + 0.52))
                post = bpy.context.active_object
                make_sharp(post)
                post.data.materials.append(mat_wood)

                bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.125, depth=0.12, location=(px, py, arch_z + 0.95))
                cap = bpy.context.active_object
                make_sharp(cap)
                cap.data.materials.append(mat_metal)

    # Corrimãos superiores e intermediários acompanhando o arco ao longo de Y
    for px in [-1.95, 1.95]:
        for rail_h in [0.52, 0.92]:
            for i in range(num_segs):
                y = -bridge_len * 0.5 + (i + 0.5) * step_y
                norm_y = y / (bridge_len * 0.5)
                arch_z = 0.42 * (1.0 - norm_y * norm_y) + 0.30 + rail_h
                slope_angle = math.atan2(-0.84 * norm_y / (bridge_len * 0.5), 1.0)
                bpy.ops.mesh.primitive_cube_add(size=1.0, location=(px, y, arch_z))
                rail = bpy.context.active_object
                rail.scale = (0.10, step_y * 1.05, 0.09)
                rail.rotation_euler = (slope_angle, 0, 0)
                make_sharp(rail)
                rail.data.materials.append(mat_wood)

    export_path = "/home/eudespatricio/Games/GameZero/assets/models/wooden_bridge_detailed.glb"
    bpy.ops.export_scene.gltf(filepath=export_path, export_format="GLB")
    print(f"Exportado: {export_path}")

# ==========================================
# 3. MONÓLITO ÉLFICO ESCULPIDO COM RUNAS (Z = UP)
# ==========================================
def generate_elven_monolith():
    reset_scene()
    mat_stone = create_material("ElvenMonolithDarkSlate", (0.09, 0.11, 0.14, 1.0), roughness=0.72, metallic=0.15)
    mat_trim = create_material("MonolithAncientBronze", (0.45, 0.36, 0.18, 1.0), roughness=0.35, metallic=0.85)
    mat_crystal = create_material("RuneCrystal", (0.15, 0.85, 0.95, 1.0), roughness=0.15,
                                  emission_color=(0.15, 0.85, 0.95, 1.0), emission_strength=2.6)

    # Base octogonal escalonada em 2 degraus (Z = altura)
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=1.15, depth=0.24, location=(0, 0, 0.12))
    step1 = bpy.context.active_object
    make_sharp(step1)
    step1.data.materials.append(mat_stone)

    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.92, depth=0.22, location=(0, 0, 0.35))
    step2 = bpy.context.active_object
    make_sharp(step2)
    step2.data.materials.append(mat_stone)

    # Obelisco hexagonal afilado (cone truncado em Z)
    bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.68, radius2=0.46, depth=3.8, location=(0, 0, 2.35))
    obelisk = bpy.context.active_object
    make_sharp(obelisk)
    obelisk.data.materials.append(mat_stone)

    # Topo piramidal chanfrado
    bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.46, radius2=0.0, depth=0.95, location=(0, 0, 4.72))
    cone_tip = bpy.context.active_object
    make_sharp(cone_tip)
    cone_tip.data.materials.append(mat_stone)

    # Anéis de contenção em bronze antigo e cristal rúnico em Z = 2.5m
    for z_off in [2.32, 2.68]:
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.62, depth=0.08, location=(0, 0, z_off))
        band = bpy.context.active_object
        make_sharp(band)
        band.data.materials.append(mat_trim)

    bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.59, depth=0.28, location=(0, 0, 2.50))
    rune_band = bpy.context.active_object
    make_sharp(rune_band)
    rune_band.data.materials.append(mat_crystal)

    export_path = "/home/eudespatricio/Games/GameZero/assets/models/elven_monolith_detailed.glb"
    bpy.ops.export_scene.gltf(filepath=export_path, export_format="GLB")
    print(f"Exportado: {export_path}")

# ==========================================
# 4. ÁRVORE ANCESTRAL DE DU WELDENVARDEN (Z = UP)
# ==========================================
def generate_elven_tree():
    reset_scene()
    mat_bark = create_material("AncientBarkPBR", (0.11, 0.08, 0.06, 1.0), roughness=0.94)
    mat_leaves1 = create_material("ElvenLeavesDeep", (0.04, 0.16, 0.09, 1.0), roughness=0.78)
    mat_leaves2 = create_material("ElvenLeavesMid", (0.07, 0.24, 0.13, 1.0), roughness=0.72)

    # Tronco cônico orgânico (afila da base 1.45m para o topo 0.85m ao longo de Z)
    bpy.ops.mesh.primitive_cone_add(vertices=14, radius1=1.45, radius2=0.82, depth=9.2, location=(0, 0, 4.6))
    trunk = bpy.context.active_object
    make_faceted(trunk, disp_strength=0.22, decimate_ratio=0.65)
    trunk.data.materials.append(mat_bark)

    # 5 Raízes retorcidas saindo da base em direção ao solo
    for i in range(5):
        ang = i * (2.0 * math.pi / 5.0) + 0.2
        rx = math.cos(ang) * 1.35
        ry = math.sin(ang) * 1.35
        bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.55, radius2=0.18, depth=2.6, location=(rx, ry, 0.65))
        root = bpy.context.active_object
        root.rotation_euler = (math.sin(ang) * 0.65, -math.cos(ang) * 0.65, ang)
        make_faceted(root, disp_strength=0.12, decimate_ratio=0.7)
        root.data.materials.append(mat_bark)

    # Galhos superiores sustentando a copa (Z = 7.8 a 9.2)
    for i in range(4):
        ang = i * (math.pi * 0.5) + 0.4
        bx = math.cos(ang) * 1.15
        by = math.sin(ang) * 1.15
        bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.48, radius2=0.22, depth=3.6, location=(bx, by, 8.4))
        br = bpy.context.active_object
        br.rotation_euler = (-math.sin(ang) * 0.55, math.cos(ang) * 0.55, 0)
        make_sharp(br)
        br.data.materials.append(mat_bark)

    # Copas densas e esculturais em camadas (Z = 9.8 a 13.8)
    canopies = [
        (0.0, 0.0, 11.2, 4.0, 2.4, mat_leaves1),
        (2.1, 0.9, 10.0, 3.0, 1.9, mat_leaves2),
        (-2.0, -0.8, 10.2, 3.1, 1.9, mat_leaves2),
        (-0.8, 2.0, 10.4, 2.9, 1.8, mat_leaves1),
        (0.9, -1.9, 10.1, 2.8, 1.8, mat_leaves1),
        (0.0, 0.0, 13.0, 2.7, 1.8, mat_leaves2)
    ]
    for cx, cy, cz, rad_xy, rad_z, mat in canopies:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=rad_xy, location=(cx, cy, cz))
        foliage = bpy.context.active_object
        foliage.scale = (1.0, 1.0, rad_z / rad_xy)
        make_faceted(foliage, disp_strength=0.32, decimate_ratio=0.42)
        foliage.data.materials.append(mat)

    export_path = "/home/eudespatricio/Games/GameZero/assets/models/elven_tree_detailed.glb"
    bpy.ops.export_scene.gltf(filepath=export_path, export_format="GLB")
    print(f"Exportado: {export_path}")

# ==========================================
# 5. VEIO DE MINÉRIO BRIGHTSTEEL (Z = UP)
# ==========================================
def generate_brightsteel_ore():
    reset_scene()
    mat_rock = create_material("OreRockBase", (0.11, 0.12, 0.14, 1.0), roughness=0.9)
    mat_brightsteel = create_material("BrightsteelCrystal", (0.25, 0.82, 1.0, 1.0), roughness=0.15, metallic=0.88,
                                      emission_color=(0.2, 0.78, 1.0, 1.0), emission_strength=2.2)

    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.92, location=(0, 0, 0.42))
    ore_base = bpy.context.active_object
    ore_base.scale = (1.25, 1.1, 0.65)
    make_faceted(ore_base, disp_strength=0.28, decimate_ratio=0.38)
    ore_base.data.materials.append(mat_rock)

    spikes = [
        (0.22, 0.18, 0.72, 0.22, 0.88, 0.32, 0.22),
        (-0.26, -0.15, 0.68, 0.19, 0.75, -0.38, -0.28),
        (0.08, -0.24, 0.82, 0.18, 0.95, -0.22, 0.18),
        (-0.18, 0.28, 0.75, 0.20, 0.70, 0.28, -0.32),
        (0.0, 0.0, 0.88, 0.24, 1.05, 0.05, -0.05)
    ]
    for sx, sy, sz, rad, h, rx, ry in spikes:
        bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=rad, radius2=0.02, depth=h, location=(sx, sy, sz))
        spike = bpy.context.active_object
        spike.rotation_euler = (rx, ry, 0)
        make_sharp(spike)
        spike.data.materials.append(mat_brightsteel)

    export_path = "/home/eudespatricio/Games/GameZero/assets/models/brightsteel_ore_detailed.glb"
    bpy.ops.export_scene.gltf(filepath=export_path, export_format="GLB")
    print(f"Exportado: {export_path}")

generate_rock_formation()
generate_wooden_bridge()
generate_elven_monolith()
generate_elven_tree()
generate_brightsteel_ore()
print("TODOS OS MODELOS 3D DE CENÁRIO FORAM GERADOS COM SUCESSO!")
"""

def main():
    print("[Pipeline 3D GameZero] Gerando modelos 3D de cenário com Blender 4.2...")
    cmd = ["/home/eudespatricio/.local/bin/blender", "--background", "--python-expr", BLENDER_SCRIPT]
    res = subprocess.run(cmd, capture_output=True, text=True)
    print(res.stdout)
    if res.returncode != 0:
        print("[Erro no Blender]:", res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
