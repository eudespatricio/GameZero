extends SceneTree
## Teste de integração headless: carrega o mapa, verifica mobs/bosses/portões, mata um boss,
## confirma loot no chão e recolhimento automático pelo jogador.
## Uso: godot --headless --path . --script scripts/tests/run_gameplay_tests.gd

var errors := 0

func _check(cond: bool, ok_msg: String, err_msg: String) -> void:
	if cond:
		print("  ✅ " + ok_msg)
	else:
		print("  ❌ " + err_msg)
		errors += 1

func _initialize() -> void:
	print("==================================================")
	print("🧪 TESTE DE INTEGRAÇÃO: MAPA, MOBS, LOOT, NPCs")
	print("==================================================")
	var map = (load("res://scenes/maps/elven_forest_mockup.tscn") as PackedScene).instantiate()
	root.add_child(map)
	current_scene = map
	await process_frame
	await process_frame
	var mb = map.get_node("MapBuilder")
	var enemies = get_nodes_in_group("enemies")
	_check(mb.gates.size() == 4, "4 portões de fronteira criados", "portões esperados 4, obtidos %d" % mb.gates.size())
	_check(enemies.size() >= 120, "%d mobs/bosses no mapa" % enemies.size(), "poucos mobs: %d" % enemies.size())
	_check(mb.half_extent >= 200.0, "mapa expandido: %d x %d m" % [int(mb.half_extent * 2), int(mb.half_extent * 2)], "mapa pequeno: %f" % mb.half_extent)
	var bosses := 0
	for e in enemies:
		if e.behavior == EnemyMob.BehaviorType.BOSS:
			bosses += 1
	_check(bosses >= 8, "%d bosses (mini + mundo) posicionados" % bosses, "bosses insuficientes: %d" % bosses)
	_check(mb.boss_markers.size() >= 8, "%d marcadores de boss no minimapa" % mb.boss_markers.size(), "marcadores insuficientes: %d" % mb.boss_markers.size())

	# Limites: todo mob dentro da área jogável
	var outside := 0
	for e in enemies:
		if absf(e.global_position.x) > mb.half_extent or absf(e.global_position.z) > mb.half_extent:
			outside += 1
	_check(outside == 0, "nenhum mob fora dos limites do mapa", "%d mobs fora dos limites" % outside)

	# Boss -> loot
	var player = get_first_node_in_group("player")
	_check(player != null and player.stats != null, "jogador com CharacterStats", "jogador ausente")
	var boss: EnemyMob
	for e in enemies:
		if e.behavior == EnemyMob.BehaviorType.BOSS:
			boss = e
			break
	var gold0 = player.stats.gold
	var xp_lvl = player.stats.level
	var kills0 = player.stats.total_kills
	player.global_position = boss.global_position + Vector3(14, 0, 0)
	boss.target_player = player
	boss.take_damage(boss.max_health * 2.0)
	await process_frame
	await create_timer(1.3).timeout
	var drops := get_nodes_in_group("__none__")
	var loot_nodes := []
	for c in map.get_children():
		if c is LootDrop:
			loot_nodes.append(c)
	_check(loot_nodes.size() >= 4, "boss soltou %d itens no chão" % loot_nodes.size(), "drops insuficientes: %d" % loot_nodes.size())
	_check(player.stats.total_kills == kills0 + 1, "kill registrada para missões", "kill não registrada")
	# Recolhimento automático ao se aproximar
	var free0 = player.stats.free_slots()
	for l in loot_nodes:
		if is_instance_valid(l):
			player.global_position = l.global_position
			await create_timer(0.1).timeout
	await create_timer(1.2).timeout
	_check(player.stats.gold > gold0, "ouro recolhido do chão (+%d)" % (player.stats.gold - gold0), "ouro não recolhido")
	var remaining := 0
	for c in map.get_children():
		if c is LootDrop and not c._collected:
			remaining += 1
	_check(remaining == 0, "todos os drops foram recolhidos", "%d drops restantes" % remaining)

	# NPCs: serviços
	var angela: NPCBase
	var brom: NPCBase
	for n in get_nodes_in_group("__npc__"):
		pass
	for c in map.get_node("NPCs").get_children():
		if c.npc_kind == "herbalist": angela = c
		if c.npc_kind == "storyteller": brom = c
	player.stats.gold = 5000
	var pot0 = player.stats.count_item("potion_health")
	angela._buy("potion_health", 500)
	_check(player.stats.count_item("potion_health") == pot0 + 1 and player.stats.gold == 4500, "compra de poção com a Herborista", "compra falhou")
	var q = brom.QUESTS[0]
	brom._accept_quest(q)
	_check(player.stats.quests.has("hunt_1"), "missão aceita com Brom", "missão não aceita")
	for i in 5:
		player.stats.register_kill("x")
	var gold_q = player.stats.gold
	brom._claim_quest(q)
	_check(player.stats.gold == gold_q + 20000, "recompensa da missão entregue", "recompensa não entregue")

	# Usar poção
	var idx := -1
	for i in player.stats.bag.size():
		if not player.stats.bag[i].is_empty() and player.stats.bag[i]["id"] == "potion_health":
			idx = i
	player.stats.current_hp = 100.0
	var msg: String = player.stats.use_bag_item(idx)
	_check(msg != "" and player.stats.current_hp > 100.0, "poção de vida usada: %s" % msg, "poção não curou")

	print("==================================================")
	print("🎉 INTEGRAÇÃO OK" if errors == 0 else "⚠️ INTEGRAÇÃO COM %d ERROS" % errors)
	print("==================================================")
	quit(errors)
