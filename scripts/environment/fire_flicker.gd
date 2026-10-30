extends OmniLight3D
class_name FireFlickerLight

@export var base_energy: float = 1.6
@export var flicker_intensity: float = 0.35
@export var flicker_speed: float = 14.0

var _time_offset: float = 0.0

func _ready() -> void:
	_time_offset = randf() * 100.0

func _process(delta: float) -> void:
	var t = (Time.get_ticks_msec() / 1000.0) * flicker_speed + _time_offset
	# Combinação de senos com frequências não-harmônicas para ruído orgânico
	var noise = sin(t) * 0.5 + sin(t * 2.3) * 0.3 + cos(t * 3.7) * 0.2
	light_energy = base_energy + noise * flicker_intensity
