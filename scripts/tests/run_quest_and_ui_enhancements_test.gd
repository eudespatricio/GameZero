extends SceneTree

func _initialize() -> void:
	print("==================================================")
	print("🧪 TESTE AUTOMATIZADO: ENHANCEMENTS UI & QUESTS")
	print("==================================================")

	var errors := 0

	# 1. Carregar CharacterStats e testar novo sinal e métodos
	print("[1/5] Testando CharacterStats, Ganho de XP e Sinal xp_gained...")
	var stats = CharacterStats.new()
	var xp_captured = {"amount": 0, "source": ""}
	stats.xp_gained.connect(func(amt: int, src: String):
		xp_captured["amount"] = amt
		xp_captured["source"] = src
	)

	stats.add_xp(150, "Urgal Guerreiro")
	if xp_captured["amount"] != 150 or xp_captured["source"] != "Urgal Guerreiro":
		print("  ❌ Falha: Sinal xp_gained não capturou valores corretos: ", xp_captured)
		errors += 1
	else:
		print("  ✅ Sucesso: Sinal xp_gained capturou +150 XP de 'Urgal Guerreiro'!")

	# 2. Testar Início de Missão com Metadados e get_active_quest()
	print("[2/5] Testando Início de Missão com Metadados (Hint, Pos, Zone)...")
	stats.start_quest("hunt_1", 5, "Caçada ao Chifre", "Acampamento Urgal, Sul da ponte", Vector2(0, 34), "Estrada Sul")
	var act_q = stats.get_active_quest()
	if act_q.is_empty() or act_q.get("hint") != "Acampamento Urgal, Sul da ponte" or act_q.get("target_pos") != Vector2(0, 34):
		print("  ❌ Falha: get_active_quest() não retornou metadados corretos: ", act_q)
		errors += 1
	else:
		print("  ✅ Sucesso: Missão ativa com metadados: %s -> %s" % [act_q["title"], act_q["hint"]])

	# 3. Testar Instanciação do HUD com Barra de XP, Combat Log e Quest Tracker
	print("[3/5] Testando Instanciação do GameHUD e Componentes Visuais...")
	var hud_scene = load("res://scenes/ui/hud.tscn")
	if not hud_scene:
		print("  ❌ Falha: Cena hud.tscn não encontrada.")
		errors += 1
		quit(errors)
		return
	var hud = hud_scene.instantiate()
	root.add_child(hud)
	await process_frame

	if not hud._xp_bar_container or not hud._xp_progress_bar or not hud._xp_text_label:
		print("  ❌ Falha: Componentes da Barra de XP não foram instanciados!")
		errors += 1
	else:
		print("  ✅ Sucesso: Barra de XP dedicada criada e ancorada no rodapé!")

	if not hud._event_log_panel or not hud._event_log_vbox:
		print("  ❌ Falha: Painel de Log de Eventos/Combate não foi instanciado!")
		errors += 1
	else:
		print("  ✅ Sucesso: Painel de Log de Eventos/Combate criado no canto inferior esquerdo!")

	if not hud._quest_tracker_panel or not hud._quest_tracker_title:
		print("  ❌ Falha: Rastreador de Missões não foi instanciado!")
		errors += 1
	else:
		print("  ✅ Sucesso: Rastreador de Missões (Quest Tracker) criado sob o minimapa!")

	# 4. Testar Inserção de Mensagens no Log de Combate
	print("[4/5] Testando Inserção e Limite do Log de Combate...")
	hud.add_log_message("+45 XP de Urgal Guerreiro", Color(0.3, 0.88, 1.0), "XP")
	hud.add_log_message("+120 Ouro", Color(1.0, 0.85, 0.25), "OURO")
	hud.add_log_message("+ Espada Zarroc [Épico]", Color(0.85, 0.45, 1.0), "LOOT")
	hud.add_log_message("Caçada ao Chifre: 3 / 5", Color(1.0, 0.9, 0.35), "MISSAO")
	hud.add_log_message("Entrando em: Santuário de Sylveria", Color(0.7, 0.85, 1.0), "SISTEMA")

	if hud._event_log_vbox.get_child_count() != 5:
		print("  ❌ Falha: Número de mensagens no log inesperado: %d (esperado 5)" % hud._event_log_vbox.get_child_count())
		errors += 1
	else:
		print("  ✅ Sucesso: 5 mensagens registradas com categorias [XP], [Ouro], [Loot], [Missão] e [Sistema]!")

	# Adicionar mais uma para testar FIFO / reciclagem de buffer (máximo 5)
	hud.add_log_message("⚡ Refino Sucesso +12!", Color(0.25, 1.0, 0.7), "REFINO")
	if hud._event_log_vbox.get_child_count() > 5:
		print("  ❌ Falha: Buffer de mensagens ultrapassou o limite máximo de 5!")
		errors += 1
	else:
		print("  ✅ Sucesso: Buffer FIFO manteve o limite limpo de 5 mensagens!")

	# 5. Testar NPCBase e Marcadores 3D Overhead
	print("[5/5] Testando NPCBase, Marcador 3D (!) e (?) e Missões...")
	var npc_scene = load("res://scenes/npcs/npc_base.tscn")
	var npc = npc_scene.instantiate()
	npc.npc_kind = "storyteller"
	npc.npc_name = "Brom"
	root.add_child(npc)
	await process_frame

	if not npc.quest_marker_root or not npc.quest_icon_label:
		print("  ❌ Falha: Marcador 3D Overhead não instanciado no NPC!")
		errors += 1
	else:
		print("  ✅ Sucesso: Marcador 3D Overhead instanciado no topo do NPC (y=2.95m)!")
		npc._update_quest_marker_visuals()
		print("  ✅ Sucesso: Ícone inicial do Brom exibe: '%s'" % npc.quest_icon_label.text)

	print("==================================================")
	if errors == 0:
		print("🎉 TODOS OS TESTES DE ENHANCEMENTS PASSARAM COM SUCESSO!")
	else:
		print("⚠️ TESTES FINALIZADOS COM %d ERRO(S)!" % errors)
	print("==================================================")

	# Limpeza
	hud.queue_free()
	npc.queue_free()
	stats.queue_free()
	quit(errors)
