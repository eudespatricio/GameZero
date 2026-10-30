extends CanvasLayer
class_name GameHUD

const BlacksmithForgeClass = preload("res://scripts/ui/blacksmith_forge_window.gd")

@onready var hp_bar: ProgressBar = $BottomBar/HBoxContainer/HPContainer/HPBar
@onready var mp_bar: ProgressBar = $BottomBar/HBoxContainer/MPContainer/MPBar
@onready var hp_label: Label = $BottomBar/HBoxContainer/HPContainer/HPLabel
@onready var mp_label: Label = $BottomBar/HBoxContainer/MPContainer/MPLabel

@onready var potion_hp_btn: Button = $BottomBar/HBoxContainer/PotionHPButton
@onready var potion_mp_btn: Button = $BottomBar/HBoxContainer/PotionMPButton
@onready var slot_attack_btn: Button = $BottomBar/HBoxContainer/SkillSlots/SlotAttack
@onready var slot1_btn: Button = $BottomBar/HBoxContainer/SkillSlots/Slot1
@onready var slot2_btn: Button = $BottomBar/HBoxContainer/SkillSlots/Slot2
@onready var slot3_btn: Button = $BottomBar/HBoxContainer/SkillSlots/Slot3
@onready var mount_btn: Button = $BottomBar/HBoxContainer/SkillSlots/SlotMount
@onready var dash_btn: Button = $BottomBar/HBoxContainer/SkillSlots/SlotDash

@onready var bottom_bar: Control = $BottomBar
@onready var top_info: Control = $TopInfo
@onready var minimap = $Minimap
@onready var world_map = $WorldMap
@onready var inv_window = $InventoryWindow
@onready var forge_window = $BlacksmithForgeWindow

@onready var char_btn: Button = $TopInfo/TopLeftHBox/CharButton
@onready var inv_btn: Button = $TopInfo/TopLeftHBox/InvButton
@onready var fullscreen_btn: Button = $TopInfo/TopLeftHBox/FullscreenButton
@onready var version_btn: Button = $TopInfo/TopLeftHBox/VersionButton
@onready var switch_char_btn: Button = $TopInfo/TopLeftHBox/SwitchCharButton
@onready var patch_notes_modal: Control = $PatchNotesModal
@onready var economy_label: Label = $TopInfo/EconomyLabel
@onready var notification_label: Label = $TopInfo/NotificationLabel

# --- MODAL DE DIÁLOGO DE NPC ---
@onready var dialog_modal: Panel = $NPCDialogModal
@onready var dialog_name: Label = $NPCDialogModal/VBox/Title
@onready var dialog_role: Label = $NPCDialogModal/VBox/Role
@onready var dialog_text: Label = $NPCDialogModal/VBox/Text
@onready var btn_refine: Button = $NPCDialogModal/VBox/HBox/BtnRefine
@onready var btn_close_dialog: Button = $NPCDialogModal/VBox/HBox/BtnClose

var player = null
var _cd_overlays: Dictionary = {}

# --- BARRA DE CHEFE NO HUD (ESTILO DIABLO IV / SOULS) ---
var _boss_bar_panel: PanelContainer = null
var _boss_name_label: Label = null
var _boss_affix_label: Label = null
var _boss_hp_bar: ProgressBar = null
var _boss_hp_text: Label = null
var _current_boss_node: Node = null

# --- BARRA DEDICADA DE EXPERIÊNCIA (RODAPÉ) ---
var _xp_bar_container: PanelContainer = null
var _xp_progress_bar: ProgressBar = null
var _xp_text_label: Label = null

# --- REGISTRO DE EVENTOS E COMBATE (CANTO INFERIOR ESQUERDO) ---
var _event_log_panel: PanelContainer = null
var _event_log_vbox: VBoxContainer = null
var _event_log_fade_timer: float = 6.0

# --- RASTREADOR DE MISSÕES (CANTO DIREITO, ABAIXO DO MINIMAPA) ---
var _quest_tracker_panel: PanelContainer = null
var _quest_tracker_title: Label = null
var _quest_tracker_progress_bar: ProgressBar = null
var _quest_tracker_count_label: Label = null
var _quest_tracker_hint_label: Label = null

