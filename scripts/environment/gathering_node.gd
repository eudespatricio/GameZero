extends Node3D
class_name GatheringNode

enum NodeType { BRIGHTSTEEL_ORE, MENOA_HERB }

@export var node_type: NodeType = NodeType.BRIGHTSTEEL_ORE
@export var resource_name: String = "Fragmentos de Brightsteel"
@export var resource_amount: int = 3
@export var respawn_time: float = 12.0

@onready var prompt_label: Label3D = $PromptLabel
@onready var visual_crystals: Node3D = $Visuals/Crystals
@onready var area_detect: Area3D = $Area3D

var player_in_range: bool = false
var is_harvested: bool = false

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false
		prompt_label.text = "[E] Coletar %s" % resource_name

	if area_detect:
		area_detect.body_entered.connect(_on_body_entered)
		area_detect.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body is Player and not is_harvested:
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		player_in_range = false
		if prompt_label:
			prompt_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and not is_harvested and event.is_action_pressed("interact"):
		harvest()

func harvest() -> void:
	is_harvested = true
	player_in_range = false
	if prompt_label:
		prompt_label.visible = false

	# Efeito Sonoro & Animação de Colheita
	GameAudio.play_gather(get_tree())
	FloatingCombatText.spawn(get_tree(), global_position + Vector3(0, 0.8, 0), "+%d %s" % [resource_amount, resource_name], FloatingCombatText.TextType.LOOT)

	# Efeito de tremor no nó
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_crystals, "scale", Vector3(1.3, 0.5, 1.3), 0.15)
	tween.tween_property(visual_crystals, "scale", Vector3.ZERO, 0.25)

	# Recompensa dada ao jogador
	var player = get_tree().get_first_node_in_group("player")
	if player and player.stats:
		player.stats.gold += 80 # Bônus de coleta

	# Temporizador de Renascimento
	var timer = get_tree().create_timer(respawn_time)
	await timer.timeout
	_respawn()

func _respawn() -> void:
	is_harvested = false
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_crystals, "scale", Vector3.ONE, 0.4)
