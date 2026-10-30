extends SceneTree
## Captura de efeitos de magia: godot --path . --script tools/studio/capture_vfx.gd -- <saida.png> <modo> [atraso_s]
## modo: flame | shock | vortex | sparks | portal | all

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "/tmp/vfx.png"
	var mode := args[1] if args.size() > 1 else "all"
	var delay := float(args[2]) if args.size() > 2 else 0.35

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.04, 0.07)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.35, 0.45)
	env.ambient_light_energy = 0.8
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.1
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)

	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.09, 0.15, 0.11)
	gm.roughness = 0.9
	pm.material = gm
	ground.mesh = pm
	root.add_child(ground)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.light_energy = 0.6
	root.add_child(sun)

	var cam := Camera3D.new()
	cam.fov = 52.0
	root.add_child(cam)
	cam.current = true

	# Dummy do herói
	var hero := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.35
	cm.height = 1.8
	hero.mesh = cm
	root.add_child(hero)

	var scene := Node3D.new()
	root.add_child(scene)
	current_scene = scene

	await process_frame
	cam.global_position = Vector3(0, 11, 11)
	cam.look_at(Vector3(0, 0.8, -1.5), Vector3.UP)
	hero.global_position = Vector3(0, 0.9, 3)
	await process_frame
	var t := self
	var origin := Vector3(0, 0, 3)
	match mode:
		"flame":
			CombatVFX.spawn_cast_charge(t, origin, Color(0.3, 0.85, 1.0))
			await create_timer(0.3).timeout
			CombatVFX.spawn_spell_flame(t, origin, Vector3(0, 0, -1))
		"shock":
			CombatVFX.spawn_shockwave_ring(t, origin, 8.5)
		"vortex":
			CombatVFX.spawn_vortex_effect(t, origin + Vector3(0, 0, -4.2), 2.5)
		"sparks":
			CombatVFX.spawn_hit_sparks(t, origin + Vector3(0, 0, -2), true)
			CombatVFX.spawn_dash_ghost(t, origin, 0.0)
		"slash":
			CombatVFX.spawn_slash_arc(t, origin, Vector3(0, 0, -1), Color(0.35, 0.9, 1.0), 8.0, 0.5, 1.4)
		"portal":
			pass
		_:
			CombatVFX.spawn_spell_flame(t, origin + Vector3(-12, 0, 0), Vector3(0, 0, -1))
			CombatVFX.spawn_shockwave_ring(t, origin + Vector3(0, 0, -6), 7.0)
			CombatVFX.spawn_vortex_effect(t, origin + Vector3(12, 0, -4), 3.0)
	await create_timer(delay).timeout
	for i in 3:
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out)
	print("SALVO ", out, " ", img.get_size())
	quit()
