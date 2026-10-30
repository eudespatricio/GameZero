extends RefCounted
class_name MobsDatabase
## Bestiário: arquétipos de mobs/bosses por região (alinhado a zones_data.gd / world_map.gd).
## model: caminho do .glb | tint: multiplicador de cor | scale: escala do visual
## kind: "mob" | "mini_boss" | "world_boss"

const URGAL := "res://assets/models/urgal_warrior.glb"
# Modelo CC0 pronto em assets/models/cc0/wolf_cc0.glb (Fox riggado).
# Troca pendente de validação em jogo: basta apontar a linha abaixo para ele.
const WOLF := "res://assets/models/wolf_spine.glb"
const GOLEM := "res://assets/models/root_golem.glb"
const WRAITH := "res://assets/models/shade_wraith.glb"

static func get_all() -> Dictionary:
	return {
		# --- Região inicial (arredores do Santuário) ---
		"boar": {"name": "Javali da Floresta", "model": WOLF, "tint": Color(0.55, 0.38, 0.25), "scale": 0.8, "lvl": [1, 3],
			"kind": "mob", "behavior": 0, "speed": 4.4, "detect": 8.0, "drop_gold": 0.5},
		"wolf": {"name": "Lobo da Espinha", "model": WOLF, "tint": Color(1, 1, 1), "scale": 1.0, "lvl": [4, 7],
			"kind": "mob", "behavior": 1, "speed": 6.6, "detect": 13.0},
		"wolf_alpha": {"name": "Alfa Voraz da Espinha", "model": WOLF, "tint": Color(0.85, 0.9, 1.2), "scale": 1.9, "lvl": [8, 8],
			"kind": "mini_boss", "behavior": 2, "speed": 7.2, "detect": 16.0},
		# --- Estrada do Oeste: Terras Devastadas dos Kulls ---
		"urgal_raider": {"name": "Guerreiro Urgal Enfurecido", "model": URGAL, "tint": Color(1.1, 0.75, 0.7), "scale": 1.0, "lvl": [21, 24],
			"kind": "mob", "behavior": 1, "speed": 5.4, "detect": 14.0},
		"kull_young": {"name": "Kull Jovem", "model": URGAL, "tint": Color(0.7, 0.8, 1.0), "scale": 1.45, "lvl": [29, 34],
			"kind": "mob", "behavior": 1, "speed": 4.8, "detect": 14.0},
		"gromk": {"name": "Chefe do Clã Gromk", "model": URGAL, "tint": Color(1.2, 0.6, 0.45), "scale": 1.75, "lvl": [28, 28],
			"kind": "mini_boss", "behavior": 2, "speed": 5.0, "detect": 17.0},
		"garzhvog": {"name": "General Kull: Nar Garzhvog", "model": URGAL, "tint": Color(0.55, 0.6, 0.75), "scale": 2.4, "lvl": [35, 35],
			"kind": "world_boss", "behavior": 2, "speed": 5.0, "detect": 20.0},
		# --- Estrada do Norte: Du Weldenvarden ---
		"golem": {"name": "Golem de Raiz Antiga", "model": GOLEM, "tint": Color(1, 1, 1), "scale": 0.75, "lvl": [36, 39],
			"kind": "mob", "behavior": 1, "speed": 3.6, "detect": 12.0},
		"fanghur": {"name": "Fanghur das Sombras", "model": WRAITH, "tint": Color(0.8, 0.95, 1.2), "scale": 0.85, "lvl": [40, 43],
			"kind": "mob", "behavior": 1, "speed": 6.0, "detect": 15.0},
		"stone_guardian": {"name": "Guardião de Pedra Élfico", "model": GOLEM, "tint": Color(0.55, 0.62, 0.7), "scale": 1.35, "lvl": [42, 42],
			"kind": "mini_boss", "behavior": 2, "speed": 3.8, "detect": 16.0},
		"durza": {"name": "Durza, O Espectro", "model": WRAITH, "tint": Color(1.1, 0.6, 0.75), "scale": 1.7, "lvl": [50, 50],
			"kind": "world_boss", "behavior": 2, "speed": 6.4, "detect": 22.0},
		# --- Estrada Imperial: Urû'baen ---
		"oathsworn": {"name": "Soldado Juramentado", "model": URGAL, "tint": Color(0.75, 0.78, 0.9), "scale": 1.15, "lvl": [46, 49],
			"kind": "mob", "behavior": 1, "speed": 5.6, "detect": 15.0},
		"oathsworn_knight": {"name": "Cavaleiro Juramentado", "model": URGAL, "tint": Color(0.5, 0.55, 0.85), "scale": 1.7, "lvl": [48, 48],
			"kind": "mini_boss", "behavior": 2, "speed": 5.2, "detect": 17.0},
		"razac": {"name": "Ra'zac, O Caçador Alado", "model": WRAITH, "tint": Color(0.9, 1.1, 0.8), "scale": 1.9, "lvl": [52, 52],
			"kind": "world_boss", "behavior": 2, "speed": 6.8, "detect": 22.0},
		# --- Trilha dos Anões: Farthen Dûr ---
		"shade_scout": {"name": "Sombra de Durza", "model": WRAITH, "tint": Color(0.75, 0.9, 1.15), "scale": 0.95, "lvl": [45, 48],
			"kind": "mob", "behavior": 1, "speed": 6.0, "detect": 15.0},
		"tomb_warden": {"name": "Guardião da Tumba de Safira", "model": GOLEM, "tint": Color(0.5, 0.65, 1.3), "scale": 1.5, "lvl": [50, 50],
			"kind": "world_boss", "behavior": 2, "speed": 4.2, "detect": 20.0},
	}

## Constrói os parâmetros de combate escalados por nível/tipo.
static func build_stats(arch: Dictionary, level: int) -> Dictionary:
	var mult_hp := 1.0
	var mult_dmg := 1.0
	var mult_xp := 1.0
	match arch["kind"]:
		"mini_boss":
			mult_hp = 4.5; mult_dmg = 1.8; mult_xp = 6.0
		"world_boss":
			mult_hp = 10.0; mult_dmg = 2.4; mult_xp = 16.0
	return {
		"hp": (150.0 + level * 70.0) * mult_hp,
		"dmg": (150.0 + level * 30.0) * mult_dmg,
		"xp": int((60 + level * 28) * mult_xp),
		"gold": int((40 + level * 25) * mult_xp * arch.get("drop_gold", 1.0)),
	}
