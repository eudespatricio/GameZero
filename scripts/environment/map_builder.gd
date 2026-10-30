extends Node3D
class_name MapBuilder
## Constrói o mapa local (Santuário de Sylveria e arredores): muralha de penhascos, estradas, portais de fronteira,
## acampamentos de mobs/bosses, vegetação por bioma, marcos, lanternas e nós de coleta.
## O mapa foi expandido: `half_extent` define a metade do lado (200 m => 400 x 400 m). Todos os dados de estradas e
## acampamentos são escritos na escala base (100 m) e reescalados em `_apply_world_scale()`.
## Eixos Godot: -Z = Norte (cima da tela), +X = Leste.
##   - Norte/Nordeste  -> Ellesmera
##   - Sul / Sudeste   -> Urû'baen   (atravessa a ponte do rio)
##   - Sul / Sudoeste  -> Farthen Dûr (Beor)
##   - Oeste           -> Yazuac, Helgrind, Teirm, Espinha, Carvahall
##   - Leste           -> fronteira fechada (limite do mundo conhecido)

const TREE_SCN := "res://assets/models/elven_tree_detailed.glb"
const TREE_FOLIAGE_SHADER := "res://assets/shaders/tree_foliage.gdshader"
const TREE_BARK_SHADER := "res://assets/shaders/tree_bark.gdshader"
const FERN_SCN := "res://assets/models/elven_fern_patch.glb"
const SHROOM_SCN := "res://assets/models/elven_mushrooms_cluster.glb"
const ROCK_SCN := "res://assets/models/rock_formation_detailed.glb"
const GATE_SCN := "res://assets/models/elven_gate.glb"
const SIGN_SCN := "res://assets/models/road_signpost.glb"
const CLIFF_SCN := "res://assets/models/cliff_wall_segment.glb"
const BRAZIER_SCN := "res://assets/models/stone_brazier.glb"
const MONOLITH_SCN := "res://assets/models/elven_monolith_detailed.glb"
const ANCIENT_TREE_SCN := "res://scenes/environment/props/elven_ancient_tree.tscn"
const GATHER_SCN := "res://scenes/environment/props/gathering_node.tscn"
const COBBLE_SHADER := "res://assets/shaders/cobblestone_path.gdshader"
const PORTAL_SHADER := "res://assets/shaders/portal_vortex.gdshader"
const VORTEX_SHADER := "res://assets/shaders/magic_vortex.gdshader"
const LAVA_SHADER := "res://assets/shaders/lava_pool.gdshader"
const SWAMP_SHADER := "res://assets/shaders/toxic_swamp.gdshader"
const TEMPLE_SHADER := "res://assets/shaders/temple_ruins_floor.gdshader"
const ICE_SHADER := "res://assets/shaders/permafrost_floor.gdshader"
const ORE_CRYSTAL_SCN := "res://assets/models/brightsteel_ore_detailed.glb"
const FLICKER_SCRIPT := "res://scripts/environment/fire_flicker.gd"
const AMBIENT_SCRIPT := "res://scripts/environment/ambient_fx.gd"
const ENEMY_SCN := "res://scenes/enemies/enemy_mob.tscn"

const BASE_EXTENT := 100.0
const GRID_CELL := 8.0

@export var half_extent: float = 300.0
@export var road_width: float = 4.0
@export var road_bake_interval: float = 2.0
@export var scatter_seed: int = 1337
@export var tree_count: int = 1450
@export var fern_count: int = 3200
@export var shroom_count: int = 340
@export var rock_count: int = 480
@export var proc_camp_count: int = 135
@export var gathering_node_count: int = 48

## Estradas: pontos em XZ (Y ignorado). "gate" = a estrada termina em um portão de fronteira.
## O primeiro ponto fica ancorado na praça/ponte (não é reescalado); os demais seguem a escala do mapa.
var roads: Array[Dictionary] = [
	{
		"id": "norte", "gate": true, "loc": "ellesmera",
		"title": "Estrada do Norte", "dest": "Ellesmera",
		"detail": "Cidade-árvore dos elfos • Níveis 36 – 50",
		"color": Color(0.45, 0.95, 0.75),
		"points": [Vector2(0, -6), Vector2(0, -20), Vector2(5, -35), Vector2(16, -52), Vector2(30, -70), Vector2(44, -86), Vector2(52, -99)],
	},
	{
		"id": "oeste", "gate": true, "loc": "carvahall",
		"title": "Estrada do Oeste", "dest": "Yazuac · Helgrind · Teirm · Espinha · Carvahall",
		"detail": "Terras Devastadas dos Kulls • Níveis 11 – 40",
		"color": Color(1.0, 0.65, 0.3),
		"points": [Vector2(-6, 2), Vector2(-16, 3), Vector2(-30, 8), Vector2(-46, 7), Vector2(-62, 11), Vector2(-80, 14), Vector2(-99, 11)],
	},
	{
		"id": "sul_urubaen", "gate": true, "loc": "urubaen",
		"title": "Estrada Imperial", "dest": "Urû'baen",
		"detail": "Cidadela Negra de Galbatorix • Nível 50+",
		"color": Color(1.0, 0.4, 0.4),
		"points": [Vector2(0, 42), Vector2(-1, 54), Vector2(3, 66), Vector2(12, 78), Vector2(22, 89), Vector2(28, 99)],
	},
	{
		"id": "sul_beor", "gate": true, "loc": "beor",
		"title": "Trilha dos Anões", "dest": "Farthen Dûr (Beor)",
		"detail": "Tronjheim & Estrela de Safira • Níveis 45 – 50",
		"color": Color(0.5, 0.75, 1.0),
		"points": [Vector2(0, 42), Vector2(-3, 56), Vector2(-9, 70), Vector2(-17, 82), Vector2(-25, 92), Vector2(-32, 99)],
	},
]

var world_scale: float = 1.0
var _road_samples: Array[Vector2] = []
var _road_grid: Dictionary = {}
var gates: Array[Dictionary] = []  # {id, loc, pos, title, dest, color}
var waystones: Array[Dictionary] = []  # {pos, name, color}
var _rng := RandomNumberGenerator.new()
var _last_notify: Dictionary = {}
var _reserved: Array[Dictionary] = []  # {pos: Vector2, r: float} – áreas sem vegetação (acampamentos, marcos)
var boss_markers: Array[Dictionary] = []  # {pos, name, kind} para o minimapa

var _portal_in_range: String = ""
var _portal_prompts: Dictionary = {}
var _zone_id: String = ""
var _zone_timer: float = 0.0
var _dormancy_timer: float = 0.25
var _player: Node3D

