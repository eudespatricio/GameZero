extends SceneTree
## Vitrine do bestiário: instancia mobs reais e enquadra lado a lado.
## Uso: godot --path . --script tools/studio/capture_bestiary_lineup.gd -- saida.png arch1 arch2 ...

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("uso: capture_bestiary_lineup.gd -- saida.png arch1 [arch2 ...]")
		quit(2)
		return
	var out: String = args[0]
	var archs: Array = args.slice(1)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.06, 0.07, 0.09)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.42, 0.48, 0.58)
	e.ambient_light_energy = 0.9
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.glow_enabled = true
	e.glow_intensity = 0.25
	env.environment = e
	root.add_child(env)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	ground.mesh = plane
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.11, 0.12, 0.14)
	gm.roughness = 0.75
	ground.material_override = gm
	root.add_child(ground)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, -34, 0)
	key.light_energy = 2.3
	key.light_color = Color(0.95, 0.96, 1.0)
	key.shadow_enabled = true
	root.add_child(key)

	var warm := OmniLight3D.new()
	warm.position = Vector3(-3.0, 2.6, 3.0)
	warm.light_energy = 8.0
	warm.light_color = Color(1.0, 0.66, 0.38)
	warm.omni_range = 14.0
	root.add_child(warm)

	var cool := OmniLight3D.new()
	cool.position = Vector3(3.0, 2.2, -2.6)
	cool.light_energy = 5.0
	cool.light_color = Color(0.4, 0.74, 1.0)
	cool.omni_range = 14.0
	root.add_child(cool)

	var mob_scene := load("res://scenes/enemies/enemy_mob.tscn") as PackedScene
	var spacing := 2.4
	var start_x := -(archs.size() - 1) * spacing * 0.5
	for i in archs.size():
		var mob = mob_scene.instantiate()
		root.add_child(mob)
		mob.global_position = Vector3(start_x + i * spacing, 0.0, 0.0)
		mob.call("configure", archs[i], 10)
		mob.set_physics_process(false)
		mob.set_process(false)
		if mob.has_method("set_dormant"):
			mob.set_dormant(false)
		# encara a câmera (frente do modelo = +Z)
		mob.rotation.y = PI

	var cam := Camera3D.new()
	cam.fov = 40.0
	root.add_child(cam)
	cam.make_current()

	await process_frame
	await process_frame
	await create_timer(0.8).timeout

	var width := spacing * archs.size()
	cam.position = Vector3(0, 2.1, width * 0.95 + 2.2)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)

	await process_frame
	await create_timer(0.4).timeout
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out)
	print("SALVO ", out)
	quit()
