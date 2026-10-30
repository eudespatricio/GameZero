extends Node3D
class_name DragonMount

@onready var visuals: Node3D = $Visuals
@onready var saphira_model: Node3D = $Visuals/SaphiraModel
@onready var breath_light: OmniLight3D = $Visuals/BreathLight
@onready var saddle_point: Marker3D = $Visuals/SaddlePoint

var wing_flap_time: float = 0.0
var is_active: bool = false

var _wing_left: Node3D
var _wing_right: Node3D
var _tail: Node3D
var _jaw: Node3D
var _wing_l_base_rot := Vector3.ZERO
var _wing_r_base_rot := Vector3.ZERO
var _tail_base_rot := Vector3.ZERO
var _jaw_base_rot := Vector3.ZERO

func _ready() -> void:
	visible = false
	if saphira_model:
		_wing_left = saphira_model.get_node_or_null("SaphiraWing_-1")
		_wing_right = saphira_model.get_node_or_null("SaphiraWing_1")
		_tail = saphira_model.get_node_or_null("TailFin")
		_jaw = saphira_model.get_node_or_null("LowerJaw")
		if _wing_left: _wing_l_base_rot = _wing_left.rotation
		if _wing_right: _wing_r_base_rot = _wing_right.rotation
		if _tail: _tail_base_rot = _tail.rotation
		if _jaw: _jaw_base_rot = _jaw.rotation

func get_saddle_local_position() -> Vector3:
	var vis_pos = visuals.position if visuals else Vector3.ZERO
	if saddle_point:
		return vis_pos + saddle_point.position
	return vis_pos + Vector3(0.0, 1.88, 0.18)

func get_saddle_local_rotation() -> Vector3:
	if visuals:
		return visuals.rotation
	return Vector3.ZERO

func mount() -> void:
	is_active = true
	visible = true
	scale = Vector3(0.1, 0.1, 0.1)
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3.ONE, 0.35)

func dismount() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.25)
	await tween.finished
	is_active = false
	visible = false
	scale = Vector3.ONE

func update_animation(current_speed: float, max_speed: float, delta: float) -> void:
	if not is_active:
		return

	var speed_ratio = clamp(current_speed / max_speed, 0.0, 1.5)
	var flap_speed = 3.0 + speed_ratio * 7.0
	wing_flap_time += delta * flap_speed

	# Arfagem, inclinação e ondulação de voo do dragão (flight bobbing & banking)
	if visuals:
		visuals.position.y = sin(wing_flap_time) * (0.09 + speed_ratio * 0.14)
		visuals.rotation.z = sin(wing_flap_time * 0.5) * (0.05 * speed_ratio)
		visuals.rotation.x = -speed_ratio * 0.04 + sin(wing_flap_time) * 0.02

	# Batimento majestoso das asas da Saphira
	var flap_amp = 0.32 + speed_ratio * 0.38
	var flap_wave = sin(wing_flap_time)
	if _wing_left:
		_wing_left.rotation.z = _wing_l_base_rot.z + flap_wave * flap_amp
		_wing_left.rotation.x = _wing_l_base_rot.x - flap_wave * 0.12
	if _wing_right:
		_wing_right.rotation.z = _wing_r_base_rot.z - flap_wave * flap_amp
		_wing_right.rotation.x = _wing_r_base_rot.x - flap_wave * 0.12

	if _tail:
		_tail.rotation.y = _tail_base_rot.y + sin(wing_flap_time * 0.6) * 0.22

	if _jaw:
		var jaw_wave = max(0.0, sin(wing_flap_time * 0.3)) * 0.15
		_jaw.rotation.x = _jaw_base_rot.x + jaw_wave
