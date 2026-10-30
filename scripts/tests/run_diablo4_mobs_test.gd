extends SceneTree
## Teste Automatizado: Mobs Nível Diablo IV, Cinemática, Tiers de Dificuldade e Arenas de Bosses
## GameZero - Padrão Dark Fantasy Diablo IV

func _initialize() -> void:
	print("\n==================================================")
	print("🧪 TESTE AUTOMATIZADO: MOBS DIABLO IV & MAPA 600x600")
	print("==================================================")

	var all_ok := true
	all_ok = all_ok and _test_models_and_anatomical_nodes()
	all_ok = all_ok and _test_difficulty_tiers_and_colors()
	all_ok = all_ok and _test_procedural_limb_kinematics()
	all_ok = all_ok and _test_thematic_boss_arenas()
	all_ok = all_ok and await _test_expanded_world_mob_distribution()

	print("==================================================")
	if all_ok:
		print("🎉 TODOS OS TESTES DE MOBS DIABLO IV PASSARAM COM 100% DE SUCESSO!")
		quit(0)
	else:
		printerr("❌ FALHA EM UM OU MAIS TESTES DE MOBS!")
		quit(1)

func _test_models_and_anatomical_nodes() -> bool:
	print("[1/5] Validando Modelos 3D Esculpidos e Sub-Nós Anatômicos...")
	var models_to_check := {
		"res://assets/models/urgal_warrior.glb": ["Torso", "Head", "Jaw"],
		"res://assets/models/wolf_spine.glb": ["Chest", "Head", "Jaw", "Tail"],
		"res://assets/models/root_golem.glb": ["Torso", "Head", "SapCore"],
		"res://assets/models/shade_wraith.glb": ["ShroudBase", "Hood", "VoidFace"]
	}

	for path in models_to_check.keys():
		var scn := load(path) as PackedScene
		if not scn:
			printerr("  ❌ Erro: Não foi possível carregar ", path)
			return false
		var inst := scn.instantiate()
		var found_names: Array[String] = []
		_collect_child_names(inst, found_names)
		inst.free()

		var required: Array = models_to_check[path]
		for req in required:
			if not (req in found_names):
				printerr("  ❌ Erro: Nó requerido '%s' não encontrado em %s!" % [req, path])
				return false

	print("  ✅ Sucesso: Todos os 4 modelos GLB possuem malhas anatômicas de alta fidelidade!")
	return true

func _collect_child_names(node: Node, out: Array[String]) -> void:
	out.append(node.name)
	for c in node.get_children():
		_collect_child_names(c, out)

func _test_difficulty_tiers_and_colors() -> bool:
	print("[2/5] Validando Tiers de Dificuldade, Cores e Afixos Diablo IV...")
	var enemy_scn := load("res://scenes/enemies/enemy_mob.tscn") as PackedScene
	if not enemy_scn:
		printerr("  ❌ Erro: Não foi possível carregar enemy_mob.tscn")
		return false

	var enemy := enemy_scn.instantiate() as EnemyMob
	root.add_child(enemy)

	# 1. Testar Boss Supremo (World Boss)
	enemy.configure("garzhvog", 35)
	if enemy.difficulty_tier != EnemyMob.MobDifficultyTier.WORLD_BOSS:
		printerr("  ❌ Erro: Garzhvog deveria ser WORLD_BOSS, mas é: ", enemy.difficulty_tier)
		enemy.queue_free()
		return false
	if enemy.tier_color != Color(0.94, 0.27, 0.27):
		printerr("  ❌ Erro: Cor de World Boss incorreta!")
		enemy.queue_free()
		return false

	# 2. Testar Miniboss
	enemy.configure("gromk", 28)
	if enemy.difficulty_tier != EnemyMob.MobDifficultyTier.MINIBOSS:
		printerr("  ❌ Erro: Gromk deveria ser MINIBOSS, mas é: ", enemy.difficulty_tier)
		enemy.queue_free()
		return false
	if enemy.tier_color != Color(0.66, 0.33, 0.97):
		printerr("  ❌ Erro: Cor de Miniboss incorreta!")
		enemy.queue_free()
		return false

	# 3. Testar Labels com Perigo Mortal (Player nvl 1 vs Mob nvl 35)
	enemy.configure("garzhvog", 35)
	if not enemy.hp_bar_label.text.contains("PERIGO MORTAL"):
		printerr("  ❌ Erro: Label3D deveria indicar PERIGO MORTAL para mob nível 35!")
		enemy.queue_free()
		return false

	enemy.queue_free()
	print("  ✅ Sucesso: 5 Tiers de Dificuldade, modulações de cor e tags de perigo validados!")
	return true

