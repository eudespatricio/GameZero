extends CharacterBody3D
class_name Player

# --- CONFIGURAÇÃO DE VELOCIDADES & FÍSICA ---
@export var walk_speed: float = 7.5
@export var run_speed: float = 14.0
@export var dragon_speed: float = 30.0
@export var dash_speed: float = 30.0
@export var jump_velocity: float = 8.5

@export var acceleration: float = 28.0
@export var friction: float = 24.0
@export var turn_speed: float = 13.0
## Distância mínima (m) de um destino clicado a partir da qual o herói passa a correr sozinho
@export var auto_run_distance: float = 14.0

# --- REFERÊNCIAS VISUAIS ---
@onready var visual_root: Node3D = $Visuals
@onready var body_mesh: Node3D = $Visuals/HeroBody
@onready var wings_root: Node3D = $Visuals/HeroBody/Wings
@onready var gedwey_light: OmniLight3D = $Visuals/HeroBody/GedweyLight
@onready var sword_mesh: Node3D = $Visuals/HeroBody
@onready var dragon_mount = $Visuals/DragonMount
@onready var dragon_pet: Node3D = $Visuals/DragonPet
@onready var click_marker: Node3D = $ClickMarker

@onready var helm_mesh: Node3D = $Visuals/HeroBody.get_node_or_null("Helm")
@onready var pauldrons_mesh: Node3D = $Visuals/HeroBody.get_node_or_null("Pauldrons")
@onready var cape_mesh: Node3D = $Visuals/HeroBody.get_node_or_null("Cape")
@onready var shield_mesh: Node3D = $Visuals/HeroBody.get_node_or_null("Shield")
var _weapon_mesh_nodes: Array[Node3D] = []

# --- SISTEMA DE STATS & COMBATE ---
var stats = null
var available_classes: Array[String] = ["zero", "arya", "roran"]
var current_class_idx: int = 0

var combo_step: int = 0
var combo_reset_timer: float = 0.0
var is_attacking: bool = false

# --- ESTADO DE LOCOMOÇÃO ---
var target_position: Vector3 = Vector3.ZERO
var is_moving_to_target: bool = false
var is_sprinting: bool = false
var is_mounted: bool = false
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown: float = 0.0
var _is_dead: bool = false

# --- MOVIMENTO AVANÇADO (SEGURAR CLIQUE, POEIRA, POUSO) ---
var _hold_move: bool = false
var _hold_refresh: float = 0.0
var _dust_timer: float = 0.0
var _was_on_floor: bool = true
var _air_speed_y: float = 0.0
var _step_idx: int = 0
var _flap_timer: float = 0.0
var _map_builder: Node

# --- FÍSICA PROCEDURAL (INÉRCIA, LEAN E BOBBING) ---
var step_cycle: float = 0.0
var current_bank_angle: float = 0.0
var current_pitch_angle: float = 0.0
var last_facing_angle: float = 0.0
var camera: Camera3D

signal combo_performed(step: int, damage: float)
signal skill_cast(slot: int)

# --- SISTEMA DE COOLDOWNS DE HABILIDADES ---
var skill_cooldowns: Dictionary = {
	1: 0.0,
	2: 0.0,
	3: 0.0,
	"dash": 0.0,
	"potion_hp": 0.0,
	"potion_mp": 0.0,
}

const SKILL_MAX_COOLDOWNS: Dictionary = {
	1: 2.5,
	2: 5.0,
	3: 9.0,
	"dash": 0.85,
	"potion_hp": 1.2,
	"potion_mp": 1.2,
}

# --- CINEMÁTICA E PLASTICIDADE PROCEDURAL DOS MEMBROS ---
var _limbs: Dictionary = {}
var _wings_base_rot: Vector3 = Vector3.ZERO
var _wings_base_scale: Vector3 = Vector3.ONE

func get_skill_cooldown(slot) -> float:
	return skill_cooldowns.get(slot, 0.0)

func get_skill_max_cooldown(slot) -> float:
	return SKILL_MAX_COOLDOWNS.get(slot, 1.0)

## Recarga efetiva, já descontando a Redução de Recarga (CDR) dos equipamentos.
func _skill_cooldown(slot) -> float:
	var base: float = float(SKILL_MAX_COOLDOWNS.get(slot, 1.0))
	if stats:
		return base * (1.0 - stats.get_cooldown_reduction() * 0.01)
	return base

## Pede ao SaveManager uma gravação agrupada (evita write a cada equip/ponto).
func _flag_dirty() -> void:
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr and save_mgr.has_method("mark_dirty"):
		save_mgr.mark_dirty()

func _ready() -> void:
	add_to_group("player")
	target_position = global_position
	click_marker.top_level = true
	click_marker.visible = false
	var vp = get_viewport()
	if vp:
		camera = vp.get_camera_3d()
	last_facing_angle = visual_root.rotation.y

	if not is_in_group("player"):
		add_to_group("player")

	# Inicializar Componente de Stats
	stats = CharacterStats.new()
	stats.name = "CharacterStats"
	add_child(stats)

	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr and not save_mgr.pending_character_sheet.is_empty():
		if save_mgr.pending_character_sheet.has("id"):
			save_mgr.active_character_id = save_mgr.pending_character_sheet["id"]
		save_mgr.deserialize_stats(stats, save_mgr.pending_character_sheet)
		save_mgr.pending_character_sheet = {}
		_apply_visual_class_style(stats.current_class_id)

	stats.level_up.connect(func(lvl):
		_on_level_up_vfx(lvl)
		_trigger_immediate_save()
	)
	stats.stat_points_changed.connect(func(): _flag_dirty())
	stats.gear_equipped.connect(func(_slot, _item):
		update_equipment_visuals()
		_flag_dirty()
	)
	stats.gear_unequipped.connect(func(_slot):
		update_equipment_visuals()
		_flag_dirty()
	)
	stats.quest_updated.connect(func(_qid): _flag_dirty())

	# Configurar cache de membros do herói e asas
	_setup_limbs()

	# Sincronizar visibilidade inicial de equipamentos
	update_equipment_visuals()

	# Atualizar arma com o Glow do refino inicial (+11)
	_update_weapon_glow()

