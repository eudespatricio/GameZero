extends SceneTree
## Captura visual do mapa: godot --path . --script tools/studio/capture_map.gd -- <saida.png> <modo>
## modo: top (visão aérea do mapa inteiro) | portal:<id> (norte|oeste|sul_urubaen|sul_beor) | biome:<n|w|se|sw> | plaza

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "/tmp/map_top.png"
	var mode := args[1] if args.size() > 1 else "top"
	var scn := load("res://scenes/maps/elven_forest_mockup.tscn") as PackedScene
	var map := scn.instantiate()
	root.add_child(map)
	current_scene = map
	await process_frame
	await process_frame
	var cam := map.get_node("IsometricCamera") as Camera3D
	if not (mode.begins_with("cast:") or mode == "gameplay"):
		cam.set_script(null)
	var hud := map.get_node_or_null("HUD")
	if hud: hud.visible = false
	var mb := map.get_node("MapBuilder")
	var pl0 := map.get_node_or_null("Player")
	if mode.begins_with("portal:") or mode.begins_with("biome:") or mode == "top":
		# Esconde herói/mobs na captura de paisagem
		if pl0: pl0.global_position = Vector3(0, -50, 0)
	match mode:
		"top":
			# Cobre exatamente ±(half_extent * 0.46/0.44) para casar com o RegionMapCanvas
			for c in mb.get_children():
				if c is MultiMeshInstance3D:
					c.visibility_range_end = 0.0
			root.size = Vector2i(2048, 2048)
			cam.projection = Camera3D.PROJECTION_ORTHOGONAL
			cam.size = mb.half_extent * 2.0 * 0.46 / 0.44
			cam.far = 1500.0
			cam.global_transform = Transform3D(Basis.looking_at(Vector3(0, -1, 0), Vector3(0, 0, -1)), Vector3(0, 600, 0))
			for e in get_nodes_in_group("enemies"):
				e.visible = false
		"road_w":
			cam.global_transform = Transform3D(Basis.IDENTITY, Vector3(-60, 16, 28)).looking_at(Vector3(-82, 1, 13), Vector3.UP)
		"plaza":
			cam.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 16, 22)).looking_at(Vector3(0, 0, 0), Vector3.UP)
		"inventory":
			cam.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 14, 11)).looking_at(Vector3(0, 0, 0), Vector3.UP)
			if hud:
				hud.visible = true
				var inv = hud.get_node("InventoryWindow")
				inv.visible = true
				inv.refresh_inventory()
		"world_map":
			cam.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 14, 11)).looking_at(Vector3(0, 0, 0), Vector3.UP)
			if hud:
				hud.visible = true
				var wmap = hud.get_node("WorldMap")
				if wmap:
					wmap.visible = true
					wmap.set_map_mode(wmap.MapMode.CONTINENT)
					wmap.select_location("ellesmera", true)
		"world_map_region":
			cam.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 14, 11)).looking_at(Vector3(0, 0, 0), Vector3.UP)
			if hud:
				hud.visible = true
				var wmap = hud.get_node("WorldMap")
				if wmap:
					wmap.visible = true
					wmap.set_map_mode(wmap.MapMode.REGION)
					var r_canvas = wmap.get_node_or_null("Window/MainHBox/CenterMapPanel/MapViewport/RegionMapCanvas")
					if r_canvas:
						r_canvas.set_player_destination(Vector2(48.0, -32.0))
		"fork":
			cam.global_transform = Transform3D(Basis.IDENTITY, Vector3(-10, 20, 44)).looking_at(Vector3(4, 0, 66), Vector3.UP)
	if mode.begins_with("portal:"):
		var rid := mode.substr(7)
		for g in mb.gates:
			if g["id"] == rid:
				var gp := Vector3(g["pos"].x, 0, g["pos"].y)
				var st := Vector3(g["stand"].x, 0, g["stand"].y)
				var back := (st - gp).normalized()
				cam.global_transform = Transform3D(Basis.IDENTITY, st + back * 9.0 + Vector3(0, 5.5, 0)).looking_at(gp + Vector3(0, 3.8, 0), Vector3.UP)
				cam.fov = 55.0
	if mode.begins_with("biome:"):
		var dirs := {"n": Vector3(0, 0, -1), "w": Vector3(-1, 0, 0), "se": Vector3(0.7, 0, 0.7), "sw": Vector3(-0.7, 0, 0.7)}
		var d: Vector3 = dirs[mode.substr(6)]
		var c := d * 150.0
		cam.global_transform = Transform3D(Basis.IDENTITY, c + Vector3(0, 22, 26)).looking_at(c + Vector3(0, 1.5, 0), Vector3.UP)
		cam.fov = 60.0
	if mode.begins_with("cast:"):
		# Câmera de jogo ativa (não remove o script); herói conjura a magia escolhida
		if hud: hud.visible = true
		var slot := int(mode.substr(5))
		var pl := map.get_node("Player")
		pl.global_position = Vector3(6, 0, 12)
		await create_timer(0.8).timeout
		pl.stats.current_mp = pl.stats.max_mp
		pl.cast_skill(slot)
		await create_timer(0.22).timeout
	if mode == "gameplay":
		# Mantém a câmera isométrica do jogo; herói na praça com a HUD
		if hud: hud.visible = true
	if mode.begins_with("mob:"):
		var aid := mode.substr(4)
		for e in get_nodes_in_group("enemies"):
			if e.get("archetype_id") == aid:
				var p: Vector3 = e.global_position
				var sc: float = e.model_scale
				var pl = map.get_node("Player")
				pl.global_position = p + Vector3(9 * sc, 0, 9 * sc)
				cam.global_transform = Transform3D(Basis.IDENTITY, p + Vector3(5.5 * sc, 3.0 * sc + 1.2, 7.5 * sc)).looking_at(p + Vector3(0, 1.1 * sc, 0), Vector3.UP)
				break
	for i in 8:
		await process_frame
	await create_timer(0.6).timeout
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out)
	print("SALVO ", out, " ", img.get_size())
	quit()
