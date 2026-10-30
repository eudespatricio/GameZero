import bpy
import bmesh
import math
from mathutils import Vector, Matrix

OUT = "/home/eudespatricio/Games/GameZero/assets/models/root_golem.glb"

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def mat(name, color, rough=0.85, metal=0.0, emit=None, strength=0.0):
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

def build_solid_golem():
    reset()

    # Materiais Dark Fantasy Diablo IV
    # Slot 0: Basalto Negro Cinzelado (Chiseled Dark Basalt)
    mat_basalt = mat("BasaltGolemRock", (0.10, 0.11, 0.12, 1.0), rough=0.78, metal=0.10)
    # Slot 1: Placas de Rocha com Musgo Ancestral
    mat_moss_rock = mat("MossyStonePlates", (0.08, 0.12, 0.08, 1.0), rough=0.88, metal=0.04)
    # Slot 2: Raízes Antigas Retorcidas que Amarram as Pedras
    mat_wood = mat("AncientRootWood", (0.14, 0.09, 0.06, 1.0), rough=0.86, metal=0.02)
    # Slot 3: Núcleo de Seiva Bioluminescente Âmbar Ardente
    mat_core = mat("SapBioluminescentCore", (1.0, 0.65, 0.08, 1.0), rough=0.15, emit=(1.0, 0.55, 0.05, 1.0), strength=4.5)
    # Slot 4: Runas Ancestrais Gravadas na Rocha
    mat_rune = mat("ArcaneRuneGlow", (0.2, 0.9, 0.6, 1.0), rough=0.2, emit=(0.15, 0.85, 0.55, 1.0), strength=3.0)

    # 1. TORSO MACIÇO MONOLÍTICO (3D VOLUMÉTRICO: X=Largura, Y=Profundidade Peito-Costas, Z=Altura)
    bm = bmesh.new()

    def add_volumetric_rings(profile, segs=12, mat_idx=0, is_smooth=False):
        """
        Gera anéis verdadeiramente volumétricos no plano horizontal X-Y com lofting ao longo de Z.
        rx = raio lateral (largura), ry = raio sagital (profundidade peito-costas).
        """
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
                # Inclinação (pitch) no plano Y-Z
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

    # Tronco de Colosso Monumental (X=Largura ~1.4m, Y=Profundidade ~1.0m, Z=Altura 2.2m)
    # Nada de fita plana: cada anel é um elipsoide 3D massivo!
    torso_profile = [
        (0.0, -0.04, 2.18, 0.44, 0.38, 10),
        (0.0, -0.06, 1.95, 0.72, 0.52, 6),
        (0.0, -0.08, 1.68, 0.68, 0.50, 0),
        (0.0, -0.04, 1.40, 0.60, 0.44, -4),
        (0.0,  0.00, 1.15, 0.58, 0.42, 0)
    ]
    add_volumetric_rings(torso_profile, segs=12, mat_idx=0, is_smooth=False)

    # Costelas de Rocha e Raízes Envolventes 3D (Slot 2: Madeira antiga)
    root_profile = [
        (0.0, -0.06, 1.82, 0.74, 0.54, 4),
        (0.0, -0.06, 1.55, 0.70, 0.52, 0),
        (0.0, -0.04, 1.28, 0.62, 0.46, -4)
    ]
    add_volumetric_rings(root_profile, segs=10, mat_idx=2, is_smooth=True)

    # Ombros Maciços de Pedregulhos Cúbicos/Poliédricos 3D
    for mult in [-1, 1]:
        shoulder_profile = [
            (0.58 * mult, -0.04, 1.90, 0.32, 0.34, 0),
            (0.84 * mult, -0.04, 2.02, 0.28, 0.30, 8),
            (1.05 * mult, -0.04, 1.96, 0.18, 0.20, 15)
        ]
        add_volumetric_rings(shoulder_profile, segs=8, mat_idx=1, is_smooth=False)

    # Braço Direito Monumental (Punho Gigante de Rocha - Cilindro 3D Completo)
    arm_r_profile = [
        (0.72, -0.04, 1.85, 0.24, 0.24, 0),
        (0.92, -0.18, 1.30, 0.24, 0.24, 10),
        (0.90, -0.38, 0.78, 0.26, 0.28, 18),
        (0.88, -0.52, 0.52, 0.28, 0.30, 22) # Punho cilíndrico massivo
    ]
    add_volumetric_rings(arm_r_profile, segs=8, mat_idx=0, is_smooth=False)

    # Braço Esquerdo Monumental (Punho Gigante de Rocha - Integrado ao Torso)
    arm_l_profile = [
        (-0.72, -0.04, 1.85, 0.24, 0.24, 0),
        (-0.92, -0.18, 1.30, 0.24, 0.24, 10),
        (-0.90, -0.38, 0.78, 0.26, 0.28, 18),
        (-0.88, -0.52, 0.52, 0.28, 0.30, 22)
    ]
    add_volumetric_rings(arm_l_profile, segs=8, mat_idx=0, is_smooth=False)

    # Pernas e Pilares de Granito 3D (Cilindros sólidos e profundos)
    for mult in [-1, 1]:
        leg_profile = [
            (0.38 * mult, 0.00, 1.15, 0.26, 0.26, 0),
            (0.42 * mult, -0.04, 0.65, 0.25, 0.25, 4),
            (0.44 * mult, 0.00, 0.18, 0.26, 0.28, -2),
            (0.44 * mult, -0.12, 0.06, 0.28, 0.36, -10) # Pedestal de rocha com base profunda
        ]
        add_volumetric_rings(leg_profile, segs=8, mat_idx=0, is_smooth=False)

    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh_torso = bpy.data.meshes.new("Torso_Mesh")
    bm.to_mesh(mesh_torso)
    bm.free()

    obj_torso = bpy.data.objects.new("Torso", mesh_torso)
    bpy.context.collection.objects.link(obj_torso)
    obj_torso.data.materials.append(mat_basalt)
    obj_torso.data.materials.append(mat_moss_rock)
    obj_torso.data.materials.append(mat_wood)
    obj_torso.data.materials.append(mat_core)
    obj_torso.data.materials.append(mat_rune)

    # 2. NÚCLEO BIOLUMINESCENTE NO PEITO (SAPCORE - Pivot centralizado)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.26, location=(0.0, -0.36, 1.68))
    core = bpy.context.active_object
    core.name = "SapCore"
    core.scale = (1.0, 0.9, 1.1)
    core.data.materials.append(mat_core)

    # 3. CABEÇA DE MONÓLITO RUNIC 3D (HEAD - Pivot anatômico no pescoço)
    head_pivot = (0.0, -0.08, 2.18)
    bm_h = bmesh.new()
    h_profile = [
        (0.0, -0.08, 2.18, 0.34, 0.32, 10),
        (0.0, -0.18, 2.38, 0.32, 0.30, 0),
        (0.0, -0.28, 2.45, 0.26, 0.26, -10),
        (0.0, -0.36, 2.32, 0.20, 0.22, -18)
    ]
    h_rings = []
    for x, y, z, rx, ry, pitch in h_profile:
        r = []
        rad_p = math.radians(pitch)
        cos_p = math.cos(rad_p)
        sin_p = math.sin(rad_p)
        for i in range(8):
            ang = (2.0 * math.pi * i) / 8
            lx = math.cos(ang) * rx
            ly = math.sin(ang) * ry
            vx = (x + lx) - head_pivot[0]
            vy = (y + ly * cos_p) - head_pivot[1]
            vz = (z + ly * sin_p) - head_pivot[2]
            r.append(bm_h.verts.new((vx, vy, vz)))
        h_rings.append(r)
    for r_idx in range(len(h_rings) - 1):
        for i in range(8):
            ni = (i + 1) % 8
            f = bm_h.faces.new((h_rings[r_idx][i], h_rings[r_idx][ni], h_rings[r_idx + 1][ni], h_rings[r_idx + 1][i]))
            f.material_index = 0
            f.smooth = False
    f_top = bm_h.faces.new(h_rings[0][::-1])
    f_top.material_index = 0
    f_bot = bm_h.faces.new(h_rings[-1])
    f_bot.material_index = 0

    # Runa Frontal na Cabeça
    r_v0 = bm_h.verts.new((0.0 - head_pivot[0], -0.42 - head_pivot[1], 2.35 - head_pivot[2]))
    r_v1 = bm_h.verts.new((-0.07 - head_pivot[0], -0.37 - head_pivot[1], 2.40 - head_pivot[2]))
    r_v2 = bm_h.verts.new((0.07 - head_pivot[0], -0.37 - head_pivot[1], 2.40 - head_pivot[2]))
    f_rune = bm_h.faces.new((r_v0, r_v1, r_v2))
    f_rune.material_index = 1
    f_rune.smooth = False

    bmesh.ops.recalc_face_normals(bm_h, faces=bm_h.faces)
    mesh_h = bpy.data.meshes.new("Head_Mesh")
    bm_h.to_mesh(mesh_h)
    bm_h.free()

    obj_h = bpy.data.objects.new("Head", mesh_h)
    obj_h.location = head_pivot
    bpy.context.collection.objects.link(obj_h)
    obj_h.data.materials.append(mat_basalt)
    obj_h.data.materials.append(mat_rune)

    # Exportar modelo sólido glTF com Torso, Head e SapCore anatomicamente ancorados
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_apply=False)
    print("=== SÓLIDO PBR 3D VOLUMÉTRICO: Root Golem Basalt Colossus Exportado com Sucesso: " + OUT + " ===")

build_solid_golem()