func _unhandled_input(event: InputEvent) -> void:
	if _is_dead:
		return

	# Mouse: clique esquerdo move/ataca, direito ataca
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_mouse_click(event.position)
			else:
				_hold_move = false
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			perform_attack()

	if event.is_action_pressed("attack"):
		perform_attack()
	elif event.is_action_pressed("jump"):
		trigger_jump()
	elif event.is_action_pressed("dash"):
		trigger_dash()
	elif event.is_action_pressed("skill_1"):
		cast_skill(1)
	elif event.is_action_pressed("skill_2"):
		cast_skill(2)
	elif event.is_action_pressed("skill_3"):
		cast_skill(3)
	elif event.is_action_pressed("potion_health"):
		use_potion("potion_health")
	elif event.is_action_pressed("potion_mana"):
		use_potion("potion_mana")
	elif event.is_action_pressed("mount"):
		toggle_dragon_mount()
	elif event.is_action_pressed("cycle_character"):
		cycle_next_character()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_trigger_immediate_save()

func _trigger_immediate_save() -> void:
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr and stats:
		save_mgr.save_current_character(stats)

func _on_level_up_vfx(_new_level: int) -> void:
	CombatVFX.spawn_level_up(get_tree(), global_position)
	CombatVFX.trigger_screen_shake(get_tree(), 0.3)

## Direção horizontal para a qual o herói está virado (o modelo olha para +Z local).
func get_facing_dir() -> Vector3:
	var f := visual_root.global_transform.basis.z
	f.y = 0.0
	if f.length() < 0.01:
		return Vector3(0, 0, 1)
	return f.normalized()

## Ponto do chão sob o cursor do mouse (ou null se indisponível)
func get_cursor_ground_point() -> Variant:
	if not camera:
		var vp = get_viewport()
		if vp:
			camera = vp.get_camera_3d()
	if not camera:
		return null
	var mp := get_viewport().get_mouse_position()
	var ro := camera.project_ray_origin(mp)
	var rd := camera.project_ray_normal(mp)
	return Plane(Vector3.UP, 0.0).intersects_ray(ro, rd)

## Direção de mira: do herói até o cursor (se válido), senão a direção atual de olhar.
func get_aim_dir() -> Vector3:
	var gp = get_cursor_ground_point()
	if gp != null:
		var d: Vector3 = gp - global_position
		d.y = 0.0
		if d.length() > 0.6:
			return d.normalized()
	return get_facing_dir()

## Vira o herói suavemente para a direção de mira (efeito imediato no início do golpe).
func face_direction(dir: Vector3) -> void:
	if dir.length() < 0.01:
		return
	var ang := atan2(dir.x, dir.z)
	visual_root.rotation.y = ang
	last_facing_angle = ang

func _handle_mouse_click(screen_pos: Vector2) -> void:
	if not camera:
		var vp = get_viewport()
		if vp:
			camera = vp.get_camera_3d()
	if not camera:
		return

	var ray_origin = camera.project_ray_origin(screen_pos)
	var ray_dir = camera.project_ray_normal(screen_pos)
	
	# Checar se clicou em um monstro próximo para atacar
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_dir * 260.0)
	query.collision_mask = 2 # Camada dos inimigos
	var hit = space_state.intersect_ray(query)
	if hit and hit.collider is EnemyMob:
		perform_attack(hit.collider)
		return

	# Caso contrário, mover para o chão
	var plane = Plane(Vector3.UP, 0.0)
	var ground_hit = plane.intersects_ray(ray_origin, ray_dir)
	if ground_hit:
		target_position = ground_hit
		is_moving_to_target = true
		_hold_move = true
		click_marker.global_position = ground_hit + Vector3(0, 0.06, 0)
		click_marker.visible = true

func trigger_jump() -> void:
	if is_on_floor():
		velocity.y = jump_velocity if not is_mounted else jump_velocity * 1.3
		GameAudio.am(get_tree(), "play_jump")
		var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(visual_root, "scale:y", 1.2, 0.15)
		tween.tween_property(visual_root, "scale:y", 1.0, 0.25)

