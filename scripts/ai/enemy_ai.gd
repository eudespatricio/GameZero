extends CharacterBody3D
class_name EnemyMob

enum BehaviorType { PASSIVE, AGGRESSIVE, BOSS }
enum State { IDLE, PATROL, CHASE, ATTACK, RETURN, DEAD }

@export var mob_name: String = "Batedor Urgal de Chifre"
@export var behavior: BehaviorType = BehaviorType.AGGRESSIVE
@export var level: int = 8
@export var max_health: float = 480.0
@export var attack_damage: float = 65.0
@export var move_speed: float = 5.2
@export var detection_range: float = 13.0
@export var attack_range: float = 2.2
@export var xp_reward: int = 220
@export var gold_reward: int = 450

@onready var visual_root: Node3D = $Visuals
@onready var hp_bar_label: Label3D = $Label3D
@onready var attack_timer: Timer = $AttackTimer

var current_health: float = 480.0
var current_state: State = State.IDLE
var target_player: CharacterBody3D
var spawn_position: Vector3
var patrol_target: Vector3
var state_timer: float = 0.0

# --- Animação procedural / habilidades de boss ---
var archetype_id: String = ""
var model_scale: float = 1.0
var slam_enabled: bool = false
var slam_radius: float = 5.0
var _slam_cooldown: float = 6.0
var _slamming: bool = false
var _anim_t: float = 0.0
var _atk_lean: float = 0.0
var _atk_lunge: float = 0.0
var _pivot: Node3D
var _sleep_tick: int = 0
var _prev_state: State = State.IDLE
var _growl_cd: float = 0.0
var _limbs: Dictionary = {}
var audio_player: AudioStreamPlayer3D = null

# --- SISTEMA DE GRAU DE DIFICULDADE (DIABLO IV TIERS) ---
enum MobDifficultyTier { NORMAL, CHAMPION, ELITE, MINIBOSS, WORLD_BOSS }
var difficulty_tier: MobDifficultyTier = MobDifficultyTier.NORMAL
var tier_affixes: Array[String] = []
var tier_color: Color = Color(0.85, 0.88, 0.92)

# --- BARREIRA SAGRADA DE SYLVERIA (SAFE ZONE) ---
const SAFE_ZONE_CENTER := Vector3(0, 0, 0)
const SAFE_ZONE_RADIUS := 24.0

func is_pos_in_safe_zone(p: Vector3) -> bool:
	return Vector2(p.x, p.z).length() <= SAFE_ZONE_RADIUS

signal enemy_died(mob_name: String, xp: int, gold: int)

