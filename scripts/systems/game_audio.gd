extends RefCounted
class_name GameAudio

## Wrapper seguro para reprodução de efeitos sonoros através do autoload AudioManager
static func play(tree: SceneTree, method_name: String) -> void:
	if not tree or not tree.root:
		return
	if tree.root.has_node("AudioManager"):
		var am = tree.root.get_node("AudioManager")
		if am and am.has_method(method_name):
			am.call(method_name)

static func play_slash(tree: SceneTree) -> void:
	play(tree, "play_slash")

static func play_hit(tree: SceneTree) -> void:
	play(tree, "play_hit")

static func play_gather(tree: SceneTree) -> void:
	play(tree, "play_gather")

static func play_jewel(tree: SceneTree) -> void:
	play(tree, "play_jewel")

static func play_pickup(tree: SceneTree) -> void:
	play(tree, "play_jewel")

static func play_level_up(tree: SceneTree) -> void:
	play(tree, "play_level_up")

static func play_refine_success(tree: SceneTree) -> void:
	play(tree, "play_refine_success")

static func play_refine_fail(tree: SceneTree) -> void:
	play(tree, "play_refine_fail")


## Chamada genérica com argumentos ao AudioManager (ex.: GameAudio.am(tree, "play_spell", [1]))
static func am(tree: SceneTree, method_name: String, args: Array = []) -> void:
	if not tree or not tree.root:
		return
	if tree.root.has_node("AudioManager"):
		var node = tree.root.get_node("AudioManager")
		if node and node.has_method(method_name):
			node.callv(method_name, args)

## Som 3D de monstro/ambiente no ponto do mundo
static func mob(tree: SceneTree, sfx_name: String, pos: Vector3, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	am(tree, "play_mob", [sfx_name, pos, volume_db, pitch])

static func play_coin(tree: SceneTree) -> void:
	am(tree, "play_coin")

static func play_potion(tree: SceneTree) -> void:
	am(tree, "play_potion")

static func play_dash(tree: SceneTree) -> void:
	am(tree, "play_dash")

static func play_ui(tree: SceneTree, kind: String = "click") -> void:
	am(tree, "play_ui", [kind])

static func play_boss_roar(tree: SceneTree, pos: Vector3 = Vector3.ZERO) -> void:
	am(tree, "play_boss_roar", [pos])

static func play_boss_slam(tree: SceneTree, pos: Vector3 = Vector3.ZERO) -> void:
	am(tree, "play_boss_slam", [pos])

static func play_npc_bark(tree: SceneTree, npc_kind: String) -> void:
	am(tree, "play_npc_bark", [npc_kind])

static func play_player_exert(tree: SceneTree, level: int = 1) -> void:
	am(tree, "play_player_exert", [level])

static func play_player_victory(tree: SceneTree) -> void:
	am(tree, "play_player_victory")
