extends Control
class_name InventoryWindow

@onready var close_btn: Button = $Window/Header/CloseButton
@onready var badge_text: Label = $Window/Header/LevelBadge/BadgeText
@onready var hero_name: Label = $Window/Header/HeroName
@onready var hero_title: Label = $Window/Header/HeroTitle

# --- ATRIBUTOS DO HERÓI (DIABLO IV STYLE) ---
@onready var attack_label: Label = $Window/MainVBox/UpperHBox/StatsPanel/VBox/Margin/VBoxInternal/AttackLabel
@onready var armor_label: Label = $Window/MainVBox/UpperHBox/StatsPanel/VBox/Margin/VBoxInternal/ArmorLabel
@onready var life_label: Label = $Window/MainVBox/UpperHBox/StatsPanel/VBox/Margin/VBoxInternal/LifeLabel
@onready var mana_label: Label = $Window/MainVBox/UpperHBox/StatsPanel/VBox/Margin/VBoxInternal/ManaLabel
@onready var cp_label: Label = $Window/MainVBox/UpperHBox/StatsPanel/VBox/Margin/VBoxInternal/CombatPowerLabel
@onready var strength_label: Label = $Window/MainVBox/UpperHBox/StatsPanel/VBox/Margin/VBoxInternal/StrengthLabel
@onready var dexterity_label: Label = $Window/MainVBox/UpperHBox/StatsPanel/VBox/Margin/VBoxInternal/DexterityLabel
@onready var vitality_label: Label = $Window/MainVBox/UpperHBox/StatsPanel/VBox/Margin/VBoxInternal/VitalityLabel
@onready var willpower_label: Label = $Window/MainVBox/UpperHBox/StatsPanel/VBox/Margin/VBoxInternal/WillpowerLabel
@onready var set_bonus_label: Label = $Window/MainVBox/UpperHBox/StatsPanel/VBox/Margin/VBoxInternal/SetBonusLabel

# --- SLOTS DO PAPERDOLL (15 SLOTS) ---
@onready var slot_head: Button = $Window/MainVBox/UpperHBox/PaperdollPanel/HBox/LeftSlots/SlotHead
@onready var slot_chest: Button = $Window/MainVBox/UpperHBox/PaperdollPanel/HBox/LeftSlots/SlotChest
@onready var slot_gloves: Button = $Window/MainVBox/UpperHBox/PaperdollPanel/HBox/LeftSlots/SlotGloves
@onready var slot_pants: Button = $Window/MainVBox/UpperHBox/PaperdollPanel/HBox/LeftSlots/SlotPants
@onready var slot_boots: Button = $Window/MainVBox/UpperHBox/PaperdollPanel/HBox/LeftSlots/SlotBoots

@onready var slot_cape: Button = $Window/MainVBox/UpperHBox/PaperdollPanel/HBox/CenterHeroView/TopPrestigeHBox/SlotCape
@onready var slot_wings: Button = $Window/MainVBox/UpperHBox/PaperdollPanel/HBox/CenterHeroView/TopPrestigeHBox/SlotWings
@onready var slot_weapon_main: Button = $Window/MainVBox/UpperHBox/PaperdollPanel/HBox/CenterHeroView/BottomWeaponsHBox/SlotWeaponMain
@onready var slot_weapon_off: Button = $Window/MainVBox/UpperHBox/PaperdollPanel/HBox/CenterHeroView/BottomWeaponsHBox/SlotWeaponOff

@onready var slot_amulet: Button = $Window/MainVBox/UpperHBox/PaperdollPanel/HBox/RightSlots/SlotAmulet
@onready var slot_ring_1: Button = $Window/MainVBox/UpperHBox/PaperdollPanel/HBox/RightSlots/SlotRing1
@onready var slot_ring_2: Button = $Window/MainVBox/UpperHBox/PaperdollPanel/HBox/RightSlots/SlotRing2
@onready var slot_pet: Button = $Window/MainVBox/UpperHBox/PaperdollPanel/HBox/RightSlots/SlotPet
@onready var slot_mount: Button = $Window/MainVBox/UpperHBox/PaperdollPanel/HBox/RightSlots/SlotMount

@onready var hero_silhouette: Panel = $Window/MainVBox/UpperHBox/PaperdollPanel/HBox/CenterHeroView/HeroSilhouette
@onready var hero_preview_3d: Node3D = $Window/MainVBox/UpperHBox/PaperdollPanel/HBox/CenterHeroView/HeroSilhouette/ViewportContainer/SubViewport/HeroPreview3D

# --- PAINEL DE DETALHES (INSPECTOR) ---
@onready var item_title: Label = $Window/MainVBox/UpperHBox/DetailsPanel/VBox/Margin/VBoxInternal/ItemTitle
@onready var item_type_rarity: Label = $Window/MainVBox/UpperHBox/DetailsPanel/VBox/Margin/VBoxInternal/ItemTypeRarity
@onready var item_stats: Label = $Window/MainVBox/UpperHBox/DetailsPanel/VBox/Margin/VBoxInternal/ItemStats
@onready var item_desc: Label = $Window/MainVBox/UpperHBox/DetailsPanel/VBox/Margin/VBoxInternal/ItemDesc
@onready var btn_equip_toggle: Button = $Window/MainVBox/UpperHBox/DetailsPanel/VBox/BtnEquipToggle
@onready var btn_action: Button = $Window/MainVBox/UpperHBox/DetailsPanel/VBox/BtnAction