func _ready() -> void:
	current_health = max_health
	if hp_bar_label:
		hp_bar_label.visibility_range_end = 22.0
		hp_bar_label.visibility_range_begin_margin = 3.0
	spawn_position = global_position
	patrol_target = spawn_position
	_update_label()
	
	if not attack_timer:
		attack_timer = Timer.new()
		attack_timer.name = "AttackTimer"
		attack_timer.wait_time = 1.4
		attack_timer.one_shot = true
		add_child(attack_timer)

	if not audio_player:
		audio_player = AudioStreamPlayer3D.new()
		audio_player.name = "MobAudio"
		audio_player.bus = "SFX"
		audio_player.unit_size = 9.0
		audio_player.max_distance = 35.0
		audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
		add_child(audio_player)

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	if not target_player:
		target_player = get_tree().get_first_node_in_group("player")
		if not target_player:
			var root = get_tree().current_scene
			if root:
				target_player = root.get_node_or_null("Player")

	# Otimização do mapa grande (alta densidade de mobs): mobs ociosos distantes diminuem a frequência de IA
	if target_player and (current_state == State.IDLE or current_state == State.PATROL):
		var d2 = global_position.distance_squared_to(target_player.global_position)
		if d2 > 120.0 * 120.0:
			_sleep_tick = (_sleep_tick + 1) % 12
			if _sleep_tick != 0:
				return
		elif d2 > 65.0 * 65.0:
			_sleep_tick = (_sleep_tick + 1) % 6
			if _sleep_tick != 0:
				return

	state_timer -= delta

	if slam_enabled and not _slamming:
		_slam_cooldown -= delta
		if _slam_cooldown <= 0.0 and target_player and current_state in [State.CHASE, State.ATTACK]:
			if global_position.distance_to(target_player.global_position) < slam_radius * 1.6:
				_boss_slam()
	if _slamming:
		velocity.x = move_toward(velocity.x, 0, 30 * delta)
		velocity.z = move_toward(velocity.z, 0, 30 * delta)
		if not is_on_floor():
			velocity.y -= 16.0 * delta
		move_and_slide()
		return

	# 0. Verificação da Barreira da Safe Zone (Santuário de Sylveria)
	if is_pos_in_safe_zone(global_position):
		var away_dir = (global_position - SAFE_ZONE_CENTER).normalized()
		away_dir.y = 0.0
		if away_dir.length() < 0.1:
			away_dir = Vector3.FORWARD
		velocity.x = away_dir.x * 12.0
		velocity.z = away_dir.z * 12.0
		current_state = State.RETURN
		target_player = null
		move_and_slide()
		return

	match current_state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0, 10 * delta)
			velocity.z = move_toward(velocity.z, 0, 10 * delta)
			if behavior != BehaviorType.PASSIVE and target_player and not is_pos_in_safe_zone(target_player.global_position):
				var dist = global_position.distance_to(target_player.global_position)
				if dist <= detection_range:
					current_state = State.CHASE

			if state_timer <= 0.0:
				current_state = State.PATROL
				state_timer = randf_range(3.0, 6.0)
				var pt = spawn_position + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))
				if not is_pos_in_safe_zone(pt):
					patrol_target = pt

		State.PATROL:
			var dir = (patrol_target - global_position)
			dir.y = 0.0
			if dir.length() > 0.5:
				var move_dir = dir.normalized()
				velocity.x = move_dir.x * (move_speed * 0.5)
				velocity.z = move_dir.z * (move_speed * 0.5)
				visual_root.rotation.y = lerp_angle(visual_root.rotation.y, atan2(move_dir.x, move_dir.z), 6 * delta)
			else:
				current_state = State.IDLE
				state_timer = randf_range(2.0, 4.0)

			if behavior != BehaviorType.PASSIVE and target_player and not is_pos_in_safe_zone(target_player.global_position):
				if global_position.distance_to(target_player.global_position) <= detection_range:
					current_state = State.CHASE

		State.CHASE:
			if not target_player or is_pos_in_safe_zone(target_player.global_position):
				# Jogador recuou para a Safe Zone ou sumiu: mob desiste e volta
				current_state = State.RETURN
				return

			var dist_to_center = global_position.distance_to(SAFE_ZONE_CENTER)
			if dist_to_center <= SAFE_ZONE_RADIUS + 1.8:
				# Mob atingiu a borda externa da Safe Zone: proibido de prosseguir
				current_state = State.RETURN
				return

			var dist = global_position.distance_to(target_player.global_position)
			if dist > detection_range * 1.8:
				# Perdeu o agro
				current_state = State.RETURN
			elif dist <= attack_range:
				current_state = State.ATTACK
			else:
				var dir = (target_player.global_position - global_position).normalized()
				velocity.x = dir.x * move_speed
				velocity.z = dir.z * move_speed
				visual_root.rotation.y = lerp_angle(visual_root.rotation.y, atan2(dir.x, dir.z), 10 * delta)

		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0, 15 * delta)
			velocity.z = move_toward(velocity.z, 0, 15 * delta)
			if not target_player or is_pos_in_safe_zone(target_player.global_position):
				current_state = State.RETURN
				return

			var dist = global_position.distance_to(target_player.global_position)
			if dist > attack_range * 1.3:
				current_state = State.CHASE
			else:
				var dir = (target_player.global_position - global_position).normalized()
				visual_root.rotation.y = lerp_angle(visual_root.rotation.y, atan2(dir.x, dir.z), 12 * delta)
				if attack_timer.is_stopped():
					_perform_attack()

		State.RETURN:
			var dir = (spawn_position - global_position)
			dir.y = 0.0
			if dir.length() > 0.8:
				var move_dir = dir.normalized()
				velocity.x = move_dir.x * move_speed
				velocity.z = move_dir.z * move_speed
				visual_root.rotation.y = lerp_angle(visual_root.rotation.y, atan2(move_dir.x, move_dir.z), 8 * delta)
			else:
				current_state = State.IDLE
				current_health = max_health
				_update_label()

	# Rugido ao entrar em combate (com recarga aleatória espaçada de 6 a 14s)
	_growl_cd = max(0.0, _growl_cd - delta)
	if current_state == State.CHASE and _prev_state != State.CHASE and _prev_state != State.ATTACK and _growl_cd <= 0.0:
		_growl_cd = randf_range(6.0, 14.0)
		_play_aggro_sound()
	_prev_state = current_state

	if not is_on_floor():
		velocity.y -= 16.0 * delta
	else:
		velocity.y = 0.0

	move_and_slide()

