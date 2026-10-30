"""
Gera criaturas para o bestiário (Blender 4.2 headless): wolf_spine.glb, root_golem.glb, shade_wraith.glb
Frente do modelo = Blender -Y (== Godot +Z). Z = altura.
Uso: blender --background --python tools/studio/generate_mob_models.py
"""
import bpy, math, random
from mathutils import Vector

OUT = "/home/eudespatricio/Games/GameZero/assets/models/"


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(name, color, rough=0.85, metal=0.0, emit=None, strength=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = color
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if emit:
        b.inputs["Emission Color"].default_value = emit
        b.inputs["Emission Strength"].default_value = strength
    return m


def finish(o, m, ang=28.0, smooth=False):
    o.data.materials.append(m)
    bpy.context.view_layer.objects.active = o
    if not smooth:
        for p in o.data.polygons:
            p.use_smooth = False
        md = o.modifiers.new("ES", "EDGE_SPLIT")
        md.use_edge_angle = True
        md.split_angle = math.radians(ang)
        bpy.ops.object.modifier_apply(modifier="ES")
    else:
        for p in o.data.polygons:
            p.use_smooth = True
    return o


def ell(name, loc, scale, m, sub=2, rot=(0, 0, 0), ang=28.0, smooth=False):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub, radius=1.0, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(scale=True, rotation=True)
    return finish(o, m, ang, smooth)


def box(name, loc, size, m, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    bpy.ops.object.transform_apply(scale=True)
    return finish(o, m, 30.0)


def cone(name, loc, r1, r2, h, m, rot=(0, 0, 0), verts=8):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r1, radius2=r2, depth=h, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    return finish(o, m, 35.0)


def limb(name, p1, p2, r1, r2, m, verts=8):
    """Cilindro/cone afunilado exatamente entre dois pontos."""
    v1, v2 = Vector(p1), Vector(p2)
    d = v2 - v1
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r1, radius2=r2, depth=d.length,
                                    location=(v1 + v2) / 2)
    o = bpy.context.active_object
    o.name = name
    o.rotation_euler = d.normalized().to_track_quat('Z', 'Y').to_euler()
    bpy.ops.object.transform_apply(rotation=True)
    return finish(o, m, 35.0)


def export(fn):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=OUT + fn, export_format="GLB")
    print("Exportado:", fn)


# ---------------------------------------------------------------
def wolf():
    reset()
    fur = mat("WolfFur", (0.34, 0.32, 0.33, 1), 0.95)
    fur2 = mat("WolfFurDark", (0.16, 0.16, 0.19, 1), 0.95)
    belly = mat("WolfBelly", (0.42, 0.40, 0.38, 1), 0.95)
    eye = mat("WolfEye", (1, 0.7, 0.1, 1), 0.3, 0, (1.0, 0.55, 0.05, 1), 6.0)
    tooth = mat("WolfTooth", (0.9, 0.88, 0.8, 1), 0.5)
    # tronco (frente = -Y)
    ell("Chest", (0, -0.45, 0.78), (0.34, 0.5, 0.36), fur)
    ell("Belly", (0, 0.05, 0.66), (0.30, 0.6, 0.30), belly)
    ell("Hip", (0, 0.62, 0.74), (0.31, 0.42, 0.33), fur)
    ell("Neck", (0, -0.88, 0.98), (0.2, 0.28, 0.24), fur, rot=(0.7, 0, 0))
    # cabeça + focinho
    ell("Skull", (0, -1.12, 1.02), (0.2, 0.26, 0.19), fur2)
    ell("Snout", (0, -1.42, 0.95), (0.11, 0.24, 0.1), fur2)
    box("Jaw", (0, -1.4, 0.85), (0.14, 0.34, 0.05), fur2)
    for sx in (-1, 1):
        cone("Ear%d" % sx, (sx * 0.12, -1.04, 1.28), 0.08, 0.0, 0.26, fur2, rot=(math.radians(-10), math.radians(sx * 10), 0), verts=4)
        ell("Eye%d" % sx, (sx * 0.11, -1.28, 1.05), (0.03, 0.03, 0.025), eye, sub=1)
        cone("Fang%d" % sx, (sx * 0.045, -1.56, 0.86), 0.015, 0.0, 0.08, tooth, rot=(math.pi, 0, 0), verts=4)
    # pernas (coxa/canela/pata)
    for sx in (-1, 1):
        for front, y in ((True, -0.55), (False, 0.7)):
            x = sx * 0.2
            top = (x, y, 0.7)
            knee = (x + sx * 0.03, y + (0.1 if front else -0.12), 0.38)
            paw = (x, y + (-0.02 if front else 0.05), 0.04)
            limb("Thigh", top, knee, 0.1, 0.06, fur, 6)
            limb("Shin", knee, paw, 0.06, 0.04, fur2, 6)
            ell("Paw", (paw[0], paw[1] - 0.05, 0.04), (0.06, 0.1, 0.04), fur2, sub=1)
    # cauda
    limb("Tail1", (0, 0.95, 0.78), (0, 1.35, 0.7), 0.08, 0.06, fur, 6)
    limb("Tail2", (0, 1.35, 0.7), (0, 1.75, 0.5), 0.06, 0.02, fur2, 6)
    # cristas dorsais
    for i in range(7):
        y = -0.7 + i * 0.22
        cone("Spike%d" % i, (0, y, 1.1 - abs(i - 3) * 0.02 + 0.0), 0.05, 0.0, 0.16, fur2, rot=(0, 0, 0), verts=4)
    export("wolf_spine.glb")


