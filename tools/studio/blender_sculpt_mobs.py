import bpy
import bmesh
import math
from mathutils import Vector, Matrix, Euler, noise

OUT = "/home/eudespatricio/Games/GameZero/assets/models/"

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def mat(name, color, rough=0.75, metal=0.0, emit=None, strength=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        if "Base Color" in bsdf.inputs:
            bsdf.inputs["Base Color"].default_value = color
        if "Roughness" in bsdf.inputs:
            bsdf.inputs["Roughness"].default_value = rough
        if "Metallic" in bsdf.inputs:
            bsdf.inputs["Metallic"].default_value = metal
        if emit and "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = emit
            bsdf.inputs["Emission Strength"].default_value = strength
    return m

def smooth(obj):
    for p in obj.data.polygons:
        p.use_smooth = True

def add_bone_segment(name, p1, p2, r1, r2, material, segs=12, bevel=0.0):
    v1 = Vector(p1)
    v2 = Vector(p2)
    diff = v2 - v1
    length = max(diff.length, 0.001)
    mid = (v1 + v2) * 0.5
    bpy.ops.mesh.primitive_cone_add(vertices=segs, radius1=r1, radius2=r2, depth=length, location=mid)
    obj = bpy.context.active_object
    obj.name = name
    quat = diff.normalized().to_track_quat('Z', 'Y')
    obj.rotation_mode = 'QUATERNION'
    obj.rotation_quaternion = quat
    if bevel > 0.0:
        bev = obj.modifiers.new("Bevel", 'BEVEL')
        bev.width = bevel
        bev.segments = 2
        bev.limit_method = 'ANGLE'
    smooth(obj)
    if material:
        obj.data.materials.append(material)
    return obj

def build_lofted_mesh(name, profile, segs=16, material=None, subsurf=1, flatten_bottom=False):
    """
    Constrói malha contínua orgânica através de lofting de anéis anatômicos (BMesh).
    Profile: [(x, y, z, rx, rz, pitch_deg)]
    """
    bm = bmesh.new()
    ring_verts = []

    for x, y, z, rx, rz, pitch in profile:
        ring = []
        rad_p = math.radians(pitch)
        cos_p = math.cos(rad_p)
        sin_p = math.sin(rad_p)
        for i in range(segs):
            ang = (2.0 * math.pi * i) / segs
            lx = math.cos(ang) * rx
            lz = math.sin(ang) * rz
            if flatten_bottom and lz < 0:
                lz *= 0.78
            wy = y - lz * sin_p
            wz = z + lz * cos_p
            wx = x + lx
            v = bm.verts.new((wx, wy, wz))
            ring.append(v)
        ring_verts.append(ring)

    bm.verts.ensure_lookup_table()

    for r_idx in range(len(ring_verts) - 1):
        r1 = ring_verts[r_idx]
        r2 = ring_verts[r_idx + 1]
        for i in range(segs):
            ni = (i + 1) % segs
            bm.faces.new((r1[i], r1[ni], r2[ni], r2[i]))

    if len(ring_verts[0]) >= 3:
        bm.faces.new(ring_verts[0][::-1])
    if len(ring_verts[-1]) >= 3:
        bm.faces.new(ring_verts[-1])

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    mesh = bpy.data.meshes.new(name + "_Mesh")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj

    if subsurf > 0:
        sub = obj.modifiers.new("Subsurf", 'SUBSURF')
        sub.levels = subsurf
        sub.render_levels = subsurf

    smooth(obj)
    if material:
        obj.data.materials.append(material)
    return obj

def build_curved_blade(name, p_socket, dir_blade, width, height, thickness, material, is_reverse=False):
    """
    Constrói lâmina de machado chanfrada com curva em crescente clássica de Dark Fantasy.
    """
    bm = bmesh.new()
    steps = 8
    half_th = thickness * 0.5
    sx, sy, sz = p_socket
    dx, dy, dz = dir_blade

    v_spine = []
    v_edge = []

    for i in range(steps):
        t = float(i) / float(steps - 1)
        ang = (t - 0.5) * math.pi * 0.75
        h_offset = math.sin(ang) * (height * 0.5)
        reach = (math.cos(ang) if not is_reverse else math.cos(ang) * 0.7) * width

        # Vértices da espinha da lâmina (grossa)
        sp_pos = Vector((sx, sy + (h_offset * 0.4), sz + h_offset))
        v1 = bm.verts.new(sp_pos + Vector((half_th, 0, 0)))
        v2 = bm.verts.new(sp_pos + Vector((-half_th, 0, 0)))
        v_spine.append((v1, v2))

        # Vértices do gume da lâmina (fina e afiada)
        ed_pos = Vector((sx, sy + (dy * reach) + (h_offset * 0.8), sz + dz * reach + h_offset))
        v3 = bm.verts.new(ed_pos + Vector((half_th * 0.15, 0, 0)))
        v4 = bm.verts.new(ed_pos + Vector((-half_th * 0.15, 0, 0)))
        v_edge.append((v3, v4))

    bm.verts.ensure_lookup_table()

    for i in range(steps - 1):
        s1a, s1b = v_spine[i]
        s2a, s2b = v_spine[i + 1]
        e1a, e1b = v_edge[i]
        e2a, e2b = v_edge[i + 1]

        # Faces laterais (chanfros de corte)
        bm.faces.new((s1a, s2a, e2a, e1a))
        bm.faces.new((s1b, e1b, e2b, s2b))
        # Espinha
        bm.faces.new((s1b, s2b, s2a, s1a))
        # Gume afiado
        bm.faces.new((e1a, e2a, e2b, e1b))

    # Tampas superior e inferior
    bm.faces.new((v_spine[0][0], v_edge[0][0], v_edge[0][1], v_spine[0][1]))
    bm.faces.new((v_spine[-1][0], v_spine[-1][1], v_edge[-1][1], v_edge[-1][0]))

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    mesh = bpy.data.meshes.new(name + "_Mesh")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    smooth(obj)
    if material:
        obj.data.materials.append(material)
    return obj

def export_model(filename):
    bpy.ops.object.select_all(action="SELECT")
    filepath = OUT + filename
    bpy.ops.export_scene.gltf(filepath=filepath, export_format="GLB", use_selection=True, export_apply=True)
    print("=== Exportado com Sucesso: " + filename + " ===")

# ====================================================================
# 1. URGAL WARRIOR / KULL (DIABLO IV BRUTE)
# ====================================================================
def build_urgal_warrior():
    reset()
    mat_skin = mat("UrgalSkinDark", (0.28, 0.22, 0.18, 1.0), rough=0.65)
    mat_iron = mat("DarkIronArmor", (0.09, 0.10, 0.12, 1.0), rough=0.28, metal=0.92)
    mat_iron_trim = mat("DarkIronTrim", (0.16, 0.17, 0.19, 1.0), rough=0.24, metal=0.95)
    mat_horn = mat("AncientHornRidge", (0.24, 0.20, 0.15, 1.0), rough=0.55)
    mat_steel = mat("BloodiedSteel", (0.34, 0.35, 0.37, 1.0), rough=0.22, metal=0.95)
    mat_eye = mat("DemonicEyeGlow", (1.0, 0.22, 0.02, 1.0), rough=0.2, emit=(1.0, 0.20, 0.02, 1.0), strength=2.4)
    mat_blood = mat("AxeBloodStain", (0.38, 0.02, 0.02, 1.0), rough=0.35, metal=0.15)

    # 1. Torso Contínuo Esculpido V-Taper (Pescoço -> Peitorais -> Cintura -> Pelve)
    torso_profile = [
        (0.0, -0.06, 1.82, 0.16, 0.16, 12),
        (0.0, -0.04, 1.68, 0.44, 0.24, 6),
        (0.0, -0.08, 1.50, 0.42, 0.26, 0),
        (0.0, -0.05, 1.32, 0.36, 0.22, -4),
        (0.0, -0.02, 1.15, 0.32, 0.20, -6),
        (0.0,  0.00, 0.98, 0.35, 0.24, -2),
        (0.0,  0.00, 0.88, 0.26, 0.18, 0)
    ]
    torso = build_lofted_mesh("Torso", torso_profile, segs=16, material=mat_skin, subsurf=2)

    # 2. Cabeça Brutal Contínua
    head_profile = [
        (0.0, -0.04, 1.82, 0.18, 0.18, 15),
        (0.0, -0.10, 1.90, 0.22, 0.22, 8),
        (0.0, -0.16, 1.94, 0.23, 0.22, 0),
        (0.0, -0.22, 1.88, 0.20, 0.18, -12),
        (0.0, -0.26, 1.82, 0.15, 0.14, -20)
    ]
    head = build_lofted_mesh("Head", head_profile, segs=14, material=mat_skin, subsurf=1)

    # Mandíbula Brutal Articulada
    jaw = add_bone_segment("Jaw", (0.0, -0.16, 1.76), (0.0, -0.28, 1.72), 0.15, 0.09, mat_skin, segs=8, bevel=0.02)

    # Olhos Demoníacos Flamejantes
    for mult in [-1, 1]:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.032, location=(0.09 * mult, -0.30, 1.89))
        eye = bpy.context.active_object
        eye.name = f"Eye_{mult}"
        eye.data.materials.append(mat_eye)

    # 3. Chifres de Carneiro Curvados e Envolventes ao Redor das Têmporas (Dark Fantasy Ram Horns)
    for mult in [-1, 1]:
        h0 = (0.15 * mult, -0.14, 1.96)
        h1 = (0.30 * mult, -0.04, 2.12)
        h2 = (0.38 * mult,  0.10, 1.98)
        h3 = (0.34 * mult,  0.08, 1.76)
        h4 = (0.24 * mult, -0.08, 1.68)
        add_bone_segment(f"Horn1_{mult}", h0, h1, 0.10, 0.08, mat_horn, segs=10)
        add_bone_segment(f"Horn2_{mult}", h1, h2, 0.08, 0.06, mat_horn, segs=10)
        add_bone_segment(f"Horn3_{mult}", h2, h3, 0.06, 0.04, mat_horn, segs=8)
        add_bone_segment(f"Horn4_{mult}", h3, h4, 0.04, 0.012, mat_horn, segs=8)

    # 4. Couraça Peitoral Esculpida e Cinturão de Ferro Escuro Forjado
    add_bone_segment("ChestArmorPlate", (0.0, -0.16, 1.38), (0.0, -0.18, 1.58), 0.38, 0.42, mat_iron, segs=12, bevel=0.035)
    add_bone_segment("PelvisGirdle", (0.0, 0.0, 0.90), (0.0, 0.0, 1.05), 0.34, 0.36, mat_iron, segs=12, bevel=0.03)

    # 5. Ombreiras de Ferro em Placas Escalonadas com Espigões
    for mult in [-1, 1]:
        add_bone_segment(f"Pauldrons_{mult}", (0.42 * mult, -0.02, 1.55), (0.58 * mult, -0.02, 1.62), 0.20, 0.22, mat_iron, segs=8, bevel=0.03)
        add_bone_segment(f"PauldronsSpike_{mult}", (0.56 * mult, 0.0, 1.65), (0.78 * mult, -0.04, 2.00), 0.06, 0.01, mat_iron_trim, segs=6)

    # 6. Membros Inferiores Articulados (Thigh, Shin, Foot)
    for mult in [-1, 1]:
        p_hip = (0.22 * mult, 0.0, 0.94)
        p_knee = (0.24 * mult, -0.06, 0.50)
        p_ankle = (0.24 * mult, 0.02, 0.10)
        p_toe = (0.24 * mult, -0.16, 0.06)
        add_bone_segment(f"Thigh_{mult}", p_hip, p_knee, 0.15, 0.11, mat_skin, segs=10)
        add_bone_segment(f"Shin_{mult}", p_knee, p_ankle, 0.11, 0.09, mat_iron, segs=10, bevel=0.02)
        add_bone_segment(f"Foot_{mult}", p_ankle, p_toe, 0.09, 0.06, mat_iron, segs=8, bevel=0.02)

    # 7. Membros Superiores (Arm_L, Forearm_L, Hand_L, Arm_R, Forearm_R, Hand_R)
    add_bone_segment("Arm_L", (-0.46, 0.0, 1.52), (-0.56, -0.22, 1.05), 0.13, 0.10, mat_skin, segs=10)
    add_bone_segment("Forearm_L", (-0.56, -0.22, 1.05), (-0.48, -0.46, 0.82), 0.10, 0.09, mat_iron, segs=10, bevel=0.02)
    add_bone_segment("Hand_L", (-0.48, -0.46, 0.82), (-0.46, -0.56, 0.78), 0.09, 0.07, mat_iron, segs=8)

    add_bone_segment("Arm_R", (0.46, 0.0, 1.52), (0.56, -0.20, 1.08), 0.13, 0.10, mat_skin, segs=10)
    add_bone_segment("Forearm_R", (0.56, -0.20, 1.08), (0.52, -0.42, 0.90), 0.10, 0.09, mat_iron, segs=10, bevel=0.02)
    add_bone_segment("Hand_R", (0.52, -0.42, 0.90), (0.50, -0.52, 0.86), 0.09, 0.07, mat_iron, segs=8)

    # 8. Machado de Guerra Brutal com Lâmina em Crescente Realista (WarAxe)
    axe_root = (0.50, -0.35, 0.35)
    axe_head = (0.50, -0.75, 1.65)
    add_bone_segment("WarAxeShaft", axe_root, axe_head, 0.038, 0.036, mat_iron, segs=8, bevel=0.015)
    
    # Lâmina de corte frontal em crescente (AxeBladeFront)
    build_curved_blade("AxeBladeFront", (0.50, -0.70, 1.52), (0.0, -1.0, 0.15), width=0.48, height=0.68, thickness=0.035, material=mat_steel)
    # Espigão de penetração traseiro (AxeBladeBack)
    build_curved_blade("AxeBladeBack", (0.50, -0.70, 1.52), (0.0, 1.0, -0.10), width=0.28, height=0.42, thickness=0.03, material=mat_steel, is_reverse=True)
    # Mancha de sangue coagulado
    add_bone_segment("AxeBloodDecal", (0.50, -1.05, 1.48), (0.50, -1.18, 1.56), 0.06, 0.02, mat_blood, segs=6)

    export_model("urgal_warrior.glb")