func _get_attack_sfx() -> String:
	var arch: Dictionary = MobsDatabase.get_all().get(archetype_id, {})
	var model_path: String = arch.get("model", "")
	var m_low := archetype_id.to_lower()
	if model_path == MobsDatabase.WOLF or m_low.contains("wolf") or m_low.contains("boar"):
		return "mob_attack_beast_1" if randf() < 0.5 else "mob_attack_beast_2"
	elif model_path == MobsDatabase.GOLEM or m_low.contains("golem") or m_low.contains("tomb") or m_low.contains("guardian"):
		return "mob_attack_blunt_1"
	elif model_path == MobsDatabase.WRAITH or m_low.contains("wraith") or m_low.contains("durza") or m_low.contains("fanghur") or m_low.contains("razac") or m_low.contains("shade"):
		return "mob_attack_spectral_1"
	else:
		return "mob_attack_heavy_1" if randf() < 0.5 else "mob_attack_heavy_2"

func _shout_boss_bark(quote: String) -> void:
	if quote.is_empty():
		return
	# 1. Notifica o HUD para exibir a citação intimidante sob a barra de chefe
	var hud_node := get_tree().get_first_node_in_group("hud")
	if not hud_node:
		var root = get_tree().current_scene
		if root:
			hud_node = root.get_node_or_null("HUD")
	if hud_node and hud_node.has_method("show_boss_bark"):
		hud_node.call("show_boss_bark", quote)

	# 2. Balão de combate flutuante em 3D sobre o Boss
	FloatingCombatText.spawn(get_tree(), global_position, "☠️ \"%s\"" % quote, FloatingCombatText.TextType.BOSS_SHOUT)

## Escolhe o som de agressão conforme o tipo de criatura e brada falas intimidantes de Boss
func _play_aggro_sound() -> void:
	if audio_player and audio_player.playing:
		return
	var sfx := "growl_small"
	var bark := ""
	var a_low := archetype_id.to_lower()
	if behavior == BehaviorType.BOSS or difficulty_tier in [MobDifficultyTier.MINIBOSS, MobDifficultyTier.WORLD_BOSS]:
		if a_low.contains("gromk") or a_low.contains("urgal") or a_low.contains("garzhvog") or a_low.contains("kull"):
			sfx = "voice_boss_gromk_aggro"
			bark = "VOU ESMAGAR SEUS OSSOS!"
		elif a_low.contains("durza") or a_low.contains("wraith"):
			sfx = "voice_boss_durza_aggro"
			bark = "SUA ALMA PERTENCE ÀS SOMBRAS..."
		elif a_low.contains("knight") or a_low.contains("oathsworn"):
			sfx = "voice_boss_knight_aggro"
			bark = "PELA GLÓRIA DE GALBATORIX!"
		else:
			sfx = "boss_roar_intimidating"
			bark = "VOCÊ NÃO PASSARÁ VIVO!"
		_shout_boss_bark(bark)
	else:
		var model_path := String(MobsDatabase.get_all().get(archetype_id, {}).get("model", ""))
		if model_path.contains("wolf"):
			sfx = "growl_beast" if model_scale >= 1.0 else "growl_small"
		elif model_path.contains("golem"):
			sfx = "miniboss_growl" if model_scale >= 1.2 else "growl_large"
		elif model_path.contains("wraith"):
			sfx = "growl_wraith"
		elif model_path.contains("urgal"):
			sfx = "miniboss_growl" if model_scale >= 1.3 else "growl_beast"

	var tree := get_tree()
	if audio_player and tree and tree.root and tree.root.has_node("AudioManager"):
		var am = tree.root.get_node("AudioManager")
		var list: Array = am._variants(sfx)
		if not list.is_empty():
			audio_player.stream = list[randi() % list.size()]
			audio_player.volume_db = 2.0 if behavior == BehaviorType.BOSS else 0.5
			audio_player.pitch_scale = randf_range(0.88, 1.12) * clamp(1.15 - model_scale * 0.12, 0.75, 1.25)
			audio_player.play()
			return

	GameAudio.mob(tree, sfx, global_position, 2.0 if behavior == BehaviorType.BOSS else 0.5, clamp(1.15 - model_scale * 0.12, 0.7, 1.2))

func _perform_attack() -> void:
	attack_timer.start()
	var atk_sfx := _get_attack_sfx()
	GameAudio.mob(get_tree(), atk_sfx, global_position, 0.0, clamp(1.15 - model_scale * 0.12, 0.75, 1.25))
	# Animação procedural: recua (anticipation), investe e retorna
	var tween = create_tween()
	tween.tween_property(self, "_atk_lean", -0.32, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "_atk_lunge", -0.25 * model_scale, 0.16)
	tween.tween_property(self, "_atk_lean", 0.55, 0.09).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "_atk_lunge", 0.8 * model_scale, 0.09)
	tween.tween_callback(_apply_attack_hit)
	tween.tween_property(self, "_atk_lean", 0.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "_atk_lunge", 0.0, 0.32)

