#!/usr/bin/env python3
"""
Studio Showcase: Renderiza a vitrine dos 4 Novos Mobs Dark Fantasy (Nível Diablo IV)
GameZero - Blender 4.2 LTS Cycles.
Mostra:
- Urgal Warrior (Kull)
- Spine Wolf (Lobo da Espinha)
- Root Golem (Colosso de Raiz e Basalto)
- Shade Wraith (Ceifador Espectral)
Em iluminação cinematográfica Dark Fantasy com chão úmido e sombras de contato.
"""

import os
import subprocess
import sys

BLENDER_BIN = "/home/eudespatricio/.gemini/antigravity/bin/blender"
OUTPUT_IMAGE = "/home/eudespatricio/Games/GameZero/assets/ui/diablo4_mobs_showcase.png"
MODELS_DIR = "/home/eudespatricio/Games/GameZero/assets/models"

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

# Chão de Ardósia Úmida Escura (Padrão Dark Fantasy Diablo IV)
bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 0, 0))
ground = bpy.context.active_object
ground.name = "Ground"

mat_ground = bpy.data.materials.new("DarkWetSlate")
mat_ground.use_nodes = True
bsdf_g = mat_ground.node_tree.nodes.get("Principled BSDF")
if bsdf_g:
    bsdf_g.inputs["Base Color"].default_value = (0.04, 0.04, 0.05, 1.0)
    bsdf_g.inputs["Roughness"].default_value = 0.18
    bsdf_g.inputs["Metallic"].default_value = 0.10
ground.data.materials.append(mat_ground)

def import_model(path, loc=(0,0,0), rot=(0,0,0), scale=(1,1,1)):
    if not os.path.exists(path):
        print("Aviso: " + path + " não encontrado")
        return None
    existing = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new_objs = [o for o in bpy.data.objects if o not in existing and o.type == 'MESH']
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=loc)
    root = bpy.context.active_object
    root.rotation_euler = (math.radians(rot[0]), math.radians(rot[1]), math.radians(rot[2]))
    root.scale = scale
    for o in new_objs:
        o.parent = root
    return root

# Posicionar os 4 Mobs em Linha de Batalha Cinematográfica
# 1. Root Golem (Esquerda Fundo - Monumental)
import_model("{MODELS_DIR}/root_golem.glb", loc=(-3.6, 1.2, 0), rot=(0, 0, 20), scale=(1.05, 1.05, 1.05))

# 2. Urgal Warrior / Kull (Centro-Esquerda - Brutal)
import_model("{MODELS_DIR}/urgal_warrior.glb", loc=(-1.2, 0.0, 0), rot=(0, 0, 15), scale=(1.15, 1.15, 1.15))

# 3. Spine Wolf (Centro-Direita - Predador Agressivo)
import_model("{MODELS_DIR}/wolf_spine.glb", loc=(1.6, -0.2, 0), rot=(0, 0, -20), scale=(1.25, 1.25, 1.25))

# 4. Shade Wraith (Direita - Flutuando no Ar com Foices)
import_model("{MODELS_DIR}/shade_wraith.glb", loc=(3.8, 1.0, 0.25), rot=(0, 0, -30), scale=(1.1, 1.1, 1.1))

# Iluminação Dark Fantasy (Key Moonlight + Rim Fúnebre + Fill de Fogo Carmesim)
# 1. Luar Frio Direcional
bpy.ops.object.light_add(type='SUN', location=(10, -10, 15))
sun = bpy.context.active_object
sun.data.energy = 3.2
sun.data.color = (0.75, 0.88, 1.0)
sun.rotation_euler = (math.radians(52), math.radians(18), math.radians(-35))

# 2. Tocha de Sangue Carmesim (Rim Light)
bpy.ops.object.light_add(type='POINT', location=(-1.8, -3.2, 2.6))
torch1 = bpy.context.active_object
torch1.data.energy = 350.0
torch1.data.color = (1.0, 0.45, 0.15)

# 3. Luz Espectral Ciano (Rim Light do Wraith)
bpy.ops.object.light_add(type='POINT', location=(4.2, 0.2, 2.6))
torch2 = bpy.context.active_object
torch2.data.energy = 280.0
torch2.data.color = (0.2, 0.85, 1.0)

# Câmera Frontal-Isométrica Épica (Enquadra perfeitamente todos os 4 monstros)
bpy.ops.object.camera_add(location=(0, -12.5, 3.6))
cam = bpy.context.active_object
cam.data.lens = 42 # Lente cinematográfica 42mm
cam.rotation_euler = (math.radians(80.0), 0, 0)
scene.camera = cam

# Renderizar Imagem
scene.render.filepath = "{OUTPUT_IMAGE}"
print(">>> Iniciando Renderização Cycles dos 4 Mobs Diablo IV...")
bpy.ops.render.render(write_still=True)
print("=== Renderização Concluída: {OUTPUT_IMAGE} ===")
"""

def main():
    print("=" * 60)
    print("📸 RENDERIZANDO SHOWCASE DOS MOBS DIABLO IV EM BLENDER CYCLES")
    print("=" * 60)
    cmd = [BLENDER_BIN, "-b", "--python-expr", BLENDER_SCRIPT]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode != 0:
        print("❌ Erro no render:", res.stderr)
        sys.exit(1)
    print(res.stdout)
    if os.path.exists(OUTPUT_IMAGE):
        print("✅ Showcase salvo com sucesso em:", OUTPUT_IMAGE)

if __name__ == "__main__":
    main()