# ====================================================================
# 2. WOLF OF THE SPINE (DIABLO IV SAVAGE PREDATOR)
# ====================================================================
def build_wolf_spine():
    reset()
    mat_fur = mat("WolfFurDark", (0.16, 0.16, 0.18, 1.0), rough=0.82)
    mat_bone = mat("WolfBoneSpikes", (0.75, 0.72, 0.65, 1.0), rough=0.45)
    mat_eye = mat("WolfFieryEye", (1.0, 0.35, 0.02, 1.0), rough=0.2, emit=(1.0, 0.25, 0.0, 1.0), strength=2.2)
    mat_tooth = mat("WolfFangs", (0.90, 0.88, 0.80, 1.0), rough=0.35)

    # 1. Corpo Contínuo do Predador (Focinho -> Cabeça -> Pescoço -> Peito -> Quadril)
    wolf_profile = [
        (0.0, -1.65, 0.96, 0.08, 0.06, -10),
        (0.0, -1.45, 1.02, 0.14, 0.12, -8),
        (0.0, -1.18, 1.12, 0.22, 0.18, -4),
        (0.0, -0.92, 1.14, 0.24, 0.22, 16),
        (0.0, -0.68, 1.02, 0.28, 0.28, 30),
        (0.0, -0.38, 0.88, 0.36, 0.38, 8),
        (0.0,  0.05, 0.80, 0.32, 0.34, 0),
        (0.0,  0.42, 0.76, 0.26, 0.28, -6),
        (0.0,  0.72, 0.78, 0.30, 0.32, -10),
        (0.0,  0.95, 0.75, 0.16, 0.18, -12)
    ]
    chest = build_lofted_mesh("Chest", wolf_profile, segs=16, material=mat_fur, subsurf=2, flatten_bottom=True)

    # 2. Cabeça / Mandíbula com Presas
    head = add_bone_segment("Head", (0.0, -1.15, 1.10), (0.0, -1.50, 1.00), 0.20, 0.12, mat_fur, segs=10)
    jaw = add_bone_segment("Jaw", (0.0, -1.15, 1.00), (0.0, -1.48, 0.90), 0.14, 0.08, mat_fur, segs=8)

    for mult in [-1, 1]:
        add_bone_segment(f"Fang_{mult}", (0.07 * mult, -1.52, 0.95), (0.07 * mult, -1.52, 0.82), 0.022, 0.005, mat_tooth, segs=6)
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.03, location=(0.11 * mult, -1.25, 1.12))
        eye = bpy.context.active_object
        eye.name = f"Eye_{mult}"
        eye.data.materials.append(mat_eye)
        add_bone_segment(f"Ear_{mult}", (0.13 * mult, -1.02, 1.25), (0.17 * mult, -0.96, 1.48), 0.07, 0.01, mat_fur, segs=6)

    # 3. 7 Espinhos Ósseos Dorsais na Coluna
    for i in range(7):
        y_pos = -0.58 + i * 0.20
        h_base = 1.08 - abs(i - 2) * 0.03
        h_tip = h_base + 0.26 + (0.06 if i in [1, 2, 3] else 0.0)
        add_bone_segment(f"SpineSpike_{i}", (0.0, y_pos, h_base), (0.0, y_pos + 0.04, h_tip), 0.048, 0.008, mat_bone, segs=8)

    # 4. 4 Patas Articuladas de Predador
    for mult in [-1, 1]:
        p_top = (0.26 * mult, -0.45, 0.75)
        p_knee = (0.28 * mult, -0.38, 0.42)
        p_paw = (0.28 * mult, -0.42, 0.08)
        p_pad = (0.28 * mult, -0.54, 0.06)
        add_bone_segment(f"LegF_Thigh_{mult}", p_top, p_knee, 0.12, 0.08, mat_fur, segs=10)
        add_bone_segment(f"LegF_{mult}", p_knee, p_paw, 0.08, 0.06, mat_fur, segs=10)
        add_bone_segment(f"PawF_{mult}", p_paw, p_pad, 0.07, 0.05, mat_fur, segs=8)

        pb_top = (0.24 * mult, 0.65, 0.72)
        pb_knee = (0.26 * mult, 0.50, 0.38)
        pb_paw = (0.26 * mult, 0.58, 0.08)
        pb_pad = (0.26 * mult, 0.50, 0.06)
        add_bone_segment(f"LegB_Thigh_{mult}", pb_top, pb_knee, 0.14, 0.09, mat_fur, segs=10)
        add_bone_segment(f"LegB_{mult}", pb_knee, pb_paw, 0.09, 0.06, mat_fur, segs=10)
        add_bone_segment(f"PawB_{mult}", pb_paw, pb_pad, 0.07, 0.05, mat_fur, segs=8)

    # 5. Cauda Predatória Curvada
    tail = add_bone_segment("Tail", (0.0, 0.90, 0.74), (0.0, 1.48, 0.92), 0.07, 0.015, mat_fur, segs=8)

    export_model("wolf_spine.glb")

