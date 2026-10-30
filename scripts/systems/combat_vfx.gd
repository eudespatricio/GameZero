extends RefCounted
class_name CombatVFX

## Biblioteca de efeitos de combate e magia (partículas aditivas, shaders procedurais, luz dinâmica).
## Todos os efeitos são auto-limpantes: cada nó criado se destrói ao final da animação.

const SHOCKWAVE_SHADER := "res://assets/shaders/magic_ring.gdshader"
const VORTEX_SHADER := "res://assets/shaders/magic_vortex.gdshader"
const SLASH_SHADER := "res://assets/shaders/slash_arc.gdshader"

static var _soft_tex: Texture2D

# ------------------------------------------------------------------
# UTILITÁRIOS INTERNOS
# ------------------------------------------------------------------

## Textura radial suave (halo) usada por todas as partículas billboard.
static func soft_texture() -> Texture2D:
	if _soft_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.30, Color(1, 1, 1, 0.55))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 128
		t.height = 128
		_soft_tex = t
	return _soft_tex

static func _billboard_material(additive: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = soft_texture()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.disable_receive_shadows = true
	return m

static func _ramp(stops: Array) -> GradientTexture1D:
	## stops: [[offset, Color], ...]
	var g := Gradient.new()
	g.set_color(0, stops[0][1])
	g.set_offset(0, stops[0][0])
	g.set_color(1, stops[stops.size() - 1][1])
	g.set_offset(1, stops[stops.size() - 1][0])
	for i in range(1, stops.size() - 1):
		g.add_point(stops[i][0], stops[i][1])
	var t := GradientTexture1D.new()
	t.gradient = g
	return t

static func _shrink_curve(start: float = 1.0, mid: float = 0.9, end: float = 0.0) -> CurveTexture:
	var c := Curve.new()
	c.add_point(Vector2(0.0, start))
	c.add_point(Vector2(0.35, mid))
	c.add_point(Vector2(1.0, end))
	var ct := CurveTexture.new()
	ct.curve = c
	return ct

## Cria um emissor GPUParticles3D com quad billboard e o adiciona à cena atual.
static func _emitter(tree: SceneTree, pos: Vector3, mat: ParticleProcessMaterial, amount: int, lifetime: float,
		quad_size: float = 1.0, additive: bool = true, one_shot: bool = true, explosiveness: float = 0.0) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.top_level = true
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = one_shot
	p.explosiveness = explosiveness
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-14, -4, -14), Vector3(28, 14, 28))
	p.process_material = mat
	if not additive:
		p.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	var q := QuadMesh.new()
	q.size = Vector2(quad_size, quad_size)
	q.material = _billboard_material(additive)
	p.draw_pass_1 = q
	tree.current_scene.add_child(p)
	p.global_position = pos
	p.emitting = true
	if one_shot:
		_free_later(tree, p, lifetime + 0.5)
	return p

static func _free_later(tree: SceneTree, node: Node, seconds: float) -> void:
	tree.create_timer(seconds).timeout.connect(func():
		if is_instance_valid(node):
			node.queue_free()
	)

