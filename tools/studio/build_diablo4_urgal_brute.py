import bpy
import bmesh
import math
from mathutils import Vector, Matrix, Euler, Quaternion

OUT = "/home/eudespatricio/Games/GameZero/assets/models/urgal_warrior.glb"

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

def build_lofted_mesh(name, profile, segs=16, material=None, subsurf=1, parent=None):
    """
    Constrói malha contínua através de lofting de anéis anatômicos.
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
    if parent:
        obj.parent = parent
    return obj

def create_joint_segment(name, p_start, p_end, r_start, r_end, material, segs=12, parent=None, bevel=0.0):
    """
    Cria segmento anatômico onde a ORIGEM do objeto é colocada exatamente na ARTICULAÇÃO (p_start).
    Isso impede completamente que joelhos, cotovelos ou quadris se desconectem ao girar!
    """
    v_start = Vector(p_start)
    v_end = Vector(p_end)
    diff = v_end - v_start
    length = max(diff.length, 0.001)

    bm = bmesh.new()
    # Construir cilindro orientado ao longo do eixo Z local, com a base Z=0 na articulação
    base_ring = []
    tip_ring = []
    for i in range(segs):
        ang = (2.0 * math.pi * i) / segs
        bx = math.cos(ang) * r_start
        by = math.sin(ang) * r_start
        base_ring.append(bm.verts.new((bx, by, 0.0)))

        tx = math.cos(ang) * r_end
        ty = math.sin(ang) * r_end
        tip_ring.append(bm.verts.new((tx, ty, length)))

    bm.verts.ensure_lookup_table()
    for i in range(segs):
        ni = (i + 1) % segs
        bm.faces.new((base_ring[i], base_ring[ni], tip_ring[ni], tip_ring[i]))
    bm.faces.new(base_ring[::-1])
    bm.faces.new(tip_ring)

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

    mesh = bpy.data.meshes.new(name + "_Mesh")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)

    # Orientar para apontar de p_start para p_end
    quat = diff.normalized().to_track_quat('Z', 'Y')
    obj.location = v_start
    obj.rotation_mode = 'QUATERNION'
    obj.rotation_quaternion = quat

    if parent:
        # Manter matriz de transformação no espaço do pai
        obj.parent = parent
        obj.matrix_parent_inverse = parent.matrix_world.inverted()

    if bevel > 0.0:
        bev = obj.modifiers.new("Bevel", 'BEVEL')
        bev.width = bevel
        bev.segments = 2
        bev.limit_method = 'ANGLE'

    smooth(obj)
    if material:
        obj.data.materials.append(material)
    return obj

def build_curved_blade(name, origin, direction, width=0.55, height=0.75, thickness=0.04, material=None, parent=None, is_reverse=False):
    bm = bmesh.new()
    segs = 12
    v_spine = []
    v_edge = []

    dir_vec = Vector(direction).normalized()
    side_vec = Vector((1.0, 0.0, 0.0))
    up_vec = side_vec.cross(dir_vec).normalized()

    half_th = thickness * 0.5

    for i in range(segs):
        t = float(i) / (segs - 1)
        curv = math.sin(t * math.pi)
        h_offset = (t - 0.5) * height
        ext = curv * width if not is_reverse else (1.0 - curv * 0.4) * width * 0.6

        p_sp = Vector(origin) + up_vec * h_offset
        p_ed = p_sp + dir_vec * ext

        v_s_l = bm.verts.new(p_sp - side_vec * half_th)
        v_s_r = bm.verts.new(p_sp + side_vec * half_th)
        v_spine.append((v_s_l, v_s_r))

        v_e_l = bm.verts.new(p_ed - side_vec * 0.003)
        v_e_r = bm.verts.new(p_ed + side_vec * 0.003)
        v_edge.append((v_e_l, v_e_r))

    bm.verts.ensure_lookup_table()

    for i in range(segs - 1):
        s1_l, s1_r = v_spine[i]
        s2_l, s2_r = v_spine[i + 1]
        e1_l, e1_r = v_edge[i]
        e2_l, e2_r = v_edge[i + 1]

        bm.faces.new((s1_l, s2_l, e2_l, e1_l))
        bm.faces.new((s1_r, e1_r, e2_r, s2_r))
        bm.faces.new((s1_l, s1_r, s2_r, s2_l))
        bm.faces.new((e1_l, e2_l, e2_r, e1_r))

    bm.faces.new((v_spine[0][0], v_edge[0][0], v_edge[0][1], v_spine[0][1]))
    bm.faces.new((v_spine[-1][0], v_spine[-1][1], v_edge[-1][1], v_edge[-1][0]))

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name + "_Mesh")
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    smooth(obj)
    if material:
        obj.data.materials.append(material)
    if parent:
        obj.parent = parent
        obj.matrix_parent_inverse = parent.matrix_world.inverted()
    return obj

def build_urgal_brute():
    reset()
    mat_skin = mat("UrgalSkinDark", (0.24, 0.18, 0.15, 1.0), rough=0.72)
    mat_iron = mat("DarkIronArmor", (0.08, 0.09, 0.11, 1.0), rough=0.30, metal=0.92)
    mat_iron_trim = mat("DarkIronTrim", (0.15, 0.16, 0.18, 1.0), rough=0.22, metal=0.95)
    mat_horn = mat("AncientHornRidge", (0.22, 0.18, 0.14, 1.0), rough=0.58)
    mat_steel = mat("BloodiedSteel", (0.32, 0.33, 0.35, 1.0), rough=0.20, metal=0.96)
    mat_eye = mat("DemonicEyeGlow", (1.0, 0.20, 0.02, 1.0), rough=0.2, emit=(1.0, 0.18, 0.02, 1.0), strength=2.8)
    mat_blood = mat("AxeBloodStain", (0.35, 0.02, 0.02, 1.0), rough=0.32, metal=0.15)

    # 1. Torso Maciço V-Taper (Pescoço -> Peito -> Cintura -> Pelve)
    torso_profile = [
        (0.0, -0.06, 1.82, 0.18, 0.18, 12),
        (0.0, -0.04, 1.68, 0.46, 0.26, 6),
        (0.0, -0.08, 1.50, 0.44, 0.28, 0),
        (0.0, -0.05, 1.32, 0.38, 0.24, -4),
        (0.0, -0.02, 1.15, 0.34, 0.22, -6),
        (0.0,  0.00, 0.98, 0.36, 0.25, -2),
        (0.0,  0.00, 0.88, 0.28, 0.20, 0)
    ]
    torso = build_lofted_mesh("Torso", torso_profile, segs=16, material=mat_skin, subsurf=2)

    # 2. Cabeça Brutal e Mandíbula (Head e Jaw requeridos pelos testes)
    head_profile = [
        (0.0, -0.04, 1.82, 0.18, 0.18, 15),
        (0.0, -0.10, 1.90, 0.23, 0.23, 8),
        (0.0, -0.18, 1.95, 0.24, 0.20, 0),
        (0.0, -0.26, 1.90, 0.20, 0.16, -10),
        (0.0, -0.32, 1.80, 0.14, 0.10, -20)
    ]
    head = build_lofted_mesh("Head", head_profile, segs=14, material=mat_skin, subsurf=1, parent=torso)
    jaw = create_joint_segment("Jaw", (0.0, -0.18, 1.78), (0.0, -0.32, 1.72), 0.15, 0.08, mat_skin, segs=8, parent=head)

    # Olhos Brilhantes
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.035, location=(-0.09, -0.29, 1.89))
    eye_l = bpy.context.active_object
    eye_l.name = "Eye_-1"
    eye_l.parent = head
    eye_l.data.materials.append(mat_eye)

    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.035, location=(0.09, -0.29, 1.89))
    eye_r = bpy.context.active_object
    eye_r.name = "Eye_1"
    eye_r.parent = head
    eye_r.data.materials.append(mat_eye)

    # 3. Chifres Demoníacos Curvados
    for mult in [-1, 1]:
        h0 = (0.16 * mult, -0.18, 1.98)
        h1 = (0.32 * mult, -0.10, 2.12)
        h2 = (0.38 * mult, 0.08, 2.05)
        h3 = (0.35 * mult, 0.12, 1.82)
        h4 = (0.24 * mult, -0.08, 1.68)
        create_joint_segment(f"Horn1_{mult}", h0, h1, 0.10, 0.08, mat_horn, segs=10, parent=head)
        create_joint_segment(f"Horn2_{mult}", h1, h2, 0.08, 0.06, mat_horn, segs=10, parent=head)
        create_joint_segment(f"Horn3_{mult}", h2, h3, 0.06, 0.04, mat_horn, segs=8, parent=head)
        create_joint_segment(f"Horn4_{mult}", h3, h4, 0.04, 0.012, mat_horn, segs=8, parent=head)

    # 4. Armadura de Ferro Forjado Peitoral e Cinturão
    create_joint_segment("ChestArmorPlate", (0.0, -0.16, 1.38), (0.0, -0.18, 1.60), 0.40, 0.44, mat_iron, segs=12, bevel=0.03, parent=torso)
    create_joint_segment("PelvisGirdle", (0.0, 0.0, 0.90), (0.0, 0.0, 1.05), 0.35, 0.37, mat_iron, segs=12, bevel=0.03, parent=torso)

    # 5. Ombreiras Escalonadas com Espigões
    for mult in [-1, 1]:
        pld = create_joint_segment(f"Pauldrons_{mult}", (0.42 * mult, -0.02, 1.55), (0.60 * mult, -0.02, 1.62), 0.22, 0.24, mat_iron, segs=8, bevel=0.03, parent=torso)
        create_joint_segment(f"PauldronsSpike_{mult}", (0.58 * mult, 0.0, 1.65), (0.80 * mult, -0.04, 2.02), 0.06, 0.01, mat_iron_trim, segs=6, parent=pld)

    # 6. Membros Inferiores Articulados com Origem nas Juntas (Thigh -> Shin -> Foot)
    for mult in [-1, 1]:
        p_hip = (0.22 * mult, 0.0, 0.94)
        p_knee = (0.24 * mult, -0.06, 0.50)
        p_ankle = (0.24 * mult, 0.02, 0.10)
        p_toe = (0.24 * mult, -0.18, 0.06)

        thigh = create_joint_segment(f"Thigh_{mult}", p_hip, p_knee, 0.16, 0.12, mat_skin, segs=12, bevel=0.02, parent=torso)
        shin = create_joint_segment(f"Shin_{mult}", p_knee, p_ankle, 0.13, 0.10, mat_iron, segs=12, bevel=0.02, parent=thigh)
        foot = create_joint_segment(f"Foot_{mult}", p_ankle, p_toe, 0.10, 0.06, mat_iron, segs=8, bevel=0.02, parent=shin)

    # 7. Membros Superiores (Arm -> Forearm -> Hand)
    for mult, suffix in [(-1, "L"), (1, "R")]:
        p_shoulder = (0.48 * mult, 0.0, 1.52)
        p_elbow = (0.58 * mult, -0.20, 1.08)
        p_wrist = (0.52 * mult, -0.44, 0.88)
        p_hand = (0.50 * mult, -0.54, 0.84)

        arm = create_joint_segment(f"Arm_{suffix}", p_shoulder, p_elbow, 0.14, 0.11, mat_skin, segs=10, parent=torso)
        forearm = create_joint_segment(f"Forearm_{suffix}", p_elbow, p_wrist, 0.12, 0.10, mat_iron, segs=10, bevel=0.02, parent=arm)
        hand = create_joint_segment(f"Hand_{suffix}", p_wrist, p_hand, 0.09, 0.07, mat_iron, segs=8, parent=forearm)

        if suffix == "R":
            # 8. Machado de Guerra (WarAxe) empunhado firmemente na mão direita
            axe_root = (0.50, -0.35, 0.30)
            axe_head = (0.50, -0.75, 1.68)
            axe = create_joint_segment("WarAxeShaft", axe_root, axe_head, 0.038, 0.036, mat_iron, segs=8, bevel=0.015, parent=hand)
            build_curved_blade("AxeBladeFront", (0.50, -0.70, 1.54), (0.0, -1.0, 0.15), width=0.52, height=0.72, thickness=0.035, material=mat_steel, parent=axe)
            build_curved_blade("AxeBladeBack", (0.50, -0.70, 1.54), (0.0, 1.0, -0.10), width=0.30, height=0.44, thickness=0.03, material=mat_steel, parent=axe, is_reverse=True)
            create_joint_segment("AxeBloodDecal", (0.50, -1.08, 1.50), (0.50, -1.22, 1.58), 0.06, 0.02, mat_blood, segs=6, parent=axe)

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_apply=True)
    print("=== Diablo IV Urgal Brute Exportado com Sucesso: " + OUT + " ===")

build_urgal_brute()