func perform_attack(target_mob = null) -> void:
	if is_attacking:
		return
	is_attacking = true
	combo_step = (combo_step % 3) + 1
	combo_reset_timer = 1.2

	# Efeito sonoro do corte da lâmina e esforço do herói
	GameAudio.play_slash(get_tree())
	GameAudio.play_player_exert(get_tree(), 2 if combo_step == 3 else 1)

	# Vira para o alvo (monstro clicado) ou para o cursor e projeta o arco de lâmina
	var atk_dir := get_aim_dir()
	if target_mob and is_instance_valid(target_mob):
		var to_t: Vector3 = target_mob.global_position - global_position
		to_t.y = 0.0
		if to_t.length() > 0.1:
			atk_dir = to_t.normalized()
	face_direction(atk_dir)
	var arc_col := Color(0.35, 0.9, 1.0) if combo_step != 3 else Color(1.0, 0.85, 0.4)
	CombatVFX.spawn_slash_arc(get_tree(), global_position, atk_dir, arc_col, 5.0 + combo_step * 0.8, 0.2, 1.3)

	# O dano nasce de CharacterStats: força, arma, refino, affixes e conjuntos
	# (antes era um 85 fixo que ignorava completamente o loot equipado).
	var damage: float = stats.get_attack_damage() if stats else 85.0
	if combo_step == 2:
		damage *= 1.35
	elif combo_step == 3:
		damage *= 2.1 # Finalizador pesado
	var is_crit := false
	if stats and randf() * 100.0 < stats.get_crit_chance():
		is_crit = true
		damage *= stats.get_crit_multiplier()

	# Animação procedural de golpe com a lâmina
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var slash_dir = 0.5 if combo_step == 1 else (-0.5 if combo_step == 2 else 0.0)
	tween.tween_property(visual_root, "rotation:y", visual_root.rotation.y + slash_dir, 0.1)
	tween.tween_property(visual_root, "rotation:y", visual_root.rotation.y, 0.18)

	# Se houver monstro ou inimigos em cone frontal, aplica dano
	if combo_step == 3:
		CombatVFX.trigger_screen_shake(get_tree(), 0.45)
		CombatVFX.trigger_hit_stop(get_tree(), 0.05)
	else:
		CombatVFX.trigger_screen_shake(get_tree(), 0.16)

	if target_mob and global_position.distance_to(target_mob.global_position) <= 4.0:
		target_mob.take_damage(damage, is_crit)
	else:
		# Acerta o monstro mais próximo em raio de 3.2m
		for mob in get_tree().get_nodes_in_group("enemies"):
			if mob is EnemyMob and global_position.distance_to(mob.global_position) <= 3.2:
				mob.take_damage(damage, is_crit)
				break

	combo_performed.emit(combo_step, damage)
	await get_tree().create_timer(0.22).timeout
	is_attacking = false

func receive_damage(amount: float) -> void:
	if _is_dead or not stats:
		return

	var res: Dictionary = stats.take_damage(amount)

	if res.get("dodged", false):
		FloatingCombatText.spawn(get_tree(), global_position + Vector3(0, 1.6, 0), "ESQUIVA!", FloatingCombatText.TextType.MAGIC)
		GameAudio.am(get_tree(), "play_ui", ["click"])
		return

	var dealt: float = float(res.get("damage", amount))
	var blocked: bool = res.get("blocked", false)
	GameAudio.am(get_tree(), "play_player_hurt")

	var label := ("BLOQUEIO -%d" % int(dealt)) if blocked else ("-%d" % int(dealt))
	var text_type = FloatingCombatText.TextType.BLOCK if blocked else FloatingCombatText.TextType.DAMAGE_TAKEN
	FloatingCombatText.spawn(get_tree(), global_position, label, text_type)

	# Flash de impacto no personagem
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_root, "position:y", -0.1, 0.08)
	tween.tween_property(visual_root, "position:y", 0.0, 0.12)

	if stats.current_hp <= 0.0:
		_handle_player_death()

func _handle_player_death() -> void:
	if _is_dead:
		return
	_is_dead = true
	is_attacking = false
	is_dashing = false
	_hold_move = false
	velocity = Vector3.ZERO
	target_position = global_position
	
	FloatingCombatText.spawn(get_tree(), global_position + Vector3(0, 1.8, 0), "💀 VOCÊ CAIU EM COMBATE!", FloatingCombatText.TextType.CRITICAL)
	
	var death_tween = create_tween()
	death_tween.tween_property(visual_root, "rotation:z", deg_to_rad(90.0), 0.35)
	await get_tree().create_timer(2.0).timeout
	
	# Renascer no Santuário de Ellesméra (área segura)
	global_position = Vector3(0, 0.5, 0)
	target_position = global_position
	stats.current_hp = stats.max_hp
	stats.current_mp = stats.max_mp
	stats.stats_changed.emit()
	
	var revive_tween = create_tween()
	revive_tween.tween_property(visual_root, "rotation:z", 0.0, 0.25)
	FloatingCombatText.spawn(get_tree(), global_position + Vector3(0, 2.0, 0), "✨ Renascido no Santuário de Ellesméra!", FloatingCombatText.TextType.MAGIC)
	_is_dead = false

func cycle_next_character() -> void:
	if _is_dead or is_attacking:
		return
	current_class_idx = (current_class_idx + 1) % available_classes.size()
	var new_class = available_classes[current_class_idx]
	# apply_class_data preserva a proporção de HP/MP: trocar de classe não cura
	stats.apply_class_data(new_class)
	_apply_visual_class_style(new_class)
	_flag_dirty()

func _apply_visual_class_style(class_id: String) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_root, "scale", Vector3(1.15, 1.15, 1.15), 0.15)
	tween.tween_property(visual_root, "scale", Vector3.ONE, 0.2)

	match class_id:
		"zero":
			if gedwey_light: gedwey_light.light_color = Color(0.85, 0.95, 1.0)
			if body_mesh: body_mesh.scale = Vector3(1.0, 1.0, 1.0)
		"arya":
			if gedwey_light: gedwey_light.light_color = Color(0.2, 0.95, 0.6)
			if body_mesh: body_mesh.scale = Vector3(0.92, 0.98, 0.92)
		"roran":
			if gedwey_light: gedwey_light.light_color = Color(1.0, 0.6, 0.1)
			if body_mesh: body_mesh.scale = Vector3(1.08, 0.96, 1.08)

	update_equipment_visuals()