static func _flash_light(tree: SceneTree, pos: Vector3, col: Color, energy: float, rng: float, dur: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.top_level = true
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	l.shadow_enabled = false
	tree.current_scene.add_child(l)
	l.global_position = pos
	var tw := tree.create_tween()
	tw.tween_property(l, "light_energy", 0.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(l.queue_free)
	return l

static func _shader_plane(size: float, shader_path: String) -> Array:
	## Retorna [MeshInstance3D, ShaderMaterial]
	var mi := MeshInstance3D.new()
	mi.top_level = true
	var pm := PlaneMesh.new()
	pm.size = Vector2(size, size)
	var mat := ShaderMaterial.new()
	mat.shader = load(shader_path) as Shader
	pm.material = mat
	mi.mesh = pm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return [mi, mat]

# ------------------------------------------------------------------
# FEEL: HIT STOP, SHAKE
# ------------------------------------------------------------------

## Executa Hit Stop (micro-congelamento temporal de impacto físico no estilo Diablo IV)
static func trigger_hit_stop(tree: SceneTree, duration_sec: float = 0.045) -> void:
	if not tree: return
	Engine.time_scale = 0.05
	var timer = tree.create_timer(duration_sec * 0.05, true, false, true) # ignore time scale
	timer.timeout.connect(func():
		Engine.time_scale = 1.0
	)

## Aciona tremor de tela através da câmera isométrica
static func trigger_screen_shake(tree: SceneTree, intensity: float = 0.35) -> void:
	if not tree: return
	var cam = tree.get_first_node_in_group("camera")
	if cam and cam.has_method("add_shake"):
		cam.add_shake(intensity)

# ------------------------------------------------------------------
# IMPACTOS
# ------------------------------------------------------------------

## Faíscas incandescentes + clarão de impacto no ponto atingido.
static func spawn_hit_sparks(tree: SceneTree, hit_pos: Vector3, is_crit: bool = false) -> void:
	if not tree or not tree.current_scene: return
	var origin := hit_pos + Vector3(0, 0.9, 0)

	# Faíscas rápidas com gravidade
	var sm := ParticleProcessMaterial.new()
	sm.direction = Vector3(0, 1, 0)
	sm.spread = 75.0
	sm.initial_velocity_min = 5.0 if not is_crit else 9.0
	sm.initial_velocity_max = 9.5 if not is_crit else 15.0
	sm.gravity = Vector3(0, -20.0, 0)
	sm.damping_min = 1.0
	sm.damping_max = 3.0
	sm.scale_min = 0.10
	sm.scale_max = 0.22 if not is_crit else 0.36
	sm.scale_curve = _shrink_curve(1.0, 0.8, 0.0)
	if is_crit:
		sm.color_ramp = _ramp([[0.0, Color(1.0, 0.95, 0.45, 1.0)], [0.4, Color(1.0, 0.5, 0.12, 1.0)], [1.0, Color(0.7, 0.1, 0.05, 0.0)]])
	else:
		sm.color_ramp = _ramp([[0.0, Color(0.6, 0.95, 1.0, 1.0)], [0.4, Color(1.0, 0.65, 0.25, 0.95)], [1.0, Color(0.5, 0.2, 0.1, 0.0)]])
	_emitter(tree, origin, sm, 26 if is_crit else 16, 0.45, 1.0, true, true, 0.97)

	# Clarão central
	var fm := ParticleProcessMaterial.new()
	fm.initial_velocity_min = 0.0
	fm.initial_velocity_max = 0.2
	fm.gravity = Vector3.ZERO
	fm.scale_min = 1.3 if not is_crit else 2.4
	fm.scale_max = fm.scale_min
	fm.scale_curve = _shrink_curve(0.6, 1.0, 0.0)
	fm.color_ramp = _ramp([[0.0, Color(1, 1, 1, 1)], [1.0, Color(1.0, 0.7, 0.3, 0.0)]])
	_emitter(tree, origin, fm, 1, 0.16, 1.0, true, true, 1.0)

	_flash_light(tree, origin, Color(1.0, 0.8, 0.5) if not is_crit else Color(1.0, 0.65, 0.2), 3.0 if not is_crit else 5.5, 5.0, 0.18)

## Rastro fantasma luminoso do Dash.
static func spawn_dash_ghost(tree: SceneTree, pos: Vector3, rot_y: float) -> void:
	if not tree or not tree.current_scene: return

	var ghost = MeshInstance3D.new()
	ghost.top_level = true
	ghost.position = pos + Vector3(0, 0.95, 0)
	ghost.rotation.y = rot_y

	var cmesh = CapsuleMesh.new()
	cmesh.radius = 0.36
	cmesh.height = 1.85
	ghost.mesh = cmesh

	var mat = StandardMaterial3D.new()
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.25, 0.85, 1.0, 0.55)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.7, 1.0)
	mat.emission_energy_multiplier = 1.5
	ghost.material_override = mat
	ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tree.current_scene.add_child(ghost)

	var tween = tree.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.32)
	tween.tween_property(ghost, "scale", Vector3(0.7, 1.05, 1.35), 0.32)
	tween.chain().tween_callback(func():
		if is_instance_valid(ghost):
			ghost.queue_free()
	)

	# Faíscas do rastro
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0.4, 0)
	pm.spread = 80.0
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 2.5
	pm.gravity = Vector3(0, 0.5, 0)
	pm.scale_min = 0.25
	pm.scale_max = 0.5
	pm.scale_curve = _shrink_curve(1.0, 0.7, 0.0)
	pm.color_ramp = _ramp([[0.0, Color(0.7, 0.98, 1.0, 0.9)], [1.0, Color(0.1, 0.4, 1.0, 0.0)]])
	_emitter(tree, pos + Vector3(0, 0.9, 0), pm, 10, 0.4, 1.0, true, true, 0.8)