# ====================================================================
# 3. ROOT GOLEM COLOSSUS (DARK FANTASY COLOSSUS)
# ====================================================================
def build_root_golem():
    reset()
    mat_bark = mat("AncientBarkRough", (0.16, 0.11, 0.08, 1.0), rough=0.92)
    mat_stone = mat("BasaltGolemArmor", (0.17, 0.18, 0.19, 1.0), rough=0.75)
    mat_core = mat("SapBioluminescentCore", (1.0, 0.65, 0.08, 1.0), rough=0.2, emit=(1.0, 0.55, 0.05, 1.0), strength=2.2)

    # 1. Tronco Contínuo Esculpido (Colosso Monumental)
    golem_profile = [
        (0.0, -0.06, 2.15, 0.36, 0.30, 15),
        (0.0, -0.04, 1.95, 0.68, 0.46, 6),
        (0.0, -0.08, 1.70, 0.62, 0.44, 0),
        (0.0, -0.04, 1.42, 0.52, 0.38, -4),
        (0.0,  0.00, 1.15, 0.54, 0.42, 0)
    ]
    torso = build_lofted_mesh("Torso", golem_profile, segs=16, material=mat_bark, subsurf=2)

    # 2. Núcleo de Seiva Bioluminescente no Peito (SapCore)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.22, location=(0.0, -0.28, 1.68))
    core = bpy.context.active_object
    core.name = "SapCore"
    core.scale = (1.0, 0.65, 1.1)
    core.data.materials.append(mat_core)

    # 3. Cabeça Monolítica de Pedra
    head = add_bone_segment("Head", (0.0, -0.10, 2.15), (0.0, -0.25, 2.38), 0.32, 0.26, mat_stone, segs=8, bevel=0.04)
    jaw = add_bone_segment("Jaw", (0.0, -0.15, 2.12), (0.0, -0.30, 2.05), 0.24, 0.14, mat_stone, segs=8, bevel=0.03)

    # 4. Ombros Maciços de Granito
    for mult in [-1, 1]:
        add_bone_segment(f"ShoulderRock_{mult}", (0.60 * mult, 0.0, 1.90), (0.78 * mult, 0.0, 1.98), 0.32, 0.30, mat_stone, segs=8, bevel=0.04)

    # 5. Braços e Punhos Pesados de Rocha
    add_bone_segment("Arm_L", (-0.68, 0.0, 1.85), (-0.88, -0.22, 1.15), 0.22, 0.18, mat_bark, segs=10)
    add_bone_segment("Forearm_L", (-0.88, -0.22, 1.15), (-0.85, -0.45, 0.62), 0.18, 0.24, mat_stone, segs=10, bevel=0.03)
    add_bone_segment("Hand_L", (-0.85, -0.45, 0.62), (-0.85, -0.55, 0.52), 0.22, 0.20, mat_stone, segs=8, bevel=0.04)

    add_bone_segment("Arm_R", (0.68, 0.0, 1.85), (0.88, -0.22, 1.15), 0.22, 0.18, mat_bark, segs=10)
    add_bone_segment("Forearm_R", (0.88, -0.22, 1.15), (0.85, -0.45, 0.62), 0.18, 0.24, mat_stone, segs=10, bevel=0.03)
    add_bone_segment("Hand_R", (0.85, -0.45, 0.62), (0.85, -0.55, 0.52), 0.22, 0.20, mat_stone, segs=8, bevel=0.04)

    # 6. Pernas Monumentais
    for mult in [-1, 1]:
        add_bone_segment(f"Thigh_{mult}", (0.35 * mult, 0.0, 1.15), (0.38 * mult, -0.05, 0.55), 0.25, 0.20, mat_bark, segs=10)
        add_bone_segment(f"Shin_{mult}", (0.38 * mult, -0.05, 0.55), (0.40 * mult, 0.02, 0.12), 0.20, 0.26, mat_stone, segs=10, bevel=0.03)
        add_bone_segment(f"Foot_{mult}", (0.40 * mult, 0.02, 0.12), (0.40 * mult, -0.20, 0.06), 0.24, 0.16, mat_stone, segs=8, bevel=0.04)

    export_model("root_golem.glb")