func _ready() -> void:
	add_to_group("hud")
	if dialog_modal:
		dialog_modal.visible = false

	_apply_diablo_hud_theme()
	_setup_skill_cooldown_overlays()
	_setup_boss_health_bar()
	_setup_dedicated_xp_bar()
	_setup_combat_event_log()
	_setup_quest_tracker_hud()

	if mount_btn:
		mount_btn.pressed.connect(_on_mount_pressed)
	if dash_btn:
		dash_btn.pressed.connect(_on_dash_pressed)
	if slot_attack_btn:
		slot_attack_btn.pressed.connect(_on_attack_pressed)
	if slot1_btn:
		slot1_btn.pressed.connect(_on_skill1_pressed)
	if slot2_btn:
		slot2_btn.pressed.connect(_on_skill2_pressed)
	if slot3_btn:
		slot3_btn.pressed.connect(_on_skill3_pressed)
	if potion_hp_btn:
		potion_hp_btn.pressed.connect(_on_potion_hp_pressed)
	if potion_mp_btn:
		potion_mp_btn.pressed.connect(_on_potion_mp_pressed)
	if fullscreen_btn:
		fullscreen_btn.pressed.connect(IsometricCamera.toggle_fullscreen)

	if version_btn:
		var ver_mgr = get_node_or_null("/root/VersionManager")
		if ver_mgr:
			version_btn.text = "📜 v%s" % ver_mgr.local_version
		version_btn.pressed.connect(func():
			if patch_notes_modal: patch_notes_modal.show_patch_notes()
		)
	if switch_char_btn:
		switch_char_btn.pressed.connect(func():
			get_tree().change_scene_to_file("res://scenes/ui/auth_and_character_select.tscn")
		)

	if char_btn:
		char_btn.pressed.connect(_on_char_btn_pressed)
	if inv_btn and inv_window:
		inv_btn.pressed.connect(inv_window.toggle_inventory)
	if btn_close_dialog:
		btn_close_dialog.pressed.connect(func(): dialog_modal.visible = false)
	if btn_refine:
		btn_refine.pressed.connect(_on_refine_pressed)

	if minimap and world_map:
		minimap.open_world_map_requested.connect(world_map.toggle_map)
	if world_map:
		world_map.visibility_changed.connect(_on_overlay_visibility_changed)
	if inv_window:
		inv_window.visibility_changed.connect(_on_overlay_visibility_changed)
	if forge_window:
		forge_window.visibility_changed.connect(_on_overlay_visibility_changed)

func _on_overlay_visibility_changed() -> void:
	var any_modal_open = (inv_window and inv_window.visible) or (world_map and world_map.visible) or (forge_window and forge_window.visible)
	if bottom_bar: bottom_bar.visible = not any_modal_open
	if top_info: top_info.visible = not any_modal_open
	if minimap: minimap.visible = not any_modal_open
	if _boss_bar_panel: _boss_bar_panel.visible = not any_modal_open
	if _xp_bar_container: _xp_bar_container.visible = not any_modal_open
	if _event_log_panel: _event_log_panel.visible = not any_modal_open
	if _quest_tracker_panel: _quest_tracker_panel.visible = not any_modal_open

func _process(delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if player and player.stats:
			player.stats.stats_changed.connect(_on_player_stats_changed)
			player.stats.enhancement_result.connect(_on_enhancement_result)
			player.stats.level_up.connect(_on_level_up)
			player.stats.quest_updated.connect(_on_quest_updated)
			player.stats.xp_gained.connect(_on_xp_gained)
			_on_player_stats_changed()
			_update_xp_bar(false)
			_update_quest_tracker()

	_update_cooldown_overlays()
	_update_boss_health_bar(delta)
	_update_event_log(delta)

func _setup_skill_cooldown_overlays() -> void:
	var slots = [
		{"key": 1, "btn": slot1_btn},
		{"key": 2, "btn": slot2_btn},
		{"key": 3, "btn": slot3_btn},
		{"key": "dash", "btn": dash_btn},
		{"key": "potion_hp", "btn": potion_hp_btn},
		{"key": "potion_mp", "btn": potion_mp_btn},
	]
	for s in slots:
		var btn: Button = s["btn"]
		if not btn:
			continue
		var key = s["key"]

		var overlay = Panel.new()
		overlay.name = "CDOverlay"
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_STOP

		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.04, 0.05, 0.09, 0.86)
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_left = 6
		sb.corner_radius_bottom_right = 6
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(1.0, 0.65, 0.2, 0.85)
		overlay.add_theme_stylebox_override("panel", sb)

		var lbl = Label.new()
		lbl.name = "CDLabel"
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.35))
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		lbl.add_theme_constant_override("outline_size", 3)
		overlay.add_child(lbl)

		overlay.visible = false
		btn.add_child(overlay)

		_cd_overlays[key] = {
			"panel": overlay,
			"label": lbl,
			"btn": btn,
			"was_on_cd": false
		}

func _update_cooldown_overlays() -> void:
	if not player or not ("skill_cooldowns" in player):
		return

	for key in _cd_overlays.keys():
		var data = _cd_overlays[key]
		var cd: float = player.get_skill_cooldown(key)
		var overlay: Panel = data["panel"]
		var lbl: Label = data["label"]
		var btn: Button = data["btn"]

		if cd > 0.05:
			if not overlay.visible:
				overlay.visible = true
			var cd_text := "%.1fs" % cd
			if lbl.text != cd_text:
				lbl.text = cd_text
			data["was_on_cd"] = true
		else:
			if data["was_on_cd"]:
				data["was_on_cd"] = false
				overlay.visible = false
				var tw = btn.create_tween()
				tw.tween_property(btn, "modulate", Color(1.6, 1.6, 1.8), 0.08)
				tw.tween_property(btn, "modulate", Color.WHITE, 0.16)
			else:
				overlay.visible = false