## Sincroniza a visibilidade das malhas 3D do jogador com o inventário real
func update_equipment_visuals() -> void:
	if not stats:
		return
	var eq = stats.equipped_gear

	var has_head = _is_gear_active(eq, "head")
	var has_shoulders = _is_gear_active(eq, "shoulders")
	var has_cape = _is_gear_active(eq, "cape")
	var has_shield = _is_gear_active(eq, "weapon_off")
	var has_wings = _is_gear_active(eq, "wings")
	var has_pet = _is_gear_active(eq, "pet")
	var has_weapon = _is_gear_active(eq, "weapon_main")

	if helm_mesh: helm_mesh.visible = has_head
	if pauldrons_mesh: pauldrons_mesh.visible = has_shoulders
	if cape_mesh: cape_mesh.visible = has_cape
	if shield_mesh: shield_mesh.visible = has_shield
	if wings_root: wings_root.visible = has_wings and not is_mounted
	if dragon_pet: dragon_pet.visible = has_pet

	for wn in _weapon_mesh_nodes:
		if wn and is_instance_valid(wn):
			wn.visible = has_weapon

func _is_gear_active(gear: Dictionary, slot_key: String) -> bool:
	if not gear.has(slot_key):
		return false
	var val = gear[slot_key]
	if val is Dictionary:
		return val.get("id", "").strip_edges() != ""
	elif val is String:
		return val.strip_edges() != ""
	return false

func use_potion(pid: String) -> bool:
	if not stats:
		return false
	var pot_key = "potion_hp" if pid == "potion_health" else "potion_mp"
	if skill_cooldowns.get(pot_key, 0.0) > 0.0:
		return false
	for i in stats.bag.size():
		if not stats.bag[i].is_empty() and stats.bag[i]["id"] == pid:
			var msg = stats.use_bag_item(i)
			if msg != "":
				skill_cooldowns[pot_key] = SKILL_MAX_COOLDOWNS[pot_key]
				FloatingCombatText.spawn(get_tree(), global_position + Vector3(0, 1.2, 0), msg, FloatingCombatText.TextType.LOOT)
				GameAudio.play_potion(get_tree())
				return true
			break
	var potion_name = "Vida" if pid == "potion_health" else "Mana"
	FloatingCombatText.spawn(get_tree(), global_position + Vector3(0, 1.2, 0), "Sem poções de %s!" % potion_name, FloatingCombatText.TextType.NORMAL)
	return false

func cast_skill(slot: int) -> void:
	if is_attacking or not stats:
		return

	if skill_cooldowns.get(slot, 0.0) > 0.0:
		FloatingCombatText.spawn(get_tree(), global_position + Vector3(0, 1.4, 0), "⏳ Recarga: %.1fs" % skill_cooldowns[slot], FloatingCombatText.TextType.NORMAL)
		GameAudio.am(get_tree(), "play_ui", ["click"])
		return

	match slot:
		1: # [1] Brisingr (Chamas Azuis do Dragão)
			if not stats.consume_mana(35.0):
				FloatingCombatText.spawn(get_tree(), global_position + Vector3(0, 1.2, 0), "Mana Insuficiente! (35 MP)", FloatingCombatText.TextType.DAMAGE_TAKEN)
				GameAudio.am(get_tree(), "play_no_mana")
				return
			skill_cooldowns[1] = _skill_cooldown(1)
			skill_cast.emit(1)
			is_attacking = true
			GameAudio.play_player_exert(get_tree(), 1)
			GameAudio.am(get_tree(), "play_spell", [1])
			var forward_dir = get_aim_dir()
			face_direction(forward_dir)
			CombatVFX.spawn_cast_charge(get_tree(), global_position, Color(0.3, 0.85, 1.0), 0.18)
			CombatVFX.spawn_spell_flame(get_tree(), global_position, forward_dir)
			CombatVFX.trigger_screen_shake(get_tree(), 0.28)

			# Animação de conjuração e golpe de espada
			var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(visual_root, "rotation:y", visual_root.rotation.y + 0.45, 0.12)
			tween.tween_property(visual_root, "rotation:y", visual_root.rotation.y, 0.18)

			# Dano em área em cone frontal (até 8.5 metros)
			var base_dmg = stats.get_attack_damage() * 2.4
			var tree = get_tree()
			for mob in tree.get_nodes_in_group("enemies"):
				if mob is EnemyMob:
					var to_mob = mob.global_position - global_position
					var dist = to_mob.length()
					if dist <= 8.5:
						var dot = forward_dir.dot(to_mob.normalized())
						if dot >= 0.25: # Dentro do cone frontal de 150 graus
							var dmg = base_dmg * (1.0 - (dist / 12.0))
							mob.take_damage(dmg)

			FloatingCombatText.spawn(get_tree(), global_position + Vector3(0, 1.6, 0), "🔥 BRISINGR!", FloatingCombatText.TextType.CRITICAL)
			await get_tree().create_timer(0.3).timeout
			is_attacking = false

		2: # [2] Jierda (Impacto Sísmico de Solo)
			if not stats.consume_mana(50.0):
				FloatingCombatText.spawn(get_tree(), global_position + Vector3(0, 1.2, 0), "Mana Insuficiente! (50 MP)", FloatingCombatText.TextType.DAMAGE_TAKEN)
				GameAudio.am(get_tree(), "play_no_mana")
				return
			skill_cooldowns[2] = _skill_cooldown(2)
			skill_cast.emit(2)
			is_attacking = true
			GameAudio.play_player_exert(get_tree(), 2)
			GameAudio.am(get_tree(), "play_spell", [2])
			CombatVFX.spawn_cast_charge(get_tree(), global_position, Color(0.3, 0.95, 0.6), 0.15)
			CombatVFX.spawn_shockwave_ring(get_tree(), global_position, 8.5)
			CombatVFX.trigger_screen_shake(get_tree(), 0.48)

			# Salto e impacto no solo
			var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(visual_root, "position:y", 0.35, 0.1)
			tween.tween_property(visual_root, "position:y", 0.0, 0.12)

			# Dano radial de 360 graus em até 8.5 metros
			var base_dmg = stats.get_attack_damage() * 3.2
			for mob in get_tree().get_nodes_in_group("enemies"):
				if mob is EnemyMob:
					var dist = global_position.distance_to(mob.global_position)
					if dist <= 8.5:
						var push = (mob.global_position - global_position).normalized() * 5.0
						mob.velocity += push
						mob.take_damage(base_dmg)

			FloatingCombatText.spawn(get_tree(), global_position + Vector3(0, 1.6, 0), "⚡ JIERDA!", FloatingCombatText.TextType.CRITICAL)
			await get_tree().create_timer(0.32).timeout
			is_attacking = false

		3: # [3] Vórtice de Sylveria
			if not stats.consume_mana(75.0):
				FloatingCombatText.spawn(get_tree(), global_position + Vector3(0, 1.2, 0), "Mana Insuficiente! (75 MP)", FloatingCombatText.TextType.DAMAGE_TAKEN)
				GameAudio.am(get_tree(), "play_no_mana")
				return
			skill_cooldowns[3] = _skill_cooldown(3)
			skill_cast.emit(3)
			is_attacking = true
			GameAudio.play_player_exert(get_tree(), 2)
			var forward_dir = get_aim_dir()
			face_direction(forward_dir)
			var aim_pt = get_cursor_ground_point()
			var vortex_center = global_position + forward_dir * 4.2
			if aim_pt != null:
				var off: Vector3 = aim_pt - global_position
				off.y = 0.0
				vortex_center = global_position + off.limit_length(9.0)
				vortex_center.y = global_position.y
			GameAudio.am(get_tree(), "play_spell", [3])
			CombatVFX.spawn_cast_charge(get_tree(), global_position, Color(0.7, 0.3, 1.0), 0.2)
			CombatVFX.spawn_vortex_effect(get_tree(), vortex_center, 2.5)
			CombatVFX.trigger_screen_shake(get_tree(), 0.35)

			# Puxa inimigos para o vórtice e causa dano
			var base_dmg = stats.get_attack_damage() * 4.0
			for mob in get_tree().get_nodes_in_group("enemies"):
				if mob is EnemyMob:
					var dist = vortex_center.distance_to(mob.global_position)
					if dist <= 7.0:
						var pull = (vortex_center - mob.global_position).normalized() * 4.0
						mob.velocity += pull
						mob.take_damage(base_dmg)

			FloatingCombatText.spawn(get_tree(), global_position + Vector3(0, 1.6, 0), "🌀 VÓRTICE!", FloatingCombatText.TextType.CRITICAL)
			await get_tree().create_timer(0.35).timeout
			is_attacking = false

