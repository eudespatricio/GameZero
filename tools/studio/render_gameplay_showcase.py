#!/usr/bin/env python3
"""
Studio Showcase: Renderiza a cena isométrica completa de GameZero em Blender Cycles 4.2 LTS.
Inclui:
- Praça Central Élfica em Ardósia Negra e Bronze Antigo
- Cavaleiro Zero com Elmo Coroado, Ombreiras, Capa Real, Escudo Heráldico, Brisingr e Asas de Arcanjo de 18 Lâminas
- Dragão Saphira com corpo contínuo escultural e asas vetoriais (zero hastes/antenas)
- 3 NPCs de Carvahall (Horst com Bigorna incandescente, Angela e Brom)
- Urgals, Monólitos Rúnicos, Rochas de Basalto Facetadas, Árvores Ancestrais Eretas e Ponte Arqueada
"""

import os
import subprocess
import sys

MODELS_DIR = "/home/eudespatricio/Games/GameZero/assets/models"
OUT_IMG = "/home/eudespatricio/Games/GameZero/assets/ui/gameplay_showcase.png"

BLENDER_SCRIPT = f"""
import bpy
import math
import os

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.samples = 48
scene.cycles.use_denoising = True
scene.render.resolution_x = 1280
scene.render.resolution_y = 720
scene.render.image_settings.file_format = 'PNG'

def import_model(path, loc=(0,0,0), rot=(0,0,0), scale=(1,1,1)):
    if not os.path.exists(path):
        print(f"Aviso: {{path}} não encontrado")
        return None
    existing = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new_objs = [o for o in bpy.data.objects if o not in existing and o.type == 'MESH']
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=loc)
    root = bpy.context.active_object
    root.rotation_euler = (math.radians(rot[0]), math.radians(rot[1]), math.radians(rot[2]))
    root.scale = scale
    for o in new_objs:
        if not o.parent:
            o.parent = root
    return root

# 1. PRAÇA CENTRAL ÉLFICA EM ARDÓSIA NEGRA
import_model("{MODELS_DIR}/elven_central_plaza.glb", loc=(0, 0, 0))

# 2. CAVALEIRO ZERO NO CENTRO DA PRAÇA (COM ALINHAMENTO ANATÔMICO EXATO!)
hero_z = 0.22
hero_rot = (0, 0, -20)
import_model("{MODELS_DIR}/character_zero.glb", loc=(0, 0, hero_z), rot=hero_rot)
import_model("{MODELS_DIR}/elven_helm.glb", loc=(0, 0, hero_z + 1.54), rot=hero_rot, scale=(0.95, 0.95, 0.95))
import_model("{MODELS_DIR}/dragon_pauldrons.glb", loc=(0, 0, hero_z + 1.15), rot=hero_rot)
import_model("{MODELS_DIR}/dragon_cape.glb", loc=(0, 0.05, hero_z + 0.25), rot=hero_rot)
import_model("{MODELS_DIR}/dragon_shield.glb", loc=(-0.38, -0.10, hero_z + 0.92), rot=hero_rot, scale=(0.85, 0.85, 0.85))
import_model("{MODELS_DIR}/crystal_wings_detailed.glb", loc=(0, 0.15, hero_z + 1.25), rot=hero_rot)
import_model("{MODELS_DIR}/dragon_pet.glb", loc=(-0.85, -0.25, hero_z + 1.20), rot=(0, 0, 15), scale=(0.65, 0.65, 0.65))

# 3. DRAGÃO SAPHIRA EM GUARDA (CORPO CONTÍNUO + ASAS VETORIAIS)
import_model("{MODELS_DIR}/dragon_mount_saphira.glb", loc=(-5.2, 2.2, 0.20), rot=(0, 0, -35), scale=(0.88, 0.88, 0.88))

# 4. FLORA ÉLFICA E FORMAÇÕES ROCHOSAS DE BASALTO ESCURO
import_model("{MODELS_DIR}/elven_mushrooms_cluster.glb", loc=(-7.8, -3.5, 0.05))
import_model("{MODELS_DIR}/elven_mushrooms_cluster.glb", loc=(7.8, -3.5, 0.05))
import_model("{MODELS_DIR}/elven_fern_patch.glb", loc=(-8.8, 3.8, 0.02), scale=(0.5, 0.5, 0.5))
import_model("{MODELS_DIR}/elven_fern_patch.glb", loc=(8.8, 3.8, 0.02), scale=(0.5, 0.5, 0.5))
import_model("{MODELS_DIR}/rock_formation_detailed.glb", loc=(-9.8, -1.2, 0.0), rot=(0, 0, 25), scale=(0.9, 0.9, 0.9))
import_model("{MODELS_DIR}/rock_formation_detailed.glb", loc=(9.8, 1.5, 0.0), rot=(0, 0, -40), scale=(0.85, 0.85, 0.85))

# 5. NPCS DE CARVAHALL
import_model("{MODELS_DIR}/npc_blacksmith.glb", loc=(-3.6, -2.0, 0.22), rot=(0, 0, 35))
import_model("{MODELS_DIR}/npc_herbalist.glb", loc=(3.6, -2.0, 0.22), rot=(0, 0, -35))
import_model("{MODELS_DIR}/npc_storyteller.glb", loc=(0, 4.2, 0.22), rot=(0, 0, 0))

# 6. BRASEIROS, ESTANDARTES, BAÚ E MONÓLITOS RÚNICOS
import_model("{MODELS_DIR}/stone_brazier.glb", loc=(-2.8, -4.8, 0.2))
import_model("{MODELS_DIR}/stone_brazier.glb", loc=(2.8, -4.8, 0.2))
import_model("{MODELS_DIR}/dragon_banner.glb", loc=(-5.8, -0.5, 0.2))
import_model("{MODELS_DIR}/dragon_banner.glb", loc=(5.8, -0.5, 0.2), rot=(0, 0, 180))
import_model("{MODELS_DIR}/treasure_chest.glb", loc=(4.6, 3.0, 0.2), rot=(0, 0, -35))

for mx, my in [(-5.8, -5.8), (5.8, -5.8), (-5.8, 5.8), (5.8, 5.8)]:
    import_model("{MODELS_DIR}/elven_monolith_detailed.glb", loc=(mx, my, 0.0))

# 7. ÁRVORES ANCESTRAIS E INIMIGOS URGAL AO FUNDO
import_model("{MODELS_DIR}/elven_tree_detailed.glb", loc=(-11.5, 7.5, 0), scale=(0.95, 0.95, 0.95))
import_model("{MODELS_DIR}/elven_tree_detailed.glb", loc=(11.5, 7.5, 0), scale=(0.95, 0.95, 0.95))
import_model("{MODELS_DIR}/urgal_warrior.glb", loc=(-3.2, 8.2, 0), rot=(0, 0, 15))
import_model("{MODELS_DIR}/urgal_warrior.glb", loc=(3.2, 8.5, 0), rot=(0, 0, -15), scale=(1.15, 1.15, 1.15))

# 8. TERRENO ESCURO DA FLORESTA DE SCOSGLEN / DU WELDENVARDEN
bpy.ops.mesh.primitive_plane_add(size=80, location=(0, 0, 0))
ground = bpy.context.active_object
m_ground = bpy.data.materials.new("GroundDarkForest")
m_ground.use_nodes = True
b_g = m_ground.node_tree.nodes.get("Principled BSDF")
if b_g:
    b_g.inputs["Base Color"].default_value = (0.04, 0.08, 0.05, 1.0)
    b_g.inputs["Roughness"].default_value = 0.94
ground.data.materials.append(m_ground)

# --- ILUMINAÇÃO CINEMATOGRÁFICA DIABLO IV ---
bpy.ops.object.light_add(type='SUN', location=(10, -12, 25))
sun = bpy.context.active_object
sun.data.energy = 2.4
sun.data.color = (0.72, 0.85, 1.0)
sun.rotation_euler = (math.radians(48), math.radians(22), math.radians(-30))

for bx in [-2.8, 2.8]:
    bpy.ops.object.light_add(type='POINT', location=(bx, -4.8, 1.6))
    fire = bpy.context.active_object
    fire.data.energy = 95.0
    fire.data.color = (1.0, 0.55, 0.15)

for mx, my in [(-5.8, -5.8), (5.8, -5.8), (-5.8, 5.8), (5.8, 5.8)]:
    bpy.ops.object.light_add(type='POINT', location=(mx, my, 2.5))
    rune_l = bpy.context.active_object
    rune_l.data.energy = 45.0
    rune_l.data.color = (0.2, 0.9, 0.95)

world = bpy.data.worlds.new("ForestWorld")
scene.world = world
world.use_nodes = True
bg = world.node_tree.nodes.get("Background")
if bg:
    bg.inputs["Color"].default_value = (0.03, 0.05, 0.09, 1.0)
    bg.inputs["Strength"].default_value = 0.55

# CÂMERA ISOMÉTRICA AMPLA
bpy.ops.object.camera_add(location=(0, -16.8, 13.8))
cam = bpy.context.active_object
cam.rotation_euler = (math.radians(52), 0, 0)
cam.data.lens = 38.0
scene.camera = cam

scene.render.filepath = "{OUT_IMG}"
bpy.ops.render.render(write_still=True)
print("Renderização finalizada com sucesso!")
"""

tmp_script = "/tmp/render_showcase.py"
with open(tmp_script, "w") as f:
    f.write(BLENDER_SCRIPT)

print("Iniciando renderização de showcase via Blender Cycles...")
res = subprocess.run([
    "/home/eudespatricio/.local/bin/blender",
    "--background",
    "--python", tmp_script
], capture_output=True, text=True)

print(res.stdout)
if res.returncode != 0:
    print("ERRO:", res.stderr, file=sys.stderr)
    sys.exit(res.returncode)
else:
    print(f"Imagem de Showcase gerada com sucesso: {OUT_IMG}")