# --- MOCHILA COM ABAS (DIABLO IV TABS) ---
@onready var category_label: Label = $Window/MainVBox/BackpackSection/VBox/TabBarHeader/CategoryLabel
@onready var tab_all: Button = $Window/MainVBox/BackpackSection/VBox/TabBarHeader/TabsHBox/TabAll
@onready var tab_equip: Button = $Window/MainVBox/BackpackSection/VBox/TabBarHeader/TabsHBox/TabEquip
@onready var tab_jewels: Button = $Window/MainVBox/BackpackSection/VBox/TabBarHeader/TabsHBox/TabJewels
@onready var tab_potions: Button = $Window/MainVBox/BackpackSection/VBox/TabBarHeader/TabsHBox/TabPotions
@onready var grid_container: GridContainer = $Window/MainVBox/BackpackSection/VBox/ScrollContainer/Margin/GridContainer
@onready var gold_label: Label = $Window/MainVBox/BackpackSection/VBox/CurrencyFooter/GoldLabel
@onready var jewels_label: Label = $Window/MainVBox/BackpackSection/VBox/CurrencyFooter/JewelsLabel

var current_tab: String = "all"
var selected_item_data: Dictionary = {}
var selected_item_id: String = ""
var selected_item_instance: Dictionary = {}
var selected_slot_key: String = ""
var is_equipped_selection: bool = false
var player_stats = null

func _ready() -> void:
	visible = false
	var vp = get_node_or_null("Window/MainVBox/UpperHBox/PaperdollPanel/HBox/CenterHeroView/HeroSilhouette/ViewportContainer/SubViewport")
	if vp:
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED

	if close_btn:
		close_btn.pressed.connect(toggle_inventory)
	if btn_action:
		btn_action.pressed.connect(_on_action_pressed)
	if btn_equip_toggle:
		btn_equip_toggle.pressed.connect(_on_equip_toggle_pressed)

	# Conectar Abas de Filtro
	if tab_all: tab_all.pressed.connect(func(): _set_tab("all"))
	if tab_equip: tab_equip.pressed.connect(func(): _set_tab("equip"))
	if tab_jewels: tab_jewels.pressed.connect(func(): _set_tab("jewels"))
	if tab_potions: tab_potions.pressed.connect(func(): _set_tab("potions"))

	if hero_silhouette:
		hero_silhouette.gui_input.connect(_on_silhouette_gui_input)

	_setup_paperdoll_signals()
	refresh_inventory()

var is_dragging_preview: bool = false

func _on_silhouette_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging_preview = event.pressed
			if hero_preview_3d:
				hero_preview_3d.is_dragging = is_dragging_preview
	elif event is InputEventMouseMotion and is_dragging_preview:
		if hero_preview_3d:
			hero_preview_3d.rotate_hero(event.relative.x)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		toggle_inventory()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		toggle_inventory()
		get_viewport().set_input_as_handled()

func toggle_inventory() -> void:
	visible = !visible
	var vp = get_node_or_null("Window/MainVBox/UpperHBox/PaperdollPanel/HBox/CenterHeroView/HeroSilhouette/ViewportContainer/SubViewport")
	if vp:
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if visible else SubViewport.UPDATE_DISABLED
	GameAudio.play_ui(get_tree(), "open" if visible else "close")
	if visible:
		refresh_inventory()

func _set_tab(tab_name: String) -> void:
	current_tab = tab_name
	match tab_name:
		"all": if category_label: category_label.text = "  📦 TODOS OS ITENS (33 SLOTS)"
		"equip": if category_label: category_label.text = "  ⚔️ EQUIPAMENTOS & ARMAS"
		"jewels": if category_label: category_label.text = "  💎 SOQUETES, JOIAS & RUNAS"
		"potions": if category_label: category_label.text = "  🧪 CONSUMÍVEIS & POÇÕES"
	refresh_inventory()

