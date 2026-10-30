extends Control
## Tela Unificada de Autenticação, Gerenciamento de Contas e Seleção de Personagens.
## Suporta até 4 slots de personagens por conta e modo offline de contingência.

@onready var server_status_label: Label = $TopBar/ServerStatus
@onready var version_button: Button = $TopBar/VersionButton
@onready var account_label: Label = $TopBar/AccountLabel
@onready var logout_button: Button = $TopBar/LogoutButton

# Painel de Login / Registro
@onready var auth_panel: PanelContainer = $AuthPanel
@onready var auth_title: Label = $AuthPanel/VBox/Title
@onready var username_input: LineEdit = $AuthPanel/VBox/UserInput
@onready var password_input: LineEdit = $AuthPanel/VBox/PassInput
@onready var auth_error_label: Label = $AuthPanel/VBox/ErrorLabel
@onready var submit_auth_btn: Button = $AuthPanel/VBox/SubmitButton
@onready var toggle_mode_btn: Button = $AuthPanel/VBox/ToggleModeButton
@onready var offline_guest_btn: Button = $AuthPanel/VBox/OfflineGuestButton

# Painel de Seleção de Personagens
@onready var char_select_panel: VBoxContainer = $CharSelectPanel
@onready var slots_container: HBoxContainer = $CharSelectPanel/SlotsContainer
@onready var enter_world_btn: Button = $CharSelectPanel/Footer/EnterWorldButton

# Modal de Criação de Personagem
@onready var create_modal: PanelContainer = $CreateCharModal
@onready var create_name_input: LineEdit = $CreateCharModal/VBox/NameInput
@onready var class_zero_btn: Button = $CreateCharModal/VBox/Classes/ZeroBtn
@onready var class_arya_btn: Button = $CreateCharModal/VBox/Classes/AryaBtn
@onready var class_roran_btn: Button = $CreateCharModal/VBox/Classes/RoranBtn
@onready var create_error_label: Label = $CreateCharModal/VBox/ErrorLabel
@onready var confirm_create_btn: Button = $CreateCharModal/VBox/Actions/ConfirmCreate
@onready var cancel_create_btn: Button = $CreateCharModal/VBox/Actions/CancelCreate

# Modal de Notas da Versão
@onready var patch_notes_modal: Control = $PatchNotesModal

var is_register_mode: bool = false
var selected_char_slot: int = -1
var selected_char_data: Dictionary = {}
var characters_cache: Array = []
var selected_class_for_creation: String = "zero"
var creating_slot_index: int = 0

func _ready() -> void:
	_setup_signals()
	_update_version_and_server()
	_show_auth_panel()

	# Se houver notas de versão novas pendentes, abre o modal automaticamente
	var ver_mgr = get_node_or_null("/root/VersionManager")
	if ver_mgr and ver_mgr.has_new_update_notes:
		patch_notes_modal.show_patch_notes(ver_mgr.patch_notes_data)

func _setup_signals() -> void:
	version_button.pressed.connect(func(): patch_notes_modal.show_patch_notes())
	logout_button.pressed.connect(_on_logout)
	submit_auth_btn.pressed.connect(_on_submit_auth)
	toggle_mode_btn.pressed.connect(_on_toggle_auth_mode)
	offline_guest_btn.pressed.connect(_on_guest_mode)
	enter_world_btn.pressed.connect(_on_enter_world)

	class_zero_btn.pressed.connect(func(): _select_creation_class("zero"))
	class_arya_btn.pressed.connect(func(): _select_creation_class("arya"))
	class_roran_btn.pressed.connect(func(): _select_creation_class("roran"))
	confirm_create_btn.pressed.connect(_on_confirm_create_character)
	cancel_create_btn.pressed.connect(func(): create_modal.visible = false)