func _on_player_stats_changed() -> void:
	if not player or not player.stats:
		return
	var s = player.stats
	if hp_bar:
		hp_bar.max_value = s.max_hp
		hp_bar.value = s.current_hp
	if mp_bar:
		mp_bar.max_value = s.max_mp
		mp_bar.value = s.current_mp
	if hp_label:
		hp_label.text = "%d / %d   (%d%%)" % [int(s.current_hp), int(s.max_hp), int(100.0 * s.current_hp / maxf(s.max_hp, 1.0))]
	if mp_label:
		mp_label.text = "%d / %d   (%d%%)" % [int(s.current_mp), int(s.max_mp), int(100.0 * s.current_mp / maxf(s.max_mp, 1.0))]

	if char_btn:
		var hero_short = s.character_name.split(" ")[0]
		char_btn.text = "🐉 %s  ·  Nv %d  ·  +%d" % [hero_short, s.level, s.weapon_refine]
		char_btn.tooltip_text = "CP %d   ·   Crítico %.0f%% (x%.2f)   ·   Esquiva %.0f%%   ·   CDR %.0f%%   ·   XP %d%%" % [
			s.get_combat_power(), s.get_crit_chance(), s.get_crit_multiplier(),
			s.get_dodge_chance(), s.get_cooldown_reduction(), int(100.0 * s.current_xp / max(s.max_xp, 1))]

	if economy_label:
		economy_label.text = "💰 %s   💎 %d   🔮 %d   🔥 %d   🧪 %d   🧿 %d" % [
			_format_number(s.gold), s.jewels_bless, s.jewels_soul, s.jewels_chaos,
			s.count_item("potion_health"), s.count_item("potion_mana")]
		if s.stat_points > 0:
			economy_label.text += "   ⭐ %d pts [I]" % s.stat_points

	var hp_pot_count = s.count_item("potion_health")
	var mp_pot_count = s.count_item("potion_mana")
	if potion_hp_btn:
		potion_hp_btn.text = "[Q]\nx%d" % hp_pot_count
		potion_hp_btn.modulate = Color(1.0, 1.0, 1.0) if hp_pot_count > 0 else Color(0.55, 0.55, 0.55, 0.7)
	if potion_mp_btn:
		potion_mp_btn.text = "[R]\nx%d" % mp_pot_count
		potion_mp_btn.modulate = Color(1.0, 1.0, 1.0) if mp_pot_count > 0 else Color(0.55, 0.55, 0.55, 0.7)

	# Indicação visual de mana disponível nas skills
	if slot1_btn:
		slot1_btn.modulate = Color(1.0, 1.0, 1.0) if s.current_mp >= 35.0 else Color(0.5, 0.5, 0.65, 0.7)
	if slot2_btn:
		slot2_btn.modulate = Color(1.0, 1.0, 1.0) if s.current_mp >= 50.0 else Color(0.5, 0.5, 0.65, 0.7)
	if slot3_btn:
		slot3_btn.modulate = Color(1.0, 1.0, 1.0) if s.current_mp >= 75.0 else Color(0.5, 0.5, 0.65, 0.7)

	_update_xp_bar(true)
	_update_quest_tracker()

func _on_level_up(new_level: int) -> void:
	show_notification("⭐ NÍVEL %d! +5 pontos de atributo — abra o inventário (I) para distribuir." % new_level, Color(1.0, 0.9, 0.3))
	add_log_message("⭐ NÍVEL %d ALCANÇADO! +5 pontos de atributo" % new_level, Color(1.0, 0.88, 0.25), "SISTEMA")
	if _xp_progress_bar:
		var tw = create_tween()
		tw.tween_property(_xp_progress_bar, "modulate", Color(2.0, 1.8, 0.5), 0.15)
		tw.tween_property(_xp_progress_bar, "modulate", Color.WHITE, 0.35)

func _on_quest_updated(quest_id: String) -> void:
	_update_quest_tracker()
	if not player or not player.stats or not player.stats.quests.has(quest_id):
		return
	var q = player.stats.quests[quest_id]
	if not q is Dictionary:
		return
	var is_done: bool = q.get("done", false)
	var is_claimed: bool = q.get("claimed", false)
	var q_title: String = q.get("title", quest_id)
	var q_prog: int = int(q.get("progress", 0))
	var q_goal: int = int(q.get("goal", 5))

	if is_done and not is_claimed:
		show_notification("✅ Missão '%s' concluída! Fale com Brom." % q_title, Color(0.5, 1.0, 0.6))
		add_log_message("Missão concluída: %s! Fale com Brom" % q_title, Color(0.35, 1.0, 0.55), "MISSAO")
	elif not is_done:
		show_notification("📜 %s: %d / %d" % [q_title, q_prog, q_goal], Color(1.0, 0.9, 0.55))
		add_log_message("📜 %s: %d / %d" % [q_title, q_prog, q_goal], Color(1.0, 0.9, 0.4), "MISSAO")

func _on_char_btn_pressed() -> void:
	if player and player.has_method("cycle_next_character"):
		player.cycle_next_character()