# ====================================================================
# 4. SHADE WRAITH (DARK FANTASY SPECTRAL REAPER)
# ====================================================================
def build_shade_wraith():
    reset()
    mat_shroud = mat("WraithDarkShroud", (0.05, 0.07, 0.09, 1.0), rough=0.82)
    mat_bone_scythe = mat("SpectralBoneClaw", (0.65, 0.72, 0.75, 1.0), rough=0.35, metal=0.45)
    mat_void = mat("ObsidianVoidShard", (0.02, 0.03, 0.04, 1.0), rough=0.15, metal=0.92)
    mat_eye = mat("SpectralSoulEye", (0.15, 0.85, 1.0, 1.0), rough=0.2, emit=(0.12, 0.85, 1.0, 1.0), strength=2.5)

    # 1. Manto Espectral Contínuo Esculpido (Capuz -> Torso -> Manto Flutuante)
    wraith_profile = [
        (0.0,  0.06, 2.22, 0.12, 0.16, -15),
        (0.0, -0.08, 1.96, 0.24, 0.28, 0),
        (0.0, -0.04, 1.70, 0.32, 0.24, 10),
        (0.0, -0.02, 1.45, 0.30, 0.22, 6),
        (0.0,  0.04, 1.15, 0.38, 0.28, 0),
        (0.0,  0.10, 0.75, 0.44, 0.32, -8),
        (0.0,  0.18, 0.35, 0.20, 0.16, -15)
    ]
    torso = build_lofted_mesh("Torso", wraith_profile, segs=16, material=mat_shroud, subsurf=2)

    # Aliases requeridos para compatibilidade de testes
    shroud_base = add_bone_segment("ShroudBase", (0.0, 0.0, 1.25), (0.0, 0.05, 1.45), 0.28, 0.26, mat_shroud, segs=8)
    hood = add_bone_segment("Hood", (0.0, -0.08, 1.95), (0.0, 0.04, 2.18), 0.22, 0.14, mat_shroud, segs=8)
    head = add_bone_segment("Head", (0.0, -0.08, 1.92), (0.0, -0.16, 1.90), 0.20, 0.18, mat_shroud, segs=8)
    void_face = add_bone_segment("VoidFace", (0.0, -0.14, 1.90), (0.0, -0.22, 1.88), 0.16, 0.12, mat_void, segs=6)

    # Olhos Fogo Fátuo Ciano
    for mult in [-1, 1]:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.03, location=(0.08 * mult, -0.20, 1.94))
        eye = bpy.context.active_object
        eye.name = f"Eye_{mult}"
        eye.data.materials.append(mat_eye)

    # 2. Braços com Lâminas de Foice Óssea Acurvada
    add_bone_segment("Arm_L", (-0.35, 0.0, 1.55), (-0.58, -0.22, 1.15), 0.10, 0.07, mat_shroud, segs=8)
    add_bone_segment("Forearm_L", (-0.58, -0.22, 1.15), (-0.68, -0.42, 0.85), 0.08, 0.06, mat_shroud, segs=8)
    add_bone_segment("Scythe_L", (-0.68, -0.42, 0.85), (-0.88, -0.80, 0.55), 0.07, 0.008, mat_bone_scythe, segs=8, bevel=0.025)

    add_bone_segment("Arm_R", (0.35, 0.0, 1.55), (0.58, -0.22, 1.15), 0.10, 0.07, mat_shroud, segs=8)
    add_bone_segment("Forearm_R", (0.58, -0.22, 1.15), (0.68, -0.42, 0.85), 0.08, 0.06, mat_shroud, segs=8)
    add_bone_segment("Scythe_R", (0.68, -0.42, 0.85), (0.88, -0.80, 0.55), 0.07, 0.008, mat_bone_scythe, segs=8, bevel=0.025)

    # 3. 5 Estilhaços de Obsidiana Orbitantes
    for i in range(5):
        ang = i * (2.0 * math.pi / 5.0)
        sx = math.cos(ang) * 0.95
        sy = math.sin(ang) * 0.95
        sz = 1.35 + (0.15 if i % 2 == 0 else -0.15)
        shard = add_bone_segment(f"orbitshard_{i}", (sx, sy, sz - 0.08), (sx, sy, sz + 0.08), 0.06, 0.01, mat_void, segs=6, bevel=0.02)

    export_model("shade_wraith.glb")

print(">>> Esculpindo Mobs em Lofted BMesh Contínuo com Lâmina em Crescente...")
build_urgal_warrior()
build_wolf_spine()
build_root_golem()
build_shade_wraith()
print(">>> Todos os 4 Mobs Esculpidos em Malha Contínua com Sucesso!")