func _apply_attack_hit() -> void:
	if current_state == State.DEAD or not is_instance_valid(target_player):
		return
	if global_position.distance_to(target_player.global_position) <= attack_range * 1.4 and target_player.has_method("receive_damage"):
		target_player.receive_damage(attack_damage)

## Pancada em área com telégrafo (anel vermelho que cresce) – esquive saindo do círculo!
func _boss_slam() -> void:
	_slamming = true
	_slam_cooldown = randf_range(7.0, 10.0)

	# Voz e brado de ataque especial do Chefe
	var a_low := archetype_id.to_lower()
	if a_low.contains("gromk") or a_low.contains("urgal") or a_low.contains("kull"):
		GameAudio.mob(get_tree(), "voice_boss_gromk_slam", global_position, 2.8)
		_shout_boss_bark("MORRA SOB MEU MACHADO!")
	elif a_low.contains("durza") or a_low.contains("wraith"):
		GameAudio.mob(get_tree(), "voice_boss_durza_aggro", global_position, 2.5)
		_shout_boss_bark("O VAZIO TE CONSOME!")
	else:
		GameAudio.mob(get_tree(), "boss_slam_heavy", global_position, 2.0)

	var ring = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = Vector2(slam_radius * 2.0, slam_radius * 2.0)
	ring.mesh = pm
	var t_sh = load("res://assets/shaders/telegraph_slam.gdshader") as Shader
	if t_sh:
		var s_mat = ShaderMaterial.new()
		s_mat.shader = t_sh
		ring.material_override = s_mat
	get_parent().add_child(ring)
	ring.global_position = Vector3(global_position.x, 0.05, global_position.z)
	ring.scale = Vector3(0.15, 1, 0.15)
	var tw = create_tween()
	tw.tween_property(self, "_atk_lean", -0.5, 0.8).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(ring, "scale", Vector3.ONE, 1.0).set_trans(Tween.TRANS_LINEAR)
	tw.parallel().tween_property(self, "_atk_lunge", -0.4 * model_scale, 0.8)
	tw.tween_property(self, "_atk_lean", 0.85, 0.12).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await tw.finished
	if not is_inside_tree() or current_state == State.DEAD:
		ring.queue_free()
		return
	CombatVFX.trigger_screen_shake(get_tree(), 0.75)
	CombatVFX.trigger_hit_stop(get_tree(), 0.06)
	GameAudio.mob(get_tree(), "boss_slam_heavy", global_position, 3.5)
	if is_instance_valid(target_player):
		var d = Vector2(target_player.global_position.x - global_position.x, target_player.global_position.z - global_position.z).length()
		if d <= slam_radius and target_player.has_method("receive_damage"):
			target_player.receive_damage(attack_damage * 1.8)
	var fade = create_tween().set_parallel(true)
	fade.tween_property(ring, "scale", Vector3(1.35, 1, 1.35), 0.35)
	fade.chain().tween_callback(ring.queue_free)
	var back = create_tween().set_parallel(true)
	back.tween_property(self, "_atk_lean", 0.0, 0.5)
	back.tween_property(self, "_atk_lunge", 0.0, 0.5)
	await get_tree().create_timer(0.45).timeout
	_slamming = false

var is_dormant: bool = false

func set_dormant(dormant: bool) -> void:
	if is_dormant == dormant:
		return
	if dormant and current_state in [State.CHASE, State.ATTACK]:
		return
	is_dormant = dormant
	set_process(not dormant)
	set_physics_process(not dormant)
	if visual_root:
		visual_root.visible = not dormant
	if hp_bar_label:
		hp_bar_label.visible = not dormant

func _process(delta: float) -> void:
	if current_state == State.DEAD or is_dormant:
		return
	if _pivot == null or not is_instance_valid(_pivot):
		_pivot = visual_root.get_child(0) as Node3D if visual_root and visual_root.get_child_count() > 0 else null
		if _pivot == null:
			return
		_cache_model_limbs(_pivot)

	# LOD de animação: se o jogador estiver a mais de 45m, poupa cálculo trigonométrico dos membros
	if target_player and global_position.distance_squared_to(target_player.global_position) > 45.0 * 45.0:
		return

	_anim_t += delta
	var sp = Vector2(velocity.x, velocity.z).length()
	var move_f = clamp(sp / max(move_speed, 0.1), 0.0, 1.0)
	var cadence = 6.0 + sp * 1.3
	var bob = abs(sin(_anim_t * cadence * 0.5)) * 0.10 * move_f * model_scale
	var sway = sin(_anim_t * cadence * 0.5) * 0.06 * move_f
	var breath = sin(_anim_t * 2.2) * 0.02
	var chase_lean = 0.14 * move_f if current_state in [State.CHASE, State.RETURN] else 0.04 * move_f
	_pivot.position.y = bob
	_pivot.position.z = _atk_lunge
	_pivot.rotation.z = sway
	_pivot.rotation.x = chase_lean + _atk_lean
	_pivot.scale = Vector3(1.0 - breath * 0.5, 1.0 + breath, 1.0 - breath * 0.5) * model_scale

	# Cinemática Anatômica Articulada dos Membros
	_animate_limbs(delta, cadence, move_f)

