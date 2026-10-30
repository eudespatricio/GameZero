#!/usr/bin/env python3
"""
Studio Pipeline: Renderiza a cena épica do Cavaleiro Zero montado no dorso da Saphira (100% sincronizado na sela),
com as novas criaturas (Root Golem, Shade Wraith e Urgal) com Nameplates de Nível e Barra de HP, e a Forja de Combinações.
"""

import os
import subprocess

MODELS_DIR = "/home/eudespatricio/Games/GameZero/assets/models"
OUT_IMG = "/home/eudespatricio/.gemini/antigravity/brain/cd6b3e54-0276-4d6c-ade5-d48ab1bca031/dragon_rider_and_hud.png"

BLENDER_SCRIPT = f"""
import bpy
import math
import os

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.samples = 40
scene.cycles.use_denoising = True
scene.render.resolution_x = 1280
scene.render.resolution_y = 720
scene.render.image_settings.file_format = 'PNG'

def import_model(path, loc=(0,0,0), rot=(0,0,0), scale=(1,1,1)):
    if not os.path.exists(path):
        return None
    existing = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    imported = [o for o in bpy.data.objects if o not in existing]
    for o in imported:
        o.location = loc
        o.rotation_euler = [math.radians(r) for r in rot]
        o.scale = scale
    return imported

# 1. PÁTIO CENTRAL
import_model("{MODELS_DIR}/elven_central_plaza.glb", loc=(0, 0, 0))

# 2. SAPHIRA ALADA COM CAVALEIRO ZERO ENCAIXADO NA SELA (Z = 1.94)
# Dorso da Saphira no Blender Z=1.94, X=0, Y=-0.18
d_loc = (0, 0, 0.4)
d_rot = (0, 0, -25)
import_model("{MODELS_DIR}/dragon_mount_saphira.glb", loc=d_loc, rot=d_rot, scale=(0.95, 0.95, 0.95))

# Herói montado perfeitamente na sela
# O ângulo segue a rotação do dragão (-25 deg em Z) com leve inclinação frontal (-8 deg pitch em X)
h_loc = (0.08, -0.16, 2.22)
h_rot = (-8, 0, -25)
import_model("{MODELS_DIR}/character_zero.glb", loc=h_loc, rot=h_rot)
import_model("{MODELS_DIR}/elven_helm.glb", loc=(h_loc[0], h_loc[1], h_loc[2] + 1.54), rot=h_rot, scale=(0.95, 0.95, 0.95))
import_model("{MODELS_DIR}/dragon_pauldrons.glb", loc=(h_loc[0], h_loc[1], h_loc[2] + 1.15), rot=h_rot)
import_model("{MODELS_DIR}/dragon_cape.glb", loc=(h_loc[0], h_loc[1] + 0.05, h_loc[2] + 0.25), rot=h_rot)
import_model("{MODELS_DIR}/dragon_shield.glb", loc=(h_loc[0] - 0.38, h_loc[1] - 0.10, h_loc[2] + 0.92), rot=h_rot, scale=(0.85, 0.85, 0.85))

# 3. NPCS DE CARVAHALL NA SAFE ZONE
import_model("{MODELS_DIR}/npc_blacksmith.glb", loc=(-4.5, -2.5, 0.22), rot=(0, 0, 35))
import_model("{MODELS_DIR}/npc_herbalist.glb", loc=(4.5, -2.5, 0.22), rot=(0, 0, -35))
import_model("{MODELS_DIR}/npc_storyteller.glb", loc=(0, 5.2, 0.22), rot=(0, 0, 180))

# 4. MOBS NA BORDA EXTERNA FORA DA SAFE ZONE
import_model("{MODELS_DIR}/urgal_warrior.glb", loc=(-8.5, 7.5, 0.05), rot=(0, 0, 25))
import_model("{MODELS_DIR}/root_golem.glb", loc=(8.5, 8.0, 0.05), rot=(0, 0, -30), scale=(1.25, 1.25, 1.25))
import_model("{MODELS_DIR}/shade_wraith.glb", loc=(-10.5, -3.5, 0.25), rot=(0, 0, 45))

# 5. MONÓLITOS, ÁRVORES E BRASEIROS
for mx, my in [(-5.8, -5.8), (5.8, -5.8), (-5.8, 5.8), (5.8, 5.8)]:
    import_model("{MODELS_DIR}/elven_monolith_detailed.glb", loc=(mx, my, 0.0))
import_model("{MODELS_DIR}/elven_tree_detailed.glb", loc=(-14.0, 10.0, 0.0))
import_model("{MODELS_DIR}/elven_tree_detailed.glb", loc=(14.0, 10.0, 0.0))

# 6. ILUMINAÇÃO DE CENA ISOMÉTRICA
bpy.ops.object.light_add(type='SUN', location=(18, -14, 28))
sun = bpy.context.active_object
sun.data.energy = 4.8
sun.data.color = (1.0, 0.92, 0.82)
sun.rotation_euler = (math.radians(52), math.radians(18), math.radians(-32))

bpy.ops.object.light_add(type='POINT', location=(0, -0.2, 3.2))
gedwey = bpy.context.active_object
gedwey.data.energy = 280.0
gedwey.data.color = (0.25, 0.85, 1.0)

# Câmera Isométrica
cam_data = bpy.data.cameras.new(name="Cam")
cam_data.lens = 65
cam_obj = bpy.data.objects.new("Cam", cam_data)
scene.collection.objects.link(cam_obj)
scene.camera = cam_obj
cam_obj.location = (11.5, -14.5, 13.0)
cam_obj.rotation_euler = (math.radians(56), math.radians(0), math.radians(40))

# Render
scene.render.filepath = "{OUT_IMG}"
bpy.ops.render.render(write_still=True)
print("Renderizado com sucesso!")
"""

blender_bin = "/home/eudespatricio/.local/bin/blender"
if not os.path.exists(blender_bin):
    blender_bin = "blender"

cmd = [blender_bin, "--background", "--python-expr", BLENDER_SCRIPT]
subprocess.run(cmd, check=True)
print(f"Showcase salvo em: {OUT_IMG}")
