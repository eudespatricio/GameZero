extends Camera3D
class_name IsometricCamera

@export var target_node: Node3D
@export var follow_offset: Vector3 = Vector3(0.0, 14.0, 11.0)
@export var follow_speed: float = 6.5

# --- SISTEMA DE ZOOM COM SCROLL DO MOUSE ---
@export var min_zoom: float = 0.45   # Visão próxima e imersiva de ação
@export var max_zoom: float = 3.20   # Visão tática ampla (mapa grande)
var target_zoom: float = 1.0
var current_zoom: float = 1.0
var base_offset: Vector3 = Vector3(0.0, 14.0, 11.0)

# --- SISTEMA DE SCREEN SHAKE (DIABLO IV IMPACT FEEL) ---
var shake_intensity: float = 0.0
var shake_decay: float = 7.5
var shake_offset: Vector3 = Vector3.ZERO

# --- FOV DINÂMICO (SENSAÇÃO DE VELOCIDADE) ---
@export var base_fov: float = 38.0
@export var max_fov_boost: float = 7.0
var current_fov_boost: float = 0.0

# --- LEAD-AHEAD SUAVE (CÂMERA ANTECIPA O MOVIMENTO) ---
var current_lead: Vector3 = Vector3.ZERO
var lead_amount: float = 1.4

func _ready() -> void:
	add_to_group("camera")
	base_offset = follow_offset
	base_fov = fov
	far = 1500.0
	look_at_from_position(global_position, global_position + Vector3(0, -1, -0.8), Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
	# Scroll do mouse para zoom da câmera (aproximar e afastar)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = clamp(target_zoom - 0.12, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = clamp(target_zoom + 0.12, min_zoom, max_zoom)

	# Tecla de Atalho para Tela Cheia (F11 ou Alt+Enter)
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_F11 or (event.alt_pressed and event.keycode == KEY_ENTER):
			toggle_fullscreen()

## Alterna entre modo Janela e Tela Cheia Real
static func toggle_fullscreen() -> void:
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _physics_process(delta: float) -> void:
	if not target_node:
		return

	# 1. Interpolação suave do Zoom da câmera
	current_zoom = lerp(current_zoom, target_zoom, 9.0 * delta)
	# Ao aproximar, ajusta suavemente o ângulo de visão (mais rasante/cinematográfico)
	var dynamic_y = base_offset.y * pow(current_zoom, 0.92)
	var dynamic_z = base_offset.z * current_zoom
	var effective_offset = Vector3(base_offset.x, dynamic_y, dynamic_z)

	# 2. Lead-Ahead suave baseado na velocidade do jogador
	if target_node is CharacterBody3D:
		var vel = target_node.velocity
		var target_lead = Vector3(vel.x, 0, vel.z).normalized() * min(vel.length() / 8.0, 1.0) * lead_amount
		current_lead = current_lead.lerp(target_lead, 4.0 * delta)

	# 2b. FOV abre conforme a velocidade (corrida, dash, voo de dragão)
	if target_node is CharacterBody3D:
		var spd: float = Vector2(target_node.velocity.x, target_node.velocity.z).length()
		var boost_t: float = clamp((spd - 7.0) / 24.0, 0.0, 1.0)
		current_fov_boost = lerp(current_fov_boost, boost_t * max_fov_boost, 3.5 * delta)
		fov = base_fov + current_fov_boost

	# 3. Atualizar Screen Shake
	if shake_intensity > 0.0:
		shake_intensity = max(0.0, shake_intensity - shake_decay * delta)
		var rx = (randf() * 2.0 - 1.0) * shake_intensity
		var ry = (randf() * 2.0 - 1.0) * shake_intensity
		var rz = (randf() * 2.0 - 1.0) * shake_intensity
		shake_offset = Vector3(rx, ry, rz)
	else:
		shake_offset = Vector3.ZERO

	# 4. Interpolação de Posição
	var desired_pos = target_node.global_position + effective_offset + current_lead + shake_offset
	global_position = global_position.lerp(desired_pos, follow_speed * delta)

	# 5. Ponto focal dinâmico
	var look_target = target_node.global_position + Vector3(0, 1.1, 0) + (shake_offset * 0.4)
	look_at(look_target, Vector3.UP)

	# 6. Atualizar posições nos shaders globais (desobstrução de visão de árvores estilo Diablo IV)
	RenderingServer.global_shader_parameter_set("camera_world_pos", global_position)
	RenderingServer.global_shader_parameter_set("player_world_pos", target_node.global_position)

## Dispara tremor de impacto com intensidade e duração
func add_shake(intensity: float = 0.35, decay_speed: float = 8.0) -> void:
	shake_intensity = max(shake_intensity, intensity)
	shake_decay = decay_speed
