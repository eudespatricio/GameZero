extends SceneTree
## Vitrine de modelo: fundo neutro, 3 pontos de luz, câmera enquadrando o modelo.
## Uso: godot --path . --script tools/studio/capture_model.gd -- saida.png modelo.glb [modelo2.glb]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("uso: capture_model.gd -- saida.png modelo.glb [modelo2.glb]")
		quit(2)
		return
	var out: String = args[0]
	var paths: Array = args.slice(1)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.06, 0.07, 0.09)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.42, 0.48, 0.58)
	e.ambient_light_energy = 0.8
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	root.add_child(env)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 30)
	ground.mesh = plane
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.10, 0.11, 0.13)
	gm.roughness = 0.7
	ground.material_override = gm
	root.add_child(ground)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-50, -35, 0)
	key.light_energy = 2.2
	key.light_color = Color(0.95, 0.96, 1.0)
	key.shadow_enabled = true
	root.add_child(key)

	var warm := OmniLight3D.new()
	warm.position = Vector3(-2.4, 2.2, 2.6)
	warm.light_energy = 6.0
	warm.light_color = Color(1.0, 0.66, 0.38)
	warm.omni_range = 10.0
	root.add_child(warm)

	var cool := OmniLight3D.new()
	cool.position = Vector3(2.6, 1.8, -2.2)
	cool.light_energy = 4.0
	cool.light_color = Color(0.38, 0.72, 1.0)
	cool.omni_range = 10.0
	root.add_child(cool)

	var cam := Camera3D.new()
	cam.fov = 38.0
	root.add_child(cam)
	cam.make_current()

	var instances: Array[Node3D] = []
	for i in paths.size():
		var scn := load(paths[i]) as PackedScene
		if scn == null:
			print("falha ao carregar ", paths[i])
			continue
		var inst := scn.instantiate() as Node3D
		root.add_child(inst)
		instances.append(inst)

	# espera a árvore resolver os transforms globais (inclui SkinnedMesh)
	await process_frame
	await process_frame
	await process_frame

	var boxes: Array[AABB] = []
	for inst in instances:
		boxes.append(_global_aabb(inst, AABB(), true))

	# distribui lado a lado e centraliza
	var offset := 0.0
	for i in instances.size():
		var b: AABB = boxes[i]
		instances[i].position = Vector3(offset - b.get_center().x, -b.position.y, -b.get_center().z)
		offset += b.size.x + 0.8

	var union := boxes[0]
	for i in range(1, boxes.size()):
		union = union.merge(boxes[i])
	var radius: float = maxf(maxf(union.size.x, union.size.y), union.size.z) * 0.5
	var center := Vector3(0, radius * 0.85, 0)
	var dist: float = radius * 3.4 + 1.0

	cam.position = center + Vector3(radius * 0.9, radius * 1.05, dist)
	cam.look_at(center, Vector3.UP)

	await process_frame
	await create_timer(0.5).timeout
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out)
	print("SALVO ", out, " | raio=%.2f dist=%.2f" % [radius, dist])
	quit()


func _global_aabb(node: Node, acc: AABB, first: bool) -> AABB:
	var box := acc
	var empty := first
	for c in node.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh:
			var mi := c as MeshInstance3D
			var a: AABB = mi.global_transform * mi.get_aabb()
			if a.size != Vector3.ZERO:
				box = a if empty else box.merge(a)
				empty = false
		var sub := _global_aabb(c, box, empty)
		if sub.size != Vector3.ZERO:
			box = sub if empty else box.merge(sub)
			empty = false
	return box