## Nuvem de poeira (pouso, dash, derrapagem, impactos).
static func spawn_dust_puff(tree: SceneTree, pos: Vector3, amount: int = 10, spread_radius: float = 0.5, tint: Color = Color(0.55, 0.50, 0.40, 0.55)) -> void:
	if not tree or not tree.current_scene: return
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = spread_radius
	pm.direction = Vector3(0, 0.6, 0)
	pm.spread = 90.0
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 2.4
	pm.gravity = Vector3(0, 0.3, 0)
	pm.damping_min = 1.5
	pm.damping_max = 3.0
	pm.scale_min = 0.9
	pm.scale_max = 1.8
	var c := Curve.new()
	c.add_point(Vector2(0.0, 0.3))
	c.add_point(Vector2(0.6, 1.0))
	c.add_point(Vector2(1.0, 1.2))
	var ct := CurveTexture.new()
	ct.curve = c
	pm.scale_curve = ct
	pm.color_ramp = _ramp([[0.0, Color(tint.r, tint.g, tint.b, 0.0)], [0.15, tint], [1.0, Color(tint.r, tint.g, tint.b, 0.0)]])
	_emitter(tree, pos + Vector3(0, 0.1, 0), pm, amount, 0.75, 1.0, false, true, 0.9)

# ------------------------------------------------------------------
# ARCO DE LÂMINA
# ------------------------------------------------------------------

## Arco de corte luminoso girando à frente do herói.
static func spawn_slash_arc(tree: SceneTree, pos: Vector3, dir: Vector3, col: Color = Color(0.3, 0.85, 1.0), size: float = 6.5, duration: float = 0.26, half_angle: float = 1.45) -> void:
	if not tree or not tree.current_scene: return
	var d := dir
	d.y = 0.0
	if d.length() < 0.01:
		d = Vector3(0, 0, -1)
	d = d.normalized()
	var pr := _shader_plane(size, SLASH_SHADER)
	var mi: MeshInstance3D = pr[0]
	var mat: ShaderMaterial = pr[1]
	mat.set_shader_parameter("color", col)
	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("arc_half_angle", half_angle)
	tree.current_scene.add_child(mi)
	mi.global_position = pos + Vector3(0, 1.0, 0)
	mi.rotation.y = atan2(-d.x, -d.z)
	var tw := tree.create_tween()
	tw.tween_method(func(v: float): mat.set_shader_parameter("progress", v), 0.0, 1.0, duration)
	tw.tween_callback(func():
		if is_instance_valid(mi):
			mi.queue_free()
	)