## Acampamentos de mobs/bosses: road + frac (0..1 ao longo da estrada) + deslocamento lateral, ou pos fixa.
## "k" (opcional) substitui a escala do mapa para acampamentos iniciais (ficam mais próximos do Santuário).
## Dificuldade cresce com a distância da praça, alinhada às regiões do Mapa-Múndi.
var camps: Array[Dictionary] = [
	# Arredores iniciais (mantidos fora da Safe Zone do Santuário)
	{"pos": Vector2(-38, -34), "k": 1.3, "mob": "boar", "n": 3},
	{"pos": Vector2(38, -32), "k": 1.3, "mob": "boar", "n": 3},
	{"pos": Vector2(42, -50), "k": 1.3, "mob": "wolf", "n": 3},
	{"pos": Vector2(-44, -54), "k": 1.3, "mob": "wolf", "n": 3},
	{"pos": Vector2(48, 12), "k": 1.3, "mob": "wolf", "n": 2},
	{"pos": Vector2(62, -36), "k": 1.6, "mob": "wolf_alpha", "n": 1},
	# Estrada do Oeste – Terras Devastadas
	{"road": "oeste", "f": 0.42, "side": 8.0, "mob": "urgal_raider", "n": 3},
	{"road": "oeste", "f": 0.56, "side": -9.0, "mob": "kull_young", "n": 2},
	{"road": "oeste", "f": 0.65, "side": 10.0, "mob": "gromk", "n": 1},
	{"road": "oeste", "f": 0.78, "side": -8.0, "mob": "kull_young", "n": 3},
	{"road": "oeste", "f": 0.88, "side": 9.0, "mob": "garzhvog", "n": 1},
	# Estrada do Norte – Du Weldenvarden
	{"road": "norte", "f": 0.38, "side": 9.0, "mob": "golem", "n": 3},
	{"road": "norte", "f": 0.50, "side": -9.0, "mob": "fanghur", "n": 3},
	{"road": "norte", "f": 0.62, "side": 9.0, "mob": "stone_guardian", "n": 1},
	{"road": "norte", "f": 0.74, "side": -8.0, "mob": "golem", "n": 2},
	{"road": "norte", "f": 0.86, "side": 8.0, "mob": "durza", "n": 1},
	# Estrada Imperial – Urû'baen
	{"road": "sul_urubaen", "f": 0.38, "side": 9.0, "mob": "oathsworn", "n": 3},
	{"road": "sul_urubaen", "f": 0.58, "side": -9.0, "mob": "oathsworn", "n": 3},
	{"road": "sul_urubaen", "f": 0.68, "side": 9.0, "mob": "oathsworn_knight", "n": 1},
	{"road": "sul_urubaen", "f": 0.85, "side": -8.0, "mob": "razac", "n": 1},
	# Trilha dos Anões – Farthen Dûr
	{"road": "sul_beor", "f": 0.42, "side": 8.0, "mob": "shade_scout", "n": 3},
	{"road": "sul_beor", "f": 0.80, "side": -8.0, "mob": "tomb_warden", "n": 1},
]

func _ready() -> void:
	add_to_group("map_builder")
	_rng.seed = scatter_seed
	_apply_world_scale()
	_setup_river_water_shader()
	_build_roads()
	_build_boundary_collision()
	_build_safe_zone_barrier()
	_build_cliff_perimeter()
	_build_gates_and_signs()
	_generate_procedural_camps()
	_spawn_mobs()
	_build_landmarks()
	_place_gathering_nodes()
	_scatter_vegetation()
	_spawn_ambient_fx()

# ------------------------------------------------------------------
# RIO & ÁGUA PROCEDURAL
# ------------------------------------------------------------------
func _setup_river_water_shader() -> void:
	var parent_scene = get_parent()
	if not parent_scene:
		return
	var river_root = parent_scene.get_node_or_null("River")
	if not river_root:
		return
	var water_sh = load("res://assets/shaders/water_river.gdshader") as Shader
	if not water_sh:
		return
	var water_mat = ShaderMaterial.new()
	water_mat.shader = water_sh

	var meshes: Array = []
	_collect_all_mesh_instances(river_root, meshes)
	for mi in meshes:
		if mi.name.contains("RiverWater"):
			mi.material_override = water_mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _collect_all_mesh_instances(node: Node, out: Array) -> void:
	if node is MeshInstance3D:
		out.append(node)
	for c in node.get_children():
		_collect_all_mesh_instances(c, out)

# ------------------------------------------------------------------
# ESCALA DO MUNDO
# ------------------------------------------------------------------
func _apply_world_scale() -> void:
	world_scale = half_extent / BASE_EXTENT
	if is_equal_approx(world_scale, 1.0):
		return
	for r in roads:
		var src: Array = r["points"]
		var pts: Array[Vector2] = []
		pts.append(src[0])
		for i in range(1, src.size()):
			pts.append((src[i] as Vector2) * world_scale)
		r["points"] = pts
	for c in camps:
		if c.has("pos"):
			var k: float = c.get("k", world_scale)
			c["pos"] = (c["pos"] as Vector2) * k

# ------------------------------------------------------------------
# BIOMAS & ZONAS
# ------------------------------------------------------------------
## Retorna o bioma do ponto (coordenadas XZ): sanctuary | start | north | west | south_east | south_west | east
func biome_at(p: Vector2) -> String:
	var r := p.length()
	var s := world_scale
	if r < 30.0:
		return "sanctuary"
	if r < 95.0 * s * 0.75:
		return "start"
	var d := p / r
	if d.y < -0.40:
		return "north"
	if d.x < -0.55:
		return "west"
	if d.y > 0.40:
		return "south_east" if d.x >= 0.0 else "south_west"
	return "east"

func zone_at(p: Vector2) -> Dictionary:
	match biome_at(p):
		"sanctuary":
			return {"id": "sanctuary", "name": "Santuário de Sylveria", "detail": "Área segura • Portal de retorno", "color": Color(0.4, 1.0, 0.7)}
		"start":
			return {"id": "start", "name": "Arredores de Sylveria", "detail": "Níveis 1 – 10", "color": Color(0.7, 0.95, 0.6)}
		"north":
			return {"id": "north", "name": "Du Weldenvarden", "detail": "Floresta élfica • Níveis 36 – 50", "color": Color(0.45, 0.95, 0.75)}
		"west":
			return {"id": "west", "name": "Terras Devastadas dos Kulls", "detail": "Níveis 21 – 40", "color": Color(1.0, 0.65, 0.3)}
		"south_east":
			return {"id": "south_east", "name": "Domínio do Império", "detail": "Estrada de Urû'baen • Níveis 46 – 52", "color": Color(1.0, 0.45, 0.45)}
		"south_west":
			return {"id": "south_west", "name": "Trilha dos Anões", "detail": "Rumo a Farthen Dûr • Níveis 45 – 50", "color": Color(0.55, 0.78, 1.0)}
		_:
			return {"id": "east", "name": "Orla Oriental", "detail": "Limite do mundo conhecido", "color": Color(0.85, 0.85, 0.7)}