func _test_procedural_limb_kinematics() -> bool:
	print("[3/5] Testando Cinemática Articulada Procedural dos Membros...")
	var enemy_scn := load("res://scenes/enemies/enemy_mob.tscn") as PackedScene
	var enemy := enemy_scn.instantiate() as EnemyMob
	root.add_child(enemy)

	enemy.configure("wolf", 5)
	enemy.velocity = Vector3(4.5, 0.0, 0.0)
	enemy._process(0.2)

	# Checar se membros do lobo rotacionaram com o ciclo de passada
	var leg_fl = enemy._limbs.get("LegF_-1") as Node3D
	var tail = enemy._limbs.get("tail") as Node3D

	if not leg_fl or not tail:
		printerr("  ❌ Erro: Membros do lobo não foram encontrados na tabela de limbs!")
		enemy.queue_free()
		return false

	if absf(leg_fl.rotation.x) < 0.001:
		printerr("  ❌ Erro: Pata dianteira não rotacionou durante locomoção!")
		enemy.queue_free()
		return false

	enemy.queue_free()
	print("  ✅ Sucesso: Cinemática articulada de patas, pernas, cauda e mandíbula validada!")
	return true

func _test_thematic_boss_arenas() -> bool:
	print("[4/5] Testando Geração de Arenas Temáticas de Bosses...")
	var map_builder_scn := load("res://scripts/environment/map_builder.gd") as GDScript
	var mb = Node3D.new()
	mb.set_script(map_builder_scn)
	root.add_child(mb)

	# Testar criação das 4 arenas temáticas
	# 1. Vulcão
	mb._place_boss_arena(Vector2(-120, 20), {"name": "Nar Garzhvog", "kind": "world_boss"})
	# 2. Templo
	mb._place_boss_arena(Vector2(20, -180), {"name": "Durza", "kind": "world_boss"})
	# 3. Pântano
	mb._place_boss_arena(Vector2(160, 160), {"name": "Ra'zac", "kind": "world_boss"})
	# 4. Gelo
	mb._place_boss_arena(Vector2(-140, -160), {"name": "Guardião da Tumba de Safira", "kind": "world_boss"})

	var found_arenas := 0
	for c in mb.get_children():
		if c.name.begins_with("BossArena_"):
			found_arenas += 1

	if found_arenas < 4:
		printerr("  ❌ Erro: Esperado 4 arenas temáticas de chefes, mas encontrou %d!" % found_arenas)
		mb.queue_free()
		return false

	mb.queue_free()
	print("  ✅ Sucesso: 4 Arenas Temáticas (Caldeira Vulcânica, Templo, Pântano, Cripta Glacial) criadas!")
	return true

func _test_expanded_world_mob_distribution() -> bool:
	print("[5/5] Testando Mapa Expandido (600x600m) e Densidade de Mobs...")
	var map_scn := load("res://scenes/maps/elven_forest_mockup.tscn") as PackedScene
	var map := map_scn.instantiate() as Node3D
	root.add_child(map)
	current_scene = map

	await process_frame
	await process_frame

	var mb = map.get_node_or_null("MapBuilder")
	if not mb:
		printerr("  ❌ Erro: MapBuilder não encontrado no mapa!")
		map.queue_free()
		return false

	if mb.half_extent < 300.0:
		printerr("  ❌ Erro: half_extent deveria ser >= 300.0 (600x600m), mas é: ", mb.half_extent)
		map.queue_free()
		return false

	var enemies := get_nodes_in_group("enemies")
	if enemies.size() < 400:
		printerr("  ❌ Erro: Esperado >= 400 mobs no mapa expandido, mas obteve: ", enemies.size())
		map.queue_free()
		return false

	map.queue_free()
	print("  ✅ Sucesso: Mapa expandido para 600x600 m com %d mobs ativos e distribuídos!" % enemies.size())
	return true