## Brilho de canalização convergindo para as mãos do conjurador.
static func spawn_cast_charge(tree: SceneTree, pos: Vector3, col: Color = Color(0.3, 0.85, 1.0), duration: float = 0.35) -> void:
	if not tree or not tree.current_scene: return
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE_SURFACE
	pm.emission_sphere_radius = 1.4
	pm.gravity = Vector3.ZERO
	pm.radial_accel_min = -9.0
	pm.radial_accel_max = -14.0
	pm.damping_min = 0.5
	pm.damping_max = 1.0
	pm.scale_min = 0.25
	pm.scale_max = 0.55
	pm.scale_curve = _shrink_curve(0.4, 1.0, 0.0)
	pm.color_ramp = _ramp([[0.0, Color(col.r, col.g, col.b, 0.0)], [0.3, Color(1, 1, 1, 0.9)], [1.0, Color(col.r, col.g, col.b, 0.0)]])
	_emitter(tree, pos + Vector3(0, 1.2, 0), pm, 28, duration, 1.0, true, true, 0.5)
	_flash_light(tree, pos + Vector3(0, 1.3, 0), col, 2.2, 5.5, duration + 0.1)

# ------------------------------------------------------------------
# MAGIAS
# ------------------------------------------------------------------

## [1] Brisingr: rajada de chamas azuis místicas com arco de lâmina, brasas e clarão.
static func spawn_spell_flame(tree: SceneTree, start_pos: Vector3, dir: Vector3) -> void:
	if not tree or not tree.current_scene: return
	var d := dir
	d.y = 0.0
	if d.length() < 0.01:
		d = Vector3(0, 0, -1)
	d = d.normalized()
	var origin := start_pos + Vector3(0, 0.95, 0) + d * 0.6

	# Núcleo das chamas
	var fm := ParticleProcessMaterial.new()
	fm.direction = d
	fm.spread = 20.0
	fm.initial_velocity_min = 14.0
	fm.initial_velocity_max = 24.0
	fm.gravity = Vector3(0, 3.0, 0)
	fm.damping_min = 1.0
	fm.damping_max = 3.0
	fm.scale_min = 0.6
	fm.scale_max = 1.25
	fm.scale_curve = _shrink_curve(0.5, 1.0, 0.1)
	fm.color_ramp = _ramp([[0.0, Color(0.9, 1, 1, 0.5)], [0.2, Color(0.45, 0.85, 1.0, 0.42)], [0.55, Color(0.12, 0.4, 1.0, 0.30)], [1.0, Color(0.05, 0.1, 0.6, 0.0)]])
	_emitter(tree, origin, fm, 70, 0.6, 1.0, true, true, 0.5)

	# Brasas azuis
	var em := ParticleProcessMaterial.new()
	em.direction = d + Vector3(0, 0.2, 0)
	em.spread = 42.0
	em.initial_velocity_min = 6.0
	em.initial_velocity_max = 15.0
	em.gravity = Vector3(0, -3.0, 0)
	em.scale_min = 0.12
	em.scale_max = 0.28
	em.scale_curve = _shrink_curve(1.0, 0.8, 0.0)
	em.color_ramp = _ramp([[0.0, Color(0.8, 1.0, 1.0, 1.0)], [0.6, Color(0.3, 0.7, 1.0, 0.9)], [1.0, Color(0.1, 0.2, 0.9, 0.0)]])
	_emitter(tree, origin, em, 46, 0.95, 1.0, true, true, 0.7)

	# Fumaça azulada leve
	var sm := ParticleProcessMaterial.new()
	sm.direction = d + Vector3(0, 0.3, 0)
	sm.spread = 30.0
	sm.initial_velocity_min = 2.0
	sm.initial_velocity_max = 6.0
	sm.gravity = Vector3(0, 0.8, 0)
	sm.damping_min = 1.0
	sm.damping_max = 2.5
	sm.scale_min = 1.2
	sm.scale_max = 2.2
	sm.color_ramp = _ramp([[0.0, Color(0.1, 0.25, 0.5, 0.0)], [0.2, Color(0.12, 0.3, 0.55, 0.28)], [1.0, Color(0.03, 0.06, 0.15, 0.0)]])
	_emitter(tree, origin + d * 1.5, sm, 16, 1.0, 1.0, false, true, 0.6)

	spawn_slash_arc(tree, start_pos, d, Color(0.35, 0.9, 1.0), 8.0, 0.24, 1.4)

	# Luz: clarão na origem + pulso projetado à frente
	_flash_light(tree, origin, Color(0.45, 0.9, 1.0), 4.2, 9.0, 0.5)
	var front := _flash_light(tree, origin + d * 4.5, Color(0.2, 0.55, 1.0), 3.0, 10.0, 0.6)
	var tl := tree.create_tween()
	tl.tween_property(front, "global_position", origin + d * 8.0, 0.4)