func refresh_inventory() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.stats:
		player_stats = player.stats
		if not player_stats.bag_changed.is_connected(_on_external_bag_change):
			player_stats.bag_changed.connect(_on_external_bag_change)
			player_stats.stat_points_changed.connect(_on_external_bag_change)

	var all_items = ItemsDatabase.get_all_items()

	# Atualizar Cabeçalho e Stats Diablo IV
	if player_stats:
		if badge_text: badge_text.text = str(player_stats.level)
		if hero_name: hero_name.text = "%s (Nvl %d)" % [player_stats.character_name.to_upper(), player_stats.level]
		if attack_label: attack_label.text = "⚔️ Poder de Ataque:  %d" % int(player_stats.get_total_attack())
		if armor_label: armor_label.text = "🛡️ Armadura / Defesa:  %d" % int(player_stats.get_total_defense())
		if life_label: life_label.text = "❤️ Vida (HP):  %d / %d" % [int(player_stats.current_hp), int(player_stats.max_hp)]
		if mana_label: mana_label.text = "🔮 Mana (MP):  %d / %d" % [int(player_stats.current_mp), int(player_stats.max_mp)]
		if cp_label: cp_label.text = "⚡ Poder Total (CP):  %d" % player_stats.get_combat_power()

		if strength_label: strength_label.text = "Força (Strength):       %d" % player_stats.strength
		if dexterity_label: dexterity_label.text = "Destreza (Dexterity):   %d" % player_stats.dexterity
		if vitality_label: vitality_label.text = "Vitalidade (Vitality):  %d" % player_stats.vitality
		if willpower_label: willpower_label.text = "Vontade (Willpower):   %d" % player_stats.willpower

		if set_bonus_label:
			var active_sets: Array = []
			var counted = {}
			for s in player_stats.equipped_gear.keys():
				var sid = player_stats._get_slot_item_id(s)
				if all_items.has(sid) and all_items[sid].has("set_name"):
					var sn = all_items[sid]["set_name"]
					if not counted.has(sn):
						counted[sn] = player_stats._get_set_count(sn)
						if counted[sn] >= 2:
							var sdef = ItemsDatabase.get_set_definition(sn)
							active_sets.append("%s (%d/6)" % [sdef.get("name", sn), counted[sn]])
			if active_sets.size() > 0:
				set_bonus_label.text = "🌟 Conjuntos: " + " | ".join(active_sets)
				set_bonus_label.modulate = Color(0.3, 1.0, 0.6)
			else:
				set_bonus_label.text = "🌟 Conjunto: Nenhum bônus ativo"
				set_bonus_label.modulate = Color(0.6, 0.6, 0.6)

		# Atualizar Paperdoll (15 Slots)
		var eq = player_stats.equipped_gear
		_update_slot_btn(slot_head, eq.get("head", ""), "— Elmo —")
		_update_slot_btn(slot_chest, eq.get("chest", ""), "— Peitoral —")
		_update_slot_btn(slot_gloves, eq.get("gloves", ""), "— Manoplas —")
		_update_slot_btn(slot_pants, eq.get("pants", ""), "— Perneiras —")
		_update_slot_btn(slot_boots, eq.get("boots", ""), "— Grevas —")

		_update_slot_btn(slot_cape, eq.get("cape", ""), "— Capa —")
		_update_slot_btn(slot_wings, eq.get("wings", ""), "— Asas —")
		_update_slot_btn(slot_weapon_main, eq.get("weapon_main", ""), "— Lâmina —")
		_update_slot_btn(slot_weapon_off, eq.get("weapon_off", ""), "— Escudo —")

		_update_slot_btn(slot_amulet, eq.get("amulet", ""), "— Amuleto —")
		_update_slot_btn(slot_ring_1, eq.get("ring_1", ""), "— Anel I —")
		_update_slot_btn(slot_ring_2, eq.get("ring_2", ""), "— Anel II —")
		_update_slot_btn(slot_pet, eq.get("pet", ""), "— Companheiro —")
		_update_slot_btn(slot_mount, eq.get("mount", ""), "— Montaria —")

		# Sincronizar o Modelo 3D no centro com os equipamentos reais
		if hero_preview_3d and hero_preview_3d.has_method("update_visuals"):
			hero_preview_3d.update_visuals(player_stats.equipped_gear, player_stats.current_class_id)

		# Atualizar Moedas no Rodapé
		if gold_label: gold_label.text = "  💰 %s Ouro" % _format_number(player_stats.gold)
		if jewels_label: jewels_label.text = "💎 Bless: %d   🔮 Soul: %d   🔥 Chaos: %d" % [player_stats.jewels_bless, player_stats.jewels_soul, player_stats.jewels_chaos]

	# Atualizar Grade da Mochila REAL (33 slots, arrastar & soltar)
	if not grid_container:
		return
	for child in grid_container.get_children():
		grid_container.remove_child(child)
		child.queue_free()

	var bag: Array = player_stats.bag if player_stats else []
	for i in range(CharacterStats.BAG_SIZE):
		var slot_btn = Button.new()
		slot_btn.custom_minimum_size = Vector2(40, 40)
		slot_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		slot_btn.add_theme_font_size_override("font_size", 8)
		slot_btn.set_meta("bag_idx", i)

		var style = StyleBoxFlat.new()
		style.set_corner_radius_all(4)
		style.set_border_width_all(1)

		var entry: Dictionary = bag[i] if i < bag.size() else {}
		if not entry.is_empty() and all_items.has(entry["id"]):
			var i_id: String = entry["id"]
			var count: int = int(entry["count"])
			var d = all_items[i_id]
			var short_name = d["name"].split(" ")[1] if d["name"].split(" ").size() > 1 else "Item"
			slot_btn.icon = RPGIconGenerator.get_item_icon(i_id, d, 24)
			slot_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			slot_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			slot_btn.text = (str(count) + "x") if count > 1 else short_name.substr(0, 6)
			var rarity_color = _get_rarity_color(d["rarity"])
			slot_btn.add_theme_color_override("font_color", rarity_color)
			style.bg_color = Color(0.06, 0.07, 0.10, 0.96)
			style.border_color = rarity_color
			slot_btn.tooltip_text = _build_item_tooltip(d, entry, false)
			slot_btn.pressed.connect(select_item.bind(d, i_id, count, false, "", entry))
			slot_btn.gui_input.connect(_on_bag_slot_input.bind(i))
			# Aba atual: itens fora do filtro ficam esmaecidos (a posição na mochila é preservada)
			if not _matches_tab(d["type"]):
				slot_btn.modulate = Color(1, 1, 1, 0.28)
		else:
			style.bg_color = Color(0.04, 0.05, 0.07, 0.6)
			style.border_color = Color(0.2, 0.22, 0.26, 0.4)
			slot_btn.text = "·"
			slot_btn.modulate = Color(0.6, 0.6, 0.6, 0.45)
		slot_btn.add_theme_stylebox_override("normal", style)
		slot_btn.add_theme_stylebox_override("hover", style)
		slot_btn.add_theme_stylebox_override("pressed", style)
		slot_btn.set_drag_forwarding(_bag_get_drag.bind(i), _bag_can_drop.bind(i), _bag_drop.bind(i))
		grid_container.add_child(slot_btn)

	_refresh_stat_points_ui()

	# Selecionar primeiro item por padrão se nenhum estiver selecionado
	if selected_item_data.is_empty() and player_stats:
		var found_selection = false
		# 1. Tentar primeiro item equipado
		for slot_k in ["weapon_main", "chest", "head", "pants", "boots", "gloves", "shoulders", "cape", "wings", "weapon_off", "pet", "ring_1", "ring_2", "amulet", "mount"]:
			var sid = player_stats._get_slot_item_id(slot_k)
			if sid != "" and all_items.has(sid):
				var raw_val = player_stats.equipped_gear.get(slot_k, {})
				var gear_instance: Dictionary = raw_val if raw_val is Dictionary else {}
				select_item(all_items[sid], sid, 1, true, slot_k, gear_instance)
				found_selection = true
				break
		# 2. Se nada equipado, tentar primeiro item válido da mochila
		if not found_selection and player_stats.bag:
			for entry in player_stats.bag:
				if not entry.is_empty() and all_items.has(entry.get("id", "")):
					var bid = entry["id"]
					select_item(all_items[bid], bid, int(entry.get("count", 1)), false, "", entry)
					found_selection = true
					break
		# 3. Se tudo estiver vazio, limpa o painel de inspeção
		if not found_selection:
			clear_details()

