import bpy
import math
import os

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def mat(name, color, rough=0.5, metal=0.0, emit=None, emit_str=0.0):
    m = bpy.data.materials.new(name=name)
    m.use_nodes = True
    nodes = m.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs['Base Color'].default_value = color
    bsdf.inputs['Roughness'].default_value = rough
    bsdf.inputs['Metallic'].default_value = metal
    if emit:
        bsdf.inputs['Emission Color'].default_value = emit
        bsdf.inputs['Emission Strength'].default_value = emit_str
    return m

def build_stone_brazier():
    reset()
    mat_stone = mat("BrazierStone", (0.18, 0.17, 0.16, 1.0), rough=0.85, metal=0.1)
    mat_metal = mat("BrazierIron", (0.1, 0.1, 0.12, 1.0), rough=0.45, metal=0.85)
    mat_fire = mat("BrazierFire", (1.0, 0.5, 0.1, 1.0), rough=0.2, metal=0.0,
                   emit=(1.0, 0.45, 0.08, 1.0), emit_str=3.5)

    # Base de pedra circular
    bpy.ops.mesh.primitive_cylinder_add(radius=0.55, depth=0.2, location=(0, 0, 0.1))
    base = bpy.context.active_object
    base.data.materials.append(mat_stone)

    # Pilar canelado
    bpy.ops.mesh.primitive_cylinder_add(radius=0.32, depth=0.75, location=(0, 0, 0.55))
    pillar = bpy.context.active_object
    pillar.data.materials.append(mat_stone)

    # Cuba de ferro do braseiro
    bpy.ops.mesh.primitive_cylinder_add(radius=0.6, depth=0.3, location=(0, 0, 1.05))
    bowl = bpy.context.active_object
    bowl.data.materials.append(mat_metal)

    # Brasas incandescentes dentro da cuba
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.42, location=(0, 0, 1.15))
    embers = bpy.context.active_object
    embers.scale = (1.0, 1.0, 0.45)
    embers.data.materials.append(mat_fire)

    out = "/home/eudespatricio/Games/GameZero/assets/models/stone_brazier.glb"
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print(f"Exportado: {out}")

def build_dragon_banner():
    reset()
    mat_wood = mat("BannerPole", (0.22, 0.14, 0.09, 1.0), rough=0.75, metal=0.0)
    mat_cloth = mat("BannerCloth", (0.06, 0.16, 0.32, 1.0), rough=0.9, metal=0.0)
    mat_gold = mat("BannerGold", (0.85, 0.7, 0.25, 1.0), rough=0.3, metal=0.85)

    # Haste vertical de madeira
    bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=3.2, location=(0, 0, 1.6))
    pole = bpy.context.active_object
    pole.data.materials.append(mat_wood)

    # Travessa horizontal
    bpy.ops.mesh.primitive_cylinder_add(radius=0.035, depth=1.1, location=(0.45, 0, 3.0))
    cross = bpy.context.active_object
    cross.rotation_euler = (math.radians(90), 0, math.radians(90))
    cross.data.materials.append(mat_wood)

    # Tecido do estandarte (caído com corte em V)
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0.45, 0, 2.05))
    cloth = bpy.context.active_object
    cloth.scale = (0.95, 1.0, 1.7)
    cloth.rotation_euler = (math.radians(90), 0, 0)
    cloth.data.materials.append(mat_cloth)

    # Brasão do Dragão dourado no centro
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.22, location=(0.45, 0.02, 2.2))
    crest = bpy.context.active_object
    crest.scale = (0.9, 0.2, 1.2)
    crest.data.materials.append(mat_gold)

    out = "/home/eudespatricio/Games/GameZero/assets/models/dragon_banner.glb"
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print(f"Exportado: {out}")

def build_treasure_chest():
    reset()
    mat_wood = mat("ChestWood", (0.25, 0.16, 0.1, 1.0), rough=0.7, metal=0.0)
    mat_iron = mat("ChestIron", (0.15, 0.15, 0.18, 1.0), rough=0.4, metal=0.8)
    mat_gold = mat("ChestGold", (0.88, 0.72, 0.2, 1.0), rough=0.25, metal=0.9,
                   emit=(0.88, 0.72, 0.2, 1.0), emit_str=0.5)

    # Base da arca
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.35))
    base = bpy.context.active_object
    base.scale = (0.9, 0.6, 0.5)
    base.data.materials.append(mat_wood)

    # Tampa abaulada
    bpy.ops.mesh.primitive_cylinder_add(radius=0.3, depth=0.9, location=(0, 0, 0.6))
    lid = bpy.context.active_object
    lid.scale = (1.0, 1.0, 0.55)
    lid.rotation_euler = (0, math.radians(90), 0)
    lid.data.materials.append(mat_wood)

    # Reforços de ferro nas bordas
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.35))
    straps = bpy.context.active_object
    straps.scale = (0.92, 0.62, 0.1)
    straps.data.materials.append(mat_iron)

    # Fechadura dourada
    bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=0.05, location=(0, -0.32, 0.45))
    lock = bpy.context.active_object
    lock.rotation_euler = (math.radians(90), 0, 0)
    lock.data.materials.append(mat_gold)

    out = "/home/eudespatricio/Games/GameZero/assets/models/treasure_chest.glb"
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
    print(f"Exportado: {out}")

def main():
    print("[Studio 3D] Criando props de riqueza visual para GameZero...")
    build_stone_brazier()
    build_dragon_banner()
    build_treasure_chest()
    print("[Studio 3D] Todos os props exportados com sucesso!")

if __name__ == "__main__":
    main()
