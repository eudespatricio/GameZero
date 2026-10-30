extends Node
## Registro central das ações de input (autoload `GameInput`).
##
## As ações são criadas em tempo de execução para manter o mapeamento versionado
## em código (fácil de revisar e testar) sem depender do editor. Trocar uma tecla
## aqui vale para o jogo inteiro — antes cada script comparava `event.keycode`.

const KEY_ACTIONS := {
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"sprint": [KEY_CTRL],
	"jump": [KEY_SPACE],
	"dash": [KEY_SHIFT],
	"attack": [KEY_F],
	"skill_1": [KEY_1],
	"skill_2": [KEY_2],
	"skill_3": [KEY_3],
	"potion_health": [KEY_Q],
	"potion_mana": [KEY_R],
	"mount": [KEY_Z],
	"toggle_inventory": [KEY_I, KEY_C],
	"toggle_map": [KEY_M],
	"cycle_character": [KEY_F2],
	"interact": [KEY_E],
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	register_actions()

func register_actions() -> void:
	for action in KEY_ACTIONS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode in KEY_ACTIONS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action, event)

## Nome da tecla principal de uma ação (usado pelas dicas da HUD).
static func key_label(action: String) -> String:
	var events := InputMap.action_get_events(action)
	if events.is_empty():
		return "?"
	var first := events[0]
	if first is InputEventKey:
		return OS.get_keycode_string((first as InputEventKey).physical_keycode)
	return "?"
