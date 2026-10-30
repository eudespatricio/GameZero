extends Label3D
class_name FloatingCombatText

enum TextType {
	NORMAL,
	CRITICAL,
	DAMAGE_TAKEN,
	MAGIC,
	HEAL,
	LOOT,
	BLOCK,
	BOSS_SHOUT
}

static func spawn(tree: SceneTree, world_pos: Vector3, text_content: String, type: TextType = TextType.NORMAL) -> void:
	var label = FloatingCombatText.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.text = text_content
	label.font_size = 32
	label.outline_size = 8
	label.outline_modulate = Color(0, 0, 0, 0.9)

	var target_scale = Vector3.ONE
	var color = Color.WHITE

	match type:
		TextType.NORMAL:
			color = Color(1.0, 0.95, 0.8)
			label.font_size = 30
		TextType.CRITICAL:
			color = Color(1.0, 0.72, 0.05) # Dourado
			target_scale = Vector3(1.4, 1.4, 1.4)
			label.font_size = 38
		TextType.DAMAGE_TAKEN:
			color = Color(1.0, 0.22, 0.25) # Vermelho
			label.font_size = 32
		TextType.MAGIC:
			color = Color(0.1, 0.95, 0.9) # Ciano Arcano
			label.font_size = 34
		TextType.HEAL:
			color = Color(0.2, 0.95, 0.5) # Verde Esmeralda
			label.font_size = 32
		TextType.BLOCK:
			color = Color(0.55, 0.78, 1.0) # Aço Azulado
			label.font_size = 30
		TextType.LOOT:
			color = Color(1.0, 0.85, 0.2)
			label.font_size = 28
		TextType.BOSS_SHOUT:
			color = Color(1.0, 0.32, 0.22) # Vermelho Fogo Intimidante
			target_scale = Vector3(1.3, 1.3, 1.3)
			label.font_size = 32
			label.outline_size = 9
			label.outline_modulate = Color(0.12, 0.02, 0.02, 0.95)

	label.modulate = color

	# Adiciona à raiz da cena
	var current_scene = tree.current_scene
	if not current_scene:
		return
	current_scene.add_child(label)

	var offset_x = randf_range(-0.4, 0.4)
	var offset_z = randf_range(-0.4, 0.4)
	label.global_position = world_pos + Vector3(offset_x, 2.4, offset_z)
	label.scale = Vector3(0.2, 0.2, 0.2)

	var is_shout := type == TextType.BOSS_SHOUT
	var dur := 2.2 if is_shout else 0.65
	var hold := 1.6 if is_shout else 0.4

	# Animação de Salto e Desaparecimento
	var tween = label.create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", target_scale, 0.22)
	tween.tween_property(label, "global_position:y", label.global_position.y + (0.9 if is_shout else 1.4), dur)

	# Fade out
	var fade_tween = label.create_tween()
	fade_tween.tween_interval(hold)
	fade_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade_tween.tween_property(label, "modulate:a", 0.0, 0.5 if is_shout else 0.3)
	fade_tween.tween_callback(label.queue_free)