func _update_version_and_server() -> void:
	var ver_mgr = get_node_or_null("/root/VersionManager")
	var v_str = ver_mgr.local_version if ver_mgr else "0.5.0"
	version_button.text = "📜 v%s Notas" % v_str

	var net = get_node_or_null("/root/NetworkManager")
	if net:
		# Verifica conexão assíncrona com o servidor
		net.check_server_version()
		await get_tree().create_timer(0.4).timeout
		if net.is_server_reachable:
			server_status_label.text = "🟢 Servidor Online (127.0.0.1:8088)"
			server_status_label.modulate = Color(0.4, 1.0, 0.4)
		else:
			server_status_label.text = "🟠 Modo Híbrido (Servidor Offline / Saves Locais)"
			server_status_label.modulate = Color(1.0, 0.75, 0.3)

func _show_auth_panel() -> void:
	auth_panel.visible = true
	char_select_panel.visible = false
	create_modal.visible = false
	account_label.text = "Não conectado"
	logout_button.visible = false
	auth_error_label.text = ""

func _on_toggle_auth_mode() -> void:
	is_register_mode = not is_register_mode
	auth_title.text = "CRIAR NOVA CONTA" if is_register_mode else "ENTRAR EM ALAGAËSIA"
	submit_auth_btn.text = "⚔️ Criar Conta e Entrar" if is_register_mode else "⚔️ Entrar"
	toggle_mode_btn.text = "Já tenho uma conta ➔ Fazer Login" if is_register_mode else "Não tem conta? ➔ Cadastre-se"
	auth_error_label.text = ""

func _on_submit_auth() -> void:
	var user = username_input.text.strip_edges()
	var pwd = password_input.text.strip_edges()
	if user.length() < 3 or pwd.length() < 4:
		auth_error_label.text = "Usuário (min 3) e Senha (min 4) obrigatórios."
		return

	auth_error_label.text = "Conectando ao servidor..."
	var net = get_node_or_null("/root/NetworkManager")
	var res: Dictionary = {}
	if net:
		if is_register_mode:
			res = await net.register_account(user, pwd)
		else:
			res = await net.login_account(user, pwd)

	if res.get("success", false):
		_on_login_success(net.current_username)
	else:
		auth_error_label.text = res.get("error", "Erro ao comunicar com o servidor. Verifique se o server está ativo.")

func _on_guest_mode() -> void:
	var net = get_node_or_null("/root/NetworkManager")
	if net:
		net.current_username = "Cavaleiro_Convidado"
		net.current_account_id = "acc_guest_local"
	_on_login_success("Convidado Local")

func _on_login_success(username: String) -> void:
	auth_panel.visible = false
	char_select_panel.visible = true
	account_label.text = "👤 Conta: %s" % username
	logout_button.visible = true
	_refresh_character_slots()

func _on_logout() -> void:
	var net = get_node_or_null("/root/NetworkManager")
	if net:
		net.logout()
	_show_auth_panel()


func _get_char_for_slot(slot_idx: int) -> Dictionary:
	# 1. Procura por slot_index explícito
	for c in characters_cache:
		if c.get("slot_index", -1) == slot_idx:
			return c
	# 2. Se nenhum registro tiver slot_index explícito, mapeia por índice da lista
	var has_explicit_slots := false
	for c in characters_cache:
		if c.get("slot_index", -1) >= 0:
			has_explicit_slots = true
			break
	if not has_explicit_slots and slot_idx < characters_cache.size():
		return characters_cache[slot_idx]
	return {}