## [2] Jierda: onda de choque sísmica, rachaduras, detritos e poeira.
static func spawn_shockwave_ring(tree: SceneTree, center_pos: Vector3, radius: float = 6.0, col: Color = Color(0.3, 0.95, 0.6)) -> void:
	if not tree or not tree.current_scene: return
	var pos := center_pos + Vector3(0, 0.1, 0)

	# Anel principal (shader)
	var pr := _shader_plane(radius * 2.25, SHOCKWAVE_SHADER)
	var mi: MeshInstance3D = pr[0]
	var mat: ShaderMaterial = pr[1]
	mat.set_shader_parameter("color", col)
	mat.set_shader_parameter("progress", 0.0)
	tree.current_scene.add_child(mi)
	mi.global_position = pos
	var tw := tree.create_tween()
	tw.tween_method(func(v: float): mat.set_shader_parameter("progress", v), 0.0, 1.0, 0.75)
	tw.tween_callback(func():
		if is_instance_valid(mi):
			mi.queue_free()
	)

	# Segundo anel menor, atrasado (eco)
	var pr2 := _shader_plane(radius * 1.6, SHOCKWAVE_SHADER)
	var mi2: MeshInstance3D = pr2[0]
	var mat2: ShaderMaterial = pr2[1]
	mat2.set_shader_parameter("color", Color(1.0, 1.0, 1.0).lerp(col, 0.4))
	mat2.set_shader_parameter("progress", 0.0)
	mat2.set_shader_parameter("cracks", 0.0)
	tree.current_scene.add_child(mi2)
	mi2.global_position = pos + Vector3(0, 0.02, 0)
	var tw2 := tree.create_tween()
	tw2.tween_interval(0.07)
	tw2.tween_method(func(v: float): mat2.set_shader_parameter("progress", v), 0.0, 1.0, 0.55)
	tw2.tween_callback(func():
		if is_instance_valid(mi2):
			mi2.queue_free()
	)

	# Poeira em anel expansivo
	var dm := ParticleProcessMaterial.new()
	dm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	dm.emission_ring_axis = Vector3(0, 1, 0)
	dm.emission_ring_radius = 1.2
	dm.emission_ring_inner_radius = 0.6
	dm.emission_ring_height = 0.2
	dm.direction = Vector3(0, 0.15, 0)
	dm.spread = 15.0
	dm.initial_velocity_min = 0.0
	dm.initial_velocity_max = 0.5
	dm.radial_accel_min = radius * 2.6
	dm.radial_accel_max = radius * 3.4
	dm.damping_min = radius * 1.2
	dm.damping_max = radius * 1.8
	dm.gravity = Vector3(0, 0.4, 0)
	dm.scale_min = 1.3
	dm.scale_max = 2.4
	dm.color_ramp = _ramp([[0.0, Color(0.5, 0.45, 0.35, 0.0)], [0.12, Color(0.5, 0.46, 0.36, 0.5)], [1.0, Color(0.35, 0.32, 0.26, 0.0)]])
	_emitter(tree, pos, dm, 36, 0.9, 1.0, false, true, 0.9)

	# Detritos de rocha (malha 3D, afetada por gravidade)
	var rock := ParticleProcessMaterial.new()
	rock.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	rock.emission_ring_axis = Vector3(0, 1, 0)
	rock.emission_ring_radius = radius * 0.5
	rock.emission_ring_inner_radius = radius * 0.2
	rock.emission_ring_height = 0.1
	rock.direction = Vector3(0, 1, 0)
	rock.spread = 35.0
	rock.initial_velocity_min = 5.0
	rock.initial_velocity_max = 10.5
	rock.gravity = Vector3(0, -26.0, 0)
	rock.scale_min = 0.5
	rock.scale_max = 1.4
	rock.angle_min = 0.0
	rock.angle_max = 360.0
	rock.angular_velocity_min = -240.0
	rock.angular_velocity_max = 240.0
	var rp := GPUParticles3D.new()
	rp.top_level = true
	rp.amount = 22
	rp.lifetime = 1.0
	rp.one_shot = true
	rp.explosiveness = 0.95
	rp.local_coords = false
	rp.visibility_aabb = AABB(Vector3(-14, -4, -14), Vector3(28, 14, 28))
	rp.process_material = rock
	var bm := BoxMesh.new()
	bm.size = Vector3(0.22, 0.18, 0.26)
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.22, 0.2, 0.18)
	rmat.roughness = 0.95
	rmat.emission_enabled = true
	rmat.emission = col
	rmat.emission_energy_multiplier = 0.25
	bm.material = rmat
	rp.draw_pass_1 = bm
	tree.current_scene.add_child(rp)
	rp.global_position = pos
	rp.emitting = true
	_free_later(tree, rp, 1.6)

	# Faíscas de energia subindo
	var sp := ParticleProcessMaterial.new()
	sp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	sp.emission_ring_axis = Vector3(0, 1, 0)
	sp.emission_ring_radius = radius * 0.7
	sp.emission_ring_inner_radius = 0.3
	sp.emission_ring_height = 0.1
	sp.direction = Vector3(0, 1, 0)
	sp.spread = 12.0
	sp.initial_velocity_min = 3.0
	sp.initial_velocity_max = 8.0
	sp.gravity = Vector3(0, -2.0, 0)
	sp.scale_min = 0.18
	sp.scale_max = 0.4
	sp.scale_curve = _shrink_curve(1.0, 0.8, 0.0)
	sp.color_ramp = _ramp([[0.0, Color(1, 1, 1, 1)], [0.4, Color(col.r, col.g, col.b, 0.9)], [1.0, Color(col.r, col.g, col.b, 0.0)]])
	_emitter(tree, pos, sp, 48, 0.8, 1.0, true, true, 0.8)

	_flash_light(tree, pos + Vector3(0, 1.0, 0), col, 5.0, radius * 1.8, 0.45)