func _cache_model_limbs(node: Node) -> void:
	_limbs.clear()
	_find_limbs_recursive(node)

func _find_limbs_recursive(node: Node) -> void:
	var n_low = node.name.to_lower()
	if n_low.begins_with("thigh_") or n_low.begins_with("legf_thigh_") or n_low.begins_with("legb_thigh_"):
		_limbs[node.name] = node
	elif n_low.begins_with("shin_") or n_low.begins_with("legf_") or n_low.begins_with("legb_") or n_low.begins_with("leg_"):
		_limbs[node.name] = node
	elif n_low.begins_with("arm_") or n_low.begins_with("forearm_"):
		_limbs[node.name] = node
	elif n_low.begins_with("jaw"):
		_limbs["jaw"] = node
	elif n_low == "tail" or n_low.begins_with("tail"):
		_limbs["tail"] = node
	elif n_low.begins_with("head") or n_low == "head":
		_limbs["head"] = node
	elif n_low.begins_with("sapcore"):
		_limbs["sapcore"] = node
	elif n_low.begins_with("orbitshard"):
		if not _limbs.has("orbitshards"):
			_limbs["orbitshards"] = []
		_limbs["orbitshards"].append(node)
	elif n_low.begins_with("waraxe"):
		_limbs["weapon"] = node

	for c in node.get_children():
		_find_limbs_recursive(c)

func _animate_limbs(delta: float, cadence: float, move_f: float) -> void:
	var step_phase = _anim_t * cadence

	# 1. Quadrúpede (Wolf / Boar)
	var leg_fl = _limbs.get("LegF_-1") as Node3D
	var leg_fr = _limbs.get("LegF_1") as Node3D
	var leg_bl = _limbs.get("LegB_-1") as Node3D
	var leg_br = _limbs.get("LegB_1") as Node3D
	if leg_fl and leg_fr:
		leg_fl.rotation.x = sin(step_phase) * 0.48 * move_f
		leg_fr.rotation.x = -sin(step_phase) * 0.48 * move_f
	if leg_bl and leg_br:
		leg_bl.rotation.x = -sin(step_phase) * 0.48 * move_f
		leg_br.rotation.x = sin(step_phase) * 0.48 * move_f

	var tail = _limbs.get("tail") as Node3D
	if tail:
		tail.rotation.z = sin(_anim_t * 6.5) * 0.32 * maxf(move_f, 0.3)
	var jaw = _limbs.get("jaw") as Node3D
	if jaw:
		jaw.rotation.x = abs(sin(_anim_t * 3.2)) * 0.12 + (_atk_lean * 0.38)

	# 2. Bípede / Humanoide (Urgal / Kull / Golem)
	var thigh_l = _limbs.get("Thigh_-1") as Node3D
	var thigh_r = _limbs.get("Thigh_1") as Node3D
	var shin_l = _limbs.get("Shin_-1") as Node3D
	var shin_r = _limbs.get("Shin_1") as Node3D
	if thigh_l and thigh_r:
		thigh_l.rotation.x = sin(step_phase) * 0.55 * move_f
		thigh_r.rotation.x = -sin(step_phase) * 0.55 * move_f
	if shin_l and shin_r:
		shin_l.rotation.x = maxf(0.0, -sin(step_phase - 0.4)) * 0.62 * move_f
		shin_r.rotation.x = maxf(0.0, sin(step_phase - 0.4)) * 0.62 * move_f

	# Braços e Armas
	var arm_l = _limbs.get("Arm_-1") as Node3D
	var arm_r = _limbs.get("Arm_1") as Node3D
	if arm_l:
		arm_l.rotation.x = -sin(step_phase) * 0.42 * move_f
	if arm_r:
		arm_r.rotation.x = (sin(step_phase) * 0.35 * move_f) + (_atk_lean * 0.85)
		arm_r.rotation.z = -0.22 + (_atk_lean * 0.4)

	# 3. Núcleo Elemental do Golem
	var core = _limbs.get("sapcore") as Node3D
	if core:
		var c_scale = 1.0 + sin(_anim_t * 4.5) * 0.15
		core.scale = Vector3(c_scale, c_scale, c_scale)

	# 4. Estilhaços Orbitantes da Sombra (Wraith)
	if _limbs.has("orbitshards"):
		var shards: Array = _limbs["orbitshards"]
		for idx in shards.size():
			var s_node = shards[idx] as Node3D
			if is_instance_valid(s_node):
				var s_ang = _anim_t * 2.4 + (idx * TAU / float(shards.size()))
				var sx = cos(s_ang) * 0.95
				var sz = sin(s_ang) * 0.95
				var sy = 1.35 + sin(_anim_t * 3.2 + idx) * 0.22
				s_node.position = Vector3(sx, sy, sz)
				s_node.rotation.y += delta * 4.0