func toggle_dragon_mount() -> void:
	if not dragon_mount:
		return

	is_mounted = !is_mounted
	if is_mounted:
		wings_root.visible = false
		GameAudio.am(get_tree(), "play_dragon_roar")
		dragon_mount.mount()
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var target_saddle = dragon_mount.get_saddle_local_position()
		tween.tween_property(body_mesh, "position", target_saddle, 0.3)
	else:
		dragon_mount.dismount()
		update_equipment_visuals()
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(body_mesh, "position", Vector3.ZERO, 0.25)
		tween.tween_property(body_mesh, "rotation", Vector3.ZERO, 0.25)

func trigger_dash() -> void:
	if dash_cooldown <= 0.0 and skill_cooldowns.get("dash", 0.0) <= 0.0 and not is_mounted:
		is_dashing = true
		dash_timer = 0.26
		dash_cooldown = _skill_cooldown("dash")
		skill_cooldowns["dash"] = dash_cooldown
		skill_cast.emit(0)
		GameAudio.play_dash(get_tree())
		GameAudio.play_player_exert(get_tree(), 1)
		CombatVFX.spawn_dash_ghost(get_tree(), global_position, visual_root.rotation.y)
		CombatVFX.spawn_dust_puff(get_tree(), global_position, 8, 0.6)
		CombatVFX.trigger_screen_shake(get_tree(), 0.12)

