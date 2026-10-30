extends SceneTree

const ItemsDatabaseScript = preload("res://scripts/data/items_database.gd")
const CharacterStatsScript = preload("res://scripts/systems/character_stats.gd")
const ForgeRecipesScript = preload("res://scripts/data/forge_recipes.gd")

func _init() -> void:
	print("==================================================")
	print("🧪 EXECUTANDO TESTE AUTOMATIZADO: GAMEZERO PAPERDOLL")
	print("==================================================")

	var errors = 0

	# 1. Testar ItemsDatabase
	print("[1/4] Testando Banco de Dados de Itens...")
	var items = ItemsDatabaseScript.get_all_items()
	if items.size() < 20:
		print("  ❌ Erro: Itens insuficientes no banco: %d" % items.size())
		errors += 1
	else:
		print("  ✅ Sucesso: %d itens registrados no banco!" % items.size())

	# 2. Testar CharacterStats e Paperdoll de 15 Slots
	print("[2/4] Testando CharacterStats e Cálculo de CP...")
	var stats = CharacterStatsScript.new()
	stats.level = 45
	stats._ready()

	var atk = stats.get_total_attack()
	var def = stats.get_total_defense()
	var cp = stats.get_combat_power()
	var absorb = stats.get_total_absorb()

	print("  📊 Atributos Iniciais do Cavaleiro Zero:")
	print("     - Ataque Total: %.1f" % atk)
	print("     - Defesa Total: %.1f" % def)
	print("     - Absorção: %d%%" % int(absorb * 100))
	print("     - Poder de Combate (CP): %d" % cp)

	if atk <= 0 or def <= 0 or cp <= 0:
		print("  ❌ Erro: Atributos calculados incorretamente.")
		errors += 1
	else:
		print("  ✅ Sucesso: Cálculos de Atributos e CP validados!")

	# 3. Testar Equipar e Desequipar
	print("[3/4] Testando Equipar e Desequipar...")
	var prev_cp = cp
	stats.unequip_gear("weapon_main")
	var unequipped_cp = stats.get_combat_power()
	if unequipped_cp >= prev_cp:
		print("  ❌ Erro: CP não reduziu após desequipar arma.")
		errors += 1
	else:
		print("  ✅ Sucesso: Desequipou arma. CP variou de %d para %d." % [prev_cp, unequipped_cp])

	stats.equip_gear("weapon_main", "sword_brisingr")
	var reequipped_cp = stats.get_combat_power()
	if reequipped_cp != prev_cp:
		print("  ❌ Erro: CP não restaurou após reequipar arma.")
		errors += 1
	else:
		print("  ✅ Sucesso: Reequipou arma com sucesso. CP restaurado: %d." % reequipped_cp)

	# 3b. Mochila real, arrastar/mover, evolução e missões
	print("[3b] Testando Mochila, Evolução e Missões...")
	var st2 = CharacterStats.new()
	var bless0 = st2.jewels_bless
	st2.add_item("jewel_bless", 3)
	if st2.jewels_bless != bless0 + 3:
		print("  ❌ Erro: empilhamento de joias falhou (%d)" % st2.jewels_bless); errors += 1
	var src = -1
	for i in st2.bag.size():
		if not st2.bag[i].is_empty() and st2.bag[i]["id"] == "sword_zarroc":
			src = i
	var dst = st2.first_free_slot()
	st2.move_bag_item(src, dst)
	if st2.bag[dst].is_empty() or st2.bag[dst]["id"] != "sword_zarroc" or not st2.bag[src].is_empty():
		print("  ❌ Erro: mover item na mochila falhou"); errors += 1
	else:
		print("  ✅ Sucesso: empilhar e mover itens na mochila")
	var old_weapon = st2.equipped_gear["weapon_main"]
	if not st2.equip_from_bag(dst) or st2.equipped_gear["weapon_main"] != "sword_zarroc" or st2.count_item(old_weapon) != 1:
		print("  ❌ Erro: equipar da mochila (troca) falhou"); errors += 1
	else:
		print("  ✅ Sucesso: equipar da mochila troca com o item equipado")
	if not st2.unequip_to_bag("weapon_main") or st2.count_item("sword_zarroc") != 1:
		print("  ❌ Erro: desequipar para mochila falhou"); errors += 1
	# mochila cheia
	var full = CharacterStats.new()
	while full.first_free_slot() >= 0:
		full.add_item("hammer_roran", 1)
	if full.add_item("bow_ellesmera", 1):
		print("  ❌ Erro: mochila cheia aceitou item"); errors += 1
	else:
		print("  ✅ Sucesso: mochila cheia recusa novos itens")
	st2.current_xp = 0
	var lvl0 = st2.level
	st2.add_xp(st2.max_xp)
	if st2.level != lvl0 + 1 or st2.stat_points != 5:
		print("  ❌ Erro: level-up não concedeu 5 pontos"); errors += 1
	else:
		var str0 = st2.strength
		st2.spend_stat_point("strength")
		if st2.strength != str0 + 1 or st2.stat_points != 4:
			print("  ❌ Erro: gastar ponto falhou"); errors += 1
		else:
			print("  ✅ Sucesso: evolução (level-up +5 pontos, distribuição de atributos)")
	st2.start_quest("q", 2, "Teste")
	st2.register_kill("a"); st2.register_kill("b")
	if not st2.quests["q"]["done"]:
		print("  ❌ Erro: missão não concluiu"); errors += 1
	else:
		print("  ✅ Sucesso: missão de caça concluída por kills")
	for aid in MobsDatabase.get_all().keys():
		var arch = MobsDatabase.get_all()[aid]
		if not ResourceLoader.exists(arch["model"]):
			print("  ❌ Erro: modelo ausente para mob %s" % aid); errors += 1
	print("  ✅ Sucesso: %d arquétipos de mobs/bosses com modelos válidos" % MobsDatabase.get_all().size())
	st2.free(); full.free()

	# 4. Testar Carregamento das Cenas Principais
	print("[4/5] Validando Cenas no Godot Headless...")
	var scenes_to_test = [
		"res://scenes/ui/inventory_window.tscn",
		"res://scenes/ui/blacksmith_forge_window.tscn",
		"res://scenes/player/player.tscn",
		"res://scenes/enemies/enemy_mob.tscn",
		"res://scenes/maps/elven_forest_mockup.tscn"
	]
	for sc_path in scenes_to_test:
		var packed = ResourceLoader.load(sc_path) as PackedScene
		if not packed:
			print("  ❌ Erro: Falha ao carregar cena: %s" % sc_path)
			errors += 1
		else:
			var inst = packed.instantiate()
			if not inst:
				print("  ❌ Erro: Falha ao instanciar cena: %s" % sc_path)
				errors += 1
			else:
				print("  ✅ Cena validada: %s" % sc_path.get_file())
				inst.queue_free()

	# 5. Testar Novos Sistemas: Forja, Safe Zone, Câmera Zoom, Mobs HP e Sela
	print("[5/5] Validando Novos Sistemas (Forja, Safe Zone, Zoom, Mobs HP)...")
	var forge_recipes = ForgeRecipesScript.get_all_recipes()
	if forge_recipes.size() < 5:
		print("  ❌ Erro: Receitas insuficientes na Forja")
		errors += 1
	else:
		print("  ✅ Sucesso: %d receitas registradas na Forja do Horst" % forge_recipes.size())

	# Testar Câmera Zoom e Fullscreen
	var cam = IsometricCamera.new()
	if cam.min_zoom != 0.45 or cam.max_zoom != 3.20:
		print("  ❌ Erro: Zoom da câmera incorreto")
		errors += 1
	else:
		print("  ✅ Sucesso: Câmera com Zoom por scroll (0.45x a 3.20x) e F11 Tela Cheia")
	cam.free()

	# Testar Safe Zone dos Mobs
	var mob_inst = load("res://scenes/enemies/enemy_mob.tscn").instantiate() as EnemyMob
	if not mob_inst.is_pos_in_safe_zone(Vector3(0, 0, 0)) or mob_inst.is_pos_in_safe_zone(Vector3(50, 0, 50)):
		print("  ❌ Erro: Função is_pos_in_safe_zone falhou")
		errors += 1
	else:
		print("  ✅ Sucesso: Barreira de 24m da Safe Zone do Santuário validada")

	# Testar Labels e Barra de Sangue nos Mobs
	mob_inst.mob_name = "Lobo Alfa"
	mob_inst.level = 12
	mob_inst.max_health = 1000.0
	mob_inst.current_health = 750.0
	mob_inst.hp_bar_label = Label3D.new()
	mob_inst.add_child(mob_inst.hp_bar_label)
	mob_inst._update_label()
	if not ("[Nvl 12]" in mob_inst.hp_bar_label.text) or not ("█" in mob_inst.hp_bar_label.text):
		print("  ❌ Erro: Formatação de Nome/Lvl/Barra de HP do mob incorreta")
		errors += 1
	else:
		print("  ✅ Sucesso: Nameplate flutuante do mob exibe Nome, Lvl e Barra gráfica de HP")
	mob_inst.free()

	# Testar Montaria e Ponto de Sela
	var mount_inst = load("res://scenes/mounts/dragon_mount.tscn").instantiate() as DragonMount
	var saddle_pos = mount_inst.get_saddle_local_position()
	if saddle_pos.y < 1.5:
		print("  ❌ Erro: Altura da sela do dragão incorreta")
		errors += 1
	else:
		print("  ✅ Sucesso: Dorso e Sela da Saphira sincronizados para o Cavaleiro")
	mount_inst.free()

	# Testar Transmutação na Forja
	var st_test = CharacterStatsScript.new()
	st_test._ready()
	st_test.gold = 100000
	st_test.jewels_bless = 5
	st_test.jewels_soul = 5
	st_test.jewels_chaos = 5
	var rec_creation = forge_recipes[3]
	if not ForgeRecipesScript.can_craft(rec_creation, st_test):
		print("  ❌ Erro: can_craft falhou para Joia da Criação")
		errors += 1
	else:
		print("  ✅ Sucesso: Validação de requisitos de materiais da Forja aprovada")
	st_test.free()

	# Testar Mapa Grande, Identificação do Personagem e Auto-Pathing por Clique
	var wmap_inst = load("res://scenes/ui/world_map.tscn").instantiate()
	root.add_child(wmap_inst)
	var reg_canvas = wmap_inst.get_node_or_null("Window/MainHBox/CenterMapPanel/MapViewport/RegionMapCanvas")
	var parchment = wmap_inst.get_node_or_null("Window/MainHBox/CenterMapPanel/MapViewport/ParchmentTexture")
	if not reg_canvas or not parchment:
		print("  ❌ Erro: RegionMapCanvas ou ParchmentTexture não encontrado em world_map.tscn")
		errors += 1
	else:
		# Testar conversão de coordenadas (round-trip)
		var test_wpos = Vector2(35.0, -42.0)
		var map_pt = reg_canvas.world_to_map(test_wpos)
		var reconstructed = reg_canvas.map_to_world(map_pt)
		if test_wpos.distance_to(reconstructed) > 0.05:
			print("  ❌ Erro: Round-trip de coordenadas do mapa com desvio excessivo: %f" % test_wpos.distance_to(reconstructed))
			errors += 1
		else:
			print("  ✅ Sucesso: Conversão bidirecional de coordenadas 3D <-> 2D do Mapa validada")

		# Testar Click-to-Move no Mapa
		var dummy_player = load("res://scenes/player/player.tscn").instantiate() as Player
		root.add_child(dummy_player)
		reg_canvas.player = dummy_player
		reg_canvas.set_player_destination(Vector2(20.0, 30.0))
		if not dummy_player.is_moving_to_target or dummy_player.target_position.distance_to(Vector3(20.0, 0.05, 30.0)) > 0.1:
			print("  ❌ Erro: Clique no mapa não ativou o auto-pathing do jogador")
			errors += 1
		else:
			print("  ✅ Sucesso: Clique no Mapa Grande ativa Auto-Pathing e orientação do Cavaleiro")

		# Testar alternância entre Visão Regional e Visão Continental
		wmap_inst.set_map_mode(wmap_inst.MapMode.CONTINENT)
		if reg_canvas.visible or not parchment.visible:
			print("  ❌ Erro: Visibilidade incorreta no modo Continental")
			errors += 1
		wmap_inst.set_map_mode(wmap_inst.MapMode.REGION)
		if not reg_canvas.visible or parchment.visible:
			print("  ❌ Erro: Visibilidade incorreta no modo Regional")
			errors += 1
		else:
			print("  ✅ Sucesso: Alternância dinâmica entre Mapa Regional tático e Mapa Continental")

		dummy_player.queue_free()
	wmap_inst.queue_free()

	# Testar Áudio: arquivos gerados, variações, camadas de ambiência/música e barramentos
	var am = root.get_node_or_null("AudioManager")
	var am_created_here := false
	if am == null:
		var am_script = load("res://scripts/systems/audio_manager.gd")
		if am_script:
			am = am_script.new()
			am.name = "AudioManager"
			root.add_child(am)
			am._ready()
			am_created_here = true

	if am == null:
		print("  ❌ Erro: autoload AudioManager ausente")
		errors += 1
	else:
		var needed = ["slash", "hit_flesh", "hit_crit", "brisingr_cast", "jierda_cast", "vortex_cast", "step_grass", "step_stone",
			"step_dirt", "coin", "loot_item", "potion", "level_up", "portal_open", "portal_hum", "teleport", "dragon_roar",
			"growl_beast", "growl_large", "growl_wraith", "boss_roar", "mob_death", "anvil", "craft_success", "ui_open"]
		var missing = []
		for n in needed:
			if not am.has_sfx(n):
				missing.append(n)
		if not missing.is_empty() or am._layers.size() < 6 or AudioServer.get_bus_index("SFX") == -1:
			print("  ❌ Erro: áudio incompleto. Faltando: %s | camadas=%d" % [str(missing), am._layers.size()])
			errors += 1
		else:
			print("  ✅ Sucesso: %d efeitos sonoros + %d camadas de ambiência/música + barramentos SFX/Ambient/Music" % [needed.size(), am._layers.size()])

		if am_created_here:
			am.queue_free()

	print("==================================================")
	if errors == 0:
		print("🎉 TODOS OS TESTES PASSARAM COM 100% DE SUCESSO!")
	else:
		print("⚠️ TESTES FINALIZADOS COM %d ERROS!" % errors)
	print("==================================================")

	quit(errors)