func _on_external_bag_change() -> void:
	if visible:
		refresh_inventory.call_deferred()

func _matches_tab(itype) -> bool:
	match current_tab:
		"equip":
			return itype in [ItemsDatabase.ItemType.WEAPON, ItemsDatabase.ItemType.WEAPON_OFFHAND,
					ItemsDatabase.ItemType.ARMOR_HEAD, ItemsDatabase.ItemType.ARMOR_SHOULDER,
					ItemsDatabase.ItemType.ARMOR_CHEST, ItemsDatabase.ItemType.ARMOR_GLOVES,
					ItemsDatabase.ItemType.ARMOR_PANTS, ItemsDatabase.ItemType.ARMOR_BOOTS,
					ItemsDatabase.ItemType.CAPE, ItemsDatabase.ItemType.WINGS]
		"jewels":
			return itype in [ItemsDatabase.ItemType.JEWEL, ItemsDatabase.ItemType.RING, ItemsDatabase.ItemType.AMULET]
		"potions":
			return itype in [ItemsDatabase.ItemType.CONSUMABLE, ItemsDatabase.ItemType.TOME]
	return true

# --- ARRASTAR & SOLTAR (mochila <-> mochila <-> paperdoll) ---
func _bag_get_drag(_pos: Vector2, idx: int) -> Variant:
	if not player_stats or idx >= player_stats.bag.size() or player_stats.bag[idx].is_empty():
		return null
	var all_items = ItemsDatabase.get_all_items()
	var item_id: String = player_stats.bag[idx]["id"]
	var preview = TextureRect.new()
	preview.texture = RPGIconGenerator.get_item_icon(item_id, all_items.get(item_id, {}), 32)
	preview.custom_minimum_size = Vector2(36, 36)
	preview.modulate = Color(1, 1, 1, 0.85)
	set_drag_preview(preview)
	return {"src": "bag", "idx": idx, "id": item_id}

func _bag_can_drop(_pos: Vector2, data: Variant, _idx: int) -> bool:
	return data is Dictionary and data.has("src")

func _bag_drop(_pos: Vector2, data: Variant, idx: int) -> void:
	if not player_stats or not (data is Dictionary):
		return
	if data["src"] == "bag":
		player_stats.move_bag_item(int(data["idx"]), idx)
	elif data["src"] == "gear":
		if not player_stats.unequip_to_bag(String(data["slot"]), idx):
			_notify("Não foi possível mover para este slot.", Color(1.0, 0.5, 0.4))
	refresh_inventory()

func _gear_get_drag(_pos: Vector2, slot_key: String) -> Variant:
	if not player_stats or not player_stats.equipped_gear.has(slot_key):
		return null
	var all_items = ItemsDatabase.get_all_items()
	var item_id: String = player_stats.equipped_gear[slot_key]
	var preview = TextureRect.new()
	preview.texture = RPGIconGenerator.get_item_icon(item_id, all_items.get(item_id, {}), 32)
	preview.custom_minimum_size = Vector2(36, 36)
	set_drag_preview(preview)
	return {"src": "gear", "slot": slot_key, "id": item_id}