func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D

	# 1. Gerenciamento de Dormência de Mobs Distantes (LOD Hierárquico)
	_dormancy_timer -= delta
	if _dormancy_timer <= 0.0:
		_dormancy_timer = 0.35 # Varre apenas 3 vezes por segundo
		_update_mobs_dormancy()

	# 2. Verificação de Zonas
	_zone_timer -= delta
	if _zone_timer <= 0.0:
		_zone_timer = 0.5
		if _player and is_instance_valid(_player):
			var z := zone_at(Vector2(_player.global_position.x, _player.global_position.z))
			if z["id"] != _zone_id:
				var first := _zone_id == ""
				_zone_id = z["id"]
				if not first:
					var hud := get_tree().get_first_node_in_group("hud")
					if hud and hud.has_method("show_notification"):
						hud.show_notification("Entrando em: %s\n%s" % [z["name"], z["detail"]], z["color"])

## Coloca em dormência (0 CPU/GPU) todos os acampamentos a mais de 75m do jogador
func _update_mobs_dormancy() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var p_pos := Vector2(_player.global_position.x, _player.global_position.z)
	var wake_dist_sq := 75.0 * 75.0

	for c in camps:
		var center: Vector2
		if c.has("road"):
			center = _road_point(c["road"], c["f"], c["side"])
		else:
			center = c["pos"]
		var should_wake: bool = center.distance_squared_to(p_pos) <= wake_dist_sq
		var mobs: Array = c.get("spawned_mobs", [])
		for m in mobs:
			if is_instance_valid(m) and m.has_method("set_dormant"):
				m.set_dormant(not should_wake)

# ------------------------------------------------------------------
# ESTRADAS
# ------------------------------------------------------------------
func _build_roads() -> void:
	var shader := load(COBBLE_SHADER) as Shader
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("uv_scale", Vector2(16.0, 16.0))
	for r in roads:
		var curve := Curve3D.new()
		for p in r["points"]:
			curve.add_point(Vector3(p.x, 0, p.y))
		# suaviza (Catmull-like) usando tangentes automáticas
		var n := curve.point_count
		for i in n:
			var prev: Vector3 = curve.get_point_position(max(i - 1, 0))
			var next: Vector3 = curve.get_point_position(min(i + 1, n - 1))
			var t := (next - prev) * 0.25
			curve.set_point_in(i, -t)
			curve.set_point_out(i, t)
		curve.bake_interval = road_bake_interval
		var pts := curve.get_baked_points()
		r["baked"] = pts
		for q in pts:
			_add_road_sample(Vector2(q.x, q.z))
		var mi := MeshInstance3D.new()
		mi.name = "Road_" + r["id"]
		mi.mesh = _ribbon_mesh(pts, road_width)
		mi.material_override = mat
		mi.position.y = 0.016
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	# amostras da estrada existente (plaza -> ponte -> margem sul) para evitar vegetação
	for z in range(-8, 44, 2):
		_add_road_sample(Vector2(0, z))

func _add_road_sample(p: Vector2) -> void:
	_road_samples.append(p)
	var key := Vector2i(int(floor(p.x / GRID_CELL)), int(floor(p.y / GRID_CELL)))
	if not _road_grid.has(key):
		_road_grid[key] = []
	(_road_grid[key] as Array).append(p)

## Verdadeiro se o ponto está a menos de `margin` (<= GRID_CELL) de alguma amostra de estrada.
func _near_road(p: Vector2, margin: float) -> bool:
	var cx := int(floor(p.x / GRID_CELL))
	var cy := int(floor(p.y / GRID_CELL))
	var m2 := margin * margin
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var key := Vector2i(cx + dx, cy + dy)
			if _road_grid.has(key):
				for q in _road_grid[key]:
					if p.distance_squared_to(q) < m2:
						return true
	return false

func _ribbon_mesh(pts: PackedVector3Array, width: float) -> ArrayMesh:
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var idx := PackedInt32Array()
	var dist := 0.0
	for i in pts.size():
		var tg: Vector3
		if i == 0:
			tg = pts[1] - pts[0]
		elif i == pts.size() - 1:
			tg = pts[i] - pts[i - 1]
		else:
			tg = pts[i + 1] - pts[i - 1]
		tg.y = 0
		tg = tg.normalized()
		var side := Vector3(-tg.z, 0, tg.x) * (width * 0.5)
		# largura levemente irregular para aspecto orgânico
		var wob := 1.0 + 0.12 * sin(dist * 0.55) + 0.06 * sin(dist * 1.7 + 2.0)
		verts.append(pts[i] - side * wob)
		verts.append(pts[i] + side * wob)
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
		uvs.append(Vector2(0.0, dist / width))
		uvs.append(Vector2(1.0, dist / width))
		if i > 0:
			dist += pts[i].distance_to(pts[i - 1])
			uvs[uvs.size() - 2].y = dist / width
			uvs[uvs.size() - 1].y = dist / width
		if i < pts.size() - 1:
			var b := i * 2
			idx.append_array([b, b + 2, b + 1, b + 1, b + 2, b + 3])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m

# ------------------------------------------------------------------
# DELIMITAÇÃO: paredes invisíveis + muralha de penhascos
# ------------------------------------------------------------------
func _build_boundary_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "BoundaryWalls"
	var e := half_extent + 1.0
	var span := (half_extent + 6.0) * 2.0
	var defs := [
		[Vector3(0, 4, -e), Vector3(span, 10, 2)],
		[Vector3(0, 4, e), Vector3(span, 10, 2)],
		[Vector3(-e, 4, 0), Vector3(2, 10, span)],
		[Vector3(e, 4, 0), Vector3(2, 10, span)],
	]
	for d in defs:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = d[1]
		cs.shape = bs
		cs.position = d[0]
		body.add_child(cs)
	add_child(body)

## Barreira física arcana do Santuário de Sylveria: bloqueia exclusivamente monstros (layer 2)
func _build_safe_zone_barrier() -> void:
	var body := StaticBody3D.new()
	body.name = "SafeZoneArcaneBarrier"
	body.collision_layer = 2  # Apenas inimigos colidem com a barreira
	body.collision_mask = 2
	var r := 23.5
	var segments := 24
	for i in range(segments):
		var a1 := float(i) * TAU / float(segments)
		var a2 := float(i + 1) * TAU / float(segments)
		var p1 := Vector3(cos(a1) * r, 0, sin(a1) * r)
		var p2 := Vector3(cos(a2) * r, 0, sin(a2) * r)
		var mid := (p1 + p2) * 0.5 + Vector3(0, 3.0, 0)
		var seg_len := p1.distance_to(p2)
		var angle := atan2(p2.x - p1.x, p2.z - p1.z)

		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(1.2, 8.0, seg_len + 0.4)
		cs.shape = bs
		cs.position = mid
		cs.rotation.y = angle
		body.add_child(cs)
	add_child(body)

