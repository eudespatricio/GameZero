#!/usr/bin/env python3
"""
União por voxel remesh (Blender 4.2 headless).

O gerador antigo monta cada criatura com dezenas de elipsoides soltos: dá para
ver as emendas e as facetas entre as "peças". Este passo junta o corpo inteiro,
refaz a superfície como um único volume contínuo (voxel remesh), relaxa e
decima para caber no orçamento de polígonos — mantendo as proporções originais.

Detalhes pequenos e emissivos (olhos, presas, garras, brilhos) ficam de fora:
seriam destruídos pela voxelização e devem continuar nítidos.

Uso:
  blender -b --python tools/studio/remesh_union.py -- in.glb out.glb [--voxel 0.02] [--tris 4000]
"""
import sys

import bpy

EXCLUDE_KEYS = ("eye", "tooth", "fang", "claw", "glow", "sap", "orb", "shard",
                "crystal", "gem", "spike", "spine", "vein", "core")


def cli():
    argv = sys.argv
    argv = argv[argv.index("--") + 1:] if "--" in argv else []
    if len(argv) < 2:
        print("uso: remesh_union.py -- in.glb out.glb [--voxel 0.02] [--tris 4000]")
        sys.exit(2)
    args = {"in": argv[0], "out": argv[1], "voxel": 0.02, "tris": 4000}
    for i in range(2, len(argv) - 1):
        key = argv[i].lstrip("-")
        if key in args:
            args[key] = float(argv[i + 1])
    return args


def material_names(obj):
    return " ".join(s.material.name.lower() for s in obj.material_slots if s.material)


def is_detail(obj):
    tag = (obj.name + " " + material_names(obj)).lower()
    return any(k in tag for k in EXCLUDE_KEYS)


def tri_count(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def main():
    a = cli()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=a["in"])

    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    body = [o for o in meshes if not is_detail(o)]
    if not body:
        print("Nenhum objeto de corpo encontrado em", a["in"])
        sys.exit(1)

    # material dominante do corpo (maior contagem de polígonos)
    dominant = max(body, key=lambda o: len(o.data.polygons))
    fur_mat = dominant.material_slots[0].material if dominant.material_slots else None

    bpy.ops.object.select_all(action="DESELECT")
    for o in body:
        o.select_set(True)
    bpy.context.view_layer.objects.active = body[0]
    bpy.ops.object.join()
    merged = bpy.context.active_object
    merged.name = "BodyUnion"

    rm = merged.modifiers.new("Remesh", "REMESH")
    rm.mode = "VOXEL"
    rm.voxel_size = a["voxel"]
    rm.use_smooth_shade = True
    bpy.ops.object.modifier_apply(modifier="Remesh")

    sm = merged.modifiers.new("Relax", "SMOOTH")
    sm.factor = 0.5
    sm.iterations = 6
    bpy.ops.object.modifier_apply(modifier="Relax")

    tris = tri_count(merged)
    target = int(a["tris"])
    if tris > target:
        dec = merged.modifiers.new("Decimate", "DECIMATE")
        dec.ratio = max(0.2, target / float(tris))
        bpy.ops.object.modifier_apply(modifier="Decimate")

    # superfície única com o material dominante
    merged.data.materials.clear()
    if fur_mat:
        merged.data.materials.append(fur_mat)
    for p in merged.data.polygons:
        p.material_index = 0
        p.use_smooth = True

    print(f">>> corpo unificado: {tri_count(merged)} tris ({len(body)} objetos fundidos)")
    print(f">>> detalhes preservados: {len(meshes) - len(body)} objetos")

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=a["out"], export_format="GLB")
    print(">>> exportado:", a["out"])


if __name__ == "__main__":
    main()