## [3] Vórtice: círculo rúnico que suga energia (partículas em espiral para o centro) por `duration` segundos.
static func spawn_vortex_effect(tree: SceneTree, center_pos: Vector3, duration: float = 2.5) -> void:
	if not tree or not tree.current_scene: return
	var col := Color(0.70, 0.30, 1.0)
	var pos := center_pos + Vector3(0, 0.1, 0)

	# Círculo rúnico (shader)
	var pr := _shader_plane(11.0, VORTEX_SHADER)
	var mi: MeshInstance3D = pr[0]
	var mat: ShaderMaterial = pr[1]
	mat.set_shader_parameter("color", col)
	mat.set_shader_parameter("alpha", 0.0)
	tree.current_scene.add_child(mi)
	mi.global_position = pos
	var tw := tree.create_tween()
	tw.tween_method(func(v: float): mat.set_shader_parameter("alpha", v), 0.0, 1.0, 0.25)
	tw.tween_interval(max(duration - 0.65, 0.1))
	tw.tween_method(func(v: float): mat.set_shader_parameter("alpha", v), 1.0, 0.0, 0.4)
	tw.tween_callback(func():
		if is_instance_valid(mi):
			mi.queue_free()
	)
	var spin := tree.create_tween()
	spin.tween_property(mi, "rotation:y", -TAU * 0.6, duration)

	# Partículas sugadas em espiral
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3(0, 1, 0)
	pm.emission_ring_radius = 5.2
	pm.emission_ring_inner_radius = 2.0
	pm.emission_ring_height = 0.3
	pm.direction = Vector3(0, 0.15, 0)
	pm.spread = 10.0
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 1.5
	pm.radial_accel_min = -15.0
	pm.radial_accel_max = -22.0
	pm.tangential_accel_min = 12.0
	pm.tangential_accel_max = 18.0
	pm.damping_min = 1.0
	pm.damping_max = 2.0
	pm.gravity = Vector3(0, 1.4, 0)
	pm.scale_min = 0.28
	pm.scale_max = 0.7
	pm.scale_curve = _shrink_curve(0.3, 1.0, 0.0)
	pm.color_ramp = _ramp([[0.0, Color(col.r, col.g, col.b, 0.0)], [0.2, Color(0.85, 0.5, 1.0, 0.95)], [0.8, Color(1.0, 0.9, 1.0, 0.8)], [1.0, Color(1, 1, 1, 0.0)]])
	var swirl := _emitter(tree, pos, pm, 170, 0.9, 1.0, true, false, 0.0)
	tree.create_timer(duration).timeout.connect(func():
		if is_instance_valid(swirl):
			swirl.emitting = false
			_free_later(tree, swirl, 1.2)
	)

	# Coluna central subindo
	var cm := ParticleProcessMaterial.new()
	cm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	cm.emission_sphere_radius = 0.7
	cm.direction = Vector3(0, 1, 0)
	cm.spread = 6.0
	cm.initial_velocity_min = 4.0
	cm.initial_velocity_max = 8.0
	cm.gravity = Vector3.ZERO
	cm.scale_min = 0.5
	cm.scale_max = 1.2
	cm.scale_curve = _shrink_curve(0.5, 1.0, 0.0)
	cm.color_ramp = _ramp([[0.0, Color(1, 1, 1, 0.0)], [0.15, Color(0.9, 0.7, 1.0, 0.8)], [1.0, Color(0.5, 0.15, 0.9, 0.0)]])
	var column := _emitter(tree, pos, cm, 44, 0.7, 1.0, true, false, 0.0)
	tree.create_timer(duration).timeout.connect(func():
		if is_instance_valid(column):
			column.emitting = false
			_free_later(tree, column, 1.0)
	)

	# Luz pulsante roxa
	var l := OmniLight3D.new()
	l.top_level = true
	l.light_color = col
	l.light_energy = 3.0
	l.omni_range = 11.0
	tree.current_scene.add_child(l)
	l.global_position = pos + Vector3(0, 1.4, 0)
	var lt := tree.create_tween().set_loops(int(duration / 0.3))
	lt.tween_property(l, "light_energy", 5.0, 0.15)
	lt.tween_property(l, "light_energy", 2.4, 0.15)
	tree.create_timer(duration).timeout.connect(func():
		if is_instance_valid(l):
			var f := tree.create_tween()
			f.tween_property(l, "light_energy", 0.0, 0.3)
			f.tween_callback(l.queue_free)
	)

