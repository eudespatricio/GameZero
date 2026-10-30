"""
Gera peças modulares de cenário para delimitação do mapa (Blender 4.2 headless):
  - elven_gate.glb      : portal de pedra negra com arco, bronze e runa de safira (vão de 4.6m, eixo X)
  - road_signpost.glb   : poste de madeira com 3 placas anguladas (texto via Label3D no Godot)
  - cliff_wall_segment.glb : segmento de 12m de penhasco facetado de basalto (eixo X)
Convenção: Blender +X = Godot +X, Blender +Y = Godot -Z, Blender +Z = Godot +Y.
Uso: blender --background --python tools/studio/generate_map_pieces.py
"""
import bpy
import bmesh
import math
import random
from mathutils import Vector

OUT = "/home/eudespatricio/Games/GameZero/assets/models/"


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mat(name, color, rough=0.8, metal=0.0, emit=None, strength=0.0):
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


def sharp(obj, ang=20.0):
    bpy.context.view_layer.objects.active = obj
    for p in obj.data.polygons:
        p.use_smooth = False
    md = obj.modifiers.new("ES", "EDGE_SPLIT")
    md.use_edge_angle = True
    md.split_angle = math.radians(ang)
    bpy.ops.object.modifier_apply(modifier="ES")


def faceted(obj, disp=0.3, ratio=0.5, scale=0.9):
    bpy.context.view_layer.objects.active = obj
    if disp > 0:
        d = obj.modifiers.new("D", "DISPLACE")
        t = bpy.data.textures.new("T" + obj.name, "VORONOI")
        t.noise_scale = scale
        d.texture = t
        d.strength = disp
        bpy.ops.object.modifier_apply(modifier="D")
    if ratio < 1:
        c = obj.modifiers.new("C", "DECIMATE")
        c.ratio = ratio
        bpy.ops.object.modifier_apply(modifier="C")
    sharp(obj, 15.0)


def box(name, loc, size, m, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(m)
    sharp(o, 30.0)
    return o


def cyl(name, loc, r, h, m, rot=(0, 0, 0), verts=12):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=h, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(m)
    sharp(o, 35.0)
    return o


def export(fn):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=OUT + fn, export_format="GLB")
    print("Exportado:", OUT + fn)


# ------------------------------------------------------------------
def gate():
    reset()
    stone = mat("GateSlate", (0.09, 0.10, 0.12, 1), 0.9, 0.05)
    stone2 = mat("GateSlateLight", (0.14, 0.15, 0.18, 1), 0.85, 0.05)
    bronze = mat("GateBronze", (0.34, 0.22, 0.09, 1), 0.38, 0.9)
    rune = mat("GateRune", (0.1, 0.5, 1.0, 1), 0.3, 0, (0.1, 0.6, 1.0, 1), 5.0)
    moss = mat("GateMoss", (0.05, 0.14, 0.07, 1), 0.95)
    random.seed(7)
    half = 2.9  # centro do pilar; vão livre = 2*(half-0.7)=4.4
    for s in (-1, 1):
        x = s * half
        box("Plinth%d" % s, (x, 0, 0.25), (1.9, 1.9, 0.5), stone2)
        # fuste afunilado: 4 blocos empilhados com leve recuo
        for i in range(5):
            w = 1.45 - i * 0.07
            box("Shaft%d_%d" % (s, i), (x + random.uniform(-.02, .02), 0, 0.5 + i * 1.0 + 0.5), (w, w, 1.02), stone,
                rot=(0, 0, random.uniform(-0.03, 0.03)))
        # bandas de bronze
        for z in (1.5, 3.5):
            box("Band%d_%f" % (s, z), (x, 0, z), (1.56 - z * 0.04, 1.56 - z * 0.04, 0.12), bronze)
        # capitel
        box("Cap%d" % s, (x, 0, 5.62), (1.75, 1.75, 0.32), stone2)
        # cristal de topo
        bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.38, radius2=0.0, depth=1.1, location=(x, 0, 6.35))
        c = bpy.context.active_object
        c.name = "TopCrystal%d" % s
        c.data.materials.append(rune)
        sharp(c, 30)
        # musgo na base
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.55, location=(x + s * 0.5, 0.55, 0.28))
        m = bpy.context.active_object
        m.scale = (1.3, 1.0, 0.45)
        m.data.materials.append(moss)
        faceted(m, 0.1, 0.6)
    # lintel em arco segmentado
    segs = 9
    R = half
    for i in range(segs):
        a0 = math.pi * i / segs
        a1 = math.pi * (i + 1) / segs
        am = (a0 + a1) / 2
        cx = math.cos(am) * (R - 0.0)
        cz = 5.78 + math.sin(am) * 1.5
        ln = 2 * math.pi * R / (2 * segs) * 1.12
        box("Arch%d" % i, (cx, 0, cz), (ln, 1.15, 0.62), stone, rot=(0, math.pi / 2 - am, 0))
    # chave do arco com runa
    box("Keystone", (0, 0, 7.45), (0.9, 1.3, 0.9), stone2)
    box("RuneGem", (0, -0.68, 7.45), (0.42, 0.1, 0.42), rune, rot=(0, math.radians(45), 0))
    box("ArchBronze", (0, -0.0, 7.95), (0.3, 1.35, 0.14), bronze)
    # soleira
    box("Threshold", (0, 0, 0.03), (5.9, 1.8, 0.06), stone2)
    # lanternas penduradas nos pilares
    for s in (-1, 1):
        cyl("LanternChain%d" % s, (s * (half - 1.0), -0.95, 4.2), 0.02, 1.2, bronze, verts=6)
        box("Lantern%d" % s, (s * (half - 1.0), -0.95, 3.4), (0.34, 0.34, 0.46), rune)
    export("elven_gate.glb")