func _build_cliff_perimeter() -> void:
	var meshes := _collect_meshes(CLIFF_SCN)
	if meshes.is_empty():
		return
	var gate_pts: Array[Vector2] = []
	for r in roads:
		if r["gate"]:
			gate_pts.append(r["points"][r["points"].size() - 1])
	var placements: Array[Transform3D] = []
	var step := 11.0
	var edge := half_extent + 4.0
	var t := -edge
	while t <= edge:
		for side in 4:
			var pos: Vector3
			var yaw: float
			match side:
				0: pos = Vector3(t, 0, -edge); yaw = 0.0
				1: pos = Vector3(t, 0, edge); yaw = PI
				2: pos = Vector3(-edge, 0, t); yaw = PI * 0.5
				_: pos = Vector3(edge, 0, t); yaw = -PI * 0.5
			var skip := false
			for g in gate_pts:
				if Vector2(pos.x, pos.z).distance_to(g) < 11.0:
					skip = true
			if skip:
				continue
			var s := _rng.randf_range(1.0, 1.35)
			var b := Basis(Vector3.UP, yaw + _rng.randf_range(-0.12, 0.12)).scaled(Vector3(s, _rng.randf_range(1.0, 1.5), s))
			placements.append(Transform3D(b, pos))
		t += step
	# segunda camada recuada e deslocada meio passo para fechar frestas e dar profundidade
	var second: Array[Transform3D] = []
	for p in placements:
		var inward := -Vector3(p.origin.x, 0, p.origin.z).normalized()
		var tangent := p.basis.x.normalized()
		var sc := _rng.randf_range(0.85, 1.15)
		second.append(Transform3D(p.basis.scaled(Vector3(sc, sc, sc)), p.origin + inward * 5.0 + tangent * step * 0.5))
	_spawn_multimesh(meshes, placements + second, "CliffWall", 180.0)

# ------------------------------------------------------------------
# PORTAIS DE FRONTEIRA & PLACAS
# ------------------------------------------------------------------
func _build_gates_and_signs() -> void:
	var gate_scene := load(GATE_SCN) as PackedScene
	var sign_scene := load(SIGN_SCN) as PackedScene
	var portal_shader := load(PORTAL_SHADER) as Shader
	var rune_shader := load(VORTEX_SHADER) as Shader
	var flicker_script = load(FLICKER_SCRIPT)
	for r in roads:
		if not r["gate"]:
			continue
		var pts: PackedVector3Array = r["baked"]
		var end: Vector3 = pts[pts.size() - 1]
		var back: Vector3 = pts[max(pts.size() - 4, 0)]
		var dir := (end - back)
		dir.y = 0
		dir = dir.normalized()
		var gpos := end - dir * 3.0
		gpos.y = 0.0
		var col: Color = r["color"]
		var yaw := atan2(dir.x, dir.z)

		var portal := Node3D.new()
		portal.name = "Portal_" + r["id"]
		add_child(portal)
		portal.global_position = gpos
		portal.rotation.y = yaw

		# Arco do portão
		if gate_scene:
			var g := gate_scene.instantiate() as Node3D
			g.name = "Gate_" + r["id"]
			portal.add_child(g)

		# Membrana de energia espiralada dentro do arco
		var membrane := MeshInstance3D.new()
		membrane.name = "Membrane"
		var qm := QuadMesh.new()
		qm.size = Vector2(5.0, 6.2)
		var pmat := ShaderMaterial.new()
		pmat.shader = portal_shader
		pmat.set_shader_parameter("core_color", col.lerp(Color.WHITE, 0.35))
		pmat.set_shader_parameter("intensity", 1.15)
		pmat.set_shader_parameter("edge_color", col * 0.7)
		qm.material = pmat
		membrane.mesh = qm
		membrane.position = Vector3(0, 3.35, 0.04)
		membrane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		portal.add_child(membrane)

		# Círculo rúnico no chão diante do portal
		var pad := MeshInstance3D.new()
		pad.name = "RunePad"
		var pm := PlaneMesh.new()
		pm.size = Vector2(9.0, 9.0)
		var rmat := ShaderMaterial.new()
		rmat.shader = rune_shader
		rmat.set_shader_parameter("color", col)
		rmat.set_shader_parameter("alpha", 0.55)
		rmat.set_shader_parameter("intensity", 1.6)
		pm.material = rmat
		pad.mesh = pm
		pad.position = Vector3(0, 0.07, -2.6)
		pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		portal.add_child(pad)

		# Partículas de energia subindo pelo arco
		var motes := GPUParticles3D.new()
		motes.name = "Motes"
		motes.amount = 70
		motes.lifetime = 3.0
		motes.preprocess = 2.0
		motes.local_coords = true
		motes.visibility_aabb = AABB(Vector3(-5, -1, -5), Vector3(10, 12, 10))
		var mm := ParticleProcessMaterial.new()
		mm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		mm.emission_box_extents = Vector3(2.3, 0.2, 0.35)
		mm.direction = Vector3(0, 1, 0)
		mm.spread = 12.0
		mm.initial_velocity_min = 0.8
		mm.initial_velocity_max = 2.4
		mm.gravity = Vector3(0, 0.25, 0)
		mm.scale_min = 0.15
		mm.scale_max = 0.38
		mm.scale_curve = CombatVFX._shrink_curve(0.6, 1.0, 0.0)
		mm.color_ramp = CombatVFX._ramp([[0.0, Color(col.r, col.g, col.b, 0.0)], [0.25, Color(1, 1, 1, 0.9)], [1.0, Color(col.r, col.g, col.b, 0.0)]])
		motes.process_material = mm
		var mq := QuadMesh.new()
		mq.size = Vector2(1, 1)
		mq.material = CombatVFX._billboard_material(true)
		motes.draw_pass_1 = mq
		motes.position = Vector3(0, 0.4, 0.0)
		portal.add_child(motes)

		# Zumbido espacial contínuo do portal (loop)
		var hum_path := "res://assets/audio/sfx/portal_hum.ogg"
		if ResourceLoader.exists(hum_path):
			var hum = load(hum_path)
			if hum is AudioStreamOggVorbis:
				(hum as AudioStreamOggVorbis).loop = true
			var hp := AudioStreamPlayer3D.new()
			hp.name = "PortalHum"
			hp.stream = hum
			hp.bus = "SFX"
			hp.unit_size = 5.0
			hp.max_distance = 55.0
			hp.autoplay = true
			hp.position = Vector3(0, 3.4, 0)
			portal.add_child(hp)

		# Luz pulsante do portal
		var lamp := OmniLight3D.new()
		lamp.set_script(flicker_script)
		lamp.light_color = col.lerp(Color.WHITE, 0.25)
		lamp.set("base_energy", 3.2)
		lamp.set("flicker_intensity", 0.6)
		lamp.set("flicker_speed", 5.0)
		lamp.omni_range = 20.0
		lamp.position = Vector3(0, 3.6, -1.4)
		portal.add_child(lamp)

		# Título luminoso e prompt de interação
		var lbl := Label3D.new()
		lbl.text = "%s\n→ %s" % [r["title"], r["dest"]]
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.font_size = 34
		lbl.outline_size = 8
		lbl.modulate = col
		lbl.no_depth_test = false
		lbl.position = Vector3(0, 9.6, 0)
		portal.add_child(lbl)

		var prompt := Label3D.new()
		prompt.text = "[E] Abrir Mapa-Múndi"
		prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		prompt.font_size = 28
		prompt.outline_size = 8
		prompt.modulate = Color(1.0, 0.95, 0.6)
		prompt.position = Vector3(0, 2.2, -3.0)
		prompt.visible = false
		portal.add_child(prompt)
		_portal_prompts[r["id"]] = prompt

		# Bloqueio logo após o portal (limite do mapa) + gatilho de interação
		var blocker := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(8.4, 8, 1.2)
		cs.shape = bs
		blocker.add_child(cs)
		blocker.position = Vector3(0, 4, 1.8)
		portal.add_child(blocker)

		var area := Area3D.new()
		var acs := CollisionShape3D.new()
		var abs_ := BoxShape3D.new()
		abs_.size = Vector3(9, 5, 8)
		acs.shape = abs_
		area.add_child(acs)
		area.collision_layer = 0
		area.collision_mask = 1
		area.position = Vector3(0, 2.5, -2.5)
		portal.add_child(area)
		area.body_entered.connect(_on_gate_entered.bind(r))
		area.body_exited.connect(_on_gate_exited.bind(r))

		var stand := gpos - dir * 6.0
		gates.append({"id": r["id"], "loc": r["loc"], "pos": Vector2(gpos.x, gpos.z), "stand": Vector2(stand.x, stand.z),
			"title": r["title"], "dest": r["dest"], "color": col})

	# Placas de orientação nos pontos-chave
	if sign_scene:
		_place_sign(sign_scene, Vector3(4.2, 0, -11.0), -0.3, "↑ NORTE: Ellesmera\n← OESTE: Yazuac / Teirm\n↓ SUL: Urû'baen / Beor")
		_place_sign(sign_scene, Vector3(-10.5, 0, 6.0), 0.9, "← Yazuac (Nvl 21–35)\n← Helgrind (Nvl 30–40)\n← Carvahall · Espinha")
		_place_sign(sign_scene, Vector3(4.2, 0, 44.5), 0.0, "↓ Urû'baen\n↓ Farthen Dûr\n↑ Sylveria")
		var fork_a := _road_point("sul_urubaen", 0.12, 6.0)
		_place_sign(sign_scene, Vector3(fork_a.x, 0, fork_a.y), -0.5, "↘ Urû'baen (Nvl 50+)\n↙ Beor – Anões (45–50)\n↑ Sylveria")
		# Placas intermediárias com distância até o portal de cada estrada
		for r in roads:
			if not r["gate"]:
				continue
			var gp: Vector2 = Vector2.ZERO
			for g in gates:
				if g["id"] == r["id"]:
					gp = g["pos"]
			for f in [0.30, 0.62]:
				var sp := _road_point(r["id"], f, 4.6)
				var dist := int(sp.distance_to(gp))
				_place_sign(sign_scene, Vector3(sp.x, 0, sp.y), randf_range(-0.6, 0.6), "→ %s\n%s\nPortal a ~%d m" % [r["dest"], r["detail"], dist])
				_reserved.append({"pos": sp, "r": 3.0})

