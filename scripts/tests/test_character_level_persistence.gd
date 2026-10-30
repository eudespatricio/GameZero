extends SceneTree

const PlayerScene = preload("res://scenes/player/player.tscn")
const SaveManagerClass = preload("res://scripts/systems/save_manager.gd")
const CharacterStatsClass = preload("res://scripts/systems/character_stats.gd")

func _init() -> void:
	print("\n==================================================")
	print("🧪 TESTE AUTOMATIZADO: PERSISTÊNCIA DE NÍVEL & XP")
	print("==================================================")
	call_deferred("_run_tests")

func _run_tests() -> void:
	# ----------------------------------------------------
	# [1/4] Testando Instanciação do SaveManager e Registro de ID Ativo
	# ----------------------------------------------------
	print("[1/4] Testando SaveManager.set_active_character()...")
	var sm = root.get_node_or_null("SaveManager")
	if not sm:
		sm = SaveManagerClass.new()
		sm.name = "SaveManager"
		root.add_child(sm)

	var test_char_id = "char_test_persistence_99"
	sm.set_active_character(test_char_id, {
		"id": test_char_id,
		"name": "AryaTest",
		"class_id": "arya",
		"level": 1,
		"current_xp": 0
	})
	assert(sm.active_character_id == test_char_id, "active_character_id deve ser registrado!")
	print("  ✅ Sucesso: active_character_id registrado com sucesso!")

	# ----------------------------------------------------
	# [2/4] Testando Player _ready() e Desserialização de Nível
	# ----------------------------------------------------
	print("[2/4] Testando Player carregando folha pendente...")
	var player = PlayerScene.instantiate()
	root.add_child(player)

	assert(player.is_in_group("player"), "Player deve estar no grupo 'player' para auto-save!")
	assert(player.stats.level == 1, "Player deve começar no Nvl 1 do payload!")
	print("  ✅ Sucesso: Player carregou Nvl 1 e entrou no grupo 'player'!")

	# ----------------------------------------------------
	# [3/4] Testando Ganho de XP, Level Up e Auto-Save Imediato
	# ----------------------------------------------------
	print("[3/4] Testando evolução para Nvl 2 e Nvl 3 com salvamento automático...")
	# Adicionar XP suficiente para subir 2 níveis
	var xp_to_level_2 = player.stats.max_xp
	player.stats.add_xp(xp_to_level_2, "Boss Urgal")
	assert(player.stats.level >= 2, "Personagem deve ter subido para Nvl 2!")

	var xp_to_level_3 = player.stats.max_xp
	player.stats.add_xp(xp_to_level_3, "Boss Urgal 2")
	assert(player.stats.level >= 3, "Personagem deve ter subido para Nvl 3!")

	var current_lvl = player.stats.level
	print("  📊 Herói evoluiu para Nível %d com XP %d/%d" % [current_lvl, player.stats.current_xp, player.stats.max_xp])

	# Força gatilho de save
	player._trigger_immediate_save()

	# Verificar se o arquivo local foi gravado com o Nível 3 (NÃO Nvl 1!)
	var saved_data = sm.load_local(test_char_id)
	assert(not saved_data.is_empty(), "Arquivo de save deve existir em user://saves/!")
	assert(saved_data.get("level") == current_lvl, "O nível salvo deve ser %d, recebido %s!" % [current_lvl, str(saved_data.get("level"))])
	print("  ✅ Sucesso: user://saves/ registrou Nível %d persistido com sucesso!" % current_lvl)

	# ----------------------------------------------------
	# [4/4] Testando Recarregamento em Nova Sessão (Simulação de Restart)
	# ----------------------------------------------------
	print("[4/4] Simulando reinicialização do jogo e carregamento do personagem salvo...")
	player.queue_free()
	await process_frame

	# Novo Player instanciado do zero
	var reloaded_player = PlayerScene.instantiate()
	sm.set_active_character(test_char_id, saved_data)
	root.add_child(reloaded_player)

	assert(reloaded_player.stats.level == current_lvl, "O novo player DEVE carregar no Nível %d, não voltar para 1!" % current_lvl)
	assert(reloaded_player.stats.level >= 3, "Nível deve ser >= 3 após restart!")
	print("  ✅ Sucesso: Personagem reabriu no Nível %d! NENHUMA perda de progresso!" % reloaded_player.stats.level)

	# Limpeza
	reloaded_player.queue_free()
	sm.active_character_id = ""
	sm.pending_character_sheet = {}
	var dir = DirAccess.open("user://saves/")
	if dir and dir.file_exists(test_char_id + ".json"):
		dir.remove(test_char_id + ".json")

	print("==================================================")
	print("🎉 TODOS OS TESTES DE PERSISTÊNCIA PASSARAM COM SUCESSO!")
	print("==================================================")
	quit(0)