## Configura mob a partir do Bestiário (MobsDatabase). Chamar após add_child().
func configure(arch_id: String, lvl: int) -> void:
	var all = MobsDatabase.get_all()
	if not all.has(arch_id):
		return
	archetype_id = arch_id
	var arch: Dictionary = all[arch_id]
	var st = MobsDatabase.build_stats(arch, lvl)
	mob_name = arch["name"]
	level = lvl
	max_health = st["hp"]
	current_health = max_health
	attack_damage = st["dmg"]
	xp_reward = st["xp"]
	gold_reward = st["gold"]
	move_speed = arch["speed"]
	detection_range = arch["detect"]
	behavior = BehaviorType.BOSS if arch["kind"] != "mob" else (BehaviorType.PASSIVE if arch["behavior"] == 0 else BehaviorType.AGGRESSIVE)
	spawn_position = global_position
	patrol_target = spawn_position
	model_scale = arch["scale"]
	attack_range = 2.2 * pow(model_scale, 0.6)
	slam_enabled = arch["kind"] != "mob"
	slam_radius = 4.5 if arch["kind"] == "mini_boss" else 6.5

	if not visual_root:
		visual_root = get_node_or_null("Visuals")
	if not hp_bar_label:
		hp_bar_label = get_node_or_null("Label3D")

	# Troca do modelo 3D
	if visual_root:
		for c in visual_root.get_children():
			visual_root.remove_child(c)
			c.queue_free()
	var scn = load(arch["model"]) as PackedScene
	if scn and visual_root:
		var model = scn.instantiate() as Node3D
		visual_root.add_child(model)
		_tint_model(model, arch["tint"])
		_pivot = model
		model.scale = Vector3.ONE * model_scale
		_cache_model_limbs(model)

	# Sistema de Tiers de Dificuldade Diablo IV
	if arch["kind"] == "world_boss":
		difficulty_tier = MobDifficultyTier.WORLD_BOSS
		tier_color = Color(0.94, 0.27, 0.27) # Vermelho Carmesim Fogo
		tier_affixes = ["Lorde Supremo", "Imparável"]
	elif arch["kind"] == "mini_boss":
		difficulty_tier = MobDifficultyTier.MINIBOSS
		tier_color = Color(0.66, 0.33, 0.97) # Violeta Profundo
		tier_affixes = ["Comandante", "Golpe Sísmico"]
	else:
		var roll := randf()
		if roll < 0.08:
			difficulty_tier = MobDifficultyTier.ELITE
			tier_color = Color(0.98, 0.75, 0.14) # Ouro Resplandecente
			max_health *= 1.8
			current_health = max_health
			attack_damage *= 1.35
			xp_reward = int(xp_reward * 2.2)
			gold_reward = int(gold_reward * 2.5)
			model_scale *= 1.25
			tier_affixes = ["Vampírico", "Muralha de Pedra"]
		elif roll < 0.22:
			difficulty_tier = MobDifficultyTier.CHAMPION
			tier_color = Color(0.22, 0.74, 0.97) # Ciano Elétrico
			max_health *= 1.35
			current_health = max_health
			move_speed *= 1.15
			xp_reward = int(xp_reward * 1.5)
			gold_reward = int(gold_reward * 1.6)
			model_scale *= 1.12
			tier_affixes = ["Ágil"]
		else:
			difficulty_tier = MobDifficultyTier.NORMAL
			tier_color = Color(0.85, 0.88, 0.92)
			tier_affixes = []

	# Colisão proporcional (duplica o recurso: é compartilhado entre instâncias)
	var cs = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if cs and cs.shape is CapsuleShape3D:
		var cap = (cs.shape as CapsuleShape3D).duplicate()
		cap.radius = 0.55 * pow(model_scale, 0.75)
		cap.height = max(2.1 * model_scale, cap.radius * 2.2)
		cs.shape = cap
		cs.position.y = cap.height * 0.5

	# Rótulo e aura
	if hp_bar_label:
		hp_bar_label.position.y = 2.5 * model_scale + 0.3
	if difficulty_tier != MobDifficultyTier.NORMAL:
		CombatVFX.spawn_mob_tier_aura(self, tier_color, arch["kind"], model_scale)

	# Hardware Distance Culling no Vulkan (corta meshes além de 55m para mobs e 95m para bosses)
	var max_vis := 55.0 if arch["kind"] == "mob" else 95.0
	_apply_visibility_culling(visual_root, max_vis)
	_update_label()

