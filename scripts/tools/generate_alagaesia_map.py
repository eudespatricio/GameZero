import bpy
import math
import os

def create_alagaesia_map():
    # Limpar cena
    bpy.ops.wm.read_factory_settings(use_empty=True)

    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE_NEXT' if 'BLENDER_EEVEE_NEXT' in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items else 'BLENDER_EEVEE'
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 1080
    scene.render.resolution_percentage = 100

    # 1. Câmera Ortográfica do Topo
    bpy.ops.object.camera_add(location=(0, 0, 15), rotation=(0, 0, 0))
    cam = bpy.context.active_object
    cam.data.type = 'ORTHO'
    cam.data.ortho_scale = 20.0
    scene.camera = cam

    # 2. Iluminação Suave Cartográfica
    bpy.ops.object.light_add(type='SUN', location=(4, -6, 12), rotation=(math.radians(35), math.radians(20), math.radians(-30)))
    sun = bpy.context.active_object
    sun.data.energy = 2.2
    sun.data.color = (1.0, 0.95, 0.88)

    # Luz de preenchimento ambiente suave
    bpy.ops.object.light_add(type='POINT', location=(0, 0, 10))
    point = bpy.context.active_object
    point.data.energy = 800
    point.data.color = (0.85, 0.9, 1.0)

    # 3. Materiais
    # Base de Pergaminho Envelhecido
    mat_parchment = bpy.data.materials.new(name="ParchmentBase")
    mat_parchment.use_nodes = True
    nodes = mat_parchment.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs['Base Color'].default_value = (0.82, 0.74, 0.58, 1.0)
    bsdf.inputs['Roughness'].default_value = 0.95

    # Oceano Antigo
    mat_ocean = bpy.data.materials.new(name="OceanOld")
    mat_ocean.use_nodes = True
    bsdf_oc = mat_ocean.node_tree.nodes.get("Principled BSDF")
    bsdf_oc.inputs['Base Color'].default_value = (0.32, 0.42, 0.48, 1.0)
    bsdf_oc.inputs['Roughness'].default_value = 0.8

    # Floresta de Du Weldenvarden
    mat_forest = bpy.data.materials.new(name="DuWeldenvardenForest")
    mat_forest.use_nodes = True
    bsdf_f = mat_forest.node_tree.nodes.get("Principled BSDF")
    bsdf_f.inputs['Base Color'].default_value = (0.12, 0.32, 0.18, 1.0)
    bsdf_f.inputs['Roughness'].default_value = 0.9

    # Deserto de Hadarac
    mat_desert = bpy.data.materials.new(name="HadaracDesert")
    mat_desert.use_nodes = True
    bsdf_d = mat_desert.node_tree.nodes.get("Principled BSDF")
    bsdf_d.inputs['Base Color'].default_value = (0.75, 0.58, 0.35, 1.0)
    bsdf_d.inputs['Roughness'].default_value = 0.9

    # Montanhas (A Espinha e Montanhas Beor)
    mat_mountains = bpy.data.materials.new(name="BeorMountains")
    mat_mountains.use_nodes = True
    bsdf_m = mat_mountains.node_tree.nodes.get("Principled BSDF")
    bsdf_m.inputs['Base Color'].default_value = (0.28, 0.26, 0.25, 1.0)
    bsdf_m.inputs['Roughness'].default_value = 0.85

    # Picos Nevados
    mat_snow = bpy.data.materials.new(name="SnowPeaks")
    mat_snow.use_nodes = True
    bsdf_s = mat_snow.node_tree.nodes.get("Principled BSDF")
    bsdf_s.inputs['Base Color'].default_value = (0.9, 0.92, 0.95, 1.0)
    bsdf_s.inputs['Roughness'].default_value = 0.6

    # Rio Anora
    mat_river = bpy.data.materials.new(name="RiverBlue")
    mat_river.use_nodes = True
    bsdf_r = mat_river.node_tree.nodes.get("Principled BSDF")
    bsdf_r.inputs['Base Color'].default_value = (0.2, 0.55, 0.7, 1.0)
    bsdf_r.inputs['Roughness'].default_value = 0.4

    # Moldura Gótica Dourada/Ferro
    mat_border = bpy.data.materials.new(name="GothicBorder")
    mat_border.use_nodes = True
    bsdf_b = mat_border.node_tree.nodes.get("Principled BSDF")
    bsdf_b.inputs['Base Color'].default_value = (0.16, 0.12, 0.08, 1.0)
    bsdf_b.inputs['Roughness'].default_value = 0.5

    mat_gold = bpy.data.materials.new(name="BorderGold")
    mat_gold.use_nodes = True
    bsdf_g = mat_gold.node_tree.nodes.get("Principled BSDF")
    bsdf_g.inputs['Base Color'].default_value = (0.78, 0.62, 0.25, 1.0)
    bsdf_g.inputs['Metallic'].default_value = 0.8
    bsdf_g.inputs['Roughness'].default_value = 0.35

    # 4. Plano de Fundo Geral (Pergaminho 16:9)
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0, 0, 0))
    canvas = bpy.context.active_object
    canvas.scale = (18.5, 10.5, 1.0)
    canvas.data.materials.append(mat_parchment)

    # 5. Oceano Ocidental à Esquerda (Costa marítima)
    bpy.ops.mesh.primitive_plane_add(size=1.0, location=(-7.2, 0, 0.02))
    ocean = bpy.context.active_object
    ocean.scale = (4.2, 10.0, 1.0)
    ocean.data.materials.append(mat_ocean)

    # Ilha de Eoam no oceano
    bpy.ops.mesh.primitive_cylinder_add(radius=0.7, depth=0.1, location=(-7.5, 2.5, 0.05))
    island1 = bpy.context.active_object
    island1.scale = (1.2, 0.7, 1.0)
    island1.data.materials.append(mat_parchment)

    # 6. Du Weldenvarden (Floresta Élfica no Norte e Nordeste)
    bpy.ops.mesh.primitive_cylinder_add(radius=1.0, depth=0.08, location=(3.5, 3.2, 0.04))
    forest = bpy.context.active_object
    forest.scale = (4.8, 2.0, 1.0)
    forest.data.materials.append(mat_forest)

    # Pequenos pinheiros estilizados sobre a floresta élfica
    tree_coords = [
        (1.0, 3.5), (2.2, 4.0), (3.5, 4.2), (4.8, 3.8), (6.0, 3.2),
        (2.0, 2.8), (3.2, 3.2), (4.5, 3.0), (5.5, 2.5), (0.5, 2.6)
    ]
    for tx, ty in tree_coords:
        bpy.ops.mesh.primitive_cone_add(radius1=0.22, radius2=0.0, depth=0.45, location=(tx, ty, 0.25))
        tr = bpy.context.active_object
        tr.data.materials.append(mat_forest)

    # 7. Cordilheira da Espinha (The Spine) - Linha de montanhas escarpadas a oeste
    spine_coords = [
        (-4.8, 4.0, 0.6), (-4.6, 3.0, 0.8), (-4.5, 2.0, 0.9), (-4.3, 1.0, 0.85),
        (-4.2, 0.0, 0.8), (-4.0, -1.2, 0.75), (-3.8, -2.4, 0.7), (-3.5, -3.6, 0.6)
    ]
    for mx, my, mscale in spine_coords:
        bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=0.45 * mscale, radius2=0.0, depth=0.85 * mscale, location=(mx, my, 0.3 * mscale))
        peak = bpy.context.active_object
        peak.rotation_euler = (0, 0, math.radians(25))
        peak.data.materials.append(mat_mountains)

        # Cume de neve
        bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=0.18 * mscale, radius2=0.0, depth=0.3 * mscale, location=(mx, my, 0.65 * mscale))
        snow = bpy.context.active_object
        snow.rotation_euler = (0, 0, math.radians(25))
        snow.data.materials.append(mat_snow)

    # 8. Deserto de Hadarac no Centro
    bpy.ops.mesh.primitive_cylinder_add(radius=1.0, depth=0.06, location=(1.0, 0.2, 0.03))
    desert = bpy.context.active_object
    desert.scale = (3.4, 2.2, 1.0)
    desert.data.materials.append(mat_desert)

    # 9. As Titânicas Montanhas Beor no Sul
    beor_coords = [
        (-2.0, -3.8, 1.3), (-0.5, -4.1, 1.5), (1.2, -4.2, 1.6), (3.0, -4.0, 1.4),
        (4.8, -3.7, 1.2), (6.2, -3.5, 1.1), (0.2, -3.2, 1.2), (2.2, -3.1, 1.3)
    ]
    for bx, by, bscale in beor_coords:
        bpy.ops.mesh.primitive_cone_add(vertices=5, radius1=0.65 * bscale, radius2=0.0, depth=1.4 * bscale, location=(bx, by, 0.5 * bscale))
        bpeak = bpy.context.active_object
        bpeak.rotation_euler = (0, 0, math.radians(15))
        bpeak.data.materials.append(mat_mountains)

        # Neve nos Beors gigantescos
        bpy.ops.mesh.primitive_cone_add(vertices=5, radius1=0.3 * bscale, radius2=0.0, depth=0.5 * bscale, location=(bx, by, 1.05 * bscale))
        bsnow = bpy.context.active_object
        bsnow.rotation_euler = (0, 0, math.radians(15))
        bsnow.data.materials.append(mat_snow)

    # 10. Rio Anora e Lagos
    # Lago Leona
    bpy.ops.mesh.primitive_cylinder_add(radius=0.55, depth=0.05, location=(-1.8, 0.8, 0.04))
    lake = bpy.context.active_object
    lake.scale = (1.1, 0.7, 1.0)
    lake.data.materials.append(mat_river)

    # Picos Negros de Helgrind ao lado do Lago Leona
    bpy.ops.mesh.primitive_cone_add(vertices=3, radius1=0.3, radius2=0.0, depth=0.7, location=(-1.3, 0.6, 0.35))
    helgrind = bpy.context.active_object
    mat_black = bpy.data.materials.new(name="HelgrindBlack")
    mat_black.use_nodes = True
    mat_black.node_tree.nodes.get("Principled BSDF").inputs['Base Color'].default_value = (0.08, 0.08, 0.1, 1.0)
    helgrind.data.materials.append(mat_black)

    # Segmentos curvos do Rio Anora (do Vale do Palancar até o deserto)
    river_path = [
        (-4.0, 3.8, -3.2, 3.2),
        (-3.2, 3.2, -2.5, 2.2),
        (-2.5, 2.2, -1.8, 0.8),
        (-1.8, 0.8, -1.0, 0.0),
        (-1.0, 0.0, 0.5, -0.8)
    ]
    for x1, y1, x2, y2 in river_path:
        mid_x = (x1 + x2) / 2.0
        mid_y = (y1 + y2) / 2.0
        length = math.hypot(x2 - x1, y2 - y1)
        angle = math.atan2(y2 - y1, x2 - x1)
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(mid_x, mid_y, 0.04))
        rseg = bpy.context.active_object
        rseg.scale = (length, 0.12, 0.02)
        rseg.rotation_euler = (0, 0, angle)
        rseg.data.materials.append(mat_river)

    # 11. Rosa dos Ventos Cartográfica no Mar Ocidental
    bpy.ops.mesh.primitive_cylinder_add(radius=0.9, depth=0.05, location=(-7.2, -3.2, 0.08))
    compass_base = bpy.context.active_object
    compass_base.data.materials.append(mat_gold)

    # Pontas da Rosa dos Ventos
    for angle_deg in [0, 45, 90, 135, 180, 225, 270, 315]:
        rad = math.radians(angle_deg)
        length = 0.95 if angle_deg % 90 == 0 else 0.65
        width = 0.14 if angle_deg % 90 == 0 else 0.09
        bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=width, radius2=0.0, depth=length, location=(-7.2 + math.cos(rad) * length * 0.45, -3.2 + math.sin(rad) * length * 0.45, 0.12))
        arrow = bpy.context.active_object
        arrow.rotation_euler = (math.radians(-90), 0, rad - math.radians(90))
        arrow.data.materials.append(mat_border if angle_deg % 90 != 0 else mat_gold)

    # 12. Moldura Gótica Ornamental Externa
    border_thickness = 0.35
    w_half = 9.0
    h_half = 5.0
    borders = [
        (0, h_half, 18.2, border_thickness),      # Topo
        (0, -h_half, 18.2, border_thickness),     # Base
        (-w_half, 0, border_thickness, 10.2),     # Esquerda
        (w_half, 0, border_thickness, 10.2)       # Direita
    ]
    for bx, by, bw, bh in borders:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(bx, by, 0.15))
        b = bpy.context.active_object
        b.scale = (bw, bh, 0.08)
        b.data.materials.append(mat_border)

        # Filete de ouro fino interno
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(bx * 0.97, by * 0.97, 0.18))
        bgold = bpy.context.active_object
        bgold.scale = (bw * 0.97, bh * 0.97 if bh == border_thickness else border_thickness * 0.25, 0.04)
        bgold.data.materials.append(mat_gold)

    # Ornatos de Canto nos 4 cantos
    for cx in [-w_half, w_half]:
        for cy in [-h_half, h_half]:
            bpy.ops.mesh.primitive_cylinder_add(radius=0.6, depth=0.12, location=(cx, cy, 0.22))
            corner_stud = bpy.context.active_object
            corner_stud.data.materials.append(mat_gold)

    # 13. Renderizar para PNG
    out_dir = "/home/eudespatricio/Games/GameZero/assets/ui"
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "alagaesia_cartography.png")
    scene.render.filepath = out_path
    bpy.ops.render.render(write_still=True)
    print(f"[Map Generator] Mapa Cartográfico gerado com sucesso em: {out_path}")

if __name__ == "__main__":
    create_alagaesia_map()