func _gear_can_drop(_pos: Vector2, data: Variant, slot_key: String) -> bool:
	if not (data is Dictionary) or data.get("src", "") != "bag" or not player_stats:
		return false
	var all_items = ItemsDatabase.get_all_items()
	var item_id: String = data.get("id", "")
	if not all_items.has(item_id):
		return false
	var k = ItemsDatabase.get_slot_key_for_type(all_items[item_id]["type"])
	return k == slot_key or (k == "ring_1" and slot_key == "ring_2")

func _gear_drop(_pos: Vector2, data: Variant, slot_key: String) -> void:
	if player_stats and player_stats.equip_from_bag(int(data["idx"]), slot_key):
		refresh_inventory()

func _on_bag_slot_input(event: InputEvent, idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
		if not player_stats or player_stats.bag[idx].is_empty():
			return
		var all_items = ItemsDatabase.get_all_items()
		var item_entry = player_stats.bag[idx]
		var item_id: String = item_entry.get("id", "")
		if ItemsDatabase.get_slot_key_for_type(all_items[item_id]["type"]) != "":
			var check = player_stats.can_equip_item(item_entry)
			if not check.get("can_equip", true):
				_notify(check.get("reason", "Não pode equipar!"), Color(1.0, 0.4, 0.4))
				return
			if player_stats.equip_from_bag(idx):
				_notify("Equipado: %s" % all_items[item_id]["name"], Color(0.5, 1.0, 0.7))
		else:
			var msg = player_stats.use_bag_item(idx)
			if msg != "":
				_notify(msg, Color(0.6, 1.0, 0.7))
		refresh_inventory()

func _notify(msg: String, color: Color) -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification(msg, color)

# --- EVOLUÇÃO: PONTOS DE ATRIBUTO ---
var _points_box: HBoxContainer
var _points_label: Label

func _refresh_stat_points_ui() -> void:
	if not player_stats or not set_bonus_label:
		return
	if _points_box == null or not is_instance_valid(_points_box):
		_points_box = HBoxContainer.new()
		_points_label = Label.new()
		_points_label.add_theme_font_size_override("font_size", 10)
		_points_box.add_child(_points_label)
		for pair in [["FOR", "strength"], ["DES", "dexterity"], ["VIT", "vitality"], ["VON", "willpower"]]:
			var b = Button.new()
			b.text = "+" + pair[0]
			b.add_theme_font_size_override("font_size", 9)
			b.pressed.connect(_on_spend_point.bind(pair[1]))
			_points_box.add_child(b)
		set_bonus_label.get_parent().add_child(_points_box)
	var sp = player_stats.stat_points
	_points_label.text = "Pontos: %d  " % sp
	_points_label.modulate = Color(1.0, 0.85, 0.3) if sp > 0 else Color(0.6, 0.6, 0.6)
	for c in _points_box.get_children():
		if c is Button:
			c.disabled = sp <= 0

func _on_spend_point(attr: String) -> void:
	if player_stats and player_stats.spend_stat_point(attr):
		refresh_inventory()

## Constrói tooltip rico com Refino, Requisitos de Nível/Classe/Asas, Affixes e Bônus de Conjunto
func _build_item_tooltip(d: Dictionary, item_instance: Dictionary = {}, is_equipped: bool = false) -> String:
	var lines: Array = []
	var name_str = d.get("name", "Item")
	var ref = item_instance.get("refine", 0)
	if ref > 0:
		name_str += " (+%d)" % ref
	elif is_equipped and player_stats:
		var itype = d.get("type", -1)
		if itype == ItemsDatabase.ItemType.WEAPON and player_stats.weapon_refine > 0:
			name_str += " (+%d)" % player_stats.weapon_refine
		elif itype == ItemsDatabase.ItemType.ARMOR_CHEST and player_stats.armor_refine > 0:
			name_str += " (+%d)" % player_stats.armor_refine

	lines.append(name_str)
	lines.append("Raridade: %s" % _get_rarity_string(d.get("rarity", 0)))

	# Requisitos de Nível e Classe
	var req_lvl = item_instance.get("level_req", d.get("level_req", 1))
	var my_lvl = player_stats.level if player_stats else 1
	var lvl_status = "✓" if my_lvl >= req_lvl else "❌ Requer Nvl %d" % req_lvl
	lines.append("Nível Mínimo: %d [%s]" % [req_lvl, lvl_status])

	var req_cls = item_instance.get("class_req", d.get("class_req", ""))
	if req_cls != "":
		var my_cls = player_stats.current_class_id if player_stats else ""
		var cls_name = ClassesData.get_all_classes().get(req_cls, {}).get("name", req_cls)
		var cls_status = "✓" if my_cls == req_cls else "❌ Incompatível"
		lines.append("Classe: %s [%s]" % [cls_name, cls_status])

	if d.get("type") == ItemsDatabase.ItemType.WINGS:
		var w_tier = d.get("tier", 1)
		var min_w_lvl = 30 if w_tier == 1 else (40 if w_tier == 2 else 50)
		var w_status = "✓" if my_lvl >= min_w_lvl else "❌ Requer Nvl %d" % min_w_lvl
		lines.append("Asas Nvl %d: Voo Nvl %d [%s]" % [w_tier, min_w_lvl, w_status])

	# Stats Básicos
	if d.has("base_attack"): lines.append("⚔️ Ataque Base: %d" % d["base_attack"])
	elif d.has("base_damage"): lines.append("⚔️ Ataque Base: %d" % d["base_damage"])
	if d.has("base_defense"): lines.append("🛡️ Defesa Base: %d" % d["base_defense"])
	if d.has("damage_absorb"): lines.append("🛡️ Absorção: %d%%" % int(d["damage_absorb"] * 100))
	if d.has("damage_bonus_pct"): lines.append("⚡ Dano Adicional: +%d%%" % d["damage_bonus_pct"])

	# Atributos Aleatórios (Affixes)
	var affs = item_instance.get("affixes", [])
	if affs.size() > 0:
		lines.append("─── Atributos Místicos ───")
		for af in affs:
			lines.append("✦ %s" % af.get("desc", "+%s %s" % [str(af.get("val", 0)), af.get("stat", "")]))

	# Conjunto (Set)
	if d.has("set_name"):
		var sname = d["set_name"]
		var sdef = ItemsDatabase.get_set_definition(sname)
		var eq_count = player_stats._get_set_count(sname) if player_stats else 0
		lines.append("─── %s (%d/6) ───" % [sdef.get("name", sname), eq_count])
		var b_map = sdef.get("bonuses", {})
		for req_pc in [2, 4, 6]:
			if b_map.has(req_pc):
				var tag = "🟢" if eq_count >= req_pc else "⚪"
				lines.append("%s (%d Peças): %s" % [tag, req_pc, b_map[req_pc].get("desc", "")])

	return "\n".join(lines)

func _update_slot_btn(btn: Button, item_val, default_text: String) -> void:
	if not btn: return
	var item_id: String = ""
	var item_instance: Dictionary = {}
	if item_val is Dictionary:
		item_id = item_val.get("id", "")
		item_instance = item_val
	elif item_val is String:
		item_id = item_val

	var all_items = ItemsDatabase.get_all_items()
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2

	if all_items.has(item_id):
		var d = all_items[item_id]
		var icon = d["name"].split(" ")[0]
		var short_name = d["name"].substr(icon.length()).strip_edges()
		if short_name.length() > 12:
			short_name = short_name.substr(0, 10) + ".."
		var rarity_color = _get_rarity_color(d["rarity"])
		style.bg_color = Color(0.06, 0.07, 0.09, 0.96)
		style.border_color = rarity_color
		style.shadow_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.35)
		style.shadow_size = 3
		btn.icon = RPGIconGenerator.get_item_icon(item_id, d, 24)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text = short_name
		btn.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82, 1.0))
		btn.add_theme_font_size_override("font_size", 9)
		btn.tooltip_text = _build_item_tooltip(d, item_instance, true)
	else:
		style.bg_color = Color(0.04, 0.05, 0.07, 0.85)
		style.border_color = Color(0.24, 0.21, 0.16, 0.6)
		style.shadow_size = 0
		btn.icon = null
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.text = default_text
		btn.add_theme_color_override("font_color", Color(0.45, 0.44, 0.40))
		btn.add_theme_font_size_override("font_size", 9)
		btn.tooltip_text = ""

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