func _physics_process(delta: float) -> void:
	if _is_dead:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= 9.8 * delta
		move_and_slide()
		return

	# Atualizar posição global para desobstrução de visão nos shaders de árvores e cenário
	RenderingServer.global_shader_parameter_set("player_world_pos", global_position)

	# Atualizar contadores e cooldowns
	if dash_cooldown > 0.0:
		dash_cooldown -= delta
	for k in skill_cooldowns.keys():
		if skill_cooldowns[k] > 0.0:
			skill_cooldowns[k] = max(0.0, skill_cooldowns[k] - delta)
	skill_cooldowns["dash"] = max(0.0, dash_cooldown)

	if is_dashing:
		dash_timer -= delta
		if fmod(dash_timer, 0.08) < delta:
			CombatVFX.spawn_dash_ghost(get_tree(), global_position, visual_root.rotation.y)
		if dash_timer <= 0.0:
			is_dashing = false

	if combo_reset_timer > 0.0:
		combo_reset_timer -= delta
		if combo_reset_timer <= 0.0:
			combo_step = 0

	# 1. Determinar Direção Desejada (WASD / setas têm prioridade; senão segue o destino clicado)
	var move_dir = Vector3.ZERO
	var key_x := Input.get_axis("move_left", "move_right")
	var key_z := Input.get_axis("move_forward", "move_back")
	# Ações digitais: normaliza o eixo para não ganhar velocidade na diagonal
	if absf(key_x) > 0.01 and absf(key_z) > 0.01:
		key_x *= 0.7071
		key_z *= 0.7071

	# Segurar o botão esquerdo continua guiando o herói até o cursor (estilo Diablo)
	if _hold_move:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_hold_move = false
		else:
			_hold_refresh -= delta
			if _hold_refresh <= 0.0:
				_hold_refresh = 0.05
				var gp = get_cursor_ground_point()
				if gp != null:
					target_position = gp
					is_moving_to_target = true
					click_marker.global_position = gp + Vector3(0, 0.06, 0)
					click_marker.visible = true

	var travel_dist := 0.0
	if key_x != 0.0 or key_z != 0.0:
		is_moving_to_target = false
		_hold_move = false
		click_marker.visible = false
		move_dir = Vector3(key_x, 0, key_z).normalized()
	elif is_moving_to_target:
		var diff = target_position - global_position
		diff.y = 0.0
		travel_dist = diff.length()
		if travel_dist > 0.3:
			move_dir = diff.normalized()
		else:
			is_moving_to_target = false
			click_marker.visible = false

	# Esquiva sem direção explícita: avança para onde o herói está olhando
	if is_dashing and move_dir.length_squared() < 0.01:
		move_dir = get_facing_dir()

	# Correr: Ctrl pressionado, ou destino distante (viagens longas pelo mapa grande)
	is_sprinting = Input.is_action_pressed("sprint") or travel_dist > auto_run_distance

	# 2. Calcular Velocidade Alvo (desacelera suavemente ao chegar no destino para não "passar direto")
	var target_speed = walk_speed
	if is_mounted:
		target_speed = dragon_speed
	elif is_dashing:
		target_speed = dash_speed
	elif is_sprinting:
		target_speed = run_speed
	if travel_dist > 0.0 and travel_dist < 2.2 and not is_dashing:
		target_speed *= clamp(travel_dist / 2.2, 0.35, 1.0)

	var target_velocity_horiz = move_dir * target_speed
	var current_horiz = Vector3(velocity.x, 0, velocity.z)

	# 3. Inércia com Curva de Aceleração e Frenagem Realista
	var accel_rate = acceleration if move_dir.length_squared() > 0.01 else friction
	var next_horiz = current_horiz.move_toward(target_velocity_horiz, accel_rate * delta)
	velocity.x = next_horiz.x
	velocity.z = next_horiz.z

	# Gravidade com queda mais pesada
	if not is_on_floor():
		velocity.y -= 22.0 * delta
		_air_speed_y = velocity.y

	move_and_slide()

	# Pouso: esmagamento do corpo + nuvem de poeira
	var on_floor_now := is_on_floor()
	if on_floor_now and not _was_on_floor and _air_speed_y < -5.0:
		var impact: float = clamp(-_air_speed_y / 14.0, 0.3, 1.0)
		CombatVFX.spawn_dust_puff(get_tree(), global_position, int(8 + impact * 8), 0.7)
		GameAudio.am(get_tree(), "play_land", [impact])
		var land_tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		land_tw.tween_property(visual_root, "scale", Vector3(1.0 + 0.12 * impact, 1.0 - 0.16 * impact, 1.0 + 0.12 * impact), 0.07)
		land_tw.tween_property(visual_root, "scale", Vector3.ONE, 0.18)
		if impact > 0.8:
			CombatVFX.trigger_screen_shake(get_tree(), 0.1)
	_was_on_floor = on_floor_now

	# Poeira dos passos ao correr / dragão levantando terra em voo rasante
	var planar_speed := Vector2(velocity.x, velocity.z).length()
	if on_floor_now and planar_speed > run_speed * 0.8 and not is_mounted:
		_dust_timer -= delta
		if _dust_timer <= 0.0:
			_dust_timer = 0.16
			CombatVFX.spawn_dust_puff(get_tree(), global_position, 3, 0.25)
	elif is_mounted and planar_speed > dragon_speed * 0.5:
		_dust_timer -= delta
		if _dust_timer <= 0.0:
			_dust_timer = 0.12
			CombatVFX.spawn_dust_puff(get_tree(), global_position - get_facing_dir() * 1.5, 4, 0.9, Color(0.55, 0.62, 0.5, 0.4))

	# 4. Rotação Orgânica & Curva de Ângulo
	var horiz_speed = next_horiz.length()
	var effective_turn_speed = turn_speed if not is_mounted else turn_speed * 0.75

	if horiz_speed > 0.2 and not is_attacking:
		var desired_angle = atan2(velocity.x, velocity.z)
		var angle_diff = wrapf(desired_angle - last_facing_angle, -PI, PI)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, desired_angle, effective_turn_speed * delta)
		last_facing_angle = visual_root.rotation.y

		# Banking / Inclinação de Curva (Leaning)
		var bank_target = clamp(-angle_diff * 1.5, -0.32, 0.32)
		current_bank_angle = lerp(current_bank_angle, bank_target, 8.0 * delta)
	else:
		current_bank_angle = lerp(current_bank_angle, 0.0, 6.0 * delta)

	# Pitch de Aceleração
	var accel_force = (target_velocity_horiz.length() - horiz_speed) / max(target_speed, 1.0)
	var target_pitch = clamp(accel_force * 0.12, -0.15, 0.15)
	current_pitch_angle = lerp(current_pitch_angle, target_pitch, 8.0 * delta)

	visual_root.rotation.z = current_bank_angle
	visual_root.rotation.x = current_pitch_angle

	# 5. Locomoção Procedural (Passos / Bobbing)
	_apply_procedural_locomotion(horiz_speed, target_speed, delta)

	# 6. Atualizar Dragão se montado e atrelar herói milimetricamente à sela
	if is_mounted and dragon_mount:
		dragon_mount.update_animation(horiz_speed, dragon_speed, delta)
		var saddle_pos = dragon_mount.get_saddle_local_position()
		var saddle_rot = dragon_mount.get_saddle_local_rotation()
		body_mesh.position = saddle_pos
		body_mesh.rotation.z = saddle_rot.z * 0.95
		body_mesh.rotation.x = saddle_rot.x - 0.08 # postura de rédeas / montaria inclinada para frente
		body_mesh.rotation.y = saddle_rot.y

	# 7. Pulsação Mística da Gedwëy Ignasia
	_update_gedwey_ignasia()

	# 8. Animação Flutuante do Pet Companheiro
	if dragon_pet:
		dragon_pet.position.y = 1.35 + sin(Time.get_ticks_msec() / 350.0) * 0.08
		dragon_pet.rotation.y = sin(Time.get_ticks_msec() / 600.0) * 0.15

