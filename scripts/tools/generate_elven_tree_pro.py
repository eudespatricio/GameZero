#!/usr/bin/env python3
"""
Gerador Avançado da Árvore Ancestral Élfica (Elven Ancient Tree PRO)
GameZero - Padrão Dark Fantasy Diablo IV
Gera Trunk unificado e Canopy unificada para alta performance (MultiMesh draw calls otimizados).
"""

import os
import subprocess
import sys

BLENDER_BIN = "/home/eudespatricio/.gemini/antigravity/bin/blender"
OUTPUT_GLB = "/home/eudespatricio/Games/GameZero/assets/models/elven_tree_detailed.glb"

BLENDER_SCRIPT = f"""
import bpy
import bmesh
import math
from mathutils import Vector, Matrix

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_material(name, base_color, roughness=0.8, metallic=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = base_color
        bsdf.inputs["Roughness"].default_value = roughness
        bsdf.inputs["Metallic"].default_value = metallic
    return mat

def generate_pro_elven_tree():
    reset_scene()
    
    mat_bark = create_material("AncientBarkPBR", (0.13, 0.08, 0.05, 1.0), roughness=0.88)
    mat_leaves = create_material("ElvenLeaves", (0.12, 0.38, 0.20, 1.0), roughness=0.76)
    
    # -----------------------------------------------------------------
    # 1. TRONCO, RAÍZES E GALHOS (UNIFICADOS EM 'Trunk')
    # -----------------------------------------------------------------
    trunk_parts = []
    
    # Tronco Central - Cilindro com fluting orgânico
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=1.65, depth=9.8, location=(0, 0, 4.9))
    trunk = bpy.context.active_object
    trunk.name = "TrunkBase"
    # Afilamento ao longo da altura
    bpy.ops.object.mode_set(mode='EDIT')
    bm = bmesh.from_edit_mesh(trunk.data)
    for v in bm.verts:
        # z de 0 a 9.8
        t = v.co.z / 9.8
        factor = 1.0 - t * 0.52
        v.co.x *= factor
        v.co.y *= factor
        # Leve torção élfica
        ang = t * 0.45
        nx = v.co.x * math.cos(ang) - v.co.y * math.sin(ang)
        ny = v.co.x * math.sin(ang) + v.co.y * math.cos(ang)
        v.co.x = nx
        v.co.y = ny
    bmesh.update_edit_mesh(trunk.data)
    bpy.ops.object.mode_set(mode='OBJECT')
    trunk_parts.append(trunk)
    
    # 6 Raízes Contrafortes Monumentais (Buttress Roots)
    for i in range(6):
        ang = i * (2.0 * math.pi / 6.0) + 0.15
        rx = math.cos(ang) * 1.85
        ry = math.sin(ang) * 1.85
        bpy.ops.mesh.primitive_cone_add(vertices=10, radius1=0.72, radius2=0.22, depth=3.8, location=(rx, ry, 1.2))
        root = bpy.context.active_object
        root.rotation_euler = (math.sin(ang) * 0.72, -math.cos(ang) * 0.72, ang)
        trunk_parts.append(root)
        
    # 6 Grandes Galhos Arquitetônicos Sustentando a Copa (Z = 7.6 a 10.8)
    for i in range(6):
        ang = i * (2.0 * math.pi / 6.0) + 0.52
        bx = math.cos(ang) * 1.45
        by = math.sin(ang) * 1.45
        bpy.ops.mesh.primitive_cone_add(vertices=10, radius1=0.55, radius2=0.20, depth=4.6, location=(bx, by, 8.8))
        branch = bpy.context.active_object
        # Inclinação de 40 graus para fora
        branch.rotation_euler = (-math.sin(ang) * 0.68, math.cos(ang) * 0.68, ang)
        trunk_parts.append(branch)
        
    # Selecionar e unificar todos os componentes do Tronco
    bpy.ops.object.select_all(action='DESELECT')
    for p in trunk_parts:
        p.select_set(True)
    bpy.context.view_layer.objects.active = trunk
    bpy.ops.object.join()
    trunk.name = "Trunk"
    
    # Deformação orgânica e facetas de casca
    mod_disp = trunk.modifiers.new("BarkDisp", type='DISPLACE')
    tex_noise = bpy.data.textures.new("BarkTex", type='VORONOI')
    tex_noise.noise_scale = 0.65
    mod_disp.texture = tex_noise
    mod_disp.strength = 0.18
    bpy.ops.object.modifier_apply(modifier="BarkDisp")
    
    # Decimate suave para otimizar geometria
    mod_dec = trunk.modifiers.new("Decimate", type='DECIMATE')
    mod_dec.ratio = 0.65
    bpy.ops.object.modifier_apply(modifier="Decimate")
    
    # UV Smart Project
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66.0), island_margin=0.015)
    bpy.ops.object.mode_set(mode='OBJECT')
    
    # Aplicar Material
    trunk.data.materials.clear()
    trunk.data.materials.append(mat_bark)
    for p in trunk.data.polygons:
        p.use_smooth = True
        
    # -----------------------------------------------------------------
    # 2. COPA E FOLHAGEM ÉLFICA ESCULTURAL (UNIFICADAS EM 'Canopy')
    # -----------------------------------------------------------------
    canopy_parts = []
    
    # Cúpulas de folhagem orgânicas em múltiplos níveis
    canopy_specs = [
        # (x, y, z, rad_xy, rad_z)
        (0.0, 0.0, 12.0, 4.4, 2.8),       # Coroa central maciça
        (2.4, 1.2, 10.8, 3.4, 2.3),       # Bough Leste-Norte
        (-2.3, -1.0, 11.0, 3.5, 2.4),     # Bough Oeste-Sul
        (-1.2, 2.3, 11.2, 3.3, 2.2),      # Bough Norte
        (1.1, -2.4, 10.9, 3.4, 2.3),      # Bough Sul
        (2.0, -1.8, 10.4, 3.1, 2.1),      # Bough Sudeste
        (-1.9, 1.8, 10.6, 3.2, 2.2),      # Bough Noroeste
        (0.0, 0.0, 14.4, 3.1, 2.0),       # Domo superior / Pinnacle
        (0.0, 0.0, 9.6, 3.8, 1.8)         # Saia inferior de transição
    ]
    
    for idx, (cx, cy, cz, rad_xy, rad_z) in enumerate(canopy_specs):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=rad_xy, location=(cx, cy, cz))
        foliage = bpy.context.active_object
        foliage.name = f"FoliageCluster_{{idx}}"
        foliage.scale = (1.0, 1.0, rad_z / rad_xy)
        
        # Displace Voronoi para silhueta recortada de folhas
        mod_d = foliage.modifiers.new("LeafDisp", type='DISPLACE')
        t_leaf = bpy.data.textures.new(f"LeafNoise_{{idx}}", type='DISTORTED_NOISE')
        t_leaf.noise_scale = 0.55
        mod_d.texture = t_leaf
        mod_d.strength = 0.26
        bpy.ops.object.modifier_apply(modifier="LeafDisp")
        
        canopy_parts.append(foliage)
        
    # Unificar todas as copas em 'Canopy'
    bpy.ops.object.select_all(action='DESELECT')
    for cp in canopy_parts:
        cp.select_set(True)
    bpy.context.view_layer.objects.active = canopy_parts[0]
    bpy.ops.object.join()
    canopy = canopy_parts[0]
    canopy.name = "Canopy"
    
    # Decimate nas copas para manter performance
    mod_cdec = canopy.modifiers.new("CanopyDecimate", type='DECIMATE')
    mod_cdec.ratio = 0.48
    bpy.ops.object.modifier_apply(modifier="CanopyDecimate")
    
    # UV Smart Project
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66.0), island_margin=0.015)
    bpy.ops.object.mode_set(mode='OBJECT')
    
    # Shading Suave / Soft Normals para Iluminação de Copa
    canopy.data.materials.clear()
    canopy.data.materials.append(mat_leaves)
    for p in canopy.data.polygons:
        p.use_smooth = True
        
    # -----------------------------------------------------------------
    # EXPORTAÇÃO GLTF 2.0 (GLB)
    # -----------------------------------------------------------------
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(
        filepath='{OUTPUT_GLB}',
        export_format='GLB',
        use_selection=True,
        export_apply=True
    )
    print(f"=== GLB ÉLFICA EXPORTADA COM SUCESSO: {{OUTPUT_GLB}} ===")

generate_pro_elven_tree()
"""

def main():
    script_path = "/tmp/generate_elven_tree_tmp.py"
    with open(script_path, "w") as f:
        f.write(BLENDER_SCRIPT)
        
    cmd = [BLENDER_BIN, "-b", "--python", script_path]
    print(f"Executando Blender 4.2 headless...")
    result = subprocess.run(cmd, capture_output=True, text=True)
    print(result.stdout)
    if result.returncode != 0:
        print(f"Erro ao executar Blender:\n{result.stderr}", file=sys.stderr)
        sys.exit(result.returncode)
    print("Sucesso!")

if __name__ == "__main__":
    main()