func _apply_visibility_culling(node: Node, max_dist: float) -> void:
	if not node:
		return
	if node is GeometryInstance3D:
		var gi := node as GeometryInstance3D
		gi.visibility_range_end = max_dist
		gi.visibility_range_end_margin = 8.0
		gi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	for c in node.get_children():
		_apply_visibility_culling(c, max_dist)

func _tint_model(node: Node, tint: Color) -> void:
	var soft_tint := Color.WHITE.lerp(tint, 0.45)
	if node is MeshInstance3D:
		var mi = node as MeshInstance3D
		if mi.mesh:
			for i in mi.mesh.get_surface_count():
				var base = mi.mesh.surface_get_material(i)
				if base is StandardMaterial3D:
					var mat = (base as StandardMaterial3D).duplicate() as StandardMaterial3D
					# Não tinge superfícies emissivas (olhos, runas, veios)
					if not mat.emission_enabled:
						mat.albedo_color = Color(mat.albedo_color.r * soft_tint.r, mat.albedo_color.g * soft_tint.g, mat.albedo_color.b * soft_tint.b, mat.albedo_color.a)
					# Oclusão ambiente assada no Blender vem em COLOR_0
					mat.vertex_color_use_as_albedo = true
					# Grão de superfície (triplanar, sem UV)
					MaterialDetail.apply(mat, 2.6, 0.85)
					mi.set_surface_override_material(i, mat)
	for c in node.get_children():
		_tint_model(c, tint)

func take_damage(amount: float, is_crit: bool = false) -> void:
	if current_state == State.DEAD:
		return

	if is_dormant:
		set_dormant(false)

	# O dano aplicado é exatamente o dano exibido (antes o crítico era só cosmético).
	current_health -= amount
	current_state = State.CHASE # Revida imediatamente ao receber dano!
	_update_label()

	# Efeitos Sonoros & Visuais de Impacto (Diablo IV)
	GameAudio.mob(get_tree(), "hit_crit" if is_crit else "hit_flesh", global_position, 0.0 if is_crit else -2.0)
	CombatVFX.spawn_hit_sparks(get_tree(), global_position, is_crit)
	CombatVFX.spawn_blood_burst(get_tree(), global_position, is_crit)

	if is_crit:
		CombatVFX.trigger_hit_stop(get_tree(), 0.055)
		CombatVFX.trigger_screen_shake(get_tree(), 0.42)
	else:
		CombatVFX.trigger_screen_shake(get_tree(), 0.18)

	var text_type = FloatingCombatText.TextType.CRITICAL if is_crit else FloatingCombatText.TextType.NORMAL
	var text_display = "-%d CRÍTICO!" % int(amount) if is_crit else "-%d" % int(amount)
	FloatingCombatText.spawn(get_tree(), global_position, text_display, text_type)

	# Flash de dano e recuo elástico
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_root, "scale", Vector3(1.3, 0.7, 1.3) if is_crit else Vector3(1.18, 0.82, 1.18), 0.08)
	tween.tween_property(visual_root, "scale", Vector3.ONE, 0.14)

	# Micro knockback no impacto
	if target_player:
		var push_dir = (global_position - target_player.global_position).normalized()
		push_dir.y = 0.0
		velocity += push_dir * (5.5 if is_crit else 3.2)

	if current_health <= 0.0:
		_die()