def signpost():
    reset()
    wood = mat("SignWood", (0.17, 0.10, 0.05, 1), 0.88)
    wood2 = mat("SignWoodLight", (0.30, 0.19, 0.09, 1), 0.85)
    iron = mat("SignIron", (0.07, 0.07, 0.08, 1), 0.5, 0.9)
    cyl("Post", (0, 0, 1.6), 0.12, 3.2, wood, verts=8)
    box("PostCap", (0, 0, 3.26), (0.34, 0.34, 0.12), iron)
    box("Base", (0, 0, 0.12), (0.55, 0.55, 0.24), iron)
    for i, (z, ang, ln) in enumerate([(2.7, 0.18, 1.7), (2.15, -0.12, 1.6), (1.6, 0.08, 1.5)]):
        b = box("Board%d" % i, (0.55, -0.16, z), (ln, 0.07, 0.38), wood2, rot=(0, 0, ang))
        # ponta de seta
        bpy.ops.mesh.primitive_cone_add(vertices=3, radius1=0.26, radius2=0.0, depth=0.3,
                                        location=(0.55 + ln / 2 + 0.12, -0.16, z + math.sin(ang) * ln / 2),
                                        rotation=(math.pi / 2, 0, -math.pi / 2 + ang))
        t = bpy.context.active_object
        t.data.materials.append(wood2)
        box("Strap%d" % i, (0.0, -0.17, z), (0.18, 0.09, 0.42), iron, rot=(0, 0, ang))
    export("road_signpost.glb")


def cliff_wall():
    reset()
    rock = mat("CliffBasalt", (0.035, 0.04, 0.05, 1), 0.95, 0.05)
    rock2 = mat("CliffBasaltLight", (0.055, 0.06, 0.07, 1), 0.93, 0.05)
    moss = mat("CliffMoss", (0.05, 0.14, 0.07, 1), 0.95)
    random.seed(11)
    n = 7
    for i in range(n):
        x = -6 + 12.0 * i / (n - 1)
        h = random.uniform(2.6, 4.6)
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1.0, location=(x, random.uniform(-0.5, 0.5), h * 0.55))
        o = bpy.context.active_object
        o.scale = (random.uniform(1.7, 2.3), random.uniform(1.6, 2.2), h * 0.95)
        faceted(o, 1.0, 0.22, 1.6)
        o.data.materials.append(rock if i % 2 else rock2)
        o.rotation_euler[2] = random.uniform(0, 6.28)
        # lasca vertical angular
        bpy.ops.mesh.primitive_cone_add(vertices=5, radius1=0.7, radius2=0.12, depth=h * 1.2,
                                        location=(x + random.uniform(-0.8, 0.8), random.uniform(-0.6, 0.6), h * 0.55))
        s = bpy.context.active_object
        s.scale = (1, random.uniform(0.7, 1.1), 1)
        faceted(s, 0.3, 0.9, 1.0)
        s.data.materials.append(rock)
        # capa de musgo
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.9, location=(x, 0, h * 0.95))
        m = bpy.context.active_object
        m.scale = (1.3, 1.1, 0.3)
        faceted(m, 0.15, 0.6)
        m.data.materials.append(moss)
    export("cliff_wall_segment.glb")


gate()
signpost()
cliff_wall()
