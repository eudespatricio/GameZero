extends SceneTree
## Mede o tamanho real do modelo importado (headless) para achar o fator de escala.

func _initialize() -> void:
	for path in ["res://assets/models/cc0/wolf_cc0.glb",
				 "res://assets/models/character_zero.glb",
				 "res://assets/models/wolf_spine.glb"]:
		var scn := load(path) as PackedScene
		if scn == null:
			print(path, ": falhou")
			continue
		var inst := scn.instantiate() as Node3D
		root.add_child(inst)
		await process_frame
		var box := AABB()
		var first := true
		for mi in _meshes(inst):
			var a: AABB = mi.global_transform * mi.get_aabb()
			box = a if first else box.merge(a)
			first = false
		print("%-46s raiz_scale=%s  aabb=%s" % [path.get_file(), str(inst.scale.round()), str(box.size.round())])
		inst.queue_free()
		await process_frame
	quit()

func _meshes(node: Node) -> Array:
	var out := []
	for c in node.get_children():
		if c is MeshInstance3D:
			out.append(c)
		out.append_array(_meshes(c))
	return out
