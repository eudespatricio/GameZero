extends SceneTree
## Teste unitário para validar seleção de personagens em auth_and_character_select.tscn

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("\n==================================================")
	print("🧪 TESTE: SELEÇÃO DE SLOTS DE PERSONAGENS")
	print("==================================================")

	var scene_res = load("res://scenes/ui/auth_and_character_select.tscn")
	if not scene_res:
		print("❌ Falha ao carregar cena auth_and_character_select.tscn")
		quit(1)
		return

	var scene = scene_res.instantiate()
	root.add_child(scene)

	# Simular login com 2 personagens no cache
	scene.characters_cache = [
		{"id": "char_zero", "name": "ZeroHero", "class_id": "zero", "level": 15, "slot_index": 0},
		{"id": "char_elfa", "name": "Elfa", "class_id": "arya", "level": 1, "slot_index": 1}
	]

	# Renderiza os slots
	for s in range(4):
		var card = scene.slots_container.get_node("SlotCard_%d" % s)
		var c_data = scene._get_char_for_slot(s)
		scene._render_slot_card(card, s, c_data)

	# Inicialmente seleciona Slot 0
	scene._select_slot(0, scene.characters_cache[0])
	assert(scene.selected_char_slot == 0, "Slot 0 deveria estar selecionado inicialmente")
	assert(scene.enter_world_btn.text.contains("ZEROHERO"), "Botão deveria indicar ZeroHero")
	print("  ✅ Slot 0 auto-selecionado: ZeroHero")

	# Teste 1: Simular clique no SelectButton do Slot 1 (Elfa)
	var card_1 = scene.slots_container.get_node("SlotCard_1")
	var btn_1: Button = card_1.get_node("SelectButton")
	assert(btn_1.visible, "SelectButton do Slot 1 deve estar visível")
	btn_1.pressed.emit()

	assert(scene.selected_char_slot == 1, "Slot 1 deveria estar selecionado após clique no botão!")
	assert(scene.selected_char_data.get("name") == "Elfa", "Nome selecionado deveria ser Elfa!")
	assert(scene.enter_world_btn.text.contains("ELFA"), "Botão deveria indicar ELFA!")
	assert(card_1.get_node("ActiveBorder").visible == true, "Borda ativa do Slot 1 deve estar visível!")
	assert(scene.slots_container.get_node("SlotCard_0/ActiveBorder").visible == false, "Borda ativa do Slot 0 deve estar oculta!")
	print("  ✅ Clique no SelectButton do Slot 1 selecionou Elfa com sucesso!")

	# Teste 2: Simular clique via gui_input no SlotCard_0
	var card_0 = scene.slots_container.get_node("SlotCard_0")
	var click_ev = InputEventMouseButton.new()
	click_ev.button_index = MOUSE_BUTTON_LEFT
	click_ev.pressed = true
	card_0.gui_input.emit(click_ev)

	assert(scene.selected_char_slot == 0, "Slot 0 deveria ser selecionado via gui_input!")
	assert(scene.selected_char_data.get("name") == "ZeroHero", "ZeroHero selecionado via gui_input!")
	print("  ✅ Clique direto no card (gui_input) selecionou Slot 0 com sucesso!")

	# Teste 3: Voltar para Elfa e verificar pending_character_sheet
	card_1.gui_input.emit(click_ev)
	assert(scene.selected_char_slot == 1, "Slot 1 selecionado!")

	var save_mgr = root.get_node_or_null("SaveManager")
	if save_mgr:
		save_mgr.pending_character_sheet = scene.selected_char_data
		assert(save_mgr.pending_character_sheet.get("name") == "Elfa", "SaveManager deve ter Elfa pendente!")
		print("  ✅ SaveManager recebeu a folha de 'Elfa' como pending_character_sheet!")

	scene.queue_free()
	print("==================================================")
	print("🎉 TODOS OS TESTES DE SELEÇÃO PASSARAM!")
	print("==================================================")
	quit(0)