func _refresh_character_slots() -> void:
	var net = get_node_or_null("/root/NetworkManager")
	var save_mgr = get_node_or_null("/root/SaveManager")
	characters_cache.clear()

	if net and not net.auth_token.is_empty():
		characters_cache = await net.fetch_characters()
	elif save_mgr:
		characters_cache = save_mgr.list_local_characters()

	# Se não houver nenhum personagem, criar um personagem padrão Zero automaticamente
	if characters_cache.is_empty() and net and not net.auth_token.is_empty():
		var cr = await net.create_character("Zero", "zero")
		if cr.get("success", false):
			characters_cache = await net.fetch_characters()

	# Renderiza os 4 slots
	for slot_idx in range(4):
		var slot_card = slots_container.get_node_or_null("SlotCard_%d" % slot_idx)
		if slot_card == null:
			continue
		
		var char_in_slot = _get_char_for_slot(slot_idx)
		_render_slot_card(slot_card, slot_idx, char_in_slot)

	# Se a seleção atual for válida, mantém; senão auto-seleciona o primeiro slot ocupado
	var current_selected_char = _get_char_for_slot(selected_char_slot) if selected_char_slot >= 0 else {}
	if current_selected_char.is_empty():
		for slot_idx in range(4):
			var c = _get_char_for_slot(slot_idx)
			if not c.is_empty():
				_select_slot(slot_idx, c)
				break
	else:
		_select_slot(selected_char_slot, current_selected_char)

func _render_slot_card(card: PanelContainer, slot_idx: int, char_data: Dictionary) -> void:
	var empty_box = card.get_node("EmptyBox")
	var info_box = card.get_node("InfoBox")
	var select_btn: Button = card.get_node("SelectButton")
	var create_btn: Button = card.get_node("EmptyBox/CreateButton")

	# Limpa conexões anteriores para evitar duplicações
	for conn in select_btn.pressed.get_connections():
		select_btn.pressed.disconnect(conn.callable)
	for conn in create_btn.pressed.get_connections():
		create_btn.pressed.disconnect(conn.callable)
	for conn in card.gui_input.get_connections():
		card.gui_input.disconnect(conn.callable)

	if char_data.is_empty():
		empty_box.visible = true
		info_box.visible = false
		select_btn.visible = false
		create_btn.pressed.connect(func(): _open_create_modal(slot_idx))
	else:
		empty_box.visible = false
		info_box.visible = true
		select_btn.visible = true
		var name_lbl: Label = info_box.get_node("CharName")
		var class_lbl: Label = info_box.get_node("CharClass")
		var lvl_lbl: Label = info_box.get_node("CharLevel")
		var icon_lbl: Label = info_box.get_node("AvatarIcon")

		var c_id = char_data.get("class_id", "zero")
		name_lbl.text = char_data.get("name", "Guerreiro")
		lvl_lbl.text = "Nível %d" % char_data.get("level", 1)

		match c_id:
			"zero":
				class_lbl.text = "Cavaleiro de Dragão"
				class_lbl.modulate = Color(0.4, 0.85, 1.0)
				icon_lbl.text = "🐉"
			"arya":
				class_lbl.text = "Guardiã de Ellesméra"
				class_lbl.modulate = Color(0.4, 1.0, 0.6)
				icon_lbl.text = "🧝"
			"roran":
				class_lbl.text = "Martelo-Forte"
				class_lbl.modulate = Color(1.0, 0.7, 0.3)
				icon_lbl.text = "🔨"

		select_btn.pressed.connect(func(): _select_slot(slot_idx, char_data))

	# Permite clicar em qualquer lugar do card e duplo clique para entrar no mundo
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not char_data.is_empty():
				_select_slot(slot_idx, char_data)
				if event.double_click:
					_on_enter_world()
			else:
				_open_create_modal(slot_idx)
	)

func _select_slot(slot_idx: int, char_data: Dictionary) -> void:
	selected_char_slot = slot_idx
	selected_char_data = char_data
	enter_world_btn.disabled = false
	enter_world_btn.text = "⚔️ ENTRAR NO MUNDO COMO %s" % char_data.get("name", "").to_upper()

	# Atualiza o visual das bordas douradas dos cards
	for i in range(4):
		var card = slots_container.get_node_or_null("SlotCard_%d" % i)
		if card:
			var border = card.get_node_or_null("ActiveBorder")
			if border:
				border.visible = (i == slot_idx)

func _open_create_modal(slot_idx: int) -> void:
	creating_slot_index = slot_idx
	create_modal.visible = true
	create_error_label.text = ""
	create_name_input.text = ""
	create_name_input.grab_focus()
	_select_creation_class("zero")