func _place_sign(scn: PackedScene, pos: Vector3, yaw: float, text: String) -> void:
	var s := scn.instantiate() as Node3D
	add_child(s)
	s.global_position = pos
	s.rotation.y = yaw
	var l := Label3D.new()
	l.text = text
	l.font_size = 20
	l.outline_size = 5
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(1.0, 0.9, 0.6)
	l.position = Vector3(0.6, 3.9, 0)
	s.add_child(l)

func _on_gate_entered(body: Node3D, r: Dictionary) -> void:
	if not body.is_in_group("player"):
		return
	_portal_in_range = r["id"]
	if _portal_prompts.has(r["id"]):
		(_portal_prompts[r["id"]] as Label3D).visible = true
	var now := Time.get_ticks_msec()
	if now - int(_last_notify.get(r["id"], -10000)) < 6000:
		return
	_last_notify[r["id"]] = now
	GameAudio.am(get_tree(), "play_portal_open")
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("Portal: %s → %s\n%s\nPressione [E] para abrir o Mapa-Múndi neste destino." % [r["title"], r["dest"], r["detail"]], r["color"])

func _on_gate_exited(body: Node3D, r: Dictionary) -> void:
	if not body.is_in_group("player"):
		return
	if _portal_in_range == r["id"]:
		_portal_in_range = ""
	if _portal_prompts.has(r["id"]):
		(_portal_prompts[r["id"]] as Label3D).visible = false

func _unhandled_input(event: InputEvent) -> void:
	if _portal_in_range == "":
		return
	if event.is_action_pressed("interact"):
		var loc := ""
		for g in gates:
			if g["id"] == _portal_in_range:
				loc = g["loc"]
		var hud := get_tree().get_first_node_in_group("hud")
		if hud == null:
			return
		var wm = hud.get("world_map")
		if wm:
			if wm.has_method("select_location") and loc != "":
				wm.select_location(loc)
			if not wm.visible and wm.has_method("toggle_map"):
				wm.toggle_map()
			get_viewport().set_input_as_handled()