func _on_potion_hp_pressed() -> void:
	if player and player.has_method("use_potion"):
		player.use_potion("potion_health")

func _on_potion_mp_pressed() -> void:
	if player and player.has_method("use_potion"):
		player.use_potion("potion_mana")

func _on_attack_pressed() -> void:
	if player and player.has_method("perform_attack"):
		player.perform_attack()

func _on_skill1_pressed() -> void:
	if player and player.has_method("cast_skill"):
		player.cast_skill(1)

func _on_skill2_pressed() -> void:
	if player and player.has_method("cast_skill"):
		player.cast_skill(2)

func _on_skill3_pressed() -> void:
	if player and player.has_method("cast_skill"):
		player.cast_skill(3)

func _on_mount_pressed() -> void:
	if player and player.has_method("toggle_dragon_mount"):
		player.toggle_dragon_mount()

func _on_dash_pressed() -> void:
	if player and player.has_method("trigger_dash"):
		player.trigger_dash()

func open_forge_window() -> void:
	if dialog_modal:
		dialog_modal.visible = false
	if forge_window:
		forge_window.open_forge()

func _on_refine_pressed() -> void:
	if player and player.stats:
		player.stats.enhance_weapon()

func _on_enhancement_result(success: bool, _new_level: int, message: String) -> void:
	show_notification(message, Color(0.2, 0.95, 0.7) if success else Color(1.0, 0.35, 0.35))
	add_log_message(message, Color(0.2, 0.95, 0.7) if success else Color(1.0, 0.35, 0.35), "REFINO")

func show_npc_dialog(npc_name: String, role: String, text: String, options: Array = []) -> void:
	if dialog_modal:
		dialog_modal.visible = true
		if dialog_name: dialog_name.text = npc_name
		if dialog_role: dialog_role.text = "< %s >" % role
		if dialog_text: dialog_text.text = text
		var vbox = dialog_modal.get_node("VBox")
		for c in vbox.get_children():
			if c.name.begins_with("Opt_"):
				vbox.remove_child(c)
				c.queue_free()
		var hbox = vbox.get_node("HBox")
		if btn_refine:
			btn_refine.visible = options.is_empty()
		var idx = 0
		for opt in options:
			var b = Button.new()
			b.name = "Opt_%d" % idx
			b.text = opt["label"]
			b.disabled = opt.get("disabled", false)
			b.add_theme_font_size_override("font_size", 13)
			b.pressed.connect(opt["action"])
			vbox.add_child(b)
			vbox.move_child(b, hbox.get_index())
			idx += 1

func show_notification(msg: String, color: Color = Color.WHITE) -> void:
	if notification_label:
		notification_label.text = msg
		notification_label.modulate = color
		notification_label.visible = true
		var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(notification_label, "modulate:a", 1.0, 0.2)
		tween.tween_interval(2.5)
		tween.tween_property(notification_label, "modulate:a", 0.0, 0.5)

func _apply_diablo_hud_theme() -> void:
	_setup_vital_bar_labels()
	# Ícones Procedurais de Alta Definição (Estilo Diablo IV)
	if potion_hp_btn:
		potion_hp_btn.icon = RPGIconGenerator.get_potion_flask_icon("health", 48)
		potion_hp_btn.expand_icon = true
		_apply_button_gold_style(potion_hp_btn, Color(0.85, 0.25, 0.25, 0.95))

	if potion_mp_btn:
		potion_mp_btn.icon = RPGIconGenerator.get_potion_flask_icon("mana", 48)
		potion_mp_btn.expand_icon = true
		_apply_button_gold_style(potion_mp_btn, Color(0.25, 0.65, 1.0, 0.95))

	if slot_attack_btn:
		slot_attack_btn.icon = RPGIconGenerator.get_skill_icon("attack", 48)
		slot_attack_btn.expand_icon = true
	if slot1_btn:
		slot1_btn.icon = RPGIconGenerator.get_skill_icon("brisingr", 48)
		slot1_btn.expand_icon = true
	if slot2_btn:
		slot2_btn.icon = RPGIconGenerator.get_skill_icon("jierda", 48)
		slot2_btn.expand_icon = true
	if slot3_btn:
		slot3_btn.icon = RPGIconGenerator.get_skill_icon("vortex", 48)
		slot3_btn.expand_icon = true
	if mount_btn:
		mount_btn.icon = RPGIconGenerator.get_skill_icon("mount", 48)
		mount_btn.expand_icon = true
	if dash_btn:
		dash_btn.icon = RPGIconGenerator.get_skill_icon("dash", 48)
		dash_btn.expand_icon = true

	var skill_box = $BottomBar/HBoxContainer/SkillSlots
	if skill_box:
		for child in skill_box.get_children():
			if child is Button:
				_apply_button_gold_style(child, Color(0.58, 0.46, 0.22, 0.92))

	for top_btn in [char_btn, inv_btn, fullscreen_btn]:
		if top_btn:
			_apply_button_gold_style(top_btn, Color(0.55, 0.44, 0.22, 0.85))

