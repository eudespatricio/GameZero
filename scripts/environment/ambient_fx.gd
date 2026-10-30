extends Node3D
class_name AmbientFX
## Efeitos atmosféricos que acompanham o jogador pelo mapa grande: vaga-lumes, névoa rasteira e esporos.
## As partículas ficam no mundo (local_coords = false) enquanto o emissor segue o herói, criando a sensação
## de uma floresta viva em qualquer ponto do mapa sem custo de partículas fora da área visível.

var _player: Node3D
var _spores: Node3D

func _ready() -> void:
	_add_fireflies()
	_add_mist()
	_add_pollen()

func _make_emitter(amount: int, lifetime: float, box: Vector3, y: float, mat_extra: Callable, additive: bool, quad: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.preprocess = lifetime
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-box.x, -6, -box.z), Vector3(box.x * 2.0, 26, box.z * 2.0))
	if not additive:
		p.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box
	mat_extra.call(pm)
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(quad, quad)
	q.material = CombatVFX._billboard_material(additive)
	p.draw_pass_1 = q
	p.position = Vector3(0, y, 0)
	add_child(p)
	return p

func _add_fireflies() -> void:
	_make_emitter(50, 9.0, Vector3(38, 4.5, 38), 3.5, _cfg_fireflies, true, 1.0)

func _cfg_fireflies(pm: ParticleProcessMaterial) -> void:
		pm.direction = Vector3(0.3, 0.2, 0.1)
		pm.spread = 180.0
		pm.initial_velocity_min = 0.15
		pm.initial_velocity_max = 0.7
		pm.gravity = Vector3.ZERO
		pm.turbulence_enabled = false
		pm.scale_min = 0.16
		pm.scale_max = 0.34
		pm.color_ramp = CombatVFX._ramp([
			[0.0, Color(0.7, 1.0, 0.5, 0.0)],
			[0.12, Color(0.75, 1.0, 0.55, 0.95)],
			[0.30, Color(0.4, 0.9, 0.7, 0.25)],
			[0.45, Color(0.85, 1.0, 0.6, 1.0)],
			[0.65, Color(0.4, 0.9, 0.7, 0.2)],
			[0.82, Color(0.8, 1.0, 0.55, 0.9)],
			[1.0, Color(0.5, 1.0, 0.6, 0.0)]])

func _add_mist() -> void:
	_make_emitter(18, 14.0, Vector3(44, 0.8, 44), 0.9, _cfg_mist, false, 1.0)

func _cfg_mist(pm: ParticleProcessMaterial) -> void:
		pm.direction = Vector3(1, 0, 0.3)
		pm.spread = 25.0
		pm.initial_velocity_min = 0.25
		pm.initial_velocity_max = 0.7
		pm.gravity = Vector3.ZERO
		pm.scale_min = 7.0
		pm.scale_max = 13.0
		pm.color_ramp = CombatVFX._ramp([
			[0.0, Color(0.55, 0.75, 0.85, 0.0)],
			[0.25, Color(0.55, 0.75, 0.85, 0.075)],
			[0.75, Color(0.5, 0.7, 0.8, 0.075)],
			[1.0, Color(0.5, 0.7, 0.8, 0.0)]])

func _add_pollen() -> void:
	_make_emitter(30, 10.0, Vector3(30, 5.0, 30), 6.0, _cfg_pollen, true, 1.0)

func _cfg_pollen(pm: ParticleProcessMaterial) -> void:
		pm.direction = Vector3(0.4, -0.2, 0.2)
		pm.spread = 40.0
		pm.initial_velocity_min = 0.3
		pm.initial_velocity_max = 0.9
		pm.gravity = Vector3(0.0, -0.15, 0.0)
		pm.turbulence_enabled = false
		pm.scale_min = 0.05
		pm.scale_max = 0.11
		pm.color_ramp = CombatVFX._ramp([
			[0.0, Color(1.0, 0.95, 0.7, 0.0)],
			[0.2, Color(1.0, 0.95, 0.75, 0.7)],
			[0.8, Color(0.9, 1.0, 0.8, 0.6)],
			[1.0, Color(0.9, 1.0, 0.8, 0.0)]])

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
		return
	global_position = Vector3(_player.global_position.x, 0.0, _player.global_position.z)
	# Esporos mágicos do mapa passam a seguir o herói também
	if _spores == null or not is_instance_valid(_spores):
		var scene := get_tree().current_scene
		if scene:
			_spores = scene.get_node_or_null("MagicSpores") as Node3D
			if _spores is GPUParticles3D:
				(_spores as GPUParticles3D).local_coords = false
				(_spores as GPUParticles3D).visibility_aabb = AABB(Vector3(-60, -10, -60), Vector3(120, 40, 120))
	if _spores:
		_spores.global_position = Vector3(_player.global_position.x, 3.5, _player.global_position.z)