func _setup_paperdoll_signals() -> void:
	var slots = {
		slot_head: "head",
		slot_cape: "cape",
		slot_gloves: "gloves",
		slot_wings: "wings",
		slot_weapon_main: "weapon_main",
		slot_chest: "chest",
		slot_mount: "mount",
		slot_weapon_off: "weapon_off",
		slot_pants: "pants",
		slot_pet: "pet",
		slot_amulet: "amulet",
		slot_boots: "boots",
		slot_ring_1: "ring_1",
		slot_ring_2: "ring_2"
	}
	for btn in slots.keys():
		if btn:
			var skey = slots[btn]
			btn.pressed.connect(func(): _on_paperdoll_slot_clicked(skey))
			btn.set_drag_forwarding(_gear_get_drag.bind(skey), _gear_can_drop.bind(skey), _gear_drop.bind(skey))

func _on_paperdoll_slot_clicked(slot_key: String) -> void:
	if not player_stats: return
	var all_items = ItemsDatabase.get_all_items()
	var item_val = player_stats.equipped_gear.get(slot_key, "")
	var item_id: String = item_val.get("id", "") if item_val is Dictionary else item_val
	var item_instance: Dictionary = item_val if item_val is Dictionary else {}
	if item_id != "" and all_items.has(item_id):
		select_item(all_items[item_id], item_id, 1, true, slot_key, item_instance)
	else:
		var slot_names = {
			"head": "Elmo", "chest": "Peitoral", "gloves": "Manoplas",
			"pants": "Perneiras", "boots": "Grevas", "shoulders": "Ombreiras",
			"cape": "Capa", "wings": "Asas", "weapon_main": "Arma Principal",
			"weapon_off": "Escudo / Secundária", "ring_1": "Anel I", "ring_2": "Anel II",
			"amulet": "Amuleto", "pet": "Companheiro", "mount": "Montaria"
		}
		clear_details("Slot Vazio: " + slot_names.get(slot_key, slot_key.capitalize()))