# ------------------------------------------------------------------
# PROGRESSÃO / AMBIENTE
# ------------------------------------------------------------------

## Pilar dourado de level-up.
static func spawn_level_up(tree: SceneTree, pos: Vector3) -> void:
	if not tree or not tree.current_scene: return
	var col := Color(1.0, 0.85, 0.35)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3(0, 1, 0)
	pm.emission_ring_radius = 1.1
	pm.emission_ring_inner_radius = 0.7
	pm.emission_ring_height = 0.1
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 4.0
	pm.initial_velocity_min = 5.0
	pm.initial_velocity_max = 9.0
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.3
	pm.scale_max = 0.8
	pm.scale_curve = _shrink_curve(0.6, 1.0, 0.0)
	pm.color_ramp = _ramp([[0.0, Color(1, 1, 0.8, 0.0)], [0.15, Color(1.0, 0.9, 0.5, 0.95)], [1.0, Color(1.0, 0.6, 0.2, 0.0)]])
	_emitter(tree, pos, pm, 90, 1.1, 1.0, true, true, 0.4)
	spawn_shockwave_ring(tree, pos, 4.5, col)
	_flash_light(tree, pos + Vector3(0, 2.0, 0), col, 5.0, 12.0, 0.9)

## Espirro visceral de sangue ao acertar golpe em monstros (Diablo IV Hit Impact)
static func spawn_blood_burst(tree: SceneTree, hit_pos: Vector3, is_crit: bool = false) -> void:
	if not tree or not tree.current_scene: return
	var origin := hit_pos + Vector3(0, 0.85, 0)
	var bm := ParticleProcessMaterial.new()
	bm.direction = Vector3(0, 0.6, 0)
	bm.spread = 85.0
	bm.initial_velocity_min = 4.0 if not is_crit else 8.0
	bm.initial_velocity_max = 7.5 if not is_crit else 12.0
	bm.gravity = Vector3(0, -22.0, 0)
	bm.damping_min = 2.0
	bm.damping_max = 4.5
	bm.scale_min = 0.14
	bm.scale_max = 0.32 if not is_crit else 0.48
	bm.scale_curve = _shrink_curve(1.0, 0.7, 0.0)
	bm.color_ramp = _ramp([
		[0.0, Color(0.65, 0.05, 0.05, 0.95)],
		[0.4, Color(0.42, 0.02, 0.02, 0.85)],
		[1.0, Color(0.18, 0.01, 0.01, 0.0)]
	])
	_emitter(tree, origin, bm, 22 if is_crit else 12, 0.55, 0.8, false, true, 0.92)

