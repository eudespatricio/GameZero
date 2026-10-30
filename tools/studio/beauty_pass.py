#!/usr/bin/env python3
"""
Beauty pass dos modelos do GameZero (Blender 4.2 headless).

O que melhora (sem UV, sem Cycles, sem aumentar textura):
  1. Shading suave em todos os polígonos -> some o aspecto facetado.
  2. Oclusão ambiente REAL por raycast (BVH) gravada em vertex color.
  3. Ruído de Perlin para mascarar a superfície "plástica" do material chapado.
  4. Gradiente vertical: escurece a base (patas/pés) e clareia o dorso.

O resultado vai em COLOR_0, que o glTF exporta e o Godot multiplica no albedo
(basta `vertex_color_use_as_albedo = true` no material).

Uso:
  blender -b --python tools/studio/beauty_pass.py -- entrada.glb saida.glb [opções]
Opções: --ao 0.55 --noise 0.22 --rays 14 --dist 0.30 --grad 0.28
"""
import sys
import math
import random

import bpy
import mathutils
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils import noise as mnoise


def cli():
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []
    if len(argv) < 2:
        print("uso: blender -b --python beauty_pass.py -- in.glb out.glb [opções]")
        sys.exit(2)
    args = {"in": argv[0], "out": argv[1], "ao": 0.55, "noise": 0.22,
            "rays": 14, "dist": 0.30, "grad": 0.28}
    for i in range(2, len(argv) - 1):
        key = argv[i].lstrip("-")
        if key in args:
            args[key] = float(argv[i + 1]) if key != "rays" else int(argv[i + 1])
    return args


def hemisphere_dirs(count):
    """Direções distribuídas em espiral de Fibonacci sobre a esfera."""
    dirs = []
    golden = math.pi * (3.0 - math.sqrt(5.0))
    for i in range(count):
        z = 1.0 - (i + 0.5) / count
        r = math.sqrt(max(0.0, 1.0 - z * z))
        theta = golden * i
        dirs.append(Vector((math.cos(theta) * r, math.sin(theta) * r, z)))
    return dirs


def world_radius(obj):
    bbox = [Vector(c) for c in obj.bound_box]
    center = sum(bbox, Vector()) / 8.0
    return max((c - center).length for c in bbox)


def bake_vertex_colors(obj, ao_strength, noise_strength, rays, dist_scale, grad_strength, rng):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    bvh = BVHTree.FromObject(obj, depsgraph)
    mesh = obj.data
    if not mesh.vertices:
        return 0

    radius = max(world_radius(obj), 0.05)
    ao_dist = radius * dist_scale
    dirs = hemisphere_dirs(rays)
    zs = [v.co.z for v in mesh.vertices]
    zmin, zmax = min(zs), max(zs)
    zspan = max(zmax - zmin, 1e-4)

    # --- 1. oclusão ambiente por vértice (raycast no hemisfério da normal)
    ao_values = []
    for v in mesh.vertices:
        origin = v.co + v.normal * (radius * 0.004)
        hits = 0
        for d in dirs:
            # reflete a direção para o hemisfério da normal
            dd = d if d.dot(v.normal) > 0 else -d
            if bvh.ray_cast(origin, dd, ao_dist)[0] is not None:
                hits += 1
        ao_values.append(1.0 - (hits / float(len(dirs))))

    # --- 2. cria/atualiza o atributo de cor
    attr_name = "BakedShade"
    if attr_name in mesh.color_attributes:
        mesh.color_attributes.remove(mesh.color_attributes[attr_name])
    attr = mesh.color_attributes.new(name=attr_name, type="FLOAT_COLOR", domain="POINT")

    seed = rng.random() * 100.0
    for i, v in enumerate(mesh.vertices):
        n_val = mnoise.noise(v.co * 9.0 + Vector((seed, seed, seed)))  # -1..1
        mottle = 1.0 + n_val * noise_strength
        ao = ao_values[i]
        shade = (1.0 - ao_strength) + ao_strength * (ao ** 1.35)
        t = (v.co.z - zmin) / zspan
        grad = 1.0 - grad_strength * (1.0 - t)
        c = max(0.0, min(2.0, mottle * shade * grad))
        attr.data[i].color = (c, c, c, 1.0)

    mesh.color_attributes.active_color = attr
    return len(mesh.vertices)


def main():
    args = cli()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=args["in"])

    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    if not meshes:
        print("Nenhuma malha importada:", args["in"])
        sys.exit(1)

    # shading suave em tudo (silhueta orgânica, sem facetas)
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.shade_smooth()

    rng = random.Random(1337)
    total = 0
    for o in meshes:
        total += bake_vertex_colors(
            o, args["ao"], args["noise"], int(args["rays"]), args["dist"], args["grad"], rng
        )

    print(f">>> {len(meshes)} malha(s), {total} vértices com sombreamento assado")

    try:
        bpy.ops.export_scene.gltf(
            filepath=args["out"], export_format="GLB", export_vertex_color="ACTIVE",
        )
    except TypeError:
        bpy.ops.export_scene.gltf(filepath=args["out"], export_format="GLB")
    print(">>> exportado:", args["out"])


if __name__ == "__main__":
    main()