# ------------------------------------------------------------------
# MARCOS: lanternas, pedras-guia, árvores ancestrais
# ------------------------------------------------------------------
func _build_landmarks() -> void:
	var brazier := load(BRAZIER_SCN) as PackedScene
	var monolith := load(MONOLITH_SCN) as PackedScene
	var tree_scn := load(ANCIENT_TREE_SCN) as PackedScene
	var flicker_script = load(FLICKER_SCRIPT)

	var lamps := Node3D.new()
	lamps.name = "RoadLanterns"
	add_child(lamps)

	for r in roads:
		var pts: PackedVector3Array = r["baked"]
		var step := int(18.0 / road_bake_interval)
		var side := 1.0
		var i := int(6.0 / road_bake_interval)
		var last := pts.size() - int(10.0 / road_bake_interval)
		while i < last:
			var a := pts[i]
			var b := pts[min(i + 1, pts.size() - 1)]
			var tg := b - a
			tg.y = 0
			tg = tg.normalized()
			var n := Vector3(-tg.z, 0, tg.x)
			var pos := a + n * (road_width * 0.5 + 1.3) * side
			side = -side
			pos.y = 0.0
			if brazier:
				var br := brazier.instantiate() as Node3D
				br.scale = Vector3(1.15, 1.15, 1.15)
				lamps.add_child(br)
				br.global_position = pos
			var l := OmniLight3D.new()
			l.set_script(flicker_script)
			l.light_color = Color(1.0, 0.60, 0.25)
			l.set("base_energy", 1.35)
			l.set("flicker_intensity", 0.22)
			l.omni_range = 14.0
			l.distance_fade_enabled = true
			l.distance_fade_begin = 60.0
			l.distance_fade_length = 30.0
			l.position = pos + Vector3(0, 1.6, 0)
			lamps.add_child(l)
			_reserved.append({"pos": Vector2(pos.x, pos.z), "r": 2.2})
			i += step

	# Pedras-guia (marcos rúnicos) com nome da região, duas por estrada
	var stones := Node3D.new()
	stones.name = "Waystones"
	add_child(stones)
	for r in roads:
		for f in [0.45, 0.80]:
			var sp := _road_point(r["id"], f, 6.2)
			var col: Color = r["color"]
			if monolith:
				var m := monolith.instantiate() as Node3D
				m.scale = Vector3(1.35, 1.35, 1.35)
				stones.add_child(m)
				m.global_position = Vector3(sp.x, 0, sp.y)
			var ml := OmniLight3D.new()
			ml.light_color = col
			ml.light_energy = 2.4
			ml.omni_range = 16.0
			ml.distance_fade_enabled = true
			ml.distance_fade_begin = 55.0
			ml.distance_fade_length = 25.0
			ml.position = Vector3(sp.x, 3.4, sp.y)
			stones.add_child(ml)
			var lb := Label3D.new()
			lb.text = "Marco de %s\n%s" % [r["dest"].split(" ·")[0], r["detail"]]
			lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			lb.font_size = 26
			lb.outline_size = 7
			lb.modulate = col
			lb.visibility_range_end = 70.0
			lb.position = Vector3(sp.x, 7.4, sp.y)
			stones.add_child(lb)
			_reserved.append({"pos": sp, "r": 5.5})
			waystones.append({"pos": sp, "name": r["dest"], "color": col})

	# Árvores ancestrais gigantes (pontos de interesse visíveis de longe)
	if tree_scn:
		var giants := Node3D.new()
		giants.name = "GiantTrees"
		add_child(giants)
		var spots := [Vector2(-130, -140), Vector2(150, -120), Vector2(-160, 115), Vector2(145, 160), Vector2(12, -160), Vector2(-70, 155), Vector2(170, 20), Vector2(-120, -40)]
		for sp in spots:
			var p: Vector2 = sp * (world_scale / 2.0) if world_scale < 2.0 else sp
			if _near_road(p, 9.0) or p.length() < 60.0:
				continue
			var t := tree_scn.instantiate() as Node3D
			var s := _rng.randf_range(2.1, 2.7)
			t.scale = Vector3(s, s, s)
			giants.add_child(t)
			t.global_position = Vector3(p.x, 0, p.y)
			t.rotation.y = _rng.randf() * TAU
			var gl := OmniLight3D.new()
			gl.light_color = Color(0.4, 1.0, 0.8)
			gl.light_energy = 2.0
			gl.omni_range = 26.0
			gl.distance_fade_enabled = true
			gl.distance_fade_begin = 90.0
			gl.distance_fade_length = 40.0
			gl.position = Vector3(p.x, 5.0, p.y)
			giants.add_child(gl)
			_reserved.append({"pos": p, "r": 20.0})

# ------------------------------------------------------------------
# NÓS DE COLETA
# ------------------------------------------------------------------
func _place_gathering_nodes() -> void:
	var scn := load(GATHER_SCN) as PackedScene
	if scn == null:
		return
	var root := Node3D.new()
	root.name = "WorldGatheringNodes"
	add_child(root)
	var placed := 0
	var tries := 0
	var span := half_extent - 14.0
	while placed < gathering_node_count and tries < 3000:
		tries += 1
		var p := Vector2(_rng.randf_range(-span, span), _rng.randf_range(-span, span))
		if p.length() < 45.0 or not _area_free(p, 5.0, 40.0):
			continue
		var node := scn.instantiate() as Node3D
		var biome := biome_at(p)
		if "node_type" in node:
			if biome == "north":
				node.set("node_type", 1)
				node.set("resource_name", "Erva de Menoa")
			else:
				node.set("node_type", 0)
				node.set("resource_name", "Brightsteel Bruto")
			node.set("resource_amount", _rng.randi_range(3, 6))
		root.add_child(node)
		node.global_position = Vector3(p.x, 0, p.y)
		node.rotation.y = _rng.randf() * TAU
		_reserved.append({"pos": p, "r": 6.0})
		placed += 1

# ------------------------------------------------------------------
# AMBIENTE: vaga-lumes, névoa, esporos acompanhando o jogador
# ------------------------------------------------------------------
func _spawn_ambient_fx() -> void:
	var scr = load(AMBIENT_SCRIPT)
	if scr == null:
		return
	var fx := Node3D.new()
	fx.name = "AmbientFX"
	fx.set_script(scr)
	add_child(fx)

# ------------------------------------------------------------------
# VEGETAÇÃO (MultiMesh): florestas densas fora das estradas, samambaias, cogumelos e rochas
# ------------------------------------------------------------------
func _tree_density(p: Vector2) -> float:
	match biome_at(p):
		"west": return 0.42
		"south_east": return 0.62
		"east": return 0.85
		_: return 1.0

func _shroom_density(p: Vector2) -> float:
	match biome_at(p):
		"north": return 1.0
		"start", "sanctuary": return 0.7
		_: return 0.3

func _scatter_vegetation() -> void:
	var span := half_extent - 4.0
	var trees: Array[Transform3D] = []
	var ferns: Array[Transform3D] = []
	var shrooms: Array[Transform3D] = []
	var rocks: Array[Transform3D] = []
	var tree_body := StaticBody3D.new()
	tree_body.name = "TreeColliders"
	add_child(tree_body)
	var tries := 0
	while trees.size() < tree_count and tries < tree_count * 14:
		tries += 1
		var p := Vector2(_rng.randf_range(-span, span), _rng.randf_range(-span, span))
		if _rng.randf() > _tree_density(p):
			continue
		if not _area_free(p, 8.0, 26.0):
			continue
		var s := _rng.randf_range(1.0, 1.7)
		trees.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s * _rng.randf_range(0.95, 1.25), s)), Vector3(p.x, 0, p.y)))
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = 0.55 * s
		sh.height = 3.0
		cs.shape = sh
		cs.position = Vector3(p.x, 1.5, p.y)
		tree_body.add_child(cs)
	tries = 0
	while ferns.size() < fern_count and tries < fern_count * 8:
		tries += 1
		var p := Vector2(_rng.randf_range(-span, span), _rng.randf_range(-span, span))
		if not _area_free(p, 2.6, 8.0):
			continue
		var s := _rng.randf_range(0.9, 1.7)
		ferns.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s, s)), Vector3(p.x, 0, p.y)))
	tries = 0
	while shrooms.size() < shroom_count and tries < shroom_count * 12:
		tries += 1
		var p := Vector2(_rng.randf_range(-span, span), _rng.randf_range(-span, span))
		if _rng.randf() > _shroom_density(p):
			continue
		if not _area_free(p, 3.5, 14.0):
			continue
		var s := _rng.randf_range(0.8, 1.6)
		shrooms.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s, s)), Vector3(p.x, 0, p.y)))
	tries = 0
	var rock_body := StaticBody3D.new()
	rock_body.name = "RockColliders"
	add_child(rock_body)
	while rocks.size() < rock_count and tries < rock_count * 10:
		tries += 1
		var p := Vector2(_rng.randf_range(-span, span), _rng.randf_range(-span, span))
		var b := biome_at(p)
		var wasteland := b == "west" or b == "south_east"
		# Terras devastadas e domínio imperial concentram mais (e maiores) rochedos
		if not wasteland and _rng.randf() > 0.5:
			continue
		if not _area_free(p, 5.0, 24.0):
			continue
		var s := _rng.randf_range(0.9, 2.2)
		if wasteland:
			s *= 1.35
		rocks.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s * _rng.randf_range(0.8, 1.2), s)), Vector3(p.x, 0, p.y)))
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = 1.4 * s
		sh.height = 2.0
		cs.shape = sh
		cs.position = Vector3(p.x, 1.0, p.y)
		rock_body.add_child(cs)
	print("[MapBuilder] mapa %dx%d m | árvores=%d samambaias=%d cogumelos=%d rochas=%d estradas=%d" % [int(half_extent * 2), int(half_extent * 2), trees.size(), ferns.size(), shrooms.size(), rocks.size(), _road_samples.size()])
	_spawn_multimesh(_collect_meshes(TREE_SCN), trees, "Forest", 100.0)
	_spawn_multimesh(_collect_meshes(FERN_SCN), ferns, "Ferns", 55.0)
	_spawn_multimesh(_collect_meshes(SHROOM_SCN), shrooms, "Shrooms", 70.0)
	_spawn_multimesh(_collect_meshes(ROCK_SCN), rocks, "Boulders", 95.0)

