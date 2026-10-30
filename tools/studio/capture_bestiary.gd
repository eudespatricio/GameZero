extends SceneTree
## Renderiza o bestiário inteiro lado a lado num palco iluminado.
## Uso: godot --path . --script tools/studio/capture_bestiary.gd -- saida.png
func _initialize() -> void:
	var out := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "/tmp/bestiary.png"
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05, 0.08, 0.1)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.45, 0.55, 0.65)
	e.ambient_light_energy = 1.0
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	world.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 30)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.12, 0.2, 0.14)
	ground.material_override = gm
	world.add_child(ground)
	await process_frame
	var ids := MobsDatabase.get_all().keys()
	var packed := load("res://scenes/enemies/enemy_mob.tscn") as PackedScene
	var cols := 8
	for i in ids.size():
		var m := packed.instantiate() as EnemyMob
		var row := i / cols
		var col := i % cols
		m.position = Vector3((col - (cols - 1) * 0.5) * 6.2, 0, row * 7.5 - 3.0)
		world.add_child(m)
		m.configure(ids[i], MobsDatabase.get_all()[ids[i]]["lvl"][0])
		m.set_physics_process(false)
		m.set_process(false)
		m.rotation.y = 0.0  # frente do modelo = +Z (câmera)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 15, 31)).looking_at(Vector3(0, 1.5, 0.5), Vector3.UP)
	cam.fov = 58
	for i in 10:
		await process_frame
	await create_timer(0.8).timeout
	root.get_viewport().get_texture().get_image().save_png(out)
	print("SALVO ", out)
	quit()
