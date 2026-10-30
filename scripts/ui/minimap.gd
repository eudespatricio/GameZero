extends Control
class_name Minimap

@export var radar_radius: float = 75.0
@export var world_to_map_scale: float = 1.6 # metros no 3D -> pixels no minimapa (raio de ~47 m)

@onready var coords_label: Label = $Header/CoordsLabel
@onready var map_button: Button = $MapButton

var player = null
var monolith_positions: Array[Vector3] = [
	Vector3(-5.5, 0, -5.5),
	Vector3(5.5, 0, -5.5),
	Vector3(-5.5, 0, 5.5),
	Vector3(5.5, 0, 5.5)
]

signal open_world_map_requested

func _ready() -> void:
	if map_button:
		map_button.pressed.connect(func(): open_world_map_requested.emit())

func _process(_delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			var root = get_tree().current_scene
			if root:
				player = root.get_node_or_null("Player")

	if player and coords_label:
		var p = player.global_position
		coords_label.text = "X: %d | Z: %d" % [int(p.x), int(p.z)]

	queue_redraw()

func _draw() -> void:
	var center = Vector2(85, 95)
	
	# Fundo do Radar
	draw_circle(center, radar_radius, Color(0.04, 0.08, 0.1, 0.85))
	draw_arc(center, radar_radius, 0, TAU, 48, Color(0.2, 0.7, 0.65, 0.9), 2.0)
	draw_arc(center, radar_radius * 0.5, 0, TAU, 32, Color(0.15, 0.45, 0.4, 0.4), 1.0)
	
	# Eixos de orientação (Norte, Sul, Leste, Oeste)
	draw_line(center - Vector2(0, radar_radius), center + Vector2(0, radar_radius), Color(0.15, 0.45, 0.4, 0.3), 1.0)
	draw_line(center - Vector2(radar_radius, 0), center + Vector2(radar_radius, 0), Color(0.15, 0.45, 0.4, 0.3), 1.0)
	
	# Letra 'N' (Norte)
	draw_string(ThemeDB.fallback_font, center - Vector2(4, radar_radius - 12), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.4, 0.9, 0.85, 0.9))

	if not player:
		return

	var p_pos = player.global_position

	# Desenhar Menires / Pontos de Interesse no radar
	for m_pos in monolith_positions:
		var rel = Vector2(m_pos.x - p_pos.x, m_pos.z - p_pos.z) * world_to_map_scale
		if rel.length() <= radar_radius - 4.0:
			draw_circle(center + rel, 3.5, Color(0.2, 0.95, 0.9, 0.9))

	# Estradas e Portões de fronteira (MapBuilder) alinhados ao Mapa-Múndi
	var mb := get_tree().get_first_node_in_group("map_builder")
	if mb:
		for r in mb.roads:
			if not r.has("baked"):
				continue
			var prev_pt := Vector2.INF
			for q in r["baked"]:
				var rel_r: Vector2 = (Vector2(q.x, q.z) - Vector2(p_pos.x, p_pos.z)) * world_to_map_scale
				if rel_r.length() <= radar_radius - 3.0:
					if prev_pt != Vector2.INF:
						draw_line(center + prev_pt, center + rel_r, Color(0.75, 0.62, 0.4, 0.85), 2.0)
					prev_pt = rel_r
				else:
					prev_pt = Vector2.INF
		for bm in mb.boss_markers:
			var rel_b: Vector2 = (bm["pos"] - Vector2(p_pos.x, p_pos.z)) * world_to_map_scale
			if rel_b.length() <= radar_radius - 4.0:
				var bcol := Color(1.0, 0.75, 0.25) if bm["kind"] == "mini_boss" else Color(1.0, 0.25, 0.3)
				draw_circle(center + rel_b, 4.5, Color(0, 0, 0, 0.8))
				draw_circle(center + rel_b, 3.2, bcol)
		for g in mb.gates:
			var rel_g: Vector2 = (g["pos"] - Vector2(p_pos.x, p_pos.z)) * world_to_map_scale
			var col: Color = g["color"]
			if rel_g.length() <= radar_radius - 6.0:
				draw_circle(center + rel_g, 4.0, col)
			else:
				# Seta na borda do radar apontando para o portão distante
				var dir_g: Vector2 = rel_g.normalized()
				var tip: Vector2 = center + dir_g * (radar_radius - 3.0)
				var side: Vector2 = Vector2(-dir_g.y, dir_g.x) * 4.0
				draw_colored_polygon(PackedVector2Array([tip, tip - dir_g * 7.0 + side, tip - dir_g * 7.0 - side]), col)

	# --- NPCs DA PRAÇA NO RADAR ---
	var npcs_radar = [
		{"pos": Vector2(-4.5, -2.5), "col": Color(1.0, 0.72, 0.25), "icon": "⚒"},
		{"pos": Vector2(4.5, -2.5), "col": Color(0.3, 1.0, 0.65), "icon": "🧪"},
		{"pos": Vector2(0.0, 6.2), "col": Color(1.0, 0.88, 0.15), "icon": "!"}
	]
	var active_q = player.stats.get_active_quest() if (player and player.stats) else {}
	if not active_q.is_empty():
		if active_q.get("done", false):
			npcs_radar[2]["icon"] = "?"
			npcs_radar[2]["col"] = Color(0.25, 1.0, 0.55)
		else:
			npcs_radar[2]["icon"] = "!"
			npcs_radar[2]["col"] = Color(0.4, 0.8, 1.0)

	for npc in npcs_radar:
		var rel_npc = (npc["pos"] - Vector2(p_pos.x, p_pos.z)) * world_to_map_scale
		if rel_npc.length() <= radar_radius - 5.0:
			draw_circle(center + rel_npc, 4.5, Color(0.04, 0.05, 0.07, 0.95))
			draw_circle(center + rel_npc, 3.2, npc["col"])
			draw_string(ThemeDB.fallback_font, center + rel_npc + Vector2(-3, 3), npc["icon"], HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color.WHITE)

	# --- MARCADOR DE OBJETIVO DE MISSÃO (ÁREA / ALVO) ---
	var q_target := Vector2.ZERO
	if not active_q.is_empty():
		var raw_target = active_q.get("target_pos", Vector2.ZERO)
		if raw_target is Vector2:
			q_target = raw_target
		else:
			q_target = SaveService.to_vector2(raw_target)
	if not active_q.is_empty() and not active_q.get("done", false) and q_target != Vector2.ZERO:
		var q_pos: Vector2 = q_target
		var rel_q = (q_pos - Vector2(p_pos.x, p_pos.z)) * world_to_map_scale
		var q_col := Color(1.0, 0.85, 0.25)
		if rel_q.length() <= radar_radius - 8.0:
			var pulse = (sin(Time.get_ticks_msec() / 180.0) + 1.0) * 0.5
			var q_rad = 6.0 + pulse * 4.0
			draw_arc(center + rel_q, q_rad, 0, TAU, 24, Color(q_col.r, q_col.g, q_col.b, 0.9), 2.0)
			draw_circle(center + rel_q, 3.8, Color(1.0, 0.45, 0.15, 0.95))
			draw_string(ThemeDB.fallback_font, center + rel_q + Vector2(7, 3), "Missão", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, q_col)
		else:
			# Seta direcional apontando na borda do radar para o objetivo da missão
			var dir_q = rel_q.normalized()
			var tip_q = center + dir_q * (radar_radius - 3.5)
			var side_q = Vector2(-dir_q.y, dir_q.x) * 5.0
			draw_colored_polygon(PackedVector2Array([tip_q, tip_q - dir_q * 8.0 + side_q, tip_q - dir_q * 8.0 - side_q]), q_col)
			draw_string(ThemeDB.fallback_font, tip_q - dir_q * 14.0 - Vector2(8, -3), "📍", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, q_col)

	# Desenhar Marcador do Jogador (Triângulo apontando na direção que ele olha)
	var facing_angle = player.visual_root.rotation.y if player.visual_root else 0.0
	var forward = Vector2(sin(facing_angle), cos(facing_angle))
	var right = Vector2(-forward.y, forward.x)

	var p1 = center + forward * 8.0
	var p2 = center - forward * 5.0 + right * 5.0
	var p3 = center - forward * 5.0 - right * 5.0
	var points = PackedVector2Array([p1, p2, p3])
	draw_colored_polygon(points, Color(0.85, 0.95, 1.0, 1.0))
