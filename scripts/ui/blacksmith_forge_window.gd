extends Panel
class_name BlacksmithForgeWindow

const ForgeRecipesClass = preload("res://scripts/data/forge_recipes.gd")

@onready var title_label: Label = $VBox/Header/TitleLabel
@onready var close_btn: Button = $VBox/Header/CloseButton
@onready var recipes_container: VBoxContainer = $VBox/Body/LeftPanel/Scroll/RecipeList
@onready var cat_all_btn: Button = $VBox/Body/LeftPanel/Categories/BtnAll
@onready var cat_wings_btn: Button = $VBox/Body/LeftPanel/Categories/BtnWings
@onready var cat_weapons_btn: Button = $VBox/Body/LeftPanel/Categories/BtnWeapons
@onready var cat_jewels_btn: Button = $VBox/Body/LeftPanel/Categories/BtnJewels
@onready var cat_alchemy_btn: Button = $VBox/Body/LeftPanel/Categories/BtnAlchemy

@onready var result_icon: TextureRect = $VBox/Body/RightPanel/ResultBox/Icon
@onready var result_name: Label = $VBox/Body/RightPanel/ResultBox/Info/Name
@onready var result_type: Label = $VBox/Body/RightPanel/ResultBox/Info/Type
@onready var result_desc: Label = $VBox/Body/RightPanel/ResultBox/Info/Desc
@onready var ingredients_container: VBoxContainer = $VBox/Body/RightPanel/IngredientsBox/List
@onready var success_rate_label: Label = $VBox/Body/RightPanel/Footer/SuccessLabel
@onready var cost_label: Label = $VBox/Body/RightPanel/Footer/CostLabel
@onready var craft_button: Button = $VBox/Body/RightPanel/Footer/CraftButton
@onready var status_feedback: Label = $VBox/Body/RightPanel/Footer/StatusFeedback

var player_stats = null
var current_category: String = "Todas"
var selected_recipe: Dictionary = {}
var all_recipes: Array[Dictionary] = []

func _ready() -> void:
	visible = false
	all_recipes = ForgeRecipesClass.get_all_recipes()

	if close_btn:
		close_btn.pressed.connect(close_forge)
	if craft_button:
		craft_button.pressed.connect(_on_craft_pressed)

	if cat_all_btn: cat_all_btn.pressed.connect(func(): _set_category("Todas"))
	if cat_wings_btn: cat_wings_btn.pressed.connect(func(): _set_category("Asas"))
	if cat_weapons_btn: cat_weapons_btn.pressed.connect(func(): _set_category("Armas"))
	if cat_jewels_btn: cat_jewels_btn.pressed.connect(func(): _set_category("Joias"))
	if cat_alchemy_btn: cat_alchemy_btn.pressed.connect(func(): _set_category("Alquimia"))

func open_forge() -> void:
	visible = true
	var pl = get_tree().get_first_node_in_group("player")
	if pl and pl.get("stats"):
		player_stats = pl.stats
		if not player_stats.stats_changed.is_connected(_refresh_ui):
			player_stats.stats_changed.connect(_refresh_ui)

	if not all_recipes.is_empty() and selected_recipe.is_empty():
		selected_recipe = all_recipes[0]

	_populate_recipe_list()
	_display_selected_recipe()

func close_forge() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			close_forge()
			get_viewport().set_input_as_handled()

func _set_category(cat: String) -> void:
	current_category = cat
	_populate_recipe_list()

func _refresh_ui() -> void:
	if visible:
		_populate_recipe_list()
		_display_selected_recipe()

func _populate_recipe_list() -> void:
	if not recipes_container:
		return
	for child in recipes_container.get_children():
		child.queue_free()

	for recipe in all_recipes:
		if current_category != "Todas" and recipe.get("category", "") != current_category:
			continue

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 48)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		var can = ForgeRecipesClass.can_craft(recipe, player_stats) if player_stats else false
		var status_icon = "🟢" if can else "⚪"
		btn.text = " %s %s" % [status_icon, recipe["name"]]
		btn.add_theme_font_size_override("font_size", 12)

		if selected_recipe and selected_recipe.get("id") == recipe["id"]:
			btn.modulate = Color(1.0, 0.9, 0.3)
		elif can:
			btn.modulate = Color(0.85, 1.0, 0.9)
		else:
			btn.modulate = Color(0.7, 0.72, 0.78)

		var cur_r = recipe
		btn.pressed.connect(func():
			selected_recipe = cur_r
			_populate_recipe_list()
			_display_selected_recipe()
		)
		recipes_container.add_child(btn)