def golem():
    reset()
    stone = mat("GolemBark", (0.27, 0.19, 0.11, 1), 0.95)
    stone2 = mat("GolemBarkLight", (0.40, 0.30, 0.19, 1), 0.92)
    moss = mat("GolemMoss", (0.06, 0.2, 0.08, 1), 0.95)
    sap = mat("GolemSap", (0.3, 1.0, 0.45, 1), 0.3, 0, (0.2, 1.0, 0.4, 1), 4.0)
    random.seed(5)
    # pernas
    for sx in (-1, 1):
        limb("Leg%d" % sx, (sx * 0.45, 0, 1.15), (sx * 0.5, 0.0, 0.1), 0.34, 0.42, stone, 7)
        box("Foot%d" % sx, (sx * 0.5, -0.18, 0.12), (0.7, 1.0, 0.28), stone2)
    # tronco massivo
    ell("Pelvis", (0, 0, 1.35), (0.7, 0.5, 0.35), stone, 2)
    ell("Torso", (0, 0, 2.05), (1.0, 0.65, 0.85), stone2, 2)
    ell("Chest", (0, -0.1, 2.4), (0.85, 0.55, 0.5), stone, 2)
    # veios de seiva brilhante no peito
    for i in range(5):
        a = random.uniform(-0.5, 0.5)
        limb("Vein%d" % i, (a, -0.62, 1.7 + i * 0.1), (a + random.uniform(-0.3, 0.3), -0.64, 2.5 + random.uniform(0, 0.3)), 0.035, 0.015, sap, 5)
    ell("Core", (0, -0.62, 2.1), (0.2, 0.08, 0.2), sap, 1)
    # ombros e braços colossais
    for sx in (-1, 1):
        ell("Shoulder%d" % sx, (sx * 1.05, 0, 2.75), (0.5, 0.45, 0.4), stone2, 2)
        limb("UpperArm%d" % sx, (sx * 1.15, 0, 2.7), (sx * 1.35, -0.2, 1.6), 0.3, 0.26, stone, 7)
        limb("ForeArm%d" % sx, (sx * 1.35, -0.2, 1.6), (sx * 1.35, -0.7, 0.55), 0.26, 0.38, stone, 7)
        ell("Fist%d" % sx, (sx * 1.35, -0.75, 0.42), (0.42, 0.42, 0.38), stone2, 2)
        # musgo nos ombros
        ell("Moss%d" % sx, (sx * 1.05, 0.0, 3.05), (0.45, 0.4, 0.14), moss, 1)
    # cabeça de tronco com olhos de seiva e galhos como chifres
    ell("Head", (0, -0.15, 3.15), (0.42, 0.4, 0.38), stone, 2)
    box("Brow", (0, -0.5, 3.28), (0.7, 0.14, 0.12), stone2)
    for sx in (-1, 1):
        ell("Eye%d" % sx, (sx * 0.17, -0.5, 3.15), (0.07, 0.04, 0.05), sap, 1)
        limb("Branch%d" % sx, (sx * 0.25, -0.1, 3.45), (sx * 0.65, 0.0, 4.0), 0.08, 0.02, stone, 5)
        limb("BranchB%d" % sx, (sx * 0.5, -0.05, 3.75), (sx * 0.95, 0.0, 3.95), 0.05, 0.015, stone, 5)
    # raízes arrastando atrás
    for i in range(6):
        a = math.radians(-60 + i * 24)
        limb("Root%d" % i, (math.sin(a) * 0.5, 0.45, 1.35), (math.sin(a) * 1.0, 1.0 + 0.2 * (i % 2), 0.05), 0.12, 0.03, stone, 5)
    export("root_golem.glb")