## Valores de vida/mana desenhados DENTRO da barra: economiza altura no rodapé
## e acaba com o texto que antes vazava por baixo das barras.
func _setup_vital_bar_labels() -> void:
	_embed_label_in_bar(hp_bar, hp_label)
	_embed_label_in_bar(mp_bar, mp_label)

func _embed_label_in_bar(bar: ProgressBar, label: Label) -> void:
	if not bar or not label:
		return
	var parent := label.get_parent()
	if parent and parent != bar:
		parent.remove_child(label)
		bar.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.97))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)

## Formata números grandes no padrão pt-BR (12.500).
func _format_number(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "." + out
	return ("-" if value < 0 else "") + out

func _apply_button_gold_style(btn: Button, border_col: Color) -> void:
	var st = StyleBoxFlat.new()
	st.bg_color = Color(0.05, 0.06, 0.08, 0.96)
	st.border_width_left = 2
	st.border_width_top = 2
	st.border_width_right = 2
	st.border_width_bottom = 2
	st.border_color = border_col
	st.corner_radius_top_left = 5
	st.corner_radius_top_right = 5
	st.corner_radius_bottom_right = 5
	st.corner_radius_bottom_left = 5
	st.shadow_color = Color(0, 0, 0, 0.65)
	st.shadow_size = 4
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("pressed", st)
	# O hover fica com o tema global (borda dourada) para dar feedback de mouse
	var hover := st.duplicate() as StyleBoxFlat
	hover.border_color = Color(1.0, 0.9, 0.62, 1.0)
	hover.shadow_size = 7
	btn.add_theme_stylebox_override("hover", hover)

## Configuração da Barra de Chefe Monumental no Topo da Tela (Estilo Diablo IV / Souls)
func _setup_boss_health_bar() -> void:
	_boss_bar_panel = PanelContainer.new()
	_boss_bar_panel.name = "BossHealthBarHUD"
	_boss_bar_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_bar_panel.offset_left = -280
	_boss_bar_panel.offset_right = 280
	_boss_bar_panel.offset_top = 124
	_boss_bar_panel.offset_bottom = 184
	_boss_bar_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_bar_panel.modulate.a = 0.0

	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.04, 0.03, 0.05, 0.92)
	panel_sb.border_width_left = 2
	panel_sb.border_width_right = 2
	panel_sb.border_width_top = 2
	panel_sb.border_width_bottom = 2
	panel_sb.border_color = Color(0.85, 0.68, 0.25, 0.95) # Moldura Dourada Rúnica
	panel_sb.corner_radius_top_left = 6
	panel_sb.corner_radius_top_right = 6
	panel_sb.corner_radius_bottom_left = 6
	panel_sb.corner_radius_bottom_right = 6
	panel_sb.content_margin_left = 16
	panel_sb.content_margin_right = 16
	panel_sb.content_margin_top = 4
	panel_sb.content_margin_bottom = 6
	_boss_bar_panel.add_theme_stylebox_override("panel", panel_sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	_boss_bar_panel.add_child(vbox)

	_boss_name_label = Label.new()
	_boss_name_label.text = "☠ NOME DO CHEFE ☠"
	_boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name_label.add_theme_font_size_override("font_size", 17)
	_boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	_boss_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_boss_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_boss_name_label.add_theme_constant_override("shadow_offset_y", 1)
	vbox.add_child(_boss_name_label)

	_boss_affix_label = Label.new()
	_boss_affix_label.text = "[World Boss] Lorde Supremo • Imparável"
	_boss_affix_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_affix_label.add_theme_font_size_override("font_size", 12)
	_boss_affix_label.add_theme_color_override("font_color", Color(0.72, 0.80, 0.90))
	vbox.add_child(_boss_affix_label)

	var bar_margin := MarginContainer.new()
	bar_margin.custom_minimum_size = Vector2(520, 15)
	vbox.add_child(bar_margin)

	_boss_hp_bar = ProgressBar.new()
	_boss_hp_bar.show_percentage = false
	_boss_hp_bar.custom_minimum_size = Vector2(520, 15)
	_boss_hp_bar.value = 100.0

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.12, 0.06, 0.08, 0.95)
	bar_bg.corner_radius_top_left = 3
	bar_bg.corner_radius_top_right = 3
	bar_bg.corner_radius_bottom_left = 3
	bar_bg.corner_radius_bottom_right = 3
	_boss_hp_bar.add_theme_stylebox_override("background", bar_bg)

	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.85, 0.12, 0.15, 1.0) # Sangue Carmesim
	bar_fill.corner_radius_top_left = 3
	bar_fill.corner_radius_top_right = 3
	bar_fill.corner_radius_bottom_left = 3
	bar_fill.corner_radius_bottom_right = 3
	_boss_hp_bar.add_theme_stylebox_override("fill", bar_fill)
	bar_margin.add_child(_boss_hp_bar)

	_boss_hp_text = Label.new()
	_boss_hp_text.text = "100%"
	_boss_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_boss_hp_text.add_theme_font_size_override("font_size", 12)
	_boss_hp_text.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	_boss_hp_text.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	bar_margin.add_child(_boss_hp_text)

	add_child(_boss_bar_panel)

