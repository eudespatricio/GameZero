extends CharacterBody3D
class_name NPCBase

@export var npc_name: String = "Ferreiro Horst"
@export var npc_role: String = "Mestre de Forja & Refino (+15)"
@export_multiline var greeting_text: String = "Bem-vindo à forja, Cavaleiro! Traga suas Joias da Bênção e da Alma para imbuir suas armas com fogo sagrado."
@export var npc_color: Color = Color(0.85, 0.45, 0.2)
@export var custom_model: PackedScene
@export_enum("blacksmith", "herbalist", "storyteller", "generic") var npc_kind: String = "blacksmith"

@onready var visuals: Node3D = $Visuals
@onready var label_name: Label3D = $Label3D
@onready var prompt_label: Label3D = $PromptLabel
@onready var area_detect: Area3D = $DetectionArea

var player_in_range: bool = false
signal npc_interacted(npc: NPCBase)

# --- MARCADOR 3D FLUTUANTE DE MISSÃO / SERVIÇO ---
var quest_marker_root: Node3D = null
var quest_icon_label: Label3D = null
var quest_marker_light: OmniLight3D = null
var _marker_scan_timer: float = 0.0

func _ready() -> void:
	if custom_model and visuals:
		for child in visuals.get_children():
			child.queue_free()
		var inst = custom_model.instantiate()
		visuals.add_child(inst)
	if label_name:
		label_name.text = "💬 %s\n<%s>" % [npc_name, npc_role]
		label_name.modulate = npc_color
	if prompt_label:
		prompt_label.visible = false

	if area_detect:
		area_detect.body_entered.connect(_on_body_entered)
		area_detect.body_exited.connect(_on_body_exited)

	_setup_quest_marker()

func _setup_quest_marker() -> void:
	quest_marker_root = Node3D.new()
	quest_marker_root.name = "QuestMarkerRoot"
	quest_marker_root.position = Vector3(0, 2.95, 0)
	add_child(quest_marker_root)

	quest_icon_label = Label3D.new()
	quest_icon_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	quest_icon_label.no_depth_test = true
	quest_icon_label.font_size = 44
	quest_icon_label.outline_size = 10
	quest_icon_label.outline_modulate = Color(0, 0, 0, 0.95)
	quest_marker_root.add_child(quest_icon_label)

	quest_marker_light = OmniLight3D.new()
	quest_marker_light.light_energy = 0.9
	quest_marker_light.omni_range = 2.8
	quest_marker_root.add_child(quest_marker_light)
	_update_quest_marker_visuals()

func _process(delta: float) -> void:
	if quest_marker_root and quest_marker_root.visible:
		var t = Time.get_ticks_msec() / 1000.0
		quest_marker_root.position.y = 2.95 + sin(t * 3.2) * 0.12
		var pulse = 1.0 + sin(t * 4.0) * 0.12
		quest_marker_root.scale = Vector3(pulse, pulse, pulse)

	_marker_scan_timer -= delta
	if _marker_scan_timer <= 0.0:
		_marker_scan_timer = 0.35
		_update_quest_marker_visuals()

func _update_quest_marker_visuals() -> void:
	if not quest_icon_label or not quest_marker_light:
		return
	var st = _player_stats()

	match npc_kind:
		"storyteller":
			if not st:
				quest_icon_label.text = "!"
				quest_icon_label.modulate = Color(1.0, 0.85, 0.15)
				quest_marker_light.light_color = Color(1.0, 0.85, 0.15)
				quest_marker_root.visible = true
				return

			var cur_q = _current_quest(st)
			if cur_q.is_empty():
				quest_marker_root.visible = false
			else:
				var q_data = st.quests.get(cur_q["id"], {})
				if q_data.is_empty():
					# Nova missão pronta para aceitar: ! Dourado Radiante
					quest_marker_root.visible = true
					quest_icon_label.text = "!"
					quest_icon_label.modulate = Color(1.0, 0.88, 0.15)
					quest_marker_light.light_color = Color(1.0, 0.88, 0.15)
				elif q_data.get("done", false) and not q_data.get("claimed", false):
					# Missão concluída pronta para entrega: ? Esmeralda/Dourado com Brilho
					quest_marker_root.visible = true
					quest_icon_label.text = "?"
					quest_icon_label.modulate = Color(0.25, 1.0, 0.55)
					quest_marker_light.light_color = Color(0.25, 1.0, 0.55)
				else:
					# Em andamento: ! Ciano suave
					quest_marker_root.visible = true
					quest_icon_label.text = "!"
					quest_icon_label.modulate = Color(0.4, 0.8, 1.0, 0.85)
					quest_marker_light.light_color = Color(0.3, 0.7, 1.0)
		"blacksmith":
			quest_marker_root.visible = true
			quest_icon_label.text = "⚒"
			quest_icon_label.modulate = Color(1.0, 0.72, 0.25)
			quest_marker_light.light_color = Color(1.0, 0.65, 0.2)
		"herbalist":
			quest_marker_root.visible = true
			quest_icon_label.text = "🧪"
			quest_icon_label.modulate = Color(0.3, 1.0, 0.65)
			quest_marker_light.light_color = Color(0.3, 1.0, 0.6)
		_:
			quest_marker_root.visible = false

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		player_in_range = false
		if prompt_label:
			prompt_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		interact()

