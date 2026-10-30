extends Control
class_name RegionMapCanvas

signal navigation_target_set(world_pos: Vector2)

var player = null
var map_builder: Node
var has_destination: bool = false
var destination_world: Vector2 = Vector2.ZERO

var top_map_tex: Texture2D = preload("res://assets/ui/sylveria_top_map.png")

# Dimensão do mapa jogável delimitada por penhascos
var map_half_extent: float = 200.0

func _ready() -> void:
	custom_minimum_size = Vector2(500, 500)
	mouse_filter = MOUSE_FILTER_STOP

func _process(_delta: float) -> void:
	if not visible:
		return

	var t = get_tree()
	if not player and t:
		player = t.get_first_node_in_group("player") as Player
	if not map_builder and t:
		map_builder = t.get_first_node_in_group("map_builder")
	if map_builder and "half_extent" in map_builder:
		map_half_extent = map_builder.half_extent

	if player and has_destination:
		var p2d = Vector2(player.global_position.x, player.global_position.z)
		if p2d.distance_to(destination_world) <= 0.8 or not player.is_moving_to_target:
			has_destination = false

	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var w_pos = map_to_world(event.position)
		set_player_destination(w_pos)
		accept_event()

## Define o destino de caminhada/voo do jogador através do clique no mapa
func set_player_destination(w_pos: Vector2) -> void:
	destination_world = w_pos
	has_destination = true

	var t = get_tree()
	if not player and t:
		player = t.get_first_node_in_group("player") as Player

	if player:
		var dest_3d = Vector3(w_pos.x, 0.05, w_pos.y)
		player.target_position = dest_3d
		player.is_moving_to_target = true
		if player.click_marker:
			player.click_marker.global_position = dest_3d + Vector3(0, 0.06, 0)
			player.click_marker.visible = true

		if t:
			GameAudio.play_pickup(t)
			var hud = t.get_first_node_in_group("hud")
			if hud and hud.has_method("show_notification"):
				hud.show_notification("🧭 Cavaleiro em marcha para o destino: [X: %d, Z: %d]" % [int(w_pos.x), int(w_pos.y)], Color(0.3, 0.95, 1.0))

		navigation_target_set.emit(w_pos)

## Converte coordenadas do mundo 3D (XZ) para pixels locais no Control do Mapa
func world_to_map(w_pos: Vector2) -> Vector2:
	var center = size * 0.5
	var scale_factor = (min(size.x, size.y) * 0.44) / map_half_extent
	return center + Vector2(w_pos.x * scale_factor, w_pos.y * scale_factor)

## Converte pixels do clique no mapa para coordenadas no mundo 3D (XZ)
func map_to_world(m_pos: Vector2) -> Vector2:
	var center = size * 0.5
	var scale_factor = (min(size.x, size.y) * 0.44) / map_half_extent
	var diff = m_pos - center
	var wx = clamp(diff.x / scale_factor, -map_half_extent + 3.0, map_half_extent - 3.0)
	var wz = clamp(diff.y / scale_factor, -map_half_extent + 3.0, map_half_extent - 3.0)
	return Vector2(wx, wz)

