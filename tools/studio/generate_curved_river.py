import bpy
import bmesh
import math
from mathutils import Vector, Matrix

OUT = "/home/eudespatricio/Games/GameZero/assets/models/elven_river_ribbon.glb"

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def river_center_z(x):
    # Meandros naturais do rio de Alagaësia. Em x=0 (onde está a ponte), Z é exatamente 22.0.
    damping = 1.0 - math.exp(-abs(x) * 0.06)
    return 22.0 + (6.5 * math.sin(x * 0.016) + 2.5 * math.sin(x * 0.042)) * damping

def river_tangent(x):
    eps = 0.5
    z1 = river_center_z(x - eps)
    z2 = river_center_z(x + eps)
    return Vector((2.0 * eps, 0.0, z2 - z1)).normalized()

def river_normal_xz(x):
    tg = river_tangent(x)
    return Vector((-tg.z, 0.0, tg.x)).normalized()

def mat(name, color, rough=0.8, metal=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = rough
        bsdf.inputs["Metallic"].default_value = metal
    return m

def build_river():
    reset()

    mat_water = mat("RiverWaterSurface", (0.08, 0.45, 0.55, 0.85), rough=0.08, metal=0.02)
    mat_sand = mat("RiverBankSand", (0.32, 0.28, 0.22, 1.0), rough=0.92, metal=0.0)
    mat_pebble = mat("RiverBankStones", (0.22, 0.22, 0.24, 1.0), rough=0.75, metal=0.05)

    bm_water = bmesh.new()
    bm_bank = bmesh.new()

    x_min = -320.0
    x_max = 320.0
    steps = 256
    dx = (x_max - x_min) / float(steps)

    water_half_w = 4.5
    bank_w = 2.2

    # Layers de UV
    uv_layer_w = bm_water.loops.layers.uv.new("UVMap")
    uv_layer_b = bm_bank.loops.layers.uv.new("UVMap")

    # 1. Gerar Anéis de Vértices ao longo do rio
    water_rings = []
    bank_left_rings = []
    bank_right_rings = []

    for i in range(steps + 1):
        x = x_min + i * dx
        z_c = river_center_z(x)
        norm = river_normal_xz(x)

        p_center = Vector((x, 0.03, z_c))
        p_w_left = p_center - norm * water_half_w
        p_w_right = p_center + norm * water_half_w

        # Água
        v_wl = bm_water.verts.new((p_w_left.x, 0.025, p_w_left.z))
        v_wc = bm_water.verts.new((p_center.x, 0.025, p_center.z))
        v_wr = bm_water.verts.new((p_w_right.x, 0.025, p_w_right.z))
        water_rings.append((v_wl, v_wc, v_wr, float(i) / steps))

        # Margem esquerda (sul)
        p_b_left_out = p_w_left - norm * bank_w
        v_bl_out = bm_bank.verts.new((p_b_left_out.x, 0.015, p_b_left_out.z))
        v_bl_in = bm_bank.verts.new((p_w_left.x, 0.030, p_w_left.z))
        bank_left_rings.append((v_bl_out, v_bl_in, float(i) / steps))

        # Margem direita (norte)
        p_b_right_out = p_w_right + norm * bank_w
        v_br_in = bm_bank.verts.new((p_w_right.x, 0.030, p_w_right.z))
        v_br_out = bm_bank.verts.new((p_b_right_out.x, 0.015, p_b_right_out.z))
        bank_right_rings.append((v_br_in, v_br_out, float(i) / steps))

    # 2. Conectar Faces da Água
    for i in range(steps):
        r1 = water_rings[i]
        r2 = water_rings[i + 1]
        u1 = r1[3] * 32.0
        u2 = r2[3] * 32.0

        f1 = bm_water.faces.new((r1[0], r2[0], r2[1], r1[1]))
        f2 = bm_water.faces.new((r1[1], r2[1], r2[2], r1[2]))

        for l in f1.loops:
            vx = u1 if l.vert in (r1[0], r1[1]) else u2
            vy = 0.0 if l.vert in (r1[0], r2[0]) else 0.5
            l[uv_layer_w].uv = (vx, vy)

        for l in f2.loops:
            vx = u1 if l.vert in (r1[1], r1[2]) else u2
            vy = 0.5 if l.vert in (r1[1], r2[1]) else 1.0
            l[uv_layer_w].uv = (vx, vy)

    # 3. Conectar Faces das Margens
    for i in range(steps):
        # Margem esquerda
        r1 = bank_left_rings[i]
        r2 = bank_left_rings[i + 1]
        u1 = r1[2] * 32.0
        u2 = r2[2] * 32.0
        f_bl = bm_bank.faces.new((r1[0], r2[0], r2[1], r1[1]))
        for l in f_bl.loops:
            vx = u1 if l.vert in (r1[0], r1[1]) else u2
            vy = 0.0 if l.vert in (r1[0], r2[0]) else 1.0
            l[uv_layer_b].uv = (vx, vy)

        # Margem direita
        r1_r = bank_right_rings[i]
        r2_r = bank_right_rings[i + 1]
        f_br = bm_bank.faces.new((r1_r[0], r2_r[0], r2_r[1], r1_r[1]))
        for l in f_br.loops:
            vx = u1 if l.vert in (r1_r[0], r1_r[1]) else u2
            vy = 0.0 if l.vert in (r1_r[0], r2_r[0]) else 1.0
            l[uv_layer_b].uv = (vx, vy)

    bmesh.ops.recalc_face_normals(bm_water, faces=bm_water.faces)
    bmesh.ops.recalc_face_normals(bm_bank, faces=bm_bank.faces)

    # Objeto da Água
    mesh_w = bpy.data.meshes.new("RiverWaterMesh")
    bm_water.to_mesh(mesh_w)
    bm_water.free()
    obj_w = bpy.data.objects.new("RiverWater", mesh_w)
    bpy.context.collection.objects.link(obj_w)
    obj_w.data.materials.append(mat_water)

    # Objeto das Margens
    mesh_b = bpy.data.meshes.new("RiverBanksMesh")
    bm_bank.to_mesh(mesh_b)
    bm_bank.free()
    obj_b = bpy.data.objects.new("RiverBanks", mesh_b)
    bpy.context.collection.objects.link(obj_b)
    obj_b.data.materials.append(mat_sand)

    for p in mesh_w.polygons:
        p.use_smooth = True
    for p in mesh_b.polygons:
        p.use_smooth = True

    # Pedras de Rio ao longo das margens
    rng = math.sin
    for idx in range(36):
        rx = -280.0 + idx * 15.5
        if abs(rx) < 14.0: # Manter a passagem sob a ponte desobstruída
            continue
        rz = river_center_z(rx)
        r_norm = river_normal_xz(rx)
        side = 1.0 if (idx % 2 == 0) else -1.0
        rock_pos = Vector((rx, 0.04, rz)) + r_norm * (side * (water_half_w + 0.6))
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.45 + (idx % 3) * 0.18, location=rock_pos)
        r_obj = bpy.context.active_object
        r_obj.name = f"RiverStone_{idx}"
        r_obj.scale = (1.2, 0.5, 0.9)
        r_obj.data.materials.append(mat_pebble)
        for p in r_obj.data.polygons:
            p.use_smooth = True

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_apply=True)
    print("=== Rio Meandrado Exportado com Sucesso: " + OUT + " ===")

build_river()