func river_z_at_x(x: float) -> float:
	var damping := 1.0 - exp(-absf(x) * 0.06)
	return 22.0 + (6.5 * sin(x * 0.016) + 2.5 * sin(x * 0.042)) * damping

func is_near_river(p: Vector2, margin: float = 7.5) -> bool:
	return absf(p.y - river_z_at_x(p.x)) < margin

## Livre de estradas, da praça, do rio e da zona dos mobs iniciais.
func _area_free(p: Vector2, road_margin: float, plaza_radius: float) -> bool:
	if p.length() < plaza_radius:
		return false
	if is_near_river(p, 7.8):  # leito meandrado do rio e margens
		return false
	if p.distance_to(Vector2(0, 34)) < 13.0:  # acampamento Urgal na margem sul
		return false
	for g in gates:
		if p.distance_to(g["pos"]) < 11.0:
			return false
	for rz in _reserved:
		if p.distance_to(rz["pos"]) < rz["r"]:
			return false
	return not _near_road(p, road_margin)

# ------------------------------------------------------------------
# UTILITÁRIOS
# ------------------------------------------------------------------
func _collect_meshes(path: String) -> Array:
	var out: Array = []
	var scn := load(path) as PackedScene
	if not scn:
		return out
	var inst := scn.instantiate()
	_walk(inst, Transform3D.IDENTITY, out, true)
	inst.free()
	return out

var _tree_foliage_mat: ShaderMaterial
var _tree_bark_mat: ShaderMaterial

func _get_tree_foliage_material() -> ShaderMaterial:
	if not _tree_foliage_mat:
		var sh := load(TREE_FOLIAGE_SHADER) as Shader
		if sh:
			_tree_foliage_mat = ShaderMaterial.new()
			_tree_foliage_mat.shader = sh
	return _tree_foliage_mat

func _get_tree_bark_material() -> ShaderMaterial:
	if not _tree_bark_mat:
		var sh := load(TREE_BARK_SHADER) as Shader
		if sh:
			_tree_bark_mat = ShaderMaterial.new()
			_tree_bark_mat.shader = sh
	return _tree_bark_mat

func _walk(node: Node, xf: Transform3D, out: Array, is_root: bool) -> void:
	var cur := xf
	if node is Node3D and not is_root:
		cur = xf * (node as Node3D).transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh:
		out.append({"mesh": (node as MeshInstance3D).mesh, "xf": cur, "name": node.name})
	for c in node.get_children():
		_walk(c, cur, out, false)

func _spawn_multimesh(meshes: Array, placements: Array, node_name: String, vis_end: float) -> void:
	if placements.is_empty():
		return
	for i in meshes.size():
		var entry: Dictionary = meshes[i]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = entry["mesh"]
		mm.instance_count = placements.size()
		for j in placements.size():
			mm.set_instance_transform(j, (placements[j] as Transform3D) * (entry["xf"] as Transform3D))
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "%s_%d" % [node_name, i]
		mmi.multimesh = mm
		mmi.visibility_range_end = vis_end
		mmi.visibility_range_end_margin = 12.0
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF

		# Aplicar Shaders Procedurais PBR e Oclusão de Visão (See-Through)
		if node_name == "Forest":
			var ename: String = str(entry.get("name", "")).to_lower()
			if ename.contains("canopy") or ename.contains("foliage") or ename.contains("leaf"):
				var f_mat = _get_tree_foliage_material()
				if f_mat:
					mmi.material_override = f_mat
			elif ename.contains("trunk") or ename.contains("bark"):
				var b_mat = _get_tree_bark_material()
				if b_mat:
					mmi.material_override = b_mat

		add_child(mmi)

# ------------------------------------------------------------------
# MOBS & BOSSES
# ------------------------------------------------------------------
func _road_point(road_id: String, frac: float, side: float) -> Vector2:
	for r in roads:
		if r["id"] == road_id:
			var pts: PackedVector3Array = r["baked"]
			var i := int(clamp(frac, 0.0, 1.0) * (pts.size() - 1))
			var a := pts[i]
			var b := pts[min(i + 1, pts.size() - 1)]
			var tg := b - a
			tg.y = 0
			if tg.length() < 0.01:
				tg = Vector3(0, 0, 1)
			tg = tg.normalized()
			var n := Vector3(-tg.z, 0, tg.x)
			return Vector2(a.x + n.x * side, a.z + n.z * side)
	return Vector2.ZERO

## Acampamentos extras espalhados pelas áreas abertas, com mobs conforme o bioma do ponto.
func _generate_procedural_camps() -> void:
	var pools := {
		"start": ["boar", "wolf"],
		"north": ["golem", "fanghur"],
		"west": ["urgal_raider", "kull_young"],
		"south_east": ["oathsworn", "oathsworn"],
		"south_west": ["shade_scout", "shade_scout"],
		"east": ["wolf", "golem"],
	}
	var minis := {
		"start": "wolf_alpha", "north": "stone_guardian", "west": "gromk",
		"south_east": "oathsworn_knight", "south_west": "", "east": "",
	}
	var chosen: Array[Vector2] = []
	for c in camps:
		if c.has("pos"):
			chosen.append(c["pos"])
		elif c.has("road"):
			chosen.append(_road_point(c["road"], c["f"], c["side"]))
	var gate_pts: Array[Vector2] = []
	for g in gates:
		gate_pts.append(g["pos"])
	var span := half_extent - 16.0
	var made := 0
	var tries := 0
	while made < proc_camp_count and tries < proc_camp_count * 80:
		tries += 1
		var p := Vector2(_rng.randf_range(-span, span), _rng.randf_range(-span, span))
		if p.length() < 56.0:
			continue
		if is_near_river(p, 12.0):
			continue
		if _near_road(p, 6.0):
			continue
		var too_close := false
		for q in chosen:
			if p.distance_to(q) < 26.0:
				too_close = true
				break
		if too_close:
			continue
		for g in gate_pts:
			if p.distance_to(g) < 30.0:
				too_close = true
				break
		if too_close:
			continue
		var b := biome_at(p)
		if not pools.has(b):
			continue
		var mob: String = pools[b][_rng.randi() % 2]
		var count := _rng.randi_range(2, 4)
		var mini_mob: String = minis.get(b, "")
		if mini_mob != "" and _rng.randf() < 0.08:
			# Garantir que minibosses procedurais mantenham distância segura (>= 55m) de outros acampamentos
			var boss_far := true
			for q in chosen:
				if p.distance_to(q) < 55.0:
					boss_far = false
					break
			if boss_far:
				mob = mini_mob
				count = 1
		camps.append({"pos": p, "mob": mob, "n": count})
		chosen.append(p)
		made += 1

