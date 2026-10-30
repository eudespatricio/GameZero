import bpy
import bmesh
import math
from mathutils import Vector, Matrix

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

def build_solid_urgal():
    reset()

    # Materiais PBR Dark Fantasy (Diablo IV)
    # Slot 0: Pele bruta acinzentada/marrom escura de Urgal
    mat_skin = mat("UrgalSkinDark", (0.18, 0.14, 0.12, 1.0), rough=0.72, metal=0.02)
    # Slot 1: Armadura de Ferro Escuro Forjado (Gothic Dark Iron)
    mat_iron = mat("DarkIronArmor", (0.05, 0.05, 0.06, 1.0), rough=0.28, metal=0.94)
    # Slot 2: Aço Forjado de Batalha Ensanguentado (Damascus Steel)
    mat_steel = mat("BloodiedSteel", (0.42, 0.44, 0.48, 1.0), rough=0.18, metal=0.96)
    # Slot 3: Chifres Antigos de Carneiro de Guerra (Bone/Horn)
    mat_horn = mat("AncientHornRidge", (0.35, 0.30, 0.22, 1.0), rough=0.52, metal=0.04)
    # Slot 4: Olhos Demoníacos Flamejantes
    mat_eye = mat("DemonicEyeGlow", (1.0, 0.22, 0.02, 1.0), rough=0.1, emit=(1.0, 0.25, 0.02, 1.0), strength=4.5)
    # Slot 5: Detalhes de Latão Escuro Envelhecido / Guarnições
    mat_trim = mat("DarkBrassTrim", (0.28, 0.22, 0.10, 1.0), rough=0.32, metal=0.88)

    # =========================================================================
    # 1. CORPO PRINCIPAL UNIFICADO E MACIÇO 3D (TORSO)
    # =========================================================================
    bm = bmesh.new()

    def add_volumetric_rings(profile, segs=14, mat_idx=0, is_smooth=True):
        rings = []
        for x, y, z, rx, ry, pitch in profile:
            ring = []
            rad_p = math.radians(pitch)
            cos_p = math.cos(rad_p)
            sin_p = math.sin(rad_p)
            for i in range(segs):
                ang = (2.0 * math.pi * i) / segs
                lx = math.cos(ang) * rx
                ly = math.sin(ang) * ry
                wy = y + ly * cos_p
                wz = z + ly * sin_p
                wx = x + lx
                v = bm.verts.new((wx, wy, wz))
                ring.append(v)
            rings.append(ring)
        for r_idx in range(len(rings) - 1):
            r1 = rings[r_idx]
            r2 = rings[r_idx + 1]
            for i in range(segs):
                ni = (i + 1) % segs
                f = bm.faces.new((r1[i], r1[ni], r2[ni], r2[i]))
                f.material_index = mat_idx
                f.smooth = is_smooth
        if len(rings[0]) >= 3:
            f0 = bm.faces.new(rings[0][::-1])
            f0.material_index = mat_idx
            f0.smooth = is_smooth
        if len(rings[-1]) >= 3:
            f1 = bm.faces.new(rings[-1])
            f1.material_index = mat_idx
            f1.smooth = is_smooth
        return rings

    # 1.1 Torso Muscular de Bárbaro V-Taper (3D Volumétrico: rx=Largura, ry=Profundidade)
    torso_profile = [
        (0.0, -0.04, 1.84, 0.22, 0.20, 12),
        (0.0, -0.04, 1.70, 0.48, 0.36, 6),
        (0.0, -0.06, 1.50, 0.46, 0.34, 0),
        (0.0, -0.04, 1.32, 0.40, 0.30, -4),
        (0.0, -0.02, 1.15, 0.36, 0.28, -6),
        (0.0,  0.00, 0.98, 0.38, 0.30, -2),
        (0.0,  0.00, 0.86, 0.32, 0.26, 0)
    ]
    add_volumetric_rings(torso_profile, segs=16, mat_idx=0, is_smooth=True)

    # 1.2 Coxas e Joelhos Musculares 3D (Cilindros Sólidos com Espessura)
    for mult in [-1, 1]:
        leg_skin_profile = [
            (0.22 * mult, 0.00, 0.92, 0.18, 0.18, 0),
            (0.24 * mult, -0.04, 0.72, 0.17, 0.17, 2),
            (0.24 * mult, -0.07, 0.50, 0.15, 0.15, 4)
        ]
        add_volumetric_rings(leg_skin_profile, segs=12, mat_idx=0, is_smooth=True)

        # Botas e Caneleiras de Ferro Escuro Forjado 3D
        greaves_profile = [
            (0.24 * mult, -0.07, 0.52, 0.16, 0.16, 4),
            (0.24 * mult, -0.02, 0.30, 0.15, 0.15, 0),
            (0.24 * mult, 0.02, 0.12, 0.13, 0.14, -2),
            (0.24 * mult, -0.14, 0.04, 0.14, 0.22, -10) # Bota com bico e calcanhar profundo
        ]
        add_volumetric_rings(greaves_profile, segs=12, mat_idx=1, is_smooth=False)

    # 1.3 Braços Musculares 3D (Cilindros com Volume)
    for mult in [-1, 1]:
        arm_skin_profile = [
            (0.48 * mult, -0.02, 1.56, 0.16, 0.16, 0),
            (0.58 * mult, -0.10, 1.32, 0.15, 0.15, 10),
            (0.56 * mult, -0.22, 1.08, 0.14, 0.14, 15)
        ]
        add_volumetric_rings(arm_skin_profile, segs=12, mat_idx=0, is_smooth=True)

        # Manoplas de Ferro Negro com Rebites 3D
        gauntlet_profile = [
            (0.56 * mult, -0.22, 1.10, 0.15, 0.15, 15),
            (0.52 * mult, -0.38, 0.88, 0.14, 0.14, 20),
            (0.50 * mult, -0.48, 0.78, 0.12, 0.13, 25)
        ]
        add_volumetric_rings(gauntlet_profile, segs=12, mat_idx=1, is_smooth=False)

    # 1.4 Peitoral e Cinto de Ferro Envolvente 3D (Cobre Frente e Costas)
    chest_plate_profile = [
        (0.0, -0.04, 1.68, 0.50, 0.38, 6),
        (0.0, -0.06, 1.52, 0.49, 0.37, 2),
        (0.0, -0.04, 1.34, 0.43, 0.33, -4),
        (0.0, -0.02, 1.18, 0.39, 0.30, -6)
    ]
    add_volumetric_rings(chest_plate_profile, segs=12, mat_idx=1, is_smooth=False)

    belt_profile = [
        (0.0, 0.0, 0.90, 0.40, 0.32, 0),
        (0.0, 0.0, 1.06, 0.41, 0.33, 0)
    ]
    add_volumetric_rings(belt_profile, segs=12, mat_idx=5, is_smooth=False)

    # 1.5 Ombreiras Góticas 3D
    for mult in [-1, 1]:
        pld_profile = [
            (0.44 * mult, -0.02, 1.58, 0.23, 0.25, 0),
            (0.60 * mult, -0.02, 1.66, 0.21, 0.23, 10),
            (0.74 * mult, -0.04, 1.88, 0.08, 0.09, 25)
        ]
        add_volumetric_rings(pld_profile, segs=8, mat_idx=1, is_smooth=False)

    # 1.6 Chifres de Carneiro Arcaicos 3D
    for mult in [-1, 1]:
        horn_profile = [
            (0.14 * mult, -0.16, 1.96, 0.11, 0.11, 0),
            (0.28 * mult, -0.10, 2.14, 0.09, 0.09, 15),
            (0.38 * mult, 0.06, 2.06, 0.08, 0.08, 30),
            (0.36 * mult, 0.16, 1.84, 0.06, 0.06, 45),
            (0.26 * mult, 0.04, 1.66, 0.035, 0.035, 60),
            (0.18 * mult, -0.10, 1.62, 0.015, 0.015, 75)
        ]
        add_volumetric_rings(horn_profile, segs=10, mat_idx=3, is_smooth=True)

    # 1.7 Machado de Guerra Brutal 3D (WarAxe)
    axe_shaft_profile = [
        (0.50, -0.42, 0.25, 0.038, 0.038, 0),
        (0.50, -0.52, 0.78, 0.036, 0.036, 0),
        (0.50, -0.66, 1.35, 0.036, 0.036, 0),
        (0.50, -0.74, 1.72, 0.038, 0.038, 0)
    ]
    add_volumetric_rings(axe_shaft_profile, segs=8, mat_idx=1, is_smooth=False)

    # Lâmina de Aço de Damasco Cortante em Crescente com Bisel Duplo 3D
    blade_segs = 14
    v_axe_spine = []
    v_axe_edge_f = []
    v_axe_edge_b = []
    for i in range(blade_segs):
        t = float(i) / (blade_segs - 1)
        z_pos = 1.32 + t * 0.42
        curv = math.sin(t * math.pi)

        sp_f = bm.verts.new((0.50 - 0.02, -0.70, z_pos))
        sp_b = bm.verts.new((0.50 + 0.02, -0.70, z_pos))
        v_axe_spine.append((sp_f, sp_b))

        y_front = -0.70 - (0.14 + curv * 0.48)
        v_f = bm.verts.new((0.50, y_front, z_pos))
        v_axe_edge_f.append(v_f)

        y_back = -0.70 + (0.08 + curv * 0.28)
        v_b = bm.verts.new((0.50, y_back, z_pos))
        v_axe_edge_b.append(v_b)

    for i in range(blade_segs - 1):
        f1 = bm.faces.new((v_axe_spine[i][0], v_axe_spine[i + 1][0], v_axe_edge_f[i + 1], v_axe_edge_f[i]))
        f1.material_index = 2
        f1.smooth = False
        f2 = bm.faces.new((v_axe_spine[i][1], v_axe_edge_f[i], v_axe_edge_f[i + 1], v_axe_spine[i + 1][1]))
        f2.material_index = 2
        f2.smooth = False

        f3 = bm.faces.new((v_axe_spine[i][0], v_axe_edge_b[i], v_axe_edge_b[i + 1], v_axe_spine[i + 1][0]))
        f3.material_index = 2
        f3.smooth = False
        f4 = bm.faces.new((v_axe_spine[i][1], v_axe_spine[i + 1][1], v_axe_edge_b[i + 1], v_axe_edge_b[i]))
        f4.material_index = 2
        f4.smooth = False

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh_torso = bpy.data.meshes.new("Torso_Mesh")
    bm.to_mesh(mesh_torso)
    bm.free()

    obj_torso = bpy.data.objects.new("Torso", mesh_torso)
    bpy.context.collection.objects.link(obj_torso)
    bpy.context.view_layer.objects.active = obj_torso
    
    obj_torso.data.materials.append(mat_skin)
    obj_torso.data.materials.append(mat_iron)
    obj_torso.data.materials.append(mat_steel)
    obj_torso.data.materials.append(mat_horn)
    obj_torso.data.materials.append(mat_eye)
    obj_torso.data.materials.append(mat_trim)

    # 2. CABEÇA E MANDÍBULA 3D (Com pivots anatômicos ancorados no pescoço/dobradiça)
    head_pivot = (0.0, -0.04, 1.84)
    bm_head = bmesh.new()
    head_profile = [
        (0.0, -0.04, 1.84, 0.18, 0.18, 12),
        (0.0, -0.10, 1.92, 0.22, 0.22, 6),
        (0.0, -0.18, 1.97, 0.23, 0.23, 0),
        (0.0, -0.26, 1.92, 0.20, 0.20, -10),
        (0.0, -0.32, 1.82, 0.14, 0.16, -20)
    ]
    h_rings = []
    for x, y, z, rx, ry, pitch in head_profile:
        r = []
        rad_p = math.radians(pitch)
        cos_p = math.cos(rad_p)
        sin_p = math.sin(rad_p)
        for i in range(12):
            ang = (2.0 * math.pi * i) / 12
            lx = math.cos(ang) * rx
            ly = math.sin(ang) * ry
            vx = (x + lx) - head_pivot[0]
            vy = (y + ly * cos_p) - head_pivot[1]
            vz = (z + ly * sin_p) - head_pivot[2]
            r.append(bm_head.verts.new((vx, vy, vz)))
        h_rings.append(r)
    for r_idx in range(len(h_rings) - 1):
        for i in range(12):
            ni = (i + 1) % 12
            f = bm_head.faces.new((h_rings[r_idx][i], h_rings[r_idx][ni], h_rings[r_idx + 1][ni], h_rings[r_idx + 1][i]))
            f.material_index = 0
            f.smooth = True
    f_top = bm_head.faces.new(h_rings[0][::-1])
    f_top.material_index = 0
    f_bot = bm_head.faces.new(h_rings[-1])
    f_bot.material_index = 0

    # Olhos Demoníacos Flamejantes 3D
    for eye_x in [-0.08, 0.08]:
        eye_center = Vector((eye_x - head_pivot[0], -0.32 - head_pivot[1], 1.91 - head_pivot[2]))
        for i in range(6):
            ang = float(i) * math.pi / 3.0
            p1 = eye_center + Vector((math.cos(ang)*0.035, 0, math.sin(ang)*0.035))
            p2 = eye_center + Vector((math.cos(ang + math.pi/3.0)*0.035, 0, math.sin(ang + math.pi/3.0)*0.035))
            f_eye = bm_head.faces.new((bm_head.verts.new(eye_center), bm_head.verts.new(p1), bm_head.verts.new(p2)))
            f_eye.material_index = 1
            f_eye.smooth = False

    bmesh.ops.recalc_face_normals(bm_head, faces=bm_head.faces)
    mesh_head = bpy.data.meshes.new("Head_Mesh")
    bm_head.to_mesh(mesh_head)
    bm_head.free()

    obj_head = bpy.data.objects.new("Head", mesh_head)
    obj_head.location = head_pivot
    bpy.context.collection.objects.link(obj_head)
    obj_head.data.materials.append(mat_skin)
    obj_head.data.materials.append(mat_eye)

    # 2.2 Mandíbula 3D (Jaw - Pivot na dobradiça da mandíbula)
    jaw_pivot = (0.0, -0.16, 1.78)
    bm_jaw = bmesh.new()
    jaw_v0 = bm_jaw.verts.new((0.0 - jaw_pivot[0], -0.16 - jaw_pivot[1], 1.78 - jaw_pivot[2]))
    jaw_v1 = bm_jaw.verts.new((-0.10 - jaw_pivot[0], -0.22 - jaw_pivot[1], 1.76 - jaw_pivot[2]))
    jaw_v2 = bm_jaw.verts.new((0.10 - jaw_pivot[0], -0.22 - jaw_pivot[1], 1.76 - jaw_pivot[2]))
    jaw_v3 = bm_jaw.verts.new((0.0 - jaw_pivot[0], -0.34 - jaw_pivot[1], 1.72 - jaw_pivot[2]))
    jaw_v_back = bm_jaw.verts.new((0.0 - jaw_pivot[0], -0.20 - jaw_pivot[1], 1.68 - jaw_pivot[2]))
    bm_jaw.faces.new((jaw_v0, jaw_v1, jaw_v3))
    bm_jaw.faces.new((jaw_v0, jaw_v3, jaw_v2))
    bm_jaw.faces.new((jaw_v3, jaw_v1, jaw_v_back))
    bm_jaw.faces.new((jaw_v3, jaw_v_back, jaw_v2))
    bmesh.ops.recalc_face_normals(bm_jaw, faces=bm_jaw.faces)
    mesh_jaw = bpy.data.meshes.new("Jaw_Mesh")
    bm_jaw.to_mesh(mesh_jaw)
    bm_jaw.free()

    obj_jaw = bpy.data.objects.new("Jaw", mesh_jaw)
    obj_jaw.location = jaw_pivot
    bpy.context.collection.objects.link(obj_jaw)
    obj_jaw.data.materials.append(mat_skin)

    # Exportar modelo sólido glTF com Torso, Head e Jaw ancorados
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_apply=False)
    print("=== SÓLIDO PBR 3D VOLUMÉTRICO: Urgal Kull Barbarian Exportado com Sucesso: " + OUT + " ===")

build_solid_urgal()