## Aura rúnica no solo sob os pés de Campeões, Elites e Bosses (Diablo IV Tier Aura)
static func spawn_mob_tier_aura(mob: Node3D, tier_color: Color, tier_kind: String, scale_radius: float = 1.0) -> Node3D:
	if not mob or not is_instance_valid(mob): return null
	var aura_root := Node3D.new()
	aura_root.name = "MobTierAura"
	mob.add_child(aura_root)
	aura_root.position = Vector3(0, 0.04, 0)

	# Anel rúnico no chão
	var torus_mesh := TorusMesh.new()
	torus_mesh.inner_radius = 0.9 * scale_radius
	torus_mesh.outer_radius = (0.9 * scale_radius) + (0.16 if tier_kind in ["mini_boss", "world_boss"] else 0.10)
	var ring := MeshInstance3D.new()
	ring.mesh = torus_mesh
	ring.visibility_range_end = 48.0
	ring.visibility_range_end_margin = 6.0
	ring.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tier_color
	mat.emission_enabled = true
	mat.emission = tier_color
	mat.emission_energy_multiplier = 2.2 if tier_kind != "mob" else 1.2
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = mat
	ring.scale = Vector3(1.0, 0.03, 1.0)
	aura_root.add_child(ring)

	# Luz radiante dinâmica (com fade de distância para não pesar com centenas de campeões/elites)
	var light := OmniLight3D.new()
	light.light_color = tier_color
	light.light_energy = 1.4 if tier_kind == "mob" else 2.6
	light.omni_range = 2.6 * scale_radius + 1.2
	light.distance_fade_enabled = true
	light.distance_fade_begin = 20.0
	light.distance_fade_length = 8.0
	light.position = Vector3(0, 0.4, 0)
	aura_root.add_child(light)

	return aura_root

