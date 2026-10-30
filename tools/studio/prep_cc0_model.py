"""
Prepara um modelo CC0 para o GameZero (Blender 4.2 headless).

O que faz:
  - importa o .glb original
  - opcionalmente neutraliza as texturas (dessatura), porque o jogo tinge cada
    arquétipo por material — assim um único lobo cinza serve para lobo, javali,
    razaac etc.
  - opcionalmente reduz a lista de animações (o pack traz ~30 clipes e o jogo
    usa 5; isso corta o tamanho do arquivo pela metade)
  - opcionalmente escala o modelo
  - exporta em Y-up (padrão do glTF) com as animações preservadas

Uso:
  blender -b --python tools/studio/prep_cc0_model.py -- entrada.glb saida.glb \
      [--scale 1.7] [--desaturate 1] [--anims idle,walk,run,attack,death]
"""
import sys
import math

import bpy


def cli():
    argv = sys.argv
    argv = argv[argv.index("--") + 1:] if "--" in argv else []
    if len(argv) < 2:
        print("uso: prep_cc0_model.py -- in.glb out.glb [--scale 1.7] [--desaturate 1] [--anims ...]")
        sys.exit(2)
    a = {"in": argv[0], "out": argv[1], "scale": 1.0, "desaturate": 0.0, "anims": ""}
    for i in range(2, len(argv) - 1):
        k = argv[i].lstrip("-")
        if k in a:
            a[k] = argv[i + 1]
    a["scale"] = float(a["scale"])
    a["desaturate"] = float(a["desaturate"])
    return a


def desaturate_images(amount):
    """Puxa a saturação das texturas para cinza, preservando o valor."""
    count = 0
    for img in bpy.data.images:
        if img.size[0] == 0 or img.name.startswith("Render"):
            continue
        px = list(img.pixels)
        for i in range(0, len(px), 4):
            r, g, b = px[i], px[i + 1], px[i + 2]
            lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
            px[i] = r + (lum - r) * amount
            px[i + 1] = g + (lum - g) * amount
            px[i + 2] = b + (lum - b) * amount
        img.pixels = px
        img.pack()
        count += 1
    return count


def trim_animations(keep):
    """Remove ações que não interessam (reduz muito o tamanho do GLB)."""
    if not keep:
        return 0
    keys = [k.strip().lower() for k in keep.split(",") if k.strip()]
    removed = 0
    for action in list(bpy.data.actions):
        name = action.name.lower()
        if not any(k in name for k in keys):
            bpy.data.actions.remove(action)
            removed += 1
    return removed


def main():
    a = cli()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=a["in"])

    if a["desaturate"] > 0:
        n = desaturate_images(a["desaturate"])
        print(f">>> {n} textura(s) neutralizada(s)")

    if a["scale"] != 1.0:
        for obj in bpy.context.scene.objects:
            if obj.parent is None:
                obj.scale = (a["scale"], a["scale"], a["scale"])
        bpy.ops.object.select_all(action="SELECT")
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        print(f">>> escala aplicada: {a['scale']}")

    removed = trim_animations(a["anims"])
    if removed:
        print(f">>> {removed} ação(ões) removida(s)")

    # Garante que TODAS as texturas vão embutidas no GLB — sem isso o modelo
    # sai branco no Godot (imagens importadas nem sempre vêm "packed").
    packed = 0
    for img in bpy.data.images:
        if img.size[0] == 0:
            continue
        if not img.packed_file:
            img.pack()
            packed += 1
    print(f">>> {packed} textura(s) empacotada(s), {len(bpy.data.images)} no total")

    acts = [x.name for x in bpy.data.actions]
    print(f">>> animações no arquivo: {len(acts)}")

    bpy.ops.object.select_all(action="SELECT")
    # export_apply NÃO pode ser usado com armature: aplica o modificador de
    # skin e a malha sai deformada/escalada em dobro.
    bpy.ops.export_scene.gltf(
        filepath=a["out"],
        export_format="GLB",
        export_animations=True,
        export_apply=False,
    )
    print(">>> exportado:", a["out"])


if __name__ == "__main__":
    main()