func _die() -> void:
	current_state = State.DEAD
	GameAudio.mob(get_tree(), "mob_death", global_position, 0.0, clamp(1.15 - model_scale * 0.18, 0.7, 1.2))
	enemy_died.emit(mob_name, xp_reward, gold_reward)

	# Impacto de Morte: Knockback violento + giro no ar
	CombatVFX.trigger_hit_stop(get_tree(), 0.07)
	CombatVFX.trigger_screen_shake(get_tree(), 0.55)

	var push_dir = Vector3.BACK
	if target_player:
		push_dir = (global_position - target_player.global_position).normalized()
	velocity = push_dir * 9.5 + Vector3(0, 4.2, 0)

	# Loot físico no chão (ouro, joias, materiais, equipamentos) – recolhido ao se aproximar
	LootSystem.roll_mob_loot(get_tree(), mob_name, level, behavior == BehaviorType.BOSS, global_position)
	if target_player and target_player.stats:
		target_player.stats.add_xp(xp_reward, mob_name)
		target_player.stats.register_kill(mob_name)

	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_root, "rotation:x", 1.8, 0.45)
	tween.tween_property(visual_root, "rotation:y", visual_root.rotation.y + 2.5, 0.45)
	tween.tween_property(visual_root, "scale", Vector3(0.05, 0.05, 0.05), 0.55)
	await tween.finished
	queue_free()

func _update_label() -> void:
	if not hp_bar_label:
		return

	# 1. Determinar Nível do Jogador para Comparação de Perigo
	var player_lvl: int = 1
	if is_instance_valid(target_player) and target_player.stats:
		player_lvl = target_player.stats.level
	elif get_tree():
		var p = get_tree().get_first_node_in_group("player")
		if p and p.stats:
			player_lvl = p.stats.level

	var lvl_diff: int = level - player_lvl
	var danger_tag := ""
	var danger_col := Color(0.90, 0.92, 0.95)
	if lvl_diff >= 5:
		danger_tag = " [☠ PERIGO MORTAL]"
		danger_col = Color(0.95, 0.18, 0.18)
	elif lvl_diff >= 2:
		danger_tag = " [⚠ DESAFIO]"
		danger_col = Color(0.98, 0.68, 0.15)
	elif lvl_diff <= -3:
		danger_tag = " [FÁCIL]"
		danger_col = Color(0.35, 0.85, 0.45)

	# 2. Tier de Dificuldade e Ícone Temático Compacto (Diablo IV)
	var tier_prefix := "⚔️"
	var tier_name_col: Color = Color(0.85, 0.88, 0.92) # Normal = Prata
	match difficulty_tier:
		MobDifficultyTier.CHAMPION:
			tier_prefix = "⚡ [CAMPEÃO]"
			tier_name_col = Color(0.22, 0.74, 0.97) # Ciano Elétrico
		MobDifficultyTier.ELITE:
			tier_prefix = "👑 [ELITE]"
			tier_name_col = Color(0.98, 0.75, 0.14) # Ouro Resplandecente
		MobDifficultyTier.MINIBOSS:
			tier_prefix = "💀 [MINIBOSS]"
			tier_name_col = Color(0.66, 0.33, 0.97) # Violeta Profundo
		MobDifficultyTier.WORLD_BOSS:
			tier_prefix = "☠️ [WORLD BOSS]"
			tier_name_col = Color(0.94, 0.27, 0.27) # Vermelho Carmesim Fogo

	var hp_ratio := clampf(current_health / maxf(max_health, 1.0), 0.0, 1.0)
	var hp_percent := int(hp_ratio * 100.0)

	# 3. Barra de Sangue Minimalista e Elegante
	var bar_len := 12
	var filled := int(roundf(hp_ratio * float(bar_len)))
	var bar_str := ""
	for i in range(bar_len):
		if i < filled:
			bar_str += "█"
		else:
			bar_str += "░"

	# Linha 1: Grau, Nível com Perigo e Nome Curto
	var title := "%s [Nvl %d]%s %s" % [tier_prefix, level, danger_tag, mob_name]
	# Linha 2: Barra Gráfica de Vida Compacta
	var bar_line := "[%s] %d%%" % [bar_str, hp_percent]
	hp_bar_label.text = "%s\n%s" % [title, bar_line]

	# Para Bosses (Miniboss / World Boss): a barra monumental já reina no topo do HUD.
	# Ocultamos a billboard 3D de texto sobre a cabeça do monstro para eliminar 100% da poluição visual.
	if difficulty_tier in [MobDifficultyTier.MINIBOSS, MobDifficultyTier.WORLD_BOSS]:
		hp_bar_label.visible = false
	else:
		hp_bar_label.visible = true

	# Altura e Tipografia Cirúrgica (Elimina poluição visual e sobreposição)
	hp_bar_label.position.y = 2.0 * maxf(model_scale, 0.85) + 0.3
	hp_bar_label.font_size = 18 if difficulty_tier >= MobDifficultyTier.MINIBOSS else 15
	hp_bar_label.outline_size = 3
	hp_bar_label.modulate = tier_name_col.lerp(danger_col, 0.25)
	hp_bar_label.outline_modulate = Color(0.02, 0.02, 0.03, 0.95)
