extends SceneTree

const HeroPreview3DScene = preload("res://scenes/ui/hero_preview_3d.tscn")
const InventoryWindowScene = preload("res://scenes/ui/inventory_window.tscn")
const PlayerScene = preload("res://scenes/player/player.tscn")
const CharacterStatsClass = preload("res://scripts/systems/character_stats.gd")

func _init() -> void:
	print("\n==================================================")
	print("🧪 TESTE AUTOMATIZADO: SINCRONIZAÇÃO VISUAL DE GEAR")
	print("==================================================")
	call_deferred("_run_tests")

func _run_tests() -> void:
	# ----------------------------------------------------
	# [1/4] Teste do HeroPreview3D com Personagem Novo (Vazio)
	# ----------------------------------------------------
	print("[1/4] Testando HeroPreview3D com personagem vazio...")
	var preview = HeroPreview3DScene.instantiate()
	root.add_child(preview)
	preview.update_visuals({}, "arya")

	assert(preview._helm_node.visible == false, "Elmo deve estar invisível para personagem sem head!")
	assert(preview._pauldrons_node.visible == false, "Ombreiras devem estar invisíveis para personagem sem shoulders!")
	assert(preview._cape_node.visible == false, "Capa deve estar invisível para personagem sem capa!")
	assert(preview._shield_node.visible == false, "Escudo deve estar invisível para personagem sem escudo!")
	assert(preview._wings_node.visible == false, "Asas devem estar invisíveis para personagem sem asas!")
	assert(preview.pet_pivot.visible == false, "Pet deve estar invisível para personagem sem pet!")
	for wn in preview._weapon_nodes:
		assert(wn.visible == false, "Arma deve estar invisível quando desarmado!")
	print("  ✅ Sucesso: Todas as malhas extras estão invisíveis por padrão!")

	# ----------------------------------------------------
	# [2/4] Teste do HeroPreview3D ao Equipar Itens
	# ----------------------------------------------------
	print("[2/4] Testando HeroPreview3D ao equipar asas, pet e arma...")
	var gear = {
		"wings": "wings_crystal_tier2",
		"weapon_main": "blade_rastreador",
		"pet": "pet_baby_dragon"
	}
	preview.update_visuals(gear, "arya")
	assert(preview._wings_node.visible == true, "Asas devem ficar visíveis!")
	assert(preview.pet_pivot.visible == true, "Pet deve ficar visível!")
	for wn in preview._weapon_nodes:
		assert(wn.visible == true, "Arma deve ficar visível!")
	assert(preview._helm_node.visible == false, "Elmo deve continuar invisível!")
	assert(preview._shield_node.visible == false, "Escudo deve continuar invisível!")
	print("  ✅ Sucesso: HeroPreview3D exibe estritamente os itens equipados!")

	preview.queue_free()

	# ----------------------------------------------------
	# [3/4] Teste do Player no Mundo 3D ao Equipar / Desequipar
	# ----------------------------------------------------
	print("[3/4] Testando Player 3D com sincronização dinâmica...")
	var player = PlayerScene.instantiate()
	root.add_child(player)
	player.stats.equipped_gear = {
		"head": "", "shoulders": "", "chest": "", "gloves": "", "pants": "", "boots": "",
		"cape": "", "wings": "", "weapon_main": "", "weapon_off": "",
		"ring_1": "", "ring_2": "", "amulet": "", "mount": "", "pet": ""
	}
	player.update_equipment_visuals()

	assert(player.helm_mesh.visible == false, "Player helm deve estar invisível!")
	assert(player.wings_root.visible == false, "Player wings deve estar invisível!")
	assert(player.dragon_pet.visible == false, "Player dragon pet deve estar invisível!")
	assert(player.shield_mesh.visible == false, "Player shield deve estar invisível!")
	for wn in player._weapon_mesh_nodes:
		assert(wn.visible == false, "Player weapon deve estar invisível!")

	# Simular equipar asas no jogador
	player.stats.equipped_gear["wings"] = "wings_crystal_tier1"
	player.stats.gear_equipped.emit("wings", "wings_crystal_tier1")
	assert(player.wings_root.visible == true, "Asas devem ativar após equipar!")

	# Simular desequipar
	player.stats.equipped_gear["wings"] = ""
	player.stats.gear_unequipped.emit("wings")
	assert(player.wings_root.visible == false, "Asas devem sumir após desequipar!")
	print("  ✅ Sucesso: Player 3D reflete dinamicamente o estado de equipamentos!")

	# ----------------------------------------------------
	# [4/4] Teste da Janela de Inventário e Painel de Inspeção
	# ----------------------------------------------------
	print("[4/4] Testando InventoryWindow sem Brisingr fantasma...")
	var inv = InventoryWindowScene.instantiate()
	root.add_child(inv)
	inv.player_stats = player.stats
	# Limpar mochila para simular personagem novinho sem nada
	for i in player.stats.bag.size():
		player.stats.bag[i] = {}

	inv.refresh_inventory()

	# Verificar se o título não é 'Brisingr'
	assert(not inv.item_title.text.contains("Brisingr"), "Brisingr NÃO deve aparecer para personagem vazio!")
	assert(inv.btn_equip_toggle.visible == false, "Botão equip toggle deve estar oculto!")

	# Clicar no slot vazio de Asas
	inv._on_paperdoll_slot_clicked("wings")
	assert(inv.item_title.text.contains("Slot Vazio: Asas"), "Deve indicar Slot Vazio: Asas!")
	assert(inv.btn_equip_toggle.visible == false, "Botão desequipar não deve aparecer para slot vazio!")

	# Simular personagem com arma inicial em formato de String no equipped_gear
	inv.selected_item_data = {}
	player.stats.equipped_gear["weapon_main"] = "blade_rastreador"
	inv.refresh_inventory()
	assert(inv.selected_item_id == "blade_rastreador", "Deve auto-selecionar a arma equipada sem crash de tipo!")
	assert(inv.item_title.text.contains("Adaga Curta"), "Deve exibir Adaga Curta dos Bosques no título!")

	print("  ✅ Sucesso: Painel de detalhes limpo e coerente sem Brisingr fantasma!")

	inv.queue_free()
	player.queue_free()

	# ----------------------------------------------------
	# [5/5] Teste de equip_from_bag com Previous sendo Dictionary, String e Empty
	# ----------------------------------------------------
	print("[5/5] Testando equip_from_bag com previous Dictionary, String e vazio...")
	var test_stats = CharacterStatsClass.new()
	test_stats.current_class_id = "zero"
	test_stats.level = 50
	for i in test_stats.bag.size():
		test_stats.bag[i] = {}

	# Caso A: Slot vazio ("") -> equipar da mochila
	test_stats.equipped_gear["head"] = ""
	test_stats.bag[0] = {"id": "helm_dragon_knight", "count": 1}
	var ok_a = test_stats.equip_from_bag(0, "head")
	assert(ok_a, "Deveria equipar em slot vazio com sucesso!")
	assert(test_stats.equipped_gear["head"] == "helm_dragon_knight", "Slot head deve conter helm_dragon_knight!")
	assert(test_stats.bag[0].is_empty(), "Mochila slot 0 deve ficar vazia!")

	# Caso B: Slot contém Dictionary (item com affixes) -> trocar com item da mochila
	var dict_helm = {"id": "helm_dragon_knight", "count": 1, "affixes": [{"stat": "strength", "val": 10}]}
	test_stats.equipped_gear["head"] = dict_helm
	test_stats.bag[1] = {"id": "helm_recruta_carvahall", "count": 1}
	# Agora equipa da bag[1], o previous é Dictionary!
	var ok_b = test_stats.equip_from_bag(1, "head")
	assert(ok_b, "Deveria trocar de equipamento quando previous é Dictionary sem crash de tipo!")
	assert(test_stats.equipped_gear["head"] == "helm_recruta_carvahall", "Head deve ser o novo elmo!")
	assert(test_stats.bag[1].get("id") == "helm_dragon_knight", "Mochila slot 1 deve receber o elmo anterior com affixes!")
	assert(test_stats.bag[1].has("affixes"), "Mochila deve ter preservado os affixes!")

	# Caso C: Slot contém String -> trocar com item da mochila
	test_stats.bag[2] = {"id": "helm_dragon_knight", "count": 1}
	var ok_c = test_stats.equip_from_bag(2, "head")
	assert(ok_c, "Deveria trocar de equipamento quando previous é String sem crash de tipo!")
	assert(test_stats.equipped_gear["head"] == "helm_dragon_knight", "Head deve ser helm_dragon_knight!")
	assert(test_stats.bag[2].get("id") == "helm_recruta_carvahall", "Mochila slot 2 deve receber a string desequipada!")

	print("  ✅ Sucesso: equip_from_bag operou com 100% de estabilidade com Dictionary e String!")

	print("==================================================")
	print("🎉 TODOS OS TESTES DE VISUAIS PASSARAM COM SUCESSO!")
	print("==================================================")
	quit()