func _draw() -> void:
	var center = size * 0.5
	var bounds_rad = min(size.x, size.y) * 0.46
	var map_rect = Rect2(center - Vector2(bounds_rad, bounds_rad), Vector2(bounds_rad * 2.0, bounds_rad * 2.0))

	# 1. Render Top-Down Real da Região de Sylveria em Alta Fidelidade (Árvores 3D, Rio, Estradas e Penhascos)
	if top_map_tex:
		draw_texture_rect(top_map_tex, map_rect, false)
	else:
		draw_rect(map_rect, Color(0.08, 0.12, 0.10, 1.0))

	# Moldura Cartográfica Dourada com cantos ornamentais
	draw_rect(map_rect, Color(0.65, 0.52, 0.25, 0.95), false, 2.5)
	draw_rect(map_rect.grow(3.0), Color(0.25, 0.18, 0.08, 0.8), false, 1.5)

	# Linhas coordenadas sutis de bússola
	draw_line(Vector2(center.x, map_rect.position.y), Vector2(center.x, map_rect.position.y + 12), Color(1, 0.85, 0.3, 0.8), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(center.x - 4, map_rect.position.y + 24), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1, 0.85, 0.3))

	# 2. Santuário de Sylveria (Safe Zone - Raio 24m)
	var safe_center = world_to_map(Vector2.ZERO)
	var safe_rad_px = 24.0 * ((min(size.x, size.y) * 0.44) / map_half_extent)
	draw_circle(safe_center, safe_rad_px, Color(0.08, 0.35, 0.22, 0.25))
	draw_arc(safe_center, safe_rad_px, 0, TAU, 36, Color(0.25, 0.95, 0.65, 0.9), 2.0)
	draw_string(ThemeDB.fallback_font, safe_center - Vector2(40, -4), "Santuário [Área Segura]", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color(0.4, 1.0, 0.6))

	# NPCs na Praça
	var active_q = player.stats.get_active_quest() if (player and player.stats) else {}
	var brom_icon = "!"
	var brom_col = Color(1.0, 0.88, 0.15)
	if not active_q.is_empty():
		if active_q.get("done", false):
			brom_icon = "?"
			brom_col = Color(0.25, 1.0, 0.55)
		else:
			brom_icon = "!"
			brom_col = Color(0.4, 0.8, 1.0)

	var npcs = [
		{"pos": Vector2(-4.5, -2.5), "name": "Horst [⚒ Forja]", "col": Color(1.0, 0.72, 0.25), "icon": "⚒"},
		{"pos": Vector2(4.5, -2.5), "name": "Angela [🧪 Poções]", "col": Color(0.3, 1.0, 0.65), "icon": "🧪"},
		{"pos": Vector2(0.0, 6.2), "name": "Brom [Missões]", "col": brom_col, "icon": brom_icon}
	]
	for npc in npcs:
		var np_pos = world_to_map(npc["pos"])
		draw_circle(np_pos, 4.5, Color(0.03, 0.04, 0.06, 0.95))
		draw_circle(np_pos, 3.2, npc["col"])
		draw_string(ThemeDB.fallback_font, np_pos + Vector2(6, 4), "%s %s" % [npc["icon"], npc["name"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, npc["col"])

	# 5. Portões de Fronteira
	if map_builder and "gates" in map_builder:
		for g in map_builder.gates:
			var gp = world_to_map(g["pos"])
			draw_circle(gp, 5.5, Color(0.05, 0.05, 0.07, 0.9))
			draw_circle(gp, 4.0, g["color"])
			var dest_str = "%s" % g.get("dest", "Fronteira")
			draw_string(ThemeDB.fallback_font, gp + Vector2(-35, 14), dest_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 9, g["color"])

	# 5b. Marcos rúnicos (pedras-guia) ao longo das estradas
	if map_builder and "waystones" in map_builder:
		for ws in map_builder.waystones:
			var wp = world_to_map(ws["pos"])
			var wc: Color = ws["color"]
			draw_colored_polygon(PackedVector2Array([wp + Vector2(0, -5), wp + Vector2(4, 0), wp + Vector2(0, 5), wp + Vector2(-4, 0)]), wc)

	# 6. Acampamentos de Chefes e Criaturas (Bosses)
	if map_builder and "boss_markers" in map_builder:
		for bm in map_builder.boss_markers:
			var bp = world_to_map(bm["pos"])
			var is_world = bm.get("kind") == "world_boss"
			var bcol = Color(1.0, 0.25, 0.25) if is_world else Color(1.0, 0.78, 0.25)
			draw_circle(bp, 6.0, Color(0.02, 0.02, 0.03, 0.9))
			draw_circle(bp, 4.2, bcol)
			var bname = "%s" % bm.get("name", "Boss")
			draw_string(ThemeDB.fallback_font, bp + Vector2(-40, -8), bname, HORIZONTAL_ALIGNMENT_CENTER, -1, 9, bcol)

	# 6b. Círculo de Objetivo de Missão Ativa
	var q_target := Vector2.ZERO
	if not active_q.is_empty():
		var raw_target = active_q.get("target_pos", Vector2.ZERO)
		q_target = raw_target if raw_target is Vector2 else SaveService.to_vector2(raw_target)
	if not active_q.is_empty() and not active_q.get("done", false) and q_target != Vector2.ZERO:
		var q_world: Vector2 = q_target
		var q_map: Vector2 = world_to_map(q_world)
		var q_rad_px = 18.0
		var pulse = (sin(Time.get_ticks_msec() / 180.0) + 1.0) * 0.5
		draw_circle(q_map, q_rad_px, Color(1.0, 0.82, 0.2, 0.18))
		draw_arc(q_map, q_rad_px + pulse * 3.0, 0, TAU, 32, Color(1.0, 0.85, 0.25, 0.9), 2.2)
		draw_circle(q_map, 4.0, Color(1.0, 0.45, 0.15, 0.95))
		var q_title = active_q.get("title", "Missão")
		draw_string(ThemeDB.fallback_font, q_map + Vector2(-50, -q_rad_px - 4), "📍 [Missão: %s]" % q_title, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1.0, 0.9, 0.35))

	# 7. Linha de Destino e Waypoint de Marcha Ativa
	if has_destination and player:
		var p_map = world_to_map(Vector2(player.global_position.x, player.global_position.z))
		var dest_map = world_to_map(destination_world)

		# Linha tracejada conectando o herói ao destino
		draw_line(p_map, dest_map, Color(1.0, 0.85, 0.35, 0.8), 2.0)

		# Anel pulsante no destino
		var pulse = (sin(Time.get_ticks_msec() / 180.0) + 1.0) * 0.5
		var dest_rad = 6.0 + pulse * 4.0
		draw_arc(dest_map, dest_rad, 0, TAU, 24, Color(1.0, 0.85, 0.25, 0.95), 2.2)
		draw_circle(dest_map, 3.5, Color(1.0, 0.4, 0.2, 1.0))
		draw_string(ThemeDB.fallback_font, dest_map + Vector2(10, -6), "Destino", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.9, 0.35))

	# 8. MARCADOR DO PERSONAGEM (VOCÊ ESTÁ AQUI)
	if player:
		var p2d = Vector2(player.global_position.x, player.global_position.z)
		var p_pos = world_to_map(p2d)

		# Radar pulsante em torno do herói
		var radar_pulse = (sin(Time.get_ticks_msec() / 220.0) + 1.0) * 0.5
		var radar_rad = 9.0 + radar_pulse * 6.0
		draw_arc(p_pos, radar_rad, 0, TAU, 32, Color(0.25, 0.9, 1.0, 0.85 - radar_pulse * 0.5), 2.0)

		# Círculo base do jogador
		draw_circle(p_pos, 6.0, Color(0.04, 0.05, 0.07, 0.95))
		draw_circle(p_pos, 4.5, Color(0.2, 0.85, 1.0, 1.0))

		# Seta Direcional apontando para o ângulo de visão do Cavaleiro
		var rot_y = player.visual_root.rotation.y if player.visual_root else 0.0
		var dir_forward = Vector2(sin(rot_y), cos(rot_y))
		var dir_right = Vector2(-dir_forward.y, dir_forward.x)
		var tip = p_pos + dir_forward * 13.0
		var base_l = p_pos - dir_forward * 4.0 - dir_right * 5.0
		var base_r = p_pos - dir_forward * 4.0 + dir_right * 5.0
		draw_colored_polygon(PackedVector2Array([tip, base_l, base_r]), Color(1.0, 0.88, 0.28, 1.0))

		# Etiqueta com Nome e Coordenadas do Jogador
		var coords_text = "VOCÊ [X: %d, Z: %d]" % [int(p2d.x), int(p2d.y)]
		draw_string(ThemeDB.fallback_font, p_pos + Vector2(14, 4), coords_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.92, 0.45))