## Superfície sob o herói para escolher o som dos passos: pedra (praça/estradas), terra (áridas) ou grama
func _ground_surface() -> String:
	var p := Vector2(global_position.x, global_position.z)
	if p.length() < 13.0:
		return "stone"
	if _map_builder == null or not is_instance_valid(_map_builder):
		_map_builder = get_tree().get_first_node_in_group("map_builder")
	if _map_builder:
		if _map_builder.has_method("_near_road") and _map_builder._near_road(p, 2.4):
			return "stone"
		var b: String = _map_builder.biome_at(p)
		if b == "west" or b == "south_east":
			return "dirt"
	return "grass"

func _apply_procedural_locomotion(speed: float, max_speed: float, delta: float) -> void:
	var base_y = 0.0
	if is_mounted:
		body_mesh.position.x = 0.0
		_reset_limbs_mounted()
		# Batidas de asa audíveis quando o dragão voa
		if speed > 2.0:
			_flap_timer -= delta
			if _flap_timer <= 0.0:
				_flap_timer = clamp(0.9 - speed / 60.0, 0.45, 0.9)
				GameAudio.am(get_tree(), "play_wing_flap", [-6.0 + clamp(speed / 10.0, 0.0, 4.0)])
		return

	# Bater de asas majestoso das asas de cristal
	_update_wings_animation(speed, delta)

	if speed > 0.4:
		var freq = 11.0 if is_sprinting else 8.5
		step_cycle += delta * freq
		# Um passo audível a cada meio ciclo (pico do bobbing) quando no chão
		if is_on_floor():
			var idx := int(step_cycle / PI)
			if idx != _step_idx:
				_step_idx = idx
				GameAudio.am(get_tree(), "play_step", [_ground_surface(), -3.0 if is_sprinting else -6.0])
		var bob_amp = 0.04 if not is_sprinting else 0.07
		body_mesh.position.y = base_y + abs(sin(step_cycle)) * bob_amp
		body_mesh.position.x = sin(step_cycle * 0.5) * 0.025

		# Articulação anatômica procedural de pernas e braços
		_animate_limbs_locomotion(speed, delta)
	else:
		var breath = sin(Time.get_ticks_msec() / 600.0) * 0.015
		body_mesh.position.y = lerp(body_mesh.position.y, base_y + breath, 6.0 * delta)
		body_mesh.position.x = lerp(body_mesh.position.x, 0.0, 6.0 * delta)
		_animate_limbs_idle(delta)

func _setup_limbs() -> void:
	if not body_mesh:
		return
	var limb_names = [
		"Thigh_-1", "Greave_-1", "Sabaton_-1", "Icosphere_002",
		"Thigh_1", "Greave_1", "Sabaton_1", "Icosphere_003",
		"LeftUpperArm", "LeftForearm",
		"RightUpperArm", "RightForearm",
		"BrisingrGrip", "BrisingrBlade", "BrisingrGuardL", "BrisingrGuardR",
		"Cape", "Shield"
	]
	for n in limb_names:
		var node = body_mesh.get_node_or_null(n)
		if node:
			_limbs[n] = {
				"node": node,
				"base_pos": node.position,
				"base_rot": node.rotation
			}
	if wings_root:
		_wings_base_rot = wings_root.rotation
		_wings_base_scale = wings_root.scale

	_weapon_mesh_nodes.clear()
	for wn in ["BrisingrBlade", "BrisingrGuardL", "BrisingrGuardR", "BrisingrGrip", "Icosphere_006"]:
		var w_node = body_mesh.get_node_or_null(wn)
		if w_node:
			_weapon_mesh_nodes.append(w_node)

func _reset_limbs_mounted() -> void:
	for k in _limbs.keys():
		var l = _limbs[k]
		l.node.rotation = l.base_rot
		l.node.position = l.base_pos

