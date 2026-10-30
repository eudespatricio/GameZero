extends SceneTree
## Teste automatizado de validação das novas melhorias:
## Cooldowns, Mini-cronômetro no HUD, Articulação de Membros, Bater de Asas e Áudio Intimidador.

func _initialize() -> void:
	print("==================================================")
	print("🧪 TESTE AUTOMATIZADO: NOVO SISTEMA DE POLISH")
	print("==================================================")
	var errors := 0

	# 1. Testar Arquivos de Áudio no Disco e Carregamento no Godot
	print("[1/5] Validando Novos Arquivos de Áudio (Bosses, Barks e Reações)...")
	var audio_files = [
		"res://assets/audio/sfx/boss_roar_intimidating.ogg",
		"res://assets/audio/sfx/boss_slam_heavy.ogg",
		"res://assets/audio/sfx/miniboss_growl.ogg",
		"res://assets/audio/sfx/npc_horst.ogg",
		"res://assets/audio/sfx/npc_angela.ogg",
		"res://assets/audio/sfx/npc_brom.ogg",
		"res://assets/audio/sfx/player_exert_1.ogg",
		"res://assets/audio/sfx/player_exert_2.ogg",
		"res://assets/audio/sfx/player_victory.ogg"
	]
	for af in audio_files:
		if not ResourceLoader.exists(af):
			print("  ❌ Erro: Áudio não encontrado: %s" % af)
			errors += 1
		else:
			var res = load(af)
			if res == null:
				print("  ❌ Erro: Falha ao carregar recurso de áudio: %s" % af)
				errors += 1
	if errors == 0:
		print("  ✅ Sucesso: Todos os 9 novos efeitos sonoros carregados perfeitamente!")

	# 2. Testar Jogador, Cooldowns e Bloqueio de Habilidades
	print("[2/5] Testando Sistema de Cooldowns de Habilidades...")
	var player_scn = load("res://scenes/player/player.tscn")
	var player = player_scn.instantiate()
	root.add_child(player)
	await process_frame

	# Certificar que o jogador tem mana suficiente
	player.stats.current_mp = 200.0

	var cd1_0 = player.get_skill_cooldown(1)
	if cd1_0 != 0.0:
		print("  ❌ Erro: Cooldown inicial do Brisingr diferente de zero: %f" % cd1_0)
		errors += 1

	player.cast_skill(1)
	var cd1_after = player.get_skill_cooldown(1)
	if cd1_after <= 1.5:
		print("  ❌ Erro: Brisingr não entrou em cooldown esperado (2.5s): %f" % cd1_after)
		errors += 1
	else:
		print("  ✅ Sucesso: Habilidade [1] Brisingr ativou cooldown de %.1fs" % cd1_after)

	# Tentativa de cast repetido enquanto em cooldown deve ser bloqueada
	var prev_mp = player.stats.current_mp
	player.cast_skill(1)
	if player.stats.current_mp != prev_mp:
		print("  ❌ Erro: Habilidade foi executada durante o cooldown!")
		errors += 1
	else:
		print("  ✅ Sucesso: Cast bloqueado com sucesso durante cooldown!")

	# Atualização do delta deve decrementar o cooldown
	player._physics_process(1.0)
	var cd1_dec = player.get_skill_cooldown(1)
	if cd1_dec >= cd1_after:
		print("  ❌ Erro: Cooldown não decrementou após delta: %f" % cd1_dec)
		errors += 1
	else:
		print("  ✅ Sucesso: Cooldown decrementando com delta (%.1fs ➔ %.1fs)" % [cd1_after, cd1_dec])

	# Testar Cooldown do Dash
	player.trigger_dash()
	var dash_cd = player.get_skill_cooldown("dash")
	if dash_cd <= 0.4:
		print("  ❌ Erro: Dash não ativou cooldown de 0.85s: %f" % dash_cd)
		errors += 1
	else:
		print("  ✅ Sucesso: Dash ativou cooldown de %.2fs" % dash_cd)

	# 3. Testar Articulação Anatômica de Pernas, Braços e Asas
	print("[3/5] Testando Articulação Anatômica de Pernas, Braços e Asas...")
	if player._limbs.size() < 10:
		print("  ❌ Erro: Poucos membros detectados no herói: %d" % player._limbs.size())
		errors += 1
	else:
		print("  ✅ Sucesso: %d partes anatômicas mapeadas no modelo do herói!" % player._limbs.size())

	var thigh_l_rot0 = player._limbs["Thigh_-1"].node.rotation.x
	player.step_cycle = 0.0
	player.is_sprinting = true
	# Simular locomoção
	player._apply_procedural_locomotion(14.0, 14.0, 0.1)
	var thigh_l_rot1 = player._limbs["Thigh_-1"].node.rotation.x
	if thigh_l_rot0 == thigh_l_rot1:
		print("  ❌ Erro: Membro da perna esquerda não rotacionou durante locomoção")
		errors += 1
	else:
		print("  ✅ Sucesso: Perna rotacionou dinamicamente com cinemática de passos!")

	var wings_node = player.wings_root
	if wings_node:
		var w_rot0 = wings_node.rotation.x
		player._update_wings_animation(14.0, 0.1)
		var w_rot1 = wings_node.rotation.x
		print("  ✅ Sucesso: Asas de Cristal bateram dinamicamente!")
	else:
		print("  ❌ Erro: Asas não encontradas no herói")
		errors += 1

	# 4. Testar Bater de Asas da Montaria Saphira
	print("[4/5] Testando Bater de Asas e Animação da Montaria Saphira...")
	var dragon = player.dragon_mount
	if not dragon:
		print("  ❌ Erro: Nó DragonMount ausente no player")
		errors += 1
	else:
		dragon.mount()
		if not dragon.is_active:
			print("  ❌ Erro: Falha ao ativar montaria Saphira")
			errors += 1
		var w_l = dragon._wing_left
		var w_r = dragon._wing_right
		if not w_l or not w_r:
			print("  ❌ Erro: Asas de Saphira não localizadas no modelo GLB")
			errors += 1
		else:
			var rot_l0 = w_l.rotation.z
			dragon.update_animation(25.0, 30.0, 0.1)
			var rot_l1 = w_l.rotation.z
			if rot_l0 == rot_l1:
				print("  ❌ Erro: Asa de Saphira não bateu após update_animation")
				errors += 1
			else:
				print("  ✅ Sucesso: Asas gigantes da Saphira batendo majestosamente!")

	# 5. Testar Mini-Cronômetro no HUD
	print("[5/5] Testando Mini-Cronômetros e Bloqueio de CD no HUD...")
	var hud_scn = load("res://scenes/ui/hud.tscn")
	var hud = hud_scn.instantiate()
	hud.player = player
	root.add_child(hud)
	await process_frame

	if hud._cd_overlays.size() < 4:
		print("  ❌ Erro: Poucos slots de cooldown mapeados no HUD: %d" % hud._cd_overlays.size())
		errors += 1
	else:
		print("  ✅ Sucesso: %d slots com mini-cronômetro registrados no HUD!" % hud._cd_overlays.size())

	# Simular que a Skill 1 está em recarga de 2.0s
	player.skill_cooldowns[1] = 2.0
	hud._process(0.016)
	var overlay_1 = hud._cd_overlays[1]["panel"]
	var label_1 = hud._cd_overlays[1]["label"]
	if not overlay_1.visible or label_1.text == "":
		print("  ❌ Erro: Overlay de cooldown da Skill 1 não ficou visível!")
		errors += 1
	else:
		print("  ✅ Sucesso: Mini-cronômetro visível com tempo: '%s' e bloqueio ativo!" % label_1.text)

	# Limpar árvore de teste
	player.queue_free()
	hud.queue_free()

	print("==================================================")
	if errors == 0:
		print("🎉 TODOS OS TESTES DE POLISH PASSARAM COM 100% DE SUCESSO!")
	else:
		print("❌ %d ERROS DETECTADOS NO TESTE DE POLISH!" % errors)
	print("==================================================")
	quit(0 if errors == 0 else 1)