func interact() -> void:
	npc_interacted.emit(self)
	GameAudio.play_npc_bark(get_tree(), npc_kind)
	_open_dialog()

func _player_stats() -> CharacterStats:
	var pl = get_tree().get_first_node_in_group("player")
	return pl.stats if pl and pl.get("stats") else null

func _hud() -> Node:
	return get_tree().get_first_node_in_group("hud")

func _notify(msg: String, color: Color = Color(0.9, 0.95, 1.0)) -> void:
	var h = _hud()
	if h and h.has_method("show_notification"):
		h.show_notification(msg, color)

func _opt(label: String, fn: Callable, disabled: bool = false) -> Dictionary:
	return {"label": label, "action": func(): fn.call(); _open_dialog(), "disabled": disabled}

func _open_dialog() -> void:
	var h = _hud()
	if not h or not h.has_method("show_npc_dialog"):
		return
	var st = _player_stats()
	var text = greeting_text
	var opts: Array = []
	if st:
		match npc_kind:
			"blacksmith":
				text += "\n\n⚔ Lâmina: +%d   💎 Bless %d  🔮 Soul %d  🔥 Chaos %d   💰 %d" % [st.weapon_refine, st.jewels_bless, st.jewels_soul, st.jewels_chaos, st.gold]
				opts.append(_opt("🔥 Abrir Forja de Combinações (Chaos Machine)", _open_forge))
				opts.append(_opt("⚒ Aprimorar Lâmina (+%d ➔ +%d)" % [st.weapon_refine, st.weapon_refine + 1], _smith_enhance))
				opts.append(_opt("💰 Vender Materiais (Aço Brilhante / Cascas)", _sell_materials))
			"herbalist":
				text += "\n\n❤ %d/%d   🔮 %d/%d   💰 %d Ouro" % [int(st.current_hp), int(st.max_hp), int(st.current_mp), int(st.max_mp), st.gold]
				opts.append(_opt("🧪 Comprar Poção de Vida (500 ouro)", _buy.bind("potion_health", 500)))
				opts.append(_opt("🔮 Comprar Elixir de Mana (400 ouro)", _buy.bind("potion_mana", 400)))
				opts.append(_opt("✨ Curar-me (200 ouro)", _heal_player, st.gold < 200))
				opts.append(_opt("💰 Vender Materiais", _sell_materials))
			"storyteller":
				var q = _current_quest(st)
				if q.is_empty():
					text += "\n\nNão há mais caçadas por hoje, rapaz. Volte quando tiver mais lendas."
				else:
					var qd = st.quests.get(q["id"], {})
					if qd.is_empty():
						text += "\n\n📜 MISSÃO: %s\n%s\nRecompensa: %s" % [q["title"], q["desc"], q["reward_text"]]
						opts.append(_opt("📜 Aceitar: %s" % q["title"], _accept_quest.bind(q)))
					elif qd.get("done", false):
						text += "\n\n✅ %s concluída! Reclame sua recompensa: %s" % [q["title"], q["reward_text"]]
						opts.append(_opt("🏆 Receber Recompensa", _claim_quest.bind(q)))
					else:
						text += "\n\n📜 %s — Progresso: %d / %d" % [q["title"], int(qd.get("progress", 0)), int(qd.get("goal", 5))]
	h.show_npc_dialog(npc_name, npc_role, text, opts)

# --- Serviços ---
func _smith_enhance() -> void:
	var st = _player_stats()
	if not st: return
	st.enhance_weapon()  # o HUD já exibe o resultado do refino

func _open_forge() -> void:
	var h = _hud()
	if h and h.has_method("open_forge_window"):
		h.open_forge_window()