func _animate_limbs_locomotion(speed: float, delta: float) -> void:
	var swing = sin(step_cycle)
	var leg_amp = 0.45 if not is_sprinting else 0.65
	var arm_amp = 0.35 if not is_sprinting else 0.55

	# Perna Esquerda (Thigh_-1, Greave_-1)
	if _limbs.has("Thigh_-1"):
		var l = _limbs["Thigh_-1"]
		l.node.rotation.x = lerp(l.node.rotation.x, l.base_rot.x + swing * leg_amp, 14.0 * delta)
		l.node.position.z = lerp(l.node.position.z, l.base_pos.z - swing * 0.06, 14.0 * delta)
	if _limbs.has("Greave_-1"):
		var l = _limbs["Greave_-1"]
		var knee_bend = max(0.0, -swing) * (leg_amp * 0.8)
		l.node.rotation.x = lerp(l.node.rotation.x, l.base_rot.x + knee_bend, 14.0 * delta)
		l.node.position.z = lerp(l.node.position.z, l.base_pos.z - swing * 0.05, 14.0 * delta)

	# Perna Direita (Thigh_1, Greave_1)
	if _limbs.has("Thigh_1"):
		var l = _limbs["Thigh_1"]
		l.node.rotation.x = lerp(l.node.rotation.x, l.base_rot.x - swing * leg_amp, 14.0 * delta)
		l.node.position.z = lerp(l.node.position.z, l.base_pos.z + swing * 0.06, 14.0 * delta)
	if _limbs.has("Greave_1"):
		var l = _limbs["Greave_1"]
		var knee_bend = max(0.0, swing) * (leg_amp * 0.8)
		l.node.rotation.x = lerp(l.node.rotation.x, l.base_rot.x + knee_bend, 14.0 * delta)
		l.node.position.z = lerp(l.node.position.z, l.base_pos.z + swing * 0.05, 14.0 * delta)

	# Braço Esquerdo (Escudo) - balanço em contra-fase
	if _limbs.has("LeftUpperArm"):
		var l = _limbs["LeftUpperArm"]
		l.node.rotation.x = lerp(l.node.rotation.x, l.base_rot.x - swing * arm_amp, 12.0 * delta)
	if _limbs.has("Shield"):
		var l = _limbs["Shield"]
		l.node.rotation.x = lerp(l.node.rotation.x, l.base_rot.x - swing * (arm_amp * 0.7), 12.0 * delta)

	# Braço Direito (Espada Brisingr) - quando não em ataque
	if not is_attacking:
		if _limbs.has("RightUpperArm"):
			var l = _limbs["RightUpperArm"]
			l.node.rotation.x = lerp(l.node.rotation.x, l.base_rot.x + swing * (arm_amp * 0.6), 12.0 * delta)
		if _limbs.has("BrisingrBlade"):
			var l = _limbs["BrisingrBlade"]
			l.node.rotation.x = lerp(l.node.rotation.x, l.base_rot.x + swing * 0.15, 10.0 * delta)

	# Capa ao vento
	if _limbs.has("Cape"):
		var l = _limbs["Cape"]
		var cape_flutter = sin(step_cycle * 2.0) * 0.12 - (speed / 14.0) * 0.35
		l.node.rotation.x = lerp(l.node.rotation.x, l.base_rot.x + cape_flutter, 10.0 * delta)

func _animate_limbs_idle(delta: float) -> void:
	var breath = sin(Time.get_ticks_msec() / 700.0)
	for k in _limbs.keys():
		var l = _limbs[k]
		if k.begins_with("Thigh") or k.begins_with("Greave") or k.begins_with("Sabaton"):
			l.node.rotation = l.node.rotation.lerp(l.base_rot, 8.0 * delta)
			l.node.position = l.node.position.lerp(l.base_pos, 8.0 * delta)
		elif k == "LeftUpperArm" or k == "RightUpperArm":
			var rot = l.base_rot
			rot.x += breath * 0.02
			l.node.rotation = l.node.rotation.lerp(rot, 6.0 * delta)
		elif k == "Cape":
			var rot = l.base_rot
			rot.x += breath * 0.05
			l.node.rotation = l.node.rotation.lerp(rot, 6.0 * delta)
		elif not is_attacking:
			l.node.rotation = l.node.rotation.lerp(l.base_rot, 8.0 * delta)
			l.node.position = l.node.position.lerp(l.base_pos, 8.0 * delta)

func _update_wings_animation(speed: float, delta: float) -> void:
	if not wings_root or not wings_root.visible:
		return
	var t = Time.get_ticks_msec() / 1000.0
	var flap_rate = 3.5 if speed < 0.4 else (6.0 if not is_sprinting else 8.5)
	var flap_amp = 0.12 if speed < 0.4 else (0.24 if not is_sprinting else 0.35)
	var flap_wave = sin(t * flap_rate)

	# Bater de asas harmônico com oscilação e expansão
	wings_root.rotation.x = _wings_base_rot.x + flap_wave * flap_amp
	wings_root.rotation.y = _wings_base_rot.y + cos(t * flap_rate * 0.5) * 0.05
	wings_root.scale.x = _wings_base_scale.x * (1.0 + flap_wave * 0.12)
	wings_root.scale.z = _wings_base_scale.z * (1.0 - flap_wave * 0.08)
	wings_root.position.y = 1.25 + sin(t * flap_rate) * 0.04

func _update_gedwey_ignasia() -> void:
	if gedwey_light:
		var pulse = (sin(Time.get_ticks_msec() / 400.0) + 1.0) * 0.5
		var base_energy = 0.5 if not is_mounted else 0.8
		gedwey_light.light_energy = base_energy + pulse * 0.3

func _update_weapon_glow() -> void:
	if gedwey_light and stats:
		var glow_energy = stats.get_weapon_glow_energy()
		gedwey_light.light_energy = 0.5 + glow_energy * 0.15