def wraith():
    reset()
    robe = mat("WraithRobe", (0.08, 0.06, 0.15, 1), 0.9)
    robe2 = mat("WraithRobeLight", (0.18, 0.13, 0.30, 1), 0.85)
    glow = mat("WraithGlow", (0.7, 0.2, 1.0, 1), 0.3, 0, (0.65, 0.15, 1.0, 1), 6.0)
    bone = mat("WraithBone", (0.55, 0.52, 0.6, 1), 0.5, 0.2)
    # manto afunilado flutuante (3 camadas)
    cone("Robe1", (0, 0, 0.9), 0.85, 0.35, 1.8, robe, verts=10, rot=(0, 0, 0))
    cone("Robe2", (0, 0, 1.55), 0.55, 0.3, 0.9, robe2, verts=10)
    for i in range(7):
        a = math.tau * i / 7
        cone("Tatter%d" % i, (math.cos(a) * 0.7, math.sin(a) * 0.7, 0.35), 0.18, 0.0, 0.8, robe, rot=(math.sin(a) * 0.35, -math.cos(a) * 0.35, 0), verts=4)
    ell("Chest", (0, 0, 1.95), (0.42, 0.28, 0.38), robe2, 2)
    # capuz
    cone("Hood", (0, -0.02, 2.5), 0.34, 0.06, 0.7, robe, verts=8)
    ell("HoodBase", (0, -0.03, 2.3), (0.3, 0.3, 0.28), robe, 2)
    ell("Face", (0, -0.22, 2.3), (0.15, 0.08, 0.17), mat("Void", (0, 0, 0, 1), 1.0), 1)
    for sx in (-1, 1):
        ell("Eye%d" % sx, (sx * 0.07, -0.3, 2.34), (0.04, 0.02, 0.025), glow, 1)
    # ombros/braços longos com lâminas de osso
    for sx in (-1, 1):
        ell("Sh%d" % sx, (sx * 0.5, 0, 2.2), (0.2, 0.2, 0.18), robe2, 1)
        limb("Arm%d" % sx, (sx * 0.5, 0, 2.15), (sx * 0.7, -0.45, 1.55), 0.1, 0.07, robe, 6)
        limb("Fore%d" % sx, (sx * 0.7, -0.45, 1.55), (sx * 0.62, -0.95, 1.4), 0.07, 0.05, robe, 6)
        limb("Claw%d" % sx, (sx * 0.62, -0.95, 1.4), (sx * 0.5, -1.65, 1.15), 0.05, 0.0, bone, 4)
        limb("ClawB%d" % sx, (sx * 0.66, -0.95, 1.42), (sx * 0.85, -1.5, 1.3), 0.04, 0.0, bone, 4)
    # estilhaços de sombra orbitando
    random.seed(9)
    for i in range(8):
        a = math.tau * i / 8
        cone("Shard%d" % i, (math.cos(a) * 1.0, math.sin(a) * 1.0, 1.0 + (i % 3) * 0.55), 0.07, 0.0, 0.36, glow,
             rot=(random.uniform(0, 3), random.uniform(0, 3), 0), verts=4)
    # coroa de espinhos
    for i in range(5):
        a = math.radians(-50 + i * 25)
        cone("Spike%d" % i, (math.sin(a) * 0.25, 0.05, 2.78 + math.cos(a) * 0.05), 0.04, 0.0, 0.3, bone, rot=(0, math.sin(a) * 0.4, 0), verts=4)
    export("shade_wraith.glb")


wolf()
golem()
wraith()