var _boss_scan_timer: float = 0.0

## Atualização Dinâmica da Barra de Chefe (com throttling do scan de entidades para alto FPS)
func _update_boss_health_bar(delta: float) -> void:
	if not _boss_bar_panel:
		return

	_boss_scan_timer -= delta
	if _boss_scan_timer <= 0.0:
		_boss_scan_timer = 0.25 # Varre apenas 4 vezes por segundo em vez de cada frame
		var target_boss: Node = null
		var min_dist := 40.0
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if not is_instance_valid(e) or not ("max_health" in e) or not ("current_health" in e):
				continue
			var is_boss: bool = false
			if "difficulty_tier" in e:
				is_boss = e.difficulty_tier in [3, 4] # MINIBOSS ou WORLD_BOSS
			elif "behavior" in e:
				is_boss = e.behavior == 2

			if is_boss and e.current_health > 0:
				var d := 999.0
				if is_instance_valid(player):
					d = player.global_position.distance_to(e.global_position)
				var max_range := 45.0 if e.get("difficulty_tier") == 4 else 32.0
				if d < max_range and d < min_dist:
					min_dist = d
					target_boss = e
		_current_boss_node = target_boss

	if is_instance_valid(_current_boss_node) and _current_boss_node.current_health > 0:
		_boss_bar_panel.modulate.a = move_toward(_boss_bar_panel.modulate.a, 1.0, delta * 4.0)

		var tier_tag := "MINIBOSS"
		if _current_boss_node.get("difficulty_tier") == 4:
			tier_tag = "WORLD BOSS"

		var affixes: Array = _current_boss_node.get("tier_affixes") if "tier_affixes" in _current_boss_node else []
		var affix_str := ""
		if not affixes.is_empty():
			affix_str = " • " + " • ".join(affixes)

		_boss_name_label.text = "☠ %s ☠" % str(_current_boss_node.get("mob_name")).to_upper()
		_boss_affix_label.text = "[%s]%s" % [tier_tag, affix_str]

		var cur_hp: float = _current_boss_node.current_health
		var max_hp: float = maxf(_current_boss_node.max_health, 1.0)
		var ratio := clampf(cur_hp / max_hp, 0.0, 1.0)
		_boss_hp_bar.value = ratio * 100.0
		_boss_hp_text.text = "%d / %d  (%d%%)" % [int(maxf(cur_hp, 0.0)), int(max_hp), int(ratio * 100.0)]
	else:
		_boss_bar_panel.modulate.a = move_toward(_boss_bar_panel.modulate.a, 0.0, delta * 2.5)

## Exibe uma fala/brado intimidante do Boss no HUD
func show_boss_bark(bark_quote: String) -> void:
	if _boss_affix_label and _boss_bar_panel and _boss_bar_panel.modulate.a > 0.05:
		_boss_affix_label.text = "💬 \"%s\"" % bark_quote
		_boss_affix_label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.32))
		var tw := create_tween()
		tw.tween_interval(3.2)
		tw.tween_callback(func():
			if is_instance_valid(_current_boss_node):
				var affixes: Array = _current_boss_node.get("tier_affixes") if "tier_affixes" in _current_boss_node else []
				var tier_tag := "MINIBOSS"
				if _current_boss_node.get("difficulty_tier") == 4:
					tier_tag = "WORLD BOSS"
				var affix_str := (" • " + " • ".join(affixes)) if not affixes.is_empty() else ""
				_boss_affix_label.text = "[%s]%s" % [tier_tag, affix_str]
				_boss_affix_label.add_theme_color_override("font_color", Color(0.72, 0.80, 0.90))
		)

# ==============================================================================
# --- BARRA DEDICADA DE EXPERIÊNCIA (XP BAR) ---
# ==============================================================================
func _setup_dedicated_xp_bar() -> void:
	_xp_bar_container = PanelContainer.new()
	_xp_bar_container.name = "DedicatedXPBarContainer"
	_xp_bar_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_xp_bar_container.offset_left = 0
	_xp_bar_container.offset_right = 0
	_xp_bar_container.offset_top = -60
	_xp_bar_container.offset_bottom = -44
	_xp_bar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var container_sb := StyleBoxFlat.new()
	container_sb.bg_color = Color(0.04, 0.05, 0.08, 0.98)
	container_sb.border_width_top = 1
	container_sb.border_color = Color(0.24, 0.44, 0.58, 0.85) # Borda rúnica azulada
	container_sb.content_margin_left = 0
	container_sb.content_margin_right = 0
	container_sb.content_margin_top = 0
	container_sb.content_margin_bottom = 0
	_xp_bar_container.add_theme_stylebox_override("panel", container_sb)

	_xp_progress_bar = ProgressBar.new()
	_xp_progress_bar.show_percentage = false
	_xp_progress_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	_xp_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = Color(0.06, 0.08, 0.12, 0.95)
	_xp_progress_bar.add_theme_stylebox_override("background", bg_sb)

	var fill_sb := StyleBoxFlat.new()
	fill_sb.bg_color = Color(0.12, 0.62, 0.92, 0.95) # Azul Safira Radiante
	_xp_progress_bar.add_theme_stylebox_override("fill", fill_sb)
	_xp_bar_container.add_child(_xp_progress_bar)

	_xp_text_label = Label.new()
	_xp_text_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_xp_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_xp_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_xp_text_label.add_theme_font_size_override("font_size", 11)
	_xp_text_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0, 0.95))
	_xp_text_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_xp_text_label.add_theme_constant_override("shadow_offset_x", 1)
	_xp_text_label.add_theme_constant_override("shadow_offset_y", 1)
	_xp_text_label.text = "XP: 0 / 1000 (0.0%) • Nível 1"
	_xp_bar_container.add_child(_xp_text_label)

	add_child(_xp_bar_container)