func _sell_materials() -> void:
	var st = _player_stats()
	if not st: return
	var all_items = ItemsDatabase.get_all_items()
	var total = 0
	for id in ["brightsteel_fragment", "menoa_bark"]:
		var n = st.count_item(id)
		if n > 0:
			total += int(n * all_items[id]["value_gold"] * 0.5)
			st.set_item_count(id, 0)
	if total > 0:
		st.gold += total
		st.stats_changed.emit()
		_notify("💰 Materiais vendidos por %d ouro" % total, Color(1.0, 0.85, 0.3))
	else:
		_notify("Você não tem materiais para vender.", Color(0.8, 0.8, 0.8))

func _buy(item_id: String, price: int) -> void:
	var st = _player_stats()
	if not st: return
	if st.gold < price:
		_notify("Ouro insuficiente!", Color(1.0, 0.5, 0.4))
		return
	if not st.add_item(item_id, 1):
		_notify("🎒 Mochila cheia!", Color(1.0, 0.5, 0.4))
		return
	st.gold -= price
	st.stats_changed.emit()
	_notify("Comprado: %s" % ItemsDatabase.get_all_items()[item_id]["name"], Color(0.6, 1.0, 0.7))

func _heal_player() -> void:
	var st = _player_stats()
	if not st or st.gold < 200: return
	st.gold -= 200
	st.heal(st.max_hp)
	st.current_mp = st.max_mp
	st.stats_changed.emit()
	_notify("✨ Vida e mana restauradas!", Color(0.5, 1.0, 0.9))

# --- Missões em cadeia do Brom ---
const QUESTS := [
	{
		"id": "hunt_1",
		"title": "Caçada ao Chifre",
		"desc": "Derrote 5 criaturas nas estradas ao redor do Santuário.",
		"hint": "Estrada Sul e Acampamento Urgal (Z: 25..45)",
		"target_pos": Vector2(0, 34),
		"target_zone": "Estrada Sul",
		"goal": 5,
		"reward_text": "2.500 XP, 20.000 ouro e 2 Joias da Bênção",
		"xp": 2500,
		"gold": 20000,
		"items": [["jewel_bless", 2]]
	},
	{
		"id": "hunt_2",
		"title": "A Marcha dos Gigantes",
		"desc": "Derrote 15 criaturas. Os Kulls e Urgals avançam pelo Oeste.",
		"hint": "Colinas Ocidentais e Floresta Oeste (X: -40..-20)",
		"target_pos": Vector2(-35, 0),
		"target_zone": "Floresta Oeste",
		"goal": 15,
		"reward_text": "9.000 XP, 60.000 ouro, 2 Joias da Alma",
		"xp": 9000,
		"gold": 60000,
		"items": [["jewel_soul", 2]]
	},
	{
		"id": "hunt_3",
		"title": "Sangue de Dragão",
		"desc": "Derrote 30 criaturas e prove seu valor como Cavaleiro.",
		"hint": "Clareira do Norte e Covil das Feras (Z: -30..-60)",
		"target_pos": Vector2(0, -45),
		"target_zone": "Trilha Norte",
		"goal": 30,
		"reward_text": "25.000 XP, 150.000 ouro e 1 Joia do Caos",
		"xp": 25000,
		"gold": 150000,
		"items": [["jewel_chaos", 1]]
	},
]

func _current_quest(st) -> Dictionary:
	for q in QUESTS:
		var d = st.quests.get(q["id"], {})
		if d.is_empty() or not d.get("claimed", false):
			return q
	return {}

func _accept_quest(q: Dictionary) -> void:
	var st = _player_stats()
	if not st: return
	st.start_quest(q["id"], q["goal"], q["title"], q.get("hint", ""), q.get("target_pos", Vector2.ZERO), q.get("target_zone", ""))
	_notify("📜 Missão aceita: %s" % q["title"], Color(1.0, 0.9, 0.5))
	var h = _hud()
	if h and h.has_method("add_log_message"):
		h.add_log_message("Missão aceita: %s" % q["title"], Color(1.0, 0.85, 0.35), "MISSAO")
	_update_quest_marker_visuals()

func _claim_quest(q: Dictionary) -> void:
	var st = _player_stats()
	if not st: return
	var d = st.quests.get(q["id"], {})
	if d.is_empty() or not d.get("done", false) or d.get("claimed", false):
		return
	d["claimed"] = true
	st.gold += q["gold"]
	for it in q["items"]:
		st.add_item(it[0], it[1])
	st.add_xp(q["xp"], "Missão: " + q["title"])
	_notify("🏆 Recompensa recebida! +%d XP" % q["xp"], Color(1.0, 0.85, 0.3))
	var h = _hud()
	if h and h.has_method("add_log_message"):
		h.add_log_message("Missão concluída: %s! +%d XP" % [q["title"], q["xp"]], Color(0.3, 1.0, 0.5), "MISSAO")
	_update_quest_marker_visuals()