func clear_details(placeholder_title: String = "") -> void:
	selected_item_data = {}
	selected_item_id = ""
	selected_item_instance = {}
	selected_slot_key = ""
	is_equipped_selection = false

	if item_title:
		item_title.text = placeholder_title if placeholder_title != "" else "Nenhum Item Selecionado"
	if item_type_rarity:
		item_type_rarity.text = "Clique em um item da mochila ou slot para inspecionar"
		item_type_rarity.modulate = Color(0.6, 0.6, 0.6)
	if item_desc:
		item_desc.text = "Selecione um item para ver atributos, requisitos de nível/classe, efeitos de conjunto ou aprimorar."
	if item_stats:
		item_stats.text = ""
	if btn_equip_toggle:
		btn_equip_toggle.visible = false
	if btn_action:
		btn_action.visible = false

func select_item(data: Dictionary, item_id: String, count: int, is_equipped: bool, slot_key: String, item_instance_val: Variant = {}) -> void:
	var item_instance: Dictionary = item_instance_val if item_instance_val is Dictionary else {}
	selected_item_data = data
	selected_item_id = item_id
	selected_item_instance = item_instance
	selected_slot_key = slot_key
	is_equipped_selection = is_equipped

	var ref = item_instance.get("refine", 0)
	if ref == 0 and is_equipped and player_stats:
		var itype = data.get("type", -1)
		if itype == ItemsDatabase.ItemType.WEAPON and player_stats.weapon_refine > 0:
			ref = player_stats.weapon_refine
		elif itype == ItemsDatabase.ItemType.ARMOR_CHEST and player_stats.armor_refine > 0:
			ref = player_stats.armor_refine

	var title_str = data.get("name", "Item")
	if ref > 0:
		title_str += " (+%d)" % ref
	if count > 1:
		title_str += " (%dx)" % count

	if item_title:
		item_title.text = title_str

	if item_type_rarity:
		var rarity_str = _get_rarity_string(data.get("rarity", 0))
		item_type_rarity.text = "Raridade: %s" % rarity_str
		item_type_rarity.modulate = _get_rarity_color(data.get("rarity", 0))

	if item_desc:
		item_desc.text = data.get("description", "")

	if item_stats:
		var stat_text = ""
		# Requisitos
		var req_lvl = item_instance.get("level_req", data.get("level_req", 1))
		var my_lvl = player_stats.level if player_stats else 1
		var lvl_ok = my_lvl >= req_lvl
		stat_text += "📜 Nível Requerido: %d %s\n" % [req_lvl, "✓" if lvl_ok else "❌ (Insuficiente)"]

		var req_cls = item_instance.get("class_req", data.get("class_req", ""))
		if req_cls != "":
			var my_cls = player_stats.current_class_id if player_stats else ""
			var cls_name = ClassesData.get_all_classes().get(req_cls, {}).get("name", req_cls)
			var cls_ok = (my_cls == req_cls)
			stat_text += "👤 Classe: %s %s\n" % [cls_name, "✓" if cls_ok else "❌ (Incompatível)"]

		if data.get("type") == ItemsDatabase.ItemType.WINGS:
			var w_tier = data.get("tier", 1)
			var min_w_lvl = 30 if w_tier == 1 else (40 if w_tier == 2 else 50)
			var w_ok = my_lvl >= min_w_lvl
			stat_text += "🪽 Asas Nvl %d: Voo Nvl %d %s\n" % [w_tier, min_w_lvl, "✓" if w_ok else "❌ (Bloqueado)"]

		if data.has("base_attack"):
			stat_text += "⚔️ Dano Base: %d\n" % data["base_attack"]
		elif data.has("base_damage"):
			stat_text += "⚔️ Dano Base: %d\n" % data["base_damage"]
		if data.has("base_defense"):
			stat_text += "🛡️ Defesa Base: %d\n" % data["base_defense"]
		if data.has("damage_absorb"):
			stat_text += "🛡️ Absorção de Dano: %d%%\n" % int(data["damage_absorb"] * 100)
		if data.has("damage_bonus_pct"):
			stat_text += "⚡ Dano Adicional: +%d%%\n" % data["damage_bonus_pct"]
		if data.has("magic_resist"):
			stat_text += "🔮 Resistência Mágica: %d\n" % data["magic_resist"]
		if data.has("special_effect"):
			stat_text += "✨ Efeito Especial: %s\n" % data["special_effect"]

		# Atributos Aleatórios (Affixes)
		var affs = item_instance.get("affixes", [])
		if affs.size() > 0:
			stat_text += "\n─── Atributos Místicos ───\n"
			for af in affs:
				stat_text += "✦ %s\n" % af.get("desc", "+%s %s" % [str(af.get("val", 0)), af.get("stat", "")])

		# Conjuntos (Sets)
		if data.has("set_name"):
			var sname = data["set_name"]
			var sdef = ItemsDatabase.get_set_definition(sname)
			var eq_count = player_stats._get_set_count(sname) if player_stats else 0
			stat_text += "\n─── %s (%d/6) ───\n" % [sdef.get("name", sname), eq_count]
			var b_map = sdef.get("bonuses", {})
			for req_pc in [2, 4, 6]:
				if b_map.has(req_pc):
					var tag = "🟢" if eq_count >= req_pc else "⚪"
					stat_text += "%s (%d Peças): %s\n" % [tag, req_pc, b_map[req_pc].get("desc", "")]

		stat_text += "\n💰 Valor de Venda: %d Ouro" % data.get("value_gold", 0)
		item_stats.text = stat_text

	if btn_equip_toggle:
		if is_equipped:
			btn_equip_toggle.text = "Desequipar"
			btn_equip_toggle.visible = true
		elif ItemsDatabase.get_slot_key_for_type(data.get("type", ItemsDatabase.ItemType.CONSUMABLE)) != "":
			btn_equip_toggle.text = "Equipar no Herói"
			btn_equip_toggle.visible = true
		else:
			btn_equip_toggle.visible = false

	if btn_action:
		var itype = data.get("type", ItemsDatabase.ItemType.CONSUMABLE)
		if itype == ItemsDatabase.ItemType.WEAPON or itype == ItemsDatabase.ItemType.ARMOR_CHEST:
			var ref_act = player_stats.weapon_refine if itype == ItemsDatabase.ItemType.WEAPON and player_stats else 0
			btn_action.text = "⚡ Aprimorar (+%d ➔ +%d)" % [ref_act, ref_act + 1]
			btn_action.visible = true
		elif itype == ItemsDatabase.ItemType.JEWEL:
			btn_action.text = "⚡ Usar para Aprimorar Lâmina"
			btn_action.visible = true
		else:
			btn_action.visible = false