func _update_xp_bar(animate: bool = true) -> void:
	if not _xp_progress_bar or not _xp_text_label or not is_instance_valid(player) or not player.stats:
		return
	var s = player.stats
	var cur_xp: int = s.current_xp
	var target_max: int = max(s.max_xp, 1)
	var pct: float = clampf(float(cur_xp) / float(target_max), 0.0, 1.0) * 100.0

	_xp_progress_bar.max_value = target_max
	if animate:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(_xp_progress_bar, "value", float(cur_xp), 0.35)
	else:
		_xp_progress_bar.value = float(cur_xp)

	if s.level >= 50:
		_xp_text_label.text = "XP: %d / %d (100%%) • Nível %d [NÍVEL MÁXIMO - DESPERTAR RÚNICO]" % [cur_xp, target_max, s.level]
	else:
		_xp_text_label.text = "XP: %d / %d (%.1f%%) • Nível %d" % [cur_xp, target_max, pct, s.level]

# ==============================================================================
# --- LOG DE EVENTOS E COMBATE (CANTO INFERIOR ESQUERDO) ---
# ==============================================================================
func _setup_combat_event_log() -> void:
	_event_log_panel = PanelContainer.new()
	_event_log_panel.name = "CombatEventLog"
	_event_log_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_event_log_panel.offset_left = 18
	_event_log_panel.offset_top = -286
	_event_log_panel.offset_right = 356
	_event_log_panel.offset_bottom = -152
	_event_log_panel.visible = false
	_event_log_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.04, 0.06, 0.72)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.20, 0.32, 0.42, 0.55)
	sb.corner_radius_top_left = 5
	sb.corner_radius_top_right = 5
	sb.corner_radius_bottom_left = 5
	sb.corner_radius_bottom_right = 5
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	_event_log_panel.add_theme_stylebox_override("panel", sb)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 3)
	_event_log_panel.add_child(main_vbox)

	var title_lbl := Label.new()
	title_lbl.text = "📜 REGISTRO DE COMBATE"
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.add_theme_color_override("font_color", Color(0.45, 0.75, 0.88, 0.85))
	main_vbox.add_child(title_lbl)

	_event_log_vbox = VBoxContainer.new()
	_event_log_vbox.add_theme_constant_override("separation", 2)
	main_vbox.add_child(_event_log_vbox)

	add_child(_event_log_panel)

func add_log_message(msg: String, color: Color = Color.WHITE, category: String = "INFO") -> void:
	if not _event_log_vbox or not _event_log_panel:
		return

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var tag_lbl := Label.new()
	tag_lbl.custom_minimum_size = Vector2(46, 0)
	tag_lbl.add_theme_font_size_override("font_size", 12)

	var tag_color := Color.WHITE
	match category.to_upper():
		"XP":
			tag_lbl.text = "[XP]"
			tag_color = Color(0.32, 0.88, 1.0)
		"OURO":
			tag_lbl.text = "[Ouro]"
			tag_color = Color(1.0, 0.85, 0.25)
		"LOOT":
			tag_lbl.text = "[Loot]"
			tag_color = color
		"MISSAO":
			tag_lbl.text = "[Missão]"
			tag_color = Color(1.0, 0.90, 0.35)
		"SISTEMA":
			tag_lbl.text = "[Sistema]"
			tag_color = Color(0.65, 0.82, 0.95)
		"REFINO":
			tag_lbl.text = "[Forja]"
			tag_color = Color(0.25, 1.0, 0.7)
		_:
			tag_lbl.text = "[Info]"
			tag_color = Color(0.8, 0.85, 0.9)

	tag_lbl.add_theme_color_override("font_color", tag_color)
	row.add_child(tag_lbl)

	var msg_lbl := Label.new()
	msg_lbl.text = msg
	msg_lbl.add_theme_font_size_override("font_size", 12)
	msg_lbl.add_theme_color_override("font_color", color)
	msg_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	msg_lbl.add_theme_constant_override("shadow_offset_x", 1)
	msg_lbl.add_theme_constant_override("shadow_offset_y", 1)
	row.add_child(msg_lbl)

	_event_log_vbox.add_child(row)
	_event_log_panel.visible = true

	while _event_log_vbox.get_child_count() > 5:
		var old = _event_log_vbox.get_child(0)
		_event_log_vbox.remove_child(old)
		old.queue_free()

	_event_log_fade_timer = 6.0
	_event_log_panel.modulate.a = 1.0