func _spawn_mobs() -> void:
	var arch_db := MobsDatabase.get_all()
	for c in camps:
		var center: Vector2
		if c.has("road"):
			center = _road_point(c["road"], c["f"], c["side"])
		else:
			center = c["pos"]
		var arch: Dictionary = arch_db[c["mob"]]
		var is_boss: bool = arch["kind"] != "mob"
		_reserved.append({"pos": center, "r": 10.0 if is_boss else 7.0})
		var count: int = int(c["n"])
		if not is_boss:
			count *= 3 # Multiplica em 3x a densidade de mobs normais no mapa
		var mob_list: Array = []
		for i in count:
			var off := Vector2.ZERO if is_boss else Vector2(_rng.randf_range(-5.0, 5.0), _rng.randf_range(-5.0, 5.0))
			var m = _spawn_one(c["mob"], center + off)
			if m:
				mob_list.append(m)
				# Se o acampamento inicial estiver a mais de 75m da praça central (0,0), inicia em dormência (0 CPU/GPU)
				if not is_boss and center.length_squared() > 75.0 * 75.0 and m.has_method("set_dormant"):
					m.set_dormant(true)
		c["spawned_mobs"] = mob_list
		if is_boss:
			boss_markers.append({"pos": center, "name": arch["name"], "kind": arch["kind"]})
			_place_boss_arena(center, arch)

func _spawn_one(arch_id: String, pos: Vector2) -> CharacterBody3D:
	# Garantir que nenhum mob spawne dentro da Safe Zone do Santuário de Sylveria (R < 36m)
	if pos.length() < 36.0:
		pos = pos.normalized() * 38.0
	var max_extent := half_extent - 12.0
	pos.x = clampf(pos.x, -max_extent, max_extent)
	pos.y = clampf(pos.y, -max_extent, max_extent)

	var scn := load(ENEMY_SCN) as PackedScene
	if scn == null:
		return null
	var arch: Dictionary = MobsDatabase.get_all()[arch_id]
	var lvl := _rng.randi_range(arch["lvl"][0], arch["lvl"][1])
	var mob := scn.instantiate() as CharacterBody3D
	mob.position = Vector3(pos.x, 0.05, pos.y)
	mob.name = "%s_%d" % [arch_id, get_child_count()]
	add_child(mob)
	mob.call("configure", arch_id, lvl)
	mob.connect("enemy_died", _on_mob_died.bind(arch_id, pos))
	return mob

func _on_mob_died(_n: String, _xp: int, _g: int, arch_id: String, pos: Vector2) -> void:
	var kind: String = MobsDatabase.get_all()[arch_id]["kind"]
	var wait := 45.0 if kind == "mob" else (150.0 if kind == "mini_boss" else 300.0)
	await get_tree().create_timer(wait).timeout
	if is_inside_tree():
		var new_m := _spawn_one(arch_id, pos)
		if new_m and _player and is_instance_valid(_player):
			var dist_sq := Vector2(_player.global_position.x, _player.global_position.z).distance_squared_to(pos)
			if dist_sq > 75.0 * 75.0 and new_m.has_method("set_dormant"):
				new_m.set_dormant(true)

## Arenas Temáticas de Bosses (Caldeira Vulcânica, Templo Abandonado, Pântano Tóxico e Cripta Glacial)
func _place_boss_arena(center: Vector2, arch: Dictionary) -> void:
	var b := biome_at(center)
	var kind: String = arch.get("kind", "mini_boss")
	var is_world: bool = kind == "world_boss"
	var radius: float = 14.0 if is_world else 10.0
	var arena_root := Node3D.new()
	arena_root.name = "BossArena_%s" % arch.get("name", "Boss").replace(" ", "_").replace("'", "_")
	add_child(arena_root)

	var arena_type := "temple"
	var arena_col := Color(0.25, 0.95, 0.75)

	var aname: String = arch.get("name", "").to_lower()
	if b == "west" or aname.contains("kull") or aname.contains("garzhvog") or aname.contains("gromk") or aname.contains("urgal"):
		arena_type = "lava"
		arena_col = Color(1.0, 0.38, 0.12)
	elif b == "south_east" or aname.contains("ra'zac") or aname.contains("juramentado"):
		arena_type = "swamp"
		arena_col = Color(0.32, 0.92, 0.22)
	elif b == "south_west" or aname.contains("safira") or aname.contains("tumba"):
		arena_type = "ice"
		arena_col = Color(0.35, 0.78, 1.0)
	else:
		arena_type = "temple"
		arena_col = Color(0.45, 0.92, 0.85)

	# 1. Piso Temático Procedural da Arena com Shaders PBR e Fade Radial Suave
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(radius * 2.5, radius * 2.5)
	floor_mesh.subdivide_width = 8
	floor_mesh.subdivide_depth = 8
	var floor_inst := MeshInstance3D.new()
	floor_inst.mesh = floor_mesh
	floor_inst.position = Vector3(center.x, 0.045, center.y)

	var floor_shader_path := ""
	match arena_type:
		"lava":
			floor_shader_path = LAVA_SHADER
		"swamp":
			floor_shader_path = SWAMP_SHADER
		"ice":
			floor_shader_path = ICE_SHADER
		"temple":
			floor_shader_path = TEMPLE_SHADER

	if floor_shader_path != "":
		var sh := load(floor_shader_path) as Shader
		if sh:
			var s_mat := ShaderMaterial.new()
			s_mat.shader = sh
			floor_inst.material_override = s_mat
	arena_root.add_child(floor_inst)

	# 2. Iluminação Atmosférica Suave e Equilibrada da Arena (Dark Fantasy)
	var light := OmniLight3D.new()
	light.light_color = arena_col
	light.light_energy = 1.35 if is_world else 0.90
	light.omni_range = radius * 1.6
	light.position = Vector3(center.x, 3.2, center.y)
	arena_root.add_child(light)