func _select_creation_class(class_id: String) -> void:
	selected_class_for_creation = class_id
	class_zero_btn.button_pressed = (class_id == "zero")
	class_arya_btn.button_pressed = (class_id == "arya")
	class_roran_btn.button_pressed = (class_id == "roran")

func _on_confirm_create_character() -> void:
	var c_name = create_name_input.text.strip_edges()
	if c_name.length() < 2:
		create_error_label.text = "O nome deve ter no mínimo 2 caracteres."
		return

	create_error_label.text = "Criando personagem..."
	var net = get_node_or_null("/root/NetworkManager")
	var res: Dictionary = {}
	if net and not net.auth_token.is_empty():
		res = await net.create_character(c_name, selected_class_for_creation)
	else:
		# Fallback local
		var save_mgr = get_node_or_null("/root/SaveManager")
		if save_mgr:
			var char_id = "char_local_" + str(Time.get_ticks_msec())
			var starter_wep = "sword_recruta"
			if selected_class_for_creation == "arya":
				starter_wep = "blade_rastreador"
			elif selected_class_for_creation == "roran":
				starter_wep = "hammer_aprendiz"

			var starter_gear = {
				"head": "", "shoulders": "", "chest": "", "gloves": "", "pants": "", "boots": "",
				"cape": "", "wings": "", "weapon_main": starter_wep, "weapon_off": "",
				"ring_1": "", "ring_2": "", "amulet": "", "mount": "", "pet": ""
			}
			var starter_bag = []
			starter_bag.resize(33)
			for bi in 33: starter_bag[bi] = {}
			starter_bag[0] = {"id": "potion_health", "count": 5}
			starter_bag[1] = {"id": "potion_mana", "count": 3}

			var new_char = {
				"id": char_id,
				"name": c_name,
				"class_id": selected_class_for_creation,
				"level": 1,
				"current_xp": 0,
				"gold": 500,
				"stat_points": 0,
				"wings_tier": 0,
				"weapon_refine": 0,
				"armor_refine": 0,
				"ritual_awakened": 0,
				"slot_index": creating_slot_index,
				"equipped_gear": starter_gear,
				"bag": starter_bag,
				"quests": {
					"hunt_1": {"title": "Caçada ao Chifre", "progress": 0, "goal": 5, "done": false, "claimed": false, "status": "in_progress"}
				}
			}
			save_mgr.save_local(char_id, new_char)
			res = {"success": true, "character": new_char}

	if res.get("success", false):
		create_modal.visible = false
		await _refresh_character_slots()
		# Seleciona automaticamente o personagem recém-criado
		var new_char_data = res.get("character", {})
		if new_char_data.is_empty():
			new_char_data = _get_char_for_slot(creating_slot_index)
		if not new_char_data.is_empty():
			_select_slot(creating_slot_index, new_char_data)
	else:
		create_error_label.text = res.get("error", "Falha ao criar personagem.")

func _on_enter_world() -> void:
	if selected_char_data.is_empty():
		return

	enter_world_btn.disabled = true
	enter_world_btn.text = "Carregando Alagaësia..."

	var net = get_node_or_null("/root/NetworkManager")
	var save_mgr = get_node_or_null("/root/SaveManager")
	var full_char_sheet: Dictionary = {}

	# Busca a folha completa
	if net and not net.auth_token.is_empty():
		full_char_sheet = await net.load_character_full(selected_char_data["id"])
	elif save_mgr:
		full_char_sheet = save_mgr.load_local(selected_char_data.get("id", ""))

	if full_char_sheet.is_empty():
		full_char_sheet = selected_char_data

	# Salva folha pendente e define personagem ativo no SaveManager
	if save_mgr:
		save_mgr.set_active_character(selected_char_data.get("id", ""), full_char_sheet)

	# Transiciona para o mapa jogável
	get_tree().change_scene_to_file("res://scenes/maps/elven_forest_mockup.tscn")