func _update_event_log(delta: float) -> void:
	if not _event_log_panel:
		return
	_event_log_fade_timer -= delta
	if _event_log_fade_timer <= 0.0:
		_event_log_panel.modulate.a = move_toward(_event_log_panel.modulate.a, 0.0, delta * 1.5)
		if _event_log_panel.modulate.a < 0.05 and _event_log_panel.visible:
			_event_log_panel.visible = false

func _on_xp_gained(amount: int, source_name: String) -> void:
	var msg = "+%d XP" % amount
	if source_name != "":
		msg += " de %s" % source_name
	add_log_message(msg, Color(0.35, 0.88, 1.0), "XP")

# ==============================================================================
# --- RASTREADOR DE MISSÕES (QUEST TRACKER NO HUD) ---
# ==============================================================================
func _setup_quest_tracker_hud() -> void:
	_quest_tracker_panel = PanelContainer.new()
	_quest_tracker_panel.name = "QuestTrackerHUD"
	_quest_tracker_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_quest_tracker_panel.offset_left = -196
	_quest_tracker_panel.offset_right = -16
	_quest_tracker_panel.offset_top = 230
	_quest_tracker_panel.offset_bottom = 372
	_quest_tracker_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.08, 0.88)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.85, 0.68, 0.25, 0.85) # Moldura Rúnica Dourada
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	_quest_tracker_panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	_quest_tracker_panel.add_child(vbox)

	var header_lbl := Label.new()
	header_lbl.text = "📜 MISSÃO ATIVA"
	header_lbl.add_theme_font_size_override("font_size", 12)
	header_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	vbox.add_child(header_lbl)

	_quest_tracker_title = Label.new()
	_quest_tracker_title.text = "Sem Missão Ativa"
	_quest_tracker_title.add_theme_font_size_override("font_size", 14)
	_quest_tracker_title.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	vbox.add_child(_quest_tracker_title)

	_quest_tracker_progress_bar = ProgressBar.new()
	_quest_tracker_progress_bar.show_percentage = false
	_quest_tracker_progress_bar.custom_minimum_size = Vector2(0, 8)
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.08, 0.1, 0.14, 0.95)
	bar_bg.corner_radius_top_left = 2
	bar_bg.corner_radius_top_right = 2
	bar_bg.corner_radius_bottom_left = 2
	bar_bg.corner_radius_bottom_right = 2
	_quest_tracker_progress_bar.add_theme_stylebox_override("background", bar_bg)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.25, 0.9, 0.55, 0.95)
	bar_fill.corner_radius_top_left = 2
	bar_fill.corner_radius_top_right = 2
	bar_fill.corner_radius_bottom_left = 2
	bar_fill.corner_radius_bottom_right = 2
	_quest_tracker_progress_bar.add_theme_stylebox_override("fill", bar_fill)
	vbox.add_child(_quest_tracker_progress_bar)

	_quest_tracker_count_label = Label.new()
	_quest_tracker_count_label.text = "Progresso: 0 / 5"
	_quest_tracker_count_label.add_theme_font_size_override("font_size", 12)
	_quest_tracker_count_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	vbox.add_child(_quest_tracker_count_label)

	_quest_tracker_hint_label = Label.new()
	_quest_tracker_hint_label.text = "📍 Fale com Brom no Santuário"
	_quest_tracker_hint_label.add_theme_font_size_override("font_size", 11)
	_quest_tracker_hint_label.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0))
	_quest_tracker_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_quest_tracker_hint_label)

	add_child(_quest_tracker_panel)

func _update_quest_tracker() -> void:
	if not _quest_tracker_panel or not is_instance_valid(player) or not player.stats:
		return
	var st = player.stats
	var q = st.get_active_quest()
	if q.is_empty():
		_quest_tracker_title.text = "Sem Missão Ativa"
		_quest_tracker_count_label.text = ""
		_quest_tracker_hint_label.text = "📍 Fale com Brom no Santuário"
		_quest_tracker_progress_bar.visible = false
	else:
		_quest_tracker_title.text = q.get("title", "Missão")
		var prog = int(q.get("progress", 0))
		var goal = int(q.get("goal", 5))
		var is_done = q.get("done", false)
		_quest_tracker_progress_bar.visible = true
		_quest_tracker_progress_bar.max_value = goal
		_quest_tracker_progress_bar.value = prog
		if is_done:
			_quest_tracker_count_label.text = "✅ CONCLUÍDA (%d / %d)" % [prog, goal]
			_quest_tracker_count_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.55))
			_quest_tracker_hint_label.text = "🏆 Retorne a Brom no Santuário"
		else:
			_quest_tracker_count_label.text = "Progresso: %d / %d" % [prog, goal]
			_quest_tracker_count_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
			var hint = q.get("hint", "")
			if hint == "":
				hint = "Elimine as criaturas nas estradas"
			_quest_tracker_hint_label.text = "📍 %s" % hint
