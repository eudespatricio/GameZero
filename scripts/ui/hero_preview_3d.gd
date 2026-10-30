extends Node3D
class_name HeroPreview3D

@onready var hero_pivot: Node3D = $HeroPivot
@onready var pet_pivot: Node3D = get_node_or_null("HeroPivot/PetPivot")
@onready var rim_light: OmniLight3D = get_node_or_null("RimLight")

var is_dragging: bool = false
var user_yaw_offset: float = -0.22
var time: float = 0.0

# Nós de Equipamento
var _helm_node: Node3D = null
var _pauldrons_node: Node3D = null
var _cape_node: Node3D = null
var _shield_node: Node3D = null
var _wings_node: Node3D = null
var _hero_model: Node3D = null
var _weapon_nodes: Array[Node3D] = []

func _ready() -> void:
	_cache_nodes()
	# Inicialmente oculta equipamentos extras até que dados reais sejam injetados
	update_visuals({}, "zero")

func _cache_nodes() -> void:
	if not hero_pivot:
		hero_pivot = get_node_or_null("HeroPivot")
	if hero_pivot:
		_hero_model = hero_pivot.get_node_or_null("HeroModel")
		if not pet_pivot:
			pet_pivot = hero_pivot.get_node_or_null("PetPivot")

	if _hero_model:
		_helm_node = _hero_model.get_node_or_null("Helm")
		_pauldrons_node = _hero_model.get_node_or_null("Pauldrons")
		_cape_node = _hero_model.get_node_or_null("Cape")
		_shield_node = _hero_model.get_node_or_null("Shield")
		_wings_node = _hero_model.get_node_or_null("Wings")

		_weapon_nodes.clear()
		for wn_name in ["BrisingrBlade", "BrisingrGuardL", "BrisingrGuardR", "BrisingrGrip", "Icosphere_006"]:
			var wn = _hero_model.get_node_or_null(wn_name)
			if wn:
				_weapon_nodes.append(wn)

func _process(delta: float) -> void:
	time += delta
	if not is_dragging and hero_pivot:
		# Oscilação nobre frontal estilo Diablo IV (mantém o herói de frente com leve movimento vivo)
		var idle_sway = sin(time * 1.1) * 0.16
		hero_pivot.rotation.y = lerp_angle(hero_pivot.rotation.y, user_yaw_offset + idle_sway, 4.0 * delta)

	if pet_pivot and pet_pivot.visible:
		pet_pivot.position.y = 1.38 + sin(time * 2.5) * 0.06
		pet_pivot.rotation.y = sin(time * 1.5) * 0.12

func rotate_hero(relative_x: float) -> void:
	if hero_pivot:
		user_yaw_offset += relative_x * 0.012
		hero_pivot.rotation.y = user_yaw_offset

## Sincroniza a visibilidade das malhas 3D com o inventário real do personagem
func update_visuals(equipped_gear: Dictionary, class_id: String = "zero") -> void:
	_cache_nodes()

	var has_head = _is_slot_equipped(equipped_gear, "head")
	var has_shoulders = _is_slot_equipped(equipped_gear, "shoulders")
	var has_cape = _is_slot_equipped(equipped_gear, "cape")
	var has_shield = _is_slot_equipped(equipped_gear, "weapon_off")
	var has_wings = _is_slot_equipped(equipped_gear, "wings")
	var has_pet = _is_slot_equipped(equipped_gear, "pet")
	var has_weapon = _is_slot_equipped(equipped_gear, "weapon_main")

	if _helm_node: _helm_node.visible = has_head
	if _pauldrons_node: _pauldrons_node.visible = has_shoulders
	if _cape_node: _cape_node.visible = has_cape
	if _shield_node: _shield_node.visible = has_shield
	if _wings_node: _wings_node.visible = has_wings
	if pet_pivot: pet_pivot.visible = has_pet

	for wn in _weapon_nodes:
		if wn and is_instance_valid(wn):
			wn.visible = has_weapon

	# Customização visual da Classe
	if _hero_model:
		match class_id:
			"arya":
				_hero_model.scale = Vector3(0.92, 0.98, 0.92)
				if rim_light: rim_light.light_color = Color(0.2, 0.95, 0.6)
			"roran":
				_hero_model.scale = Vector3(1.08, 0.96, 1.08)
				if rim_light: rim_light.light_color = Color(1.0, 0.6, 0.1)
			_:
				_hero_model.scale = Vector3(1.0, 1.0, 1.0)
				if rim_light: rim_light.light_color = Color(0.25, 0.75, 1.0)

func _is_slot_equipped(gear: Dictionary, slot_key: String) -> bool:
	if not gear.has(slot_key):
		return false
	var val = gear[slot_key]
	if val is Dictionary:
		return val.get("id", "").strip_edges() != ""
	elif val is String:
		return val.strip_edges() != ""
	return false
