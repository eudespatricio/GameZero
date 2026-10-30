extends Node3D
class_name LootDrop
## Item no chão: quica ao cair, brilha com a cor da raridade, mostra ícone/nome e é recolhido
## automaticamente quando o jogador chega perto (com efeito de "sucção").

@export var kind: String = "item"   # "gold" | "item"
@export var item_id: String = ""
@export var amount: int = 1
var item_instance: Dictionary = {}

const PICKUP_RADIUS := 2.4
const MAGNET_RADIUS := 5.0
const LIFETIME := 90.0

var _age: float = 0.0
var _landed: bool = false
var _collected: bool = false
var _player: Node3D
var _visual: Node3D
var _color: Color = Color(1.0, 0.85, 0.3)
var _retry_cooldown: float = 0.0

func _ready() -> void:
	var data := {}
	if kind == "item":
		data = ItemsDatabase.get_all_items().get(item_id, {})
		if data.has("rarity"):
			_color = _rarity_color(data["rarity"])
		elif data.has("glow_color"):
			_color = data["glow_color"]
	_visual = Node3D.new()
	add_child(_visual)

	if kind == "gold":
		for i in 3:
			var coin := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.17
			cyl.bottom_radius = 0.17
			cyl.height = 0.05
			coin.mesh = cyl
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(1.0, 0.78, 0.2)
			m.metallic = 1.0
			m.roughness = 0.25
			m.emission_enabled = true
			m.emission = Color(1.0, 0.6, 0.1)
			m.emission_energy_multiplier = 0.8
			coin.material_override = m
			coin.position = Vector3(randf_range(-0.12, 0.12), 0.05 * i, randf_range(-0.12, 0.12))
			coin.rotation = Vector3(randf_range(-0.2, 0.2), randf() * TAU, randf_range(-0.2, 0.2))
			_visual.add_child(coin)
	else:
		# Ícone ilustrado em billboard + gema giratória na cor da raridade
		var spr := Sprite3D.new()
		spr.texture = RPGIconGenerator.get_item_icon(item_id, data, 64)
		spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		spr.pixel_size = 0.011
		spr.position.y = 0.75
		spr.shaded = false
		spr.no_depth_test = false
		_visual.add_child(spr)
		var gem := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(0.22, 0.32, 0.22)
		gem.mesh = prism
		gem.name = "Gem"
		var gm := StandardMaterial3D.new()
		gm.albedo_color = _color
		gm.emission_enabled = true
		gm.emission = _color
		gm.emission_energy_multiplier = 2.4
		gem.material_override = gm
		gem.position.y = 0.25
		_visual.add_child(gem)

	# Feixe de luz da raridade
	var beam := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.05
	bm.bottom_radius = 0.2
	bm.height = 3.2 if _is_valuable() else 1.6
	beam.mesh = bm
	var beam_mat := StandardMaterial3D.new()
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.albedo_color = Color(_color.r, _color.g, _color.b, 0.28)
	beam_mat.emission_enabled = true
	beam_mat.emission = _color
	beam_mat.emission_energy_multiplier = 1.6
	beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam.material_override = beam_mat
	beam.position.y = bm.height * 0.5
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(beam)

	var light := OmniLight3D.new()
	light.light_color = _color
	light.light_energy = 1.2
	light.omni_range = 4.0
	light.position.y = 0.6
	add_child(light)

	# Nome flutuante
	var lbl := Label3D.new()
	lbl.text = _display_name(data)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 22
	lbl.outline_size = 6
	lbl.modulate = _color
	lbl.position.y = 1.45 if kind == "item" else 0.7
	lbl.no_depth_test = true
	add_child(lbl)

func _is_valuable() -> bool:
	if kind != "item":
		return false
	var d = ItemsDatabase.get_all_items().get(item_id, {})
	return d.get("rarity", 0) >= ItemsDatabase.Rarity.RARE

func _display_name(data: Dictionary) -> String:
	if kind == "gold":
		return "💰 %d Ouro" % amount
	return data.get("name", item_id)

func launch(target: Vector3) -> void:
	# Arco de queda com quique
	var start := global_position
	var mid := start.lerp(target, 0.5) + Vector3(0, 1.6, 0)
	var land := Vector3(target.x, 0.12, target.z)
	var tw := create_tween()
	tw.tween_property(self, "global_position", mid, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position", land, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "global_position:y", 0.45, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position:y", 0.12, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): _landed = true)

func _process(delta: float) -> void:
	_age += delta
	_retry_cooldown = max(0.0, _retry_cooldown - delta)
	if _age > LIFETIME:
		queue_free()
		return
	if _visual:
		_visual.position.y = (sin(_age * 3.0) * 0.06) if _landed else 0.0
		var gem := _visual.get_node_or_null("Gem")
		if gem:
			gem.rotation.y += delta * 2.4
	if _collected or not _landed:
		return
	if not _player or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if not _player:
			return
	var to_p: Vector3 = _player.global_position - global_position
	to_p.y = 0.0
	var dist := to_p.length()
	if dist < MAGNET_RADIUS and _age > 0.9:
		global_position += to_p.normalized() * delta * lerp(1.2, 9.0, 1.0 - dist / MAGNET_RADIUS)
	if dist < PICKUP_RADIUS and _age > 0.9 and _retry_cooldown <= 0.0:
		_collect()

func _collect() -> void:
	var stats = _player.get("stats") if _player else null
	if stats == null:
		return
	var label := ""
	var color := _color
	if kind == "gold":
		stats.gold += amount
		stats.stats_changed.emit()
		label = "+%d Ouro" % amount
	else:
		var data = ItemsDatabase.get_all_items().get(item_id, {})
		if not stats.add_item(item_id, 1, item_instance):
			_retry_cooldown = 2.0
			var hud = get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("show_notification"):
				hud.show_notification("🎒 Mochila cheia! Libere espaço para recolher %s" % data.get("name", item_id), Color(1.0, 0.5, 0.4))
			return
		label = "+ %s" % data.get("name", item_id)
	_collected = true
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("add_log_message"):
		if kind == "gold":
			hud.add_log_message("+%d Ouro" % amount, Color(1.0, 0.85, 0.25), "OURO")
		else:
			var data = ItemsDatabase.get_all_items().get(item_id, {})
			hud.add_log_message("+ %s" % data.get("name", item_id), color, "LOOT")
	FloatingCombatText.spawn(get_tree(), global_position + Vector3(0, 1.2, 0), label, FloatingCombatText.TextType.LOOT)
	if kind == "gold":
		GameAudio.play_coin(get_tree())
	else:
		GameAudio.play_jewel(get_tree())
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "global_position", _player.global_position + Vector3(0, 1.2, 0), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 0.18)
	tw.chain().tween_callback(queue_free)

static func _rarity_color(r: int) -> Color:
	match r:
		ItemsDatabase.Rarity.COMMON: return Color(0.78, 0.78, 0.8)
		ItemsDatabase.Rarity.MAGIC: return Color(0.35, 0.9, 0.45)
		ItemsDatabase.Rarity.RARE: return Color(0.3, 0.6, 1.0)
		ItemsDatabase.Rarity.EPIC: return Color(0.75, 0.35, 0.95)
		ItemsDatabase.Rarity.LEGENDARY: return Color(1.0, 0.75, 0.2)
	return Color(1.0, 0.3, 0.3)