func _on_equip_toggle_pressed() -> void:
	if not player_stats or selected_item_data.is_empty():
		return
	if is_equipped_selection and selected_slot_key != "":
		var was_data = selected_item_data
		var was_id = selected_item_id
		if player_stats.unequip_to_bag(selected_slot_key):
			select_item(was_data, was_id, 1, false, "")
		else:
			_notify("Mochila cheia!", Color(1.0, 0.5, 0.4))
		refresh_inventory()
	else:
		var idx = -1
		for i in player_stats.bag.size():
			if not player_stats.bag[i].is_empty() and player_stats.bag[i]["id"] == selected_item_id:
				idx = i
				break
		var target_slot = ItemsDatabase.get_slot_key_for_type(selected_item_data.get("type", ItemsDatabase.ItemType.CONSUMABLE))
		if target_slot != "":
			var was_data = selected_item_data
			var was_id = selected_item_id
			if idx >= 0:
				var check = player_stats.can_equip_item(player_stats.bag[idx])
				if not check.get("can_equip", true):
					_notify(check.get("reason", "Não pode equipar!"), Color(1.0, 0.4, 0.4))
					return
				player_stats.equip_from_bag(idx)
			else:
				var check = player_stats.can_equip_item(selected_item_id)
				if not check.get("can_equip", true):
					_notify(check.get("reason", "Não pode equipar!"), Color(1.0, 0.4, 0.4))
					return
				player_stats.equip_gear(target_slot, selected_item_id)
			select_item(was_data, was_id, 1, true, target_slot)
			refresh_inventory()

func _on_action_pressed() -> void:
	if not player_stats: return
	var itype = selected_item_data.get("type", ItemsDatabase.ItemType.CONSUMABLE)
	if itype == ItemsDatabase.ItemType.JEWEL or selected_item_id == "sword_brisingr":
		player_stats.enhance_weapon()
		refresh_inventory()

func _format_number(n: int) -> String:
	var s = str(n)
	var res = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	return res

func _get_rarity_color(rarity: ItemsDatabase.Rarity) -> Color:
	match rarity:
		ItemsDatabase.Rarity.COMMON: return Color(0.8, 0.8, 0.8)
		ItemsDatabase.Rarity.MAGIC: return Color(0.2, 0.9, 0.4)
		ItemsDatabase.Rarity.RARE: return Color(0.2, 0.7, 1.0)
		ItemsDatabase.Rarity.EPIC: return Color(0.75, 0.3, 0.95)
		ItemsDatabase.Rarity.LEGENDARY: return Color(1.0, 0.82, 0.15)
		ItemsDatabase.Rarity.MYTHIC: return Color(1.0, 0.25, 0.3)
		ItemsDatabase.Rarity.DIVINE: return Color(1.0, 0.45, 0.95)
	return Color.WHITE

func _get_rarity_string(rarity: ItemsDatabase.Rarity) -> String:
	match rarity:
		ItemsDatabase.Rarity.COMMON: return "Comum"
		ItemsDatabase.Rarity.MAGIC: return "Mágico"
		ItemsDatabase.Rarity.RARE: return "Raro"
		ItemsDatabase.Rarity.EPIC: return "Épico"
		ItemsDatabase.Rarity.LEGENDARY: return "Lendário (Brightsteel)"
		ItemsDatabase.Rarity.MYTHIC: return "Mítico (Reis Cavaleiros)"
		ItemsDatabase.Rarity.DIVINE: return "Divino (Origem Primordial)"
	return "Comum"