func _display_selected_recipe() -> void:
	if selected_recipe.is_empty() or not result_name:
		return

	var res_id = selected_recipe.get("result_id", "")
	var all_items = ItemsDatabase.get_all_items()
	var res_data = all_items.get(res_id, {})

	result_name.text = selected_recipe.get("name", "Receita")
	result_type.text = "< Categoria: %s >" % selected_recipe.get("category", "Geral")
	result_desc.text = selected_recipe.get("desc", "")

	if result_icon and not res_data.is_empty():
		result_icon.texture = RPGIconGenerator.get_item_icon(res_id, res_data, 64)

	# Limpar e preencher ingredientes
	if ingredients_container:
		for c in ingredients_container.get_children():
			c.queue_free()

		var ings = selected_recipe.get("ingredients", [])
		for ing in ings:
			var i_id = ing["id"]
			var req_count = ing["count"]
			var has_count = player_stats.count_item(i_id) if player_stats else 0
			var i_data = all_items.get(i_id, {})

			var row = HBoxContainer.new()
			row.custom_minimum_size = Vector2(0, 36)
			row.add_theme_constant_override("separation", 10)

			var icon_rect = TextureRect.new()
			icon_rect.custom_minimum_size = Vector2(32, 32)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.texture = RPGIconGenerator.get_item_icon(i_id, i_data, 32)
			row.add_child(icon_rect)

			var lbl = Label.new()
			var item_name = i_data.get("name", i_id)
			lbl.text = "%s :  %d / %d" % [item_name, has_count, req_count]
			lbl.add_theme_font_size_override("font_size", 12)
			if has_count >= req_count:
				lbl.modulate = Color(0.4, 1.0, 0.5)
			else:
				lbl.modulate = Color(1.0, 0.4, 0.4)
			row.add_child(lbl)

			ingredients_container.add_child(row)

	var s_rate = selected_recipe.get("success_rate", 1.0) * 100.0
	var cost = selected_recipe.get("gold_cost", 0)
	var has_gold = player_stats.gold if player_stats else 0

	if success_rate_label:
		success_rate_label.text = "⚡ Taxa de Sucesso: %d%%" % int(s_rate)
		if s_rate >= 90.0:
			success_rate_label.modulate = Color(0.4, 1.0, 0.5)
		elif s_rate >= 75.0:
			success_rate_label.modulate = Color(1.0, 0.85, 0.3)
		else:
			success_rate_label.modulate = Color(1.0, 0.4, 0.4)

	if cost_label:
		cost_label.text = "💰 Custo: %d Ouro (Seu Ouro: %d)" % [cost, has_gold]
		cost_label.modulate = Color(1.0, 0.9, 0.4) if has_gold >= cost else Color(1.0, 0.35, 0.35)

	var can_craft = ForgeRecipesClass.can_craft(selected_recipe, player_stats) if player_stats else false
	if craft_button:
		craft_button.disabled = not can_craft
		craft_button.text = "🔥 FORJAR ITEM" if can_craft else "MATERIAL INSUFICIENTE"

func _on_craft_pressed() -> void:
	if not player_stats or selected_recipe.is_empty():
		return
	if not ForgeRecipesClass.can_craft(selected_recipe, player_stats):
		_show_feedback("Você não possui ouro ou materiais suficientes!", Color(1.0, 0.35, 0.35))
		return

	var cost = selected_recipe.get("gold_cost", 0)
	var rate = selected_recipe.get("success_rate", 1.0)
	var res_id = selected_recipe.get("result_id", "")
	var res_count = selected_recipe.get("result_count", 1)
	var ings = selected_recipe.get("ingredients", [])

	# Consumir ouro
	player_stats.gold -= cost

	# Consumir ingredientes
	for ing in ings:
		var i_id = ing["id"]
		var req = ing["count"]
		_consume_item_from_player(i_id, req)

	GameAudio.am(get_tree(), "play_anvil")
	# Rolar chance de sucesso
	var roll = randf()
	if roll <= rate:
		# SUCESSO!
		for c_i in range(res_count):
			player_stats.add_item(res_id, 1)
		GameAudio.play_refine_success(get_tree())
		var item_name = ItemsDatabase.get_all_items().get(res_id, {}).get("name", res_id)
		_show_feedback("✨ SUCESSO! %s criado com glória!" % item_name, Color(0.3, 1.0, 0.6))
	else:
		# FALHA!
		GameAudio.play_refine_fail(get_tree())
		_show_feedback("💥 A COMBINAÇÃO FALHOU! Os materiais foram consumidos.", Color(1.0, 0.3, 0.3))

	player_stats.stats_changed.emit()
	_refresh_ui()

func _consume_item_from_player(item_id: String, count: int) -> void:
	var remaining = count
	# Se for joia controlada por propriedade no stats
	if item_id == "jewel_bless" and player_stats.jewels_bless > 0:
		var take = min(player_stats.jewels_bless, remaining)
		player_stats.jewels_bless -= take
		remaining -= take
	elif item_id == "jewel_soul" and player_stats.jewels_soul > 0:
		var take = min(player_stats.jewels_soul, remaining)
		player_stats.jewels_soul -= take
		remaining -= take
	elif item_id == "jewel_chaos" and player_stats.jewels_chaos > 0:
		var take = min(player_stats.jewels_chaos, remaining)
		player_stats.jewels_chaos -= take
		remaining -= take

	if remaining <= 0:
		return

	# Buscar e remover da mochila (bag)
	for i in range(player_stats.bag.size() - 1, -1, -1):
		var slot = player_stats.bag[i]
		if not slot.is_empty() and slot["id"] == item_id:
			var slot_amt = slot.get("count", 1)
			if slot_amt <= remaining:
				remaining -= slot_amt
				player_stats.remove_item_at(i)
			else:
				slot["count"] -= remaining
				remaining = 0
			if remaining <= 0:
				break

func _show_feedback(msg: String, color: Color) -> void:
	if status_feedback:
		status_feedback.text = msg
		status_feedback.modulate = color
		var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(status_feedback, "modulate:a", 1.0, 0.15)
		tween.tween_interval(3.0)
		tween.tween_property(status_feedback, "modulate:a", 0.0, 0.5)
