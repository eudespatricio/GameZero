#!/usr/bin/env python3
"""
Render de comparação: dois GLBs lado a lado com a mesma luz e câmera.
Uso: blender -b --python tools/studio/render_compare.py -- antigo.glb novo.glb saida.png
"""
import sys
import math
import os

import bpy


def cli():
    argv = sys.argv
    argv = argv[argv.index("--") + 1:] if "--" in argv else []
    if len(argv) < 3:
        print("uso: render_compare.py -- a.glb b.glb out.png")
        sys.exit(2)
    return argv[0], argv[1], argv[2]


def main():
    a, b, out = cli()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 40
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 1280
    scene.render.resolution_y = 560
    scene.render.film_transparent = False
    scene.render.image_settings.file_format = "PNG"

    # chão
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
    ground = bpy.context.active_object
    gm = bpy.data.materials.new("Ground")
    gm.use_nodes = True
    bsdf = gm.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (0.05, 0.055, 0.065, 1)
    bsdf.inputs["Roughness"].default_value = 0.35
    ground.data.materials.append(gm)

    def load(path, x):
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=path)
        new = [o for o in bpy.data.objects if o not in before]
        root = bpy.data.objects.new("root_" + os.path.basename(path), None)
        scene.collection.objects.link(root)
        root.location = (x, 0, 0)
        for o in new:
            if o.parent is None:
                o.parent = root
        return root

    load(a, -1.5)
    load(b, 1.5)

    # luzes (mesmo setup do showcase)
    bpy.ops.object.light_add(type="SUN", location=(8, -9, 12))
    sun = bpy.context.active_object
    sun.data.energy = 3.0
    sun.data.color = (0.78, 0.88, 1.0)
    sun.rotation_euler = (math.radians(52), math.radians(16), math.radians(-38))

    bpy.ops.object.light_add(type="POINT", location=(-2.6, -3.4, 2.2))
    warm = bpy.context.active_object
    warm.data.energy = 260.0
    warm.data.color = (1.0, 0.55, 0.22)

    bpy.ops.object.light_add(type="POINT", location=(3.0, -3.0, 2.4))
    cool = bpy.context.active_object
    cool.data.energy = 160.0
    cool.data.color = (0.35, 0.8, 1.0)

    bpy.ops.object.camera_add(location=(0, -7.2, 2.1))
    cam = bpy.context.active_object
    cam.data.lens = 50
    cam.rotation_euler = (math.radians(80), 0, 0)
    scene.camera = cam

    scene.render.filepath = out
    bpy.ops.render.render(write_still=True)
    print("RENDER:", out)


if __name__ == "__main__":
    main()
