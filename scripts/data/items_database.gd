extends RefCounted
class_name ItemsDatabase
## Catálogo Canônico de Itens, Sets, Asas, Capas e Joias do GameZero.

enum Rarity {
	COMMON,      # 0 Cinza (Ferro Rústico)
	MAGIC,       # 1 Verde (Imbuído com Ervas/Runas)
	RARE,        # 2 Azul (Aço Temperado)
	EPIC,        # 3 Roxo (Relíquias de Batalha)
	LEGENDARY,   # 4 Dourado (Brightsteel / Ouro Élfico)
	MYTHIC,      # 5 Vermelho / Mítico (Reis Cavaleiros)
	DIVINE       # 6 Rosa Prismático / Celestial (Origem Primordial)
}

enum ItemType {
	WEAPON,            # Arma Principal
	WEAPON_OFFHAND,    # Escudo / Orbe Secundário
	ARMOR_HEAD,        # Elmo
	ARMOR_SHOULDER,    # Ombreiras
	ARMOR_CHEST,       # Peitoral
	ARMOR_GLOVES,      # Luvas
	ARMOR_PANTS,       # Calças
	ARMOR_BOOTS,       # Botas
	CAPE,              # Capa
	WINGS,             # Asas
	AMULET,            # Colar / Amuleto
	RING,              # Anel
	MOUNT,             # Montaria (Dragão)
	PET,               # Pet Companheiro
	TOME,              # Livro de Habilidade
	JEWEL,             # Joias MU Online
	CONSUMABLE         # Poções e Pedras
}

## Cache do catálogo. Sem ele, cada consulta reconstruía ~250 dicionários
## literais — e havia 30 call sites, vários em caminho quente de combate.
static var _items_cache: Dictionary = {}

## Retorna o catálogo canônico de itens (somente leitura: não mutar o resultado).
static func get_all_items() -> Dictionary:
	if _items_cache.is_empty():
		_items_cache = _build_items()
	return _items_cache

static func _build_items() -> Dictionary:
	return {
		# --- JOIAS ESTILO MU ONLINE ---
		"jewel_bless": {
			"name": "💎 Joia da Bênção (Bless)",
			"type": ItemType.JEWEL,
			"rarity": Rarity.RARE,
			"description": "Aprimora equipamentos de +0 até +6 com 100% de sucesso. Emite sino cristalino lendário ao tocar o chão.",
			"value_gold": 5000,
			"glow_color": Color(0.2, 0.7, 1.0)
		},
		"jewel_soul": {
			"name": "🔮 Joia da Alma (Soul)",
			"type": ItemType.JEWEL,
			"rarity": Rarity.EPIC,
			"description": "Fragmento de alma de dragão ancestral. Necessária para refinos de +7 até +9.",
			"value_gold": 15000,
			"glow_color": Color(0.8, 0.3, 0.9)
		},
		"jewel_chaos": {
			"name": "🔥 Joia do Caos (Chaos)",
			"type": ItemType.JEWEL,
			"rarity": Rarity.EPIC,
			"description": "Energia elemental da Máquina do Caos. Essencial para criar Asas e elevar equipamentos de +10 a +15.",
			"value_gold": 25000,
			"glow_color": Color(1.0, 0.4, 0.1)
		},
		"jewel_creation": {
			"name": "💎 Joia da Criação (Creation)",
			"type": ItemType.JEWEL,
			"rarity": Rarity.LEGENDARY,
			"description": "Cristal puro que emana energia primordial do santuário de Sylveria.",
			"value_gold": 50000,
			"glow_color": Color(0.95, 0.85, 0.25)
		},

		# --- OS 21 SETS DE ARMADURA (6 PEÇAS POR SET) ---
		"helm_recruta_carvahall": {
			"name": "🪖 Elmo do Recruta de Carvahall",
			"type": ItemType.ARMOR_HEAD,
			"rarity": Rarity.COMMON,
			"class_req": "zero",
			"level_req": 1,
			"base_defense": 18,
			"magic_resist": 8,
			"set_name": "recruta_carvahall",
			"set_display_name": "do Recruta de Carvahall",
			"value_gold": 4500
		},
		"shoulders_recruta_carvahall": {
			"name": "🛡️ Ombreiras do Recruta de Carvahall",
			"type": ItemType.ARMOR_SHOULDER,
			"rarity": Rarity.COMMON,
			"class_req": "zero",
			"level_req": 1,
			"base_defense": 13,
			"magic_resist": 5,
			"set_name": "recruta_carvahall",
			"set_display_name": "do Recruta de Carvahall",
			"value_gold": 3375
		},
		"chest_recruta_carvahall": {
			"name": "🥋 Peitoral do Recruta de Carvahall",
			"type": ItemType.ARMOR_CHEST,
			"rarity": Rarity.COMMON,
			"class_req": "zero",
			"level_req": 1,
			"base_defense": 26,
			"magic_resist": 11,
			"set_name": "recruta_carvahall",
			"set_display_name": "do Recruta de Carvahall",
			"value_gold": 6525
		},
		"gloves_recruta_carvahall": {
			"name": "🧤 Luvas do Recruta de Carvahall",
			"type": ItemType.ARMOR_GLOVES,
			"rarity": Rarity.COMMON,
			"class_req": "zero",
			"level_req": 1,
			"base_defense": 12,
			"magic_resist": 5,
			"set_name": "recruta_carvahall",
			"set_display_name": "do Recruta de Carvahall",
			"value_gold": 3150
		},
		"pants_recruta_carvahall": {
			"name": "👖 Calças do Recruta de Carvahall",
			"type": ItemType.ARMOR_PANTS,
			"rarity": Rarity.COMMON,
			"class_req": "zero",
			"level_req": 1,
			"base_defense": 20,
			"magic_resist": 9,
			"set_name": "recruta_carvahall",
			"set_display_name": "do Recruta de Carvahall",
			"value_gold": 5175
		},
		"boots_recruta_carvahall": {
			"name": "🥾 Botas do Recruta de Carvahall",
			"type": ItemType.ARMOR_BOOTS,
			"rarity": Rarity.COMMON,
			"class_req": "zero",
			"level_req": 1,
			"base_defense": 14,
			"magic_resist": 6,
			"set_name": "recruta_carvahall",
			"set_display_name": "do Recruta de Carvahall",
			"value_gold": 3600
		},
		"helm_escudeiro_aco": {
			"name": "🪖 Elmo do Escudeiro de Aço",
			"type": ItemType.ARMOR_HEAD,
			"rarity": Rarity.MAGIC,
			"class_req": "zero",
			"level_req": 11,
			"base_defense": 45,
			"magic_resist": 20,
			"set_name": "escudeiro_aco",
			"set_display_name": "do Escudeiro de Aço",
			"value_gold": 9000
		},
		"shoulders_escudeiro_aco": {
			"name": "🛡️ Ombreiras do Escudeiro de Aço",
			"type": ItemType.ARMOR_SHOULDER,
			"rarity": Rarity.MAGIC,
			"class_req": "zero",
			"level_req": 11,
			"base_defense": 33,
			"magic_resist": 14,
			"set_name": "escudeiro_aco",
			"set_display_name": "do Escudeiro de Aço",
			"value_gold": 6750
		},
		"chest_escudeiro_aco": {
			"name": "🥋 Peitoral do Escudeiro de Aço",
			"type": ItemType.ARMOR_CHEST,
			"rarity": Rarity.MAGIC,
			"class_req": "zero",
			"level_req": 11,
			"base_defense": 65,
			"magic_resist": 29,
			"set_name": "escudeiro_aco",
			"set_display_name": "do Escudeiro de Aço",
			"value_gold": 13050
		},
		"gloves_escudeiro_aco": {
			"name": "🧤 Luvas do Escudeiro de Aço",
			"type": ItemType.ARMOR_GLOVES,
			"rarity": Rarity.MAGIC,
			"class_req": "zero",
			"level_req": 11,
			"base_defense": 31,
			"magic_resist": 13,
			"set_name": "escudeiro_aco",
			"set_display_name": "do Escudeiro de Aço",
			"value_gold": 6300
		},
		"pants_escudeiro_aco": {
			"name": "👖 Calças do Escudeiro de Aço",
			"type": ItemType.ARMOR_PANTS,
			"rarity": Rarity.MAGIC,
			"class_req": "zero",
			"level_req": 11,
			"base_defense": 51,
			"magic_resist": 22,
			"set_name": "escudeiro_aco",
			"set_display_name": "do Escudeiro de Aço",
			"value_gold": 10350
		},
		"boots_escudeiro_aco": {
			"name": "🥾 Botas do Escudeiro de Aço",
			"type": ItemType.ARMOR_BOOTS,
			"rarity": Rarity.MAGIC,
			"class_req": "zero",
			"level_req": 11,
			"base_defense": 36,
			"magic_resist": 16,
			"set_name": "escudeiro_aco",
			"set_display_name": "do Escudeiro de Aço",
			"value_gold": 7200
		},
		"helm_cavaleiro_fogo": {
			"name": "🪖 Elmo do Cavaleiro de Fogo",
			"type": ItemType.ARMOR_HEAD,
			"rarity": Rarity.RARE,
			"class_req": "zero",
			"level_req": 21,
			"base_defense": 85,
			"magic_resist": 38,
			"set_name": "cavaleiro_fogo",
			"set_display_name": "do Cavaleiro de Fogo",
			"value_gold": 13500
		},
		"shoulders_cavaleiro_fogo": {
			"name": "🛡️ Ombreiras do Cavaleiro de Fogo",
			"type": ItemType.ARMOR_SHOULDER,
			"rarity": Rarity.RARE,
			"class_req": "zero",
			"level_req": 21,
			"base_defense": 63,
			"magic_resist": 28,
			"set_name": "cavaleiro_fogo",
			"set_display_name": "do Cavaleiro de Fogo",
			"value_gold": 10125
		},
		"chest_cavaleiro_fogo": {
			"name": "🥋 Peitoral do Cavaleiro de Fogo",
			"type": ItemType.ARMOR_CHEST,
			"rarity": Rarity.RARE,
			"class_req": "zero",
			"level_req": 21,
			"base_defense": 123,
			"magic_resist": 55,
			"set_name": "cavaleiro_fogo",
			"set_display_name": "do Cavaleiro de Fogo",
			"value_gold": 19575
		},
		"gloves_cavaleiro_fogo": {
			"name": "🧤 Luvas do Cavaleiro de Fogo",
			"type": ItemType.ARMOR_GLOVES,
			"rarity": Rarity.RARE,
			"class_req": "zero",
			"level_req": 21,
			"base_defense": 59,
			"magic_resist": 26,
			"set_name": "cavaleiro_fogo",
			"set_display_name": "do Cavaleiro de Fogo",
			"value_gold": 9450
		},
		"pants_cavaleiro_fogo": {
			"name": "👖 Calças do Cavaleiro de Fogo",
			"type": ItemType.ARMOR_PANTS,
			"rarity": Rarity.RARE,
			"class_req": "zero",
			"level_req": 21,
			"base_defense": 97,
			"magic_resist": 43,
			"set_name": "cavaleiro_fogo",
			"set_display_name": "do Cavaleiro de Fogo",
			"value_gold": 15524
		},
		"boots_cavaleiro_fogo": {
			"name": "🥾 Botas do Cavaleiro de Fogo",
			"type": ItemType.ARMOR_BOOTS,
			"rarity": Rarity.RARE,
			"class_req": "zero",
			"level_req": 21,
			"base_defense": 68,
			"magic_resist": 30,
			"set_name": "cavaleiro_fogo",
			"set_display_name": "do Cavaleiro de Fogo",
			"value_gold": 10800
		},
		"helm_dragon_knight": {
			"name": "🪖 Elmo do Dragão Carmesim",
			"type": ItemType.ARMOR_HEAD,
			"rarity": Rarity.EPIC,
			"class_req": "zero",
			"level_req": 31,
			"base_defense": 140,
			"magic_resist": 63,
			"set_name": "dragon_knight",
			"set_display_name": "do Dragão Carmesim",
			"value_gold": 18000
		},
		"shoulders_dragon_knight": {
			"name": "🛡️ Ombreiras do Dragão Carmesim",
			"type": ItemType.ARMOR_SHOULDER,
			"rarity": Rarity.EPIC,
			"class_req": "zero",
			"level_req": 31,
			"base_defense": 105,
			"magic_resist": 47,
			"set_name": "dragon_knight",
			"set_display_name": "do Dragão Carmesim",
			"value_gold": 13500
		},
		"chest_dragon_knight": {
			"name": "🥋 Peitoral do Dragão Carmesim",
			"type": ItemType.ARMOR_CHEST,
			"rarity": Rarity.EPIC,
			"class_req": "zero",
			"level_req": 31,
			"base_defense": 203,
			"magic_resist": 91,
			"set_name": "dragon_knight",
			"set_display_name": "do Dragão Carmesim",
			"value_gold": 26100
		},
		"gloves_dragon_knight": {
			"name": "🧤 Luvas do Dragão Carmesim",
			"type": ItemType.ARMOR_GLOVES,
			"rarity": Rarity.EPIC,
			"class_req": "zero",
			"level_req": 31,
			"base_defense": 98,
			"magic_resist": 44,
			"set_name": "dragon_knight",
			"set_display_name": "do Dragão Carmesim",
			"value_gold": 12600
		},
		"pants_dragon_knight": {
			"name": "👖 Calças do Dragão Carmesim",
			"type": ItemType.ARMOR_PANTS,
			"rarity": Rarity.EPIC,
			"class_req": "zero",
			"level_req": 31,
			"base_defense": 161,
			"magic_resist": 72,
			"set_name": "dragon_knight",
			"set_display_name": "do Dragão Carmesim",
			"value_gold": 20700
		},
		"boots_dragon_knight": {
			"name": "🥾 Botas do Dragão Carmesim",
			"type": ItemType.ARMOR_BOOTS,
			"rarity": Rarity.EPIC,
			"class_req": "zero",
			"level_req": 31,
			"base_defense": 112,
			"magic_resist": 50,
			"set_name": "dragon_knight",
			"set_display_name": "do Dragão Carmesim",
			"value_gold": 14400
		},
		"helm_soberano_sylveria": {
			"name": "🪖 Elmo do Soberano de Sylveria",
			"type": ItemType.ARMOR_HEAD,
			"rarity": Rarity.EPIC,
			"class_req": "zero",
			"level_req": 41,
			"base_defense": 210,
			"magic_resist": 94,
			"set_name": "soberano_sylveria",
			"set_display_name": "do Soberano de Sylveria",
			"value_gold": 22500
		},
		"shoulders_soberano_sylveria": {
			"name": "🛡️ Ombreiras do Soberano de Sylveria",
			"type": ItemType.ARMOR_SHOULDER,
			"rarity": Rarity.EPIC,
			"class_req": "zero",
			"level_req": 41,
			"base_defense": 157,
			"magic_resist": 70,
			"set_name": "soberano_sylveria",
			"set_display_name": "do Soberano de Sylveria",
			"value_gold": 16875
		},
		"chest_soberano_sylveria": {
			"name": "🥋 Peitoral do Soberano de Sylveria",
			"type": ItemType.ARMOR_CHEST,
			"rarity": Rarity.EPIC,
			"class_req": "zero",
			"level_req": 41,
			"base_defense": 304,
			"magic_resist": 136,
			"set_name": "soberano_sylveria",
			"set_display_name": "do Soberano de Sylveria",
			"value_gold": 32625
		},
		"gloves_soberano_sylveria": {
			"name": "🧤 Luvas do Soberano de Sylveria",
			"type": ItemType.ARMOR_GLOVES,
			"rarity": Rarity.EPIC,
			"class_req": "zero",
			"level_req": 41,
			"base_defense": 147,
			"magic_resist": 66,
			"set_name": "soberano_sylveria",
			"set_display_name": "do Soberano de Sylveria",
			"value_gold": 15749
		},
		"pants_soberano_sylveria": {
			"name": "👖 Calças do Soberano de Sylveria",
			"type": ItemType.ARMOR_PANTS,
			"rarity": Rarity.EPIC,
			"class_req": "zero",
			"level_req": 41,
			"base_defense": 241,
			"magic_resist": 108,
			"set_name": "soberano_sylveria",
			"set_display_name": "do Soberano de Sylveria",
			"value_gold": 25874
		},
		"boots_soberano_sylveria": {
			"name": "🥾 Botas do Soberano de Sylveria",
			"type": ItemType.ARMOR_BOOTS,
			"rarity": Rarity.EPIC,
			"class_req": "zero",
			"level_req": 41,
			"base_defense": 168,
			"magic_resist": 75,
			"set_name": "soberano_sylveria",
			"set_display_name": "do Soberano de Sylveria",
			"value_gold": 18000
		},
		"helm_primeiros_cavaleiros": {
			"name": "🪖 Elmo dos Primeiros Cavaleiros",
			"type": ItemType.ARMOR_HEAD,
			"rarity": Rarity.LEGENDARY,
			"class_req": "zero",
			"level_req": 1,
			"base_defense": 260,
			"magic_resist": 117,
			"set_name": "primeiros_cavaleiros",
			"set_display_name": "dos Primeiros Cavaleiros",
			"value_gold": 22500
		},
		"shoulders_primeiros_cavaleiros": {
			"name": "🛡️ Ombreiras dos Primeiros Cavaleiros",
			"type": ItemType.ARMOR_SHOULDER,
			"rarity": Rarity.LEGENDARY,
			"class_req": "zero",
			"level_req": 1,
			"base_defense": 195,
			"magic_resist": 87,
			"set_name": "primeiros_cavaleiros",
			"set_display_name": "dos Primeiros Cavaleiros",
			"value_gold": 16875
		},
		"chest_primeiros_cavaleiros": {
			"name": "🥋 Peitoral dos Primeiros Cavaleiros",
			"type": ItemType.ARMOR_CHEST,
			"rarity": Rarity.LEGENDARY,
			"class_req": "zero",
			"level_req": 1,
			"base_defense": 377,
			"magic_resist": 169,
			"set_name": "primeiros_cavaleiros",
			"set_display_name": "dos Primeiros Cavaleiros",
			"value_gold": 32625
		},
		"gloves_primeiros_cavaleiros": {
			"name": "🧤 Luvas dos Primeiros Cavaleiros",
			"type": ItemType.ARMOR_GLOVES,
			"rarity": Rarity.LEGENDARY,
			"class_req": "zero",
			"level_req": 1,
			"base_defense": 182,
			"magic_resist": 81,
			"set_name": "primeiros_cavaleiros",
			"set_display_name": "dos Primeiros Cavaleiros",
			"value_gold": 15749
		},
		"pants_primeiros_cavaleiros": {
			"name": "👖 Calças dos Primeiros Cavaleiros",
			"type": ItemType.ARMOR_PANTS,
			"rarity": Rarity.LEGENDARY,
			"class_req": "zero",
			"level_req": 1,
			"base_defense": 299,
			"magic_resist": 134,
			"set_name": "primeiros_cavaleiros",
			"set_display_name": "dos Primeiros Cavaleiros",
			"value_gold": 25874
		},
		"boots_primeiros_cavaleiros": {
			"name": "🥾 Botas dos Primeiros Cavaleiros",
			"type": ItemType.ARMOR_BOOTS,
			"rarity": Rarity.LEGENDARY,
			"class_req": "zero",
			"level_req": 1,
			"base_defense": 208,
			"magic_resist": 93,
			"set_name": "primeiros_cavaleiros",
			"set_display_name": "dos Primeiros Cavaleiros",
			"value_gold": 18000
		},
		"helm_cosmico_vermund": {
			"name": "🪖 Elmo Cósmico de Vermund",
			"type": ItemType.ARMOR_HEAD,
			"rarity": Rarity.DIVINE,
			"class_req": "zero",
			"level_req": 1,
			"base_defense": 340,
			"magic_resist": 153,
			"set_name": "cosmico_vermund",
			"set_display_name": "Cósmico de Vermund",
			"value_gold": 22500
		},
		"shoulders_cosmico_vermund": {
			"name": "🛡️ Ombreiras Cósmico de Vermund",
			"type": ItemType.ARMOR_SHOULDER,
			"rarity": Rarity.DIVINE,
			"class_req": "zero",
			"level_req": 1,
			"base_defense": 255,
			"magic_resist": 114,
			"set_name": "cosmico_vermund",
			"set_display_name": "Cósmico de Vermund",
			"value_gold": 16875
		},
		"chest_cosmico_vermund": {
			"name": "🥋 Peitoral Cósmico de Vermund",
			"type": ItemType.ARMOR_CHEST,
			"rarity": Rarity.DIVINE,
			"class_req": "zero",
			"level_req": 1,
			"base_defense": 493,
			"magic_resist": 221,
			"set_name": "cosmico_vermund",
			"set_display_name": "Cósmico de Vermund",
			"value_gold": 32625
		},
		"gloves_cosmico_vermund": {
			"name": "🧤 Luvas Cósmico de Vermund",
			"type": ItemType.ARMOR_GLOVES,
			"rarity": Rarity.DIVINE,
			"class_req": "zero",
			"level_req": 1,
			"base_defense": 237,
			"magic_resist": 106,
			"set_name": "cosmico_vermund",
			"set_display_name": "Cósmico de Vermund",
			"value_gold": 15749
		},
		"pants_cosmico_vermund": {
			"name": "👖 Calças Cósmico de Vermund",
			"type": ItemType.ARMOR_PANTS,
			"rarity": Rarity.DIVINE,
			"class_req": "zero",
			"level_req": 1,
			"base_defense": 390,
			"magic_resist": 175,
			"set_name": "cosmico_vermund",
			"set_display_name": "Cósmico de Vermund",
			"value_gold": 25874
		},
		"boots_cosmico_vermund": {
			"name": "🥾 Botas Cósmico de Vermund",
			"type": ItemType.ARMOR_BOOTS,
			"rarity": Rarity.DIVINE,
			"class_req": "zero",
			"level_req": 1,
			"base_defense": 272,
			"magic_resist": 122,
			"set_name": "cosmico_vermund",
			"set_display_name": "Cósmico de Vermund",
			"value_gold": 18000
		},
		"helm_rastreador_bosques": {
			"name": "🪖 Elmo do Rastreador dos Bosques",
			"type": ItemType.ARMOR_HEAD,
			"rarity": Rarity.COMMON,
			"class_req": "arya",
			"level_req": 1,
			"base_defense": 14,
			"magic_resist": 6,
			"set_name": "rastreador_bosques",
			"set_display_name": "do Rastreador dos Bosques",
			"value_gold": 4500
		},
		"shoulders_rastreador_bosques": {
			"name": "🛡️ Ombreiras do Rastreador dos Bosques",
			"type": ItemType.ARMOR_SHOULDER,
			"rarity": Rarity.COMMON,
			"class_req": "arya",
			"level_req": 1,
			"base_defense": 10,
			"magic_resist": 4,
			"set_name": "rastreador_bosques",
			"set_display_name": "do Rastreador dos Bosques",
			"value_gold": 3375
		},
		"chest_rastreador_bosques": {
			"name": "🥋 Peitoral do Rastreador dos Bosques",
			"type": ItemType.ARMOR_CHEST,
			"rarity": Rarity.COMMON,
			"class_req": "arya",
			"level_req": 1,
			"base_defense": 20,
			"magic_resist": 9,
			"set_name": "rastreador_bosques",
			"set_display_name": "do Rastreador dos Bosques",
			"value_gold": 6525
		},
		"gloves_rastreador_bosques": {
			"name": "🧤 Luvas do Rastreador dos Bosques",
			"type": ItemType.ARMOR_GLOVES,
			"rarity": Rarity.COMMON,
			"class_req": "arya",
			"level_req": 1,
			"base_defense": 9,
			"magic_resist": 4,
			"set_name": "rastreador_bosques",
			"set_display_name": "do Rastreador dos Bosques",
			"value_gold": 3150
		},
		"pants_rastreador_bosques": {
			"name": "👖 Calças do Rastreador dos Bosques",
			"type": ItemType.ARMOR_PANTS,
			"rarity": Rarity.COMMON,
			"class_req": "arya",
			"level_req": 1,
			"base_defense": 16,
			"magic_resist": 7,
			"set_name": "rastreador_bosques",
			"set_display_name": "do Rastreador dos Bosques",
			"value_gold": 5175
		},
		"boots_rastreador_bosques": {
			"name": "🥾 Botas do Rastreador dos Bosques",
			"type": ItemType.ARMOR_BOOTS,
			"rarity": Rarity.COMMON,
			"class_req": "arya",
			"level_req": 1,
			"base_defense": 11,
			"magic_resist": 4,
			"set_name": "rastreador_bosques",
			"set_display_name": "do Rastreador dos Bosques",
			"value_gold": 3600
		},
		"helm_patrulha_elfica": {
			"name": "🪖 Elmo da Patrulha Élfica",
			"type": ItemType.ARMOR_HEAD,
			"rarity": Rarity.MAGIC,
			"class_req": "arya",
			"level_req": 11,
			"base_defense": 36,
			"magic_resist": 16,
			"set_name": "patrulha_elfica",
			"set_display_name": "da Patrulha Élfica",
			"value_gold": 9000
		},
		"shoulders_patrulha_elfica": {
			"name": "🛡️ Ombreiras da Patrulha Élfica",
			"type": ItemType.ARMOR_SHOULDER,
			"rarity": Rarity.MAGIC,
			"class_req": "arya",
			"level_req": 11,
			"base_defense": 27,
			"magic_resist": 12,
			"set_name": "patrulha_elfica",
			"set_display_name": "da Patrulha Élfica",
			"value_gold": 6750
		},
		"chest_patrulha_elfica": {
			"name": "🥋 Peitoral da Patrulha Élfica",
			"type": ItemType.ARMOR_CHEST,
			"rarity": Rarity.MAGIC,
			"class_req": "arya",
			"level_req": 11,
			"base_defense": 52,
			"magic_resist": 23,
			"set_name": "patrulha_elfica",
			"set_display_name": "da Patrulha Élfica",
			"value_gold": 13050
		},
		"gloves_patrulha_elfica": {
			"name": "🧤 Luvas da Patrulha Élfica",
			"type": ItemType.ARMOR_GLOVES,
			"rarity": Rarity.MAGIC,
			"class_req": "arya",
			"level_req": 11,
			"base_defense": 25,
			"magic_resist": 11,
			"set_name": "patrulha_elfica",
			"set_display_name": "da Patrulha Élfica",
			"value_gold": 6300
		},
		"pants_patrulha_elfica": {
			"name": "👖 Calças da Patrulha Élfica",
			"type": ItemType.ARMOR_PANTS,
			"rarity": Rarity.MAGIC,
			"class_req": "arya",
			"level_req": 11,
			"base_defense": 41,
			"magic_resist": 18,
			"set_name": "patrulha_elfica",
			"set_display_name": "da Patrulha Élfica",
			"value_gold": 10350
		},
		"boots_patrulha_elfica": {
			"name": "🥾 Botas da Patrulha Élfica",
			"type": ItemType.ARMOR_BOOTS,
			"rarity": Rarity.MAGIC,
			"class_req": "arya",
			"level_req": 11,
			"base_defense": 28,
			"magic_resist": 12,
			"set_name": "patrulha_elfica",
			"set_display_name": "da Patrulha Élfica",
			"value_gold": 7200
		},
		"helm_sombras_weldenvarden": {
			"name": "🪖 Elmo das Sombras de Du Weldenvarden",
			"type": ItemType.ARMOR_HEAD,
			"rarity": Rarity.RARE,
			"class_req": "arya",
			"level_req": 21,
			"base_defense": 70,
			"magic_resist": 31,
			"set_name": "sombras_weldenvarden",
			"set_display_name": "das Sombras de Du Weldenvarden",
			"value_gold": 13500
		},
		"shoulders_sombras_weldenvarden": {
			"name": "🛡️ Ombreiras das Sombras de Du Weldenvarden",
			"type": ItemType.ARMOR_SHOULDER,
			"rarity": Rarity.RARE,
			"class_req": "arya",
			"level_req": 21,
			"base_defense": 52,
			"magic_resist": 23,
			"set_name": "sombras_weldenvarden",
			"set_display_name": "das Sombras de Du Weldenvarden",
			"value_gold": 10125
		},
		"chest_sombras_weldenvarden": {
			"name": "🥋 Peitoral das Sombras de Du Weldenvarden",
			"type": ItemType.ARMOR_CHEST,
			"rarity": Rarity.RARE,
			"class_req": "arya",
			"level_req": 21,
			"base_defense": 101,
			"magic_resist": 45,
			"set_name": "sombras_weldenvarden",
			"set_display_name": "das Sombras de Du Weldenvarden",
			"value_gold": 19575
		},
		"gloves_sombras_weldenvarden": {
			"name": "🧤 Luvas das Sombras de Du Weldenvarden",
			"type": ItemType.ARMOR_GLOVES,
			"rarity": Rarity.RARE,
			"class_req": "arya",
			"level_req": 21,
			"base_defense": 49,
			"magic_resist": 22,
			"set_name": "sombras_weldenvarden",
			"set_display_name": "das Sombras de Du Weldenvarden",
			"value_gold": 9450
		},
		"pants_sombras_weldenvarden": {
			"name": "👖 Calças das Sombras de Du Weldenvarden",
			"type": ItemType.ARMOR_PANTS,
			"rarity": Rarity.RARE,
			"class_req": "arya",
			"level_req": 21,
			"base_defense": 80,
			"magic_resist": 36,
			"set_name": "sombras_weldenvarden",
			"set_display_name": "das Sombras de Du Weldenvarden",
			"value_gold": 15524
		},
		"boots_sombras_weldenvarden": {
			"name": "🥾 Botas das Sombras de Du Weldenvarden",
			"type": ItemType.ARMOR_BOOTS,
			"rarity": Rarity.RARE,
			"class_req": "arya",
			"level_req": 21,
			"base_defense": 56,
			"magic_resist": 25,
			"set_name": "sombras_weldenvarden",
			"set_display_name": "das Sombras de Du Weldenvarden",
			"value_gold": 10800
		},
		"helm_prata_menoa": {
			"name": "🪖 Elmo da Lâmina de Prata de Menoa",
			"type": ItemType.ARMOR_HEAD,
			"rarity": Rarity.EPIC,
			"class_req": "arya",
			"level_req": 31,
			"base_defense": 115,
			"magic_resist": 51,
			"set_name": "prata_menoa",
			"set_display_name": "da Lâmina de Prata de Menoa",
			"value_gold": 18000
		},
		"shoulders_prata_menoa": {
			"name": "🛡️ Ombreiras da Lâmina de Prata de Menoa",
			"type": ItemType.ARMOR_SHOULDER,
			"rarity": Rarity.EPIC,
			"class_req": "arya",
			"level_req": 31,
			"base_defense": 86,
			"magic_resist": 38,
			"set_name": "prata_menoa",
			"set_display_name": "da Lâmina de Prata de Menoa",
			"value_gold": 13500
		},
		"chest_prata_menoa": {
			"name": "🥋 Peitoral da Lâmina de Prata de Menoa",
			"type": ItemType.ARMOR_CHEST,
			"rarity": Rarity.EPIC,
			"class_req": "arya",
			"level_req": 31,
			"base_defense": 166,
			"magic_resist": 74,
			"set_name": "prata_menoa",
			"set_display_name": "da Lâmina de Prata de Menoa",
			"value_gold": 26100
		},
		"gloves_prata_menoa": {
			"name": "🧤 Luvas da Lâmina de Prata de Menoa",
			"type": ItemType.ARMOR_GLOVES,
			"rarity": Rarity.EPIC,
			"class_req": "arya",
			"level_req": 31,
			"base_defense": 80,
			"magic_resist": 36,
			"set_name": "prata_menoa",
			"set_display_name": "da Lâmina de Prata de Menoa",
			"value_gold": 12600
		},
		"pants_prata_menoa": {
			"name": "👖 Calças da Lâmina de Prata de Menoa",
			"type": ItemType.ARMOR_PANTS,
			"rarity": Rarity.EPIC,
			"class_req": "arya",
			"level_req": 31,
			"base_defense": 132,
			"magic_resist": 59,
			"set_name": "prata_menoa",
			"set_display_name": "da Lâmina de Prata de Menoa",
			"value_gold": 20700
		},
		"boots_prata_menoa": {
			"name": "🥾 Botas da Lâmina de Prata de Menoa",
			"type": ItemType.ARMOR_BOOTS,
			"rarity": Rarity.EPIC,
			"class_req": "arya",
			"level_req": 31,
			"base_defense": 92,
			"magic_resist": 41,
			"set_name": "prata_menoa",
			"set_display_name": "da Lâmina de Prata de Menoa",
			"value_gold": 14400
		},
		"helm_nobreza_ellesmera": {
			"name": "🪖 Elmo da Nobreza de Ellesméra",
			"type": ItemType.ARMOR_HEAD,
			"rarity": Rarity.EPIC,
			"class_req": "arya",
			"level_req": 41,
			"base_defense": 175,
			"magic_resist": 78,
			"set_name": "nobreza_ellesmera",
			"set_display_name": "da Nobreza de Ellesméra",
			"value_gold": 22500
		},
		"shoulders_nobreza_ellesmera": {
			"name": "🛡️ Ombreiras da Nobreza de Ellesméra",
			"type": ItemType.ARMOR_SHOULDER,
			"rarity": Rarity.EPIC,
			"class_req": "arya",
			"level_req": 41,
			"base_defense": 131,
			"magic_resist": 58,
			"set_name": "nobreza_ellesmera",
			"set_display_name": "da Nobreza de Ellesméra",
			"value_gold": 16875
		},
		"chest_nobreza_ellesmera": {
			"name": "🥋 Peitoral da Nobreza de Ellesméra",
			"type": ItemType.ARMOR_CHEST,
			"rarity": Rarity.EPIC,
			"class_req": "arya",
			"level_req": 41,
			"base_defense": 253,
			"magic_resist": 113,
			"set_name": "nobreza_ellesmera",
			"set_display_name": "da Nobreza de Ellesméra",
			"value_gold": 32625
		},
		"gloves_nobreza_ellesmera": {
			"name": "🧤 Luvas da Nobreza de Ellesméra",
			"type": ItemType.ARMOR_GLOVES,
			"rarity": Rarity.EPIC,
			"class_req": "arya",
			"level_req": 41,
			"base_defense": 122,
			"magic_resist": 54,
			"set_name": "nobreza_ellesmera",
			"set_display_name": "da Nobreza de Ellesméra",
			"value_gold": 15749
		},
		"pants_nobreza_ellesmera": {
			"name": "👖 Calças da Nobreza de Ellesméra",
			"type": ItemType.ARMOR_PANTS,
			"rarity": Rarity.EPIC,
			"class_req": "arya",
			"level_req": 41,
			"base_defense": 201,
			"magic_resist": 90,
			"set_name": "nobreza_ellesmera",
			"set_display_name": "da Nobreza de Ellesméra",
			"value_gold": 25874
		},
		"boots_nobreza_ellesmera": {
			"name": "🥾 Botas da Nobreza de Ellesméra",
			"type": ItemType.ARMOR_BOOTS,
			"rarity": Rarity.EPIC,
			"class_req": "arya",
			"level_req": 41,
			"base_defense": 140,
			"magic_resist": 63,
			"set_name": "nobreza_ellesmera",
			"set_display_name": "da Nobreza de Ellesméra",
			"value_gold": 18000
		},
		"helm_rainha_islanzadi": {
			"name": "🪖 Elmo da Rainha Islanzadí",
			"type": ItemType.ARMOR_HEAD,
			"rarity": Rarity.LEGENDARY,
			"class_req": "arya",
			"level_req": 1,
			"base_defense": 220,
			"magic_resist": 99,
			"set_name": "rainha_islanzadi",
			"set_display_name": "da Rainha Islanzadí",
			"value_gold": 22500
		},
		"shoulders_rainha_islanzadi": {
			"name": "🛡️ Ombreiras da Rainha Islanzadí",
			"type": ItemType.ARMOR_SHOULDER,
			"rarity": Rarity.LEGENDARY,
			"class_req": "arya",
			"level_req": 1,
			"base_defense": 165,
			"magic_resist": 74,
			"set_name": "rainha_islanzadi",
			"set_display_name": "da Rainha Islanzadí",
			"value_gold": 16875
		},
		"chest_rainha_islanzadi": {
			"name": "🥋 Peitoral da Rainha Islanzadí",
			"type": ItemType.ARMOR_CHEST,
			"rarity": Rarity.LEGENDARY,
			"class_req": "arya",
			"level_req": 1,
			"base_defense": 319,
			"magic_resist": 143,
			"set_name": "rainha_islanzadi",
			"set_display_name": "da Rainha Islanzadí",
			"value_gold": 32625
		},
		"gloves_rainha_islanzadi": {
			"name": "🧤 Luvas da Rainha Islanzadí",
			"type": ItemType.ARMOR_GLOVES,
			"rarity": Rarity.LEGENDARY,
			"class_req": "arya",
			"level_req": 1,
			"base_defense": 154,
			"magic_resist": 69,
			"set_name": "rainha_islanzadi",
			"set_display_name": "da Rainha Islanzadí",
			"value_gold": 15749
		},
		"pants_rainha_islanzadi": {
			"name": "👖 Calças da Rainha Islanzadí",
			"type": ItemType.ARMOR_PANTS,
			"rarity": Rarity.LEGENDARY,
			"class_req": "arya",
			"level_req": 1,
			"base_defense": 252,
			"magic_resist": 113,
			"set_name": "rainha_islanzadi",
			"set_display_name": "da Rainha Islanzadí",
			"value_gold": 25874
		},
		"boots_rainha_islanzadi": {
			"name": "🥾 Botas da Rainha Islanzadí",
			"type": ItemType.ARMOR_BOOTS,
			"rarity": Rarity.LEGENDARY,
			"class_req": "arya",
			"level_req": 1,
			"base_defense": 176,
			"magic_resist": 79,
			"set_name": "rainha_islanzadi",
			"set_display_name": "da Rainha Islanzadí",
			"value_gold": 18000
		},
		"helm_astral_menoa": {
			"name": "🪖 Elmo Astral da Deusa Menoa",
			"type": ItemType.ARMOR_HEAD,
			"rarity": Rarity.DIVINE,
			"class_req": "arya",
			"level_req": 1,
			"base_defense": 290,
			"magic_resist": 130,
			"set_name": "astral_menoa",
			"set_display_name": "Astral da Deusa Menoa",
			"value_gold": 22500
		},
		"shoulders_astral_menoa": {
			"name": "🛡️ Ombreiras Astral da Deusa Menoa",
			"type": ItemType.ARMOR_SHOULDER,
			"rarity": Rarity.DIVINE,
			"class_req": "arya",
			"level_req": 1,
			"base_defense": 217,
			"magic_resist": 97,
			"set_name": "astral_menoa",
			"set_display_name": "Astral da Deusa Menoa",
			"value_gold": 16875
		},
		"chest_astral_menoa": {
			"name": "🥋 Peitoral Astral da Deusa Menoa",
			"type": ItemType.ARMOR_CHEST,
			"rarity": Rarity.DIVINE,
			"class_req": "arya",
			"level_req": 1,
			"base_defense": 420,
			"magic_resist": 189,
			"set_name": "astral_menoa",
			"set_display_name": "Astral da Deusa Menoa",
			"value_gold": 32625
		},
		"gloves_astral_menoa": {
			"name": "🧤 Luvas Astral da Deusa Menoa",
			"type": ItemType.ARMOR_GLOVES,
			"rarity": Rarity.DIVINE,
			"class_req": "arya",
			"level_req": 1,
			"base_defense": 203,
			"magic_resist": 91,
			"set_name": "astral_menoa",
			"set_display_name": "Astral da Deusa Menoa",
			"value_gold": 15749
		},
		"pants_astral_menoa": {
			"name": "👖 Calças Astral da Deusa Menoa",
			"type": ItemType.ARMOR_PANTS,
			"rarity": Rarity.DIVINE,
			"class_req": "arya",
			"level_req": 1,
			"base_defense": 333,
			"magic_resist": 149,
			"set_name": "astral_menoa",
			"set_display_name": "Astral da Deusa Menoa",
			"value_gold": 25874
		},
		"boots_astral_menoa": {
			"name": "🥾 Botas Astral da Deusa Menoa",
			"type": ItemType.ARMOR_BOOTS,
			"rarity": Rarity.DIVINE,
			"class_req": "arya",
			"level_req": 1,
			"base_defense": 232,
			"magic_resist": 104,
			"set_name": "astral_menoa",
			"set_display_name": "Astral da Deusa Menoa",
			"value_gold": 18000
		},
		"helm_aprendiz_forja": {
			"name": "🪖 Elmo do Aprendiz de Forja",
			"type": ItemType.ARMOR_HEAD,
			"rarity": Rarity.COMMON,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 24,
			"magic_resist": 10,
			"set_name": "aprendiz_forja",
			"set_display_name": "do Aprendiz de Forja",
			"value_gold": 4500
		},
		"shoulders_aprendiz_forja": {
			"name": "🛡️ Ombreiras do Aprendiz de Forja",
			"type": ItemType.ARMOR_SHOULDER,
			"rarity": Rarity.COMMON,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 18,
			"magic_resist": 8,
			"set_name": "aprendiz_forja",
			"set_display_name": "do Aprendiz de Forja",
			"value_gold": 3375
		},
		"chest_aprendiz_forja": {
			"name": "🥋 Peitoral do Aprendiz de Forja",
			"type": ItemType.ARMOR_CHEST,
			"rarity": Rarity.COMMON,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 34,
			"magic_resist": 15,
			"set_name": "aprendiz_forja",
			"set_display_name": "do Aprendiz de Forja",
			"value_gold": 6525
		},
		"gloves_aprendiz_forja": {
			"name": "🧤 Luvas do Aprendiz de Forja",
			"type": ItemType.ARMOR_GLOVES,
			"rarity": Rarity.COMMON,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 16,
			"magic_resist": 7,
			"set_name": "aprendiz_forja",
			"set_display_name": "do Aprendiz de Forja",
			"value_gold": 3150
		},
		"pants_aprendiz_forja": {
			"name": "👖 Calças do Aprendiz de Forja",
			"type": ItemType.ARMOR_PANTS,
			"rarity": Rarity.COMMON,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 27,
			"magic_resist": 12,
			"set_name": "aprendiz_forja",
			"set_display_name": "do Aprendiz de Forja",
			"value_gold": 5175
		},
		"boots_aprendiz_forja": {
			"name": "🥾 Botas do Aprendiz de Forja",
			"type": ItemType.ARMOR_BOOTS,
			"rarity": Rarity.COMMON,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 19,
			"magic_resist": 8,
			"set_name": "aprendiz_forja",
			"set_display_name": "do Aprendiz de Forja",
			"value_gold": 3600
		},
		"helm_milicia_espinha": {
			"name": "🪖 Elmo da Milícia da Espinha",
			"type": ItemType.ARMOR_HEAD,
			"rarity": Rarity.MAGIC,
			"class_req": "roran",
			"level_req": 11,
			"base_defense": 55,
			"magic_resist": 24,
			"set_name": "milicia_espinha",
			"set_display_name": "da Milícia da Espinha",
			"value_gold": 9000
		},
		"shoulders_milicia_espinha": {
			"name": "🛡️ Ombreiras da Milícia da Espinha",
			"type": ItemType.ARMOR_SHOULDER,
			"rarity": Rarity.MAGIC,
			"class_req": "roran",
			"level_req": 11,
			"base_defense": 41,
			"magic_resist": 18,
			"set_name": "milicia_espinha",
			"set_display_name": "da Milícia da Espinha",
			"value_gold": 6750
		},
		"chest_milicia_espinha": {
			"name": "🥋 Peitoral da Milícia da Espinha",
			"type": ItemType.ARMOR_CHEST,
			"rarity": Rarity.MAGIC,
			"class_req": "roran",
			"level_req": 11,
			"base_defense": 79,
			"magic_resist": 35,
			"set_name": "milicia_espinha",
			"set_display_name": "da Milícia da Espinha",
			"value_gold": 13050
		},
		"gloves_milicia_espinha": {
			"name": "🧤 Luvas da Milícia da Espinha",
			"type": ItemType.ARMOR_GLOVES,
			"rarity": Rarity.MAGIC,
			"class_req": "roran",
			"level_req": 11,
			"base_defense": 38,
			"magic_resist": 17,
			"set_name": "milicia_espinha",
			"set_display_name": "da Milícia da Espinha",
			"value_gold": 6300
		},
		"pants_milicia_espinha": {
			"name": "👖 Calças da Milícia da Espinha",
			"type": ItemType.ARMOR_PANTS,
			"rarity": Rarity.MAGIC,
			"class_req": "roran",
			"level_req": 11,
			"base_defense": 63,
			"magic_resist": 28,
			"set_name": "milicia_espinha",
			"set_display_name": "da Milícia da Espinha",
			"value_gold": 10350
		},
		"boots_milicia_espinha": {
			"name": "🥾 Botas da Milícia da Espinha",
			"type": ItemType.ARMOR_BOOTS,
			"rarity": Rarity.MAGIC,
			"class_req": "roran",
			"level_req": 11,
			"base_defense": 44,
			"magic_resist": 19,
			"set_name": "milicia_espinha",
			"set_display_name": "da Milícia da Espinha",
			"value_gold": 7200
		},
		"helm_rompedor_batalha": {
			"name": "🪖 Elmo do Rompedor de Batalha",
			"type": ItemType.ARMOR_HEAD,
			"rarity": Rarity.RARE,
			"class_req": "roran",
			"level_req": 21,
			"base_defense": 105,
			"magic_resist": 47,
			"set_name": "rompedor_batalha",
			"set_display_name": "do Rompedor de Batalha",
			"value_gold": 13500
		},
		"shoulders_rompedor_batalha": {
			"name": "🛡️ Ombreiras do Rompedor de Batalha",
			"type": ItemType.ARMOR_SHOULDER,
			"rarity": Rarity.RARE,
			"class_req": "roran",
			"level_req": 21,
			"base_defense": 78,
			"magic_resist": 35,
			"set_name": "rompedor_batalha",
			"set_display_name": "do Rompedor de Batalha",
			"value_gold": 10125
		},
		"chest_rompedor_batalha": {
			"name": "🥋 Peitoral do Rompedor de Batalha",
			"type": ItemType.ARMOR_CHEST,
			"rarity": Rarity.RARE,
			"class_req": "roran",
			"level_req": 21,
			"base_defense": 152,
			"magic_resist": 68,
			"set_name": "rompedor_batalha",
			"set_display_name": "do Rompedor de Batalha",
			"value_gold": 19575
		},
		"gloves_rompedor_batalha": {
			"name": "🧤 Luvas do Rompedor de Batalha",
			"type": ItemType.ARMOR_GLOVES,
			"rarity": Rarity.RARE,
			"class_req": "roran",
			"level_req": 21,
			"base_defense": 73,
			"magic_resist": 32,
			"set_name": "rompedor_batalha",
			"set_display_name": "do Rompedor de Batalha",
			"value_gold": 9450
		},
		"pants_rompedor_batalha": {
			"name": "👖 Calças do Rompedor de Batalha",
			"type": ItemType.ARMOR_PANTS,
			"rarity": Rarity.RARE,
			"class_req": "roran",
			"level_req": 21,
			"base_defense": 120,
			"magic_resist": 54,
			"set_name": "rompedor_batalha",
			"set_display_name": "do Rompedor de Batalha",
			"value_gold": 15524
		},
		"boots_rompedor_batalha": {
			"name": "🥾 Botas do Rompedor de Batalha",
			"type": ItemType.ARMOR_BOOTS,
			"rarity": Rarity.RARE,
			"class_req": "roran",
			"level_req": 21,
			"base_defense": 84,
			"magic_resist": 37,
			"set_name": "rompedor_batalha",
			"set_display_name": "do Rompedor de Batalha",
			"value_gold": 10800
		},
		"helm_flagelo_kulls": {
			"name": "🪖 Elmo do Flagelo dos Kulls",
			"type": ItemType.ARMOR_HEAD,
			"rarity": Rarity.EPIC,
			"class_req": "roran",
			"level_req": 31,
			"base_defense": 170,
			"magic_resist": 76,
			"set_name": "flagelo_kulls",
			"set_display_name": "do Flagelo dos Kulls",
			"value_gold": 18000
		},
		"shoulders_flagelo_kulls": {
			"name": "🛡️ Ombreiras do Flagelo dos Kulls",
			"type": ItemType.ARMOR_SHOULDER,
			"rarity": Rarity.EPIC,
			"class_req": "roran",
			"level_req": 31,
			"base_defense": 127,
			"magic_resist": 57,
			"set_name": "flagelo_kulls",
			"set_display_name": "do Flagelo dos Kulls",
			"value_gold": 13500
		},
		"chest_flagelo_kulls": {
			"name": "🥋 Peitoral do Flagelo dos Kulls",
			"type": ItemType.ARMOR_CHEST,
			"rarity": Rarity.EPIC,
			"class_req": "roran",
			"level_req": 31,
			"base_defense": 246,
			"magic_resist": 110,
			"set_name": "flagelo_kulls",
			"set_display_name": "do Flagelo dos Kulls",
			"value_gold": 26100
		},
		"gloves_flagelo_kulls": {
			"name": "🧤 Luvas do Flagelo dos Kulls",
			"type": ItemType.ARMOR_GLOVES,
			"rarity": Rarity.EPIC,
			"class_req": "roran",
			"level_req": 31,
			"base_defense": 118,
			"magic_resist": 53,
			"set_name": "flagelo_kulls",
			"set_display_name": "do Flagelo dos Kulls",
			"value_gold": 12600
		},
		"pants_flagelo_kulls": {
			"name": "👖 Calças do Flagelo dos Kulls",
			"type": ItemType.ARMOR_PANTS,
			"rarity": Rarity.EPIC,
			"class_req": "roran",
			"level_req": 31,
			"base_defense": 195,
			"magic_resist": 87,
			"set_name": "flagelo_kulls",
			"set_display_name": "do Flagelo dos Kulls",
			"value_gold": 20700
		},
		"boots_flagelo_kulls": {
			"name": "🥾 Botas do Flagelo dos Kulls",
			"type": ItemType.ARMOR_BOOTS,
			"rarity": Rarity.EPIC,
			"class_req": "roran",
			"level_req": 31,
			"base_defense": 136,
			"magic_resist": 61,
			"set_name": "flagelo_kulls",
			"set_display_name": "do Flagelo dos Kulls",
			"value_gold": 14400
		},
		"helm_inquebravel_farthen": {
			"name": "🪖 Elmo do Inquebrável de Farthen Dûr",
			"type": ItemType.ARMOR_HEAD,
			"rarity": Rarity.EPIC,
			"class_req": "roran",
			"level_req": 41,
			"base_defense": 245,
			"magic_resist": 110,
			"set_name": "inquebravel_farthen",
			"set_display_name": "do Inquebrável de Farthen Dûr",
			"value_gold": 22500
		},
		"shoulders_inquebravel_farthen": {
			"name": "🛡️ Ombreiras do Inquebrável de Farthen Dûr",
			"type": ItemType.ARMOR_SHOULDER,
			"rarity": Rarity.EPIC,
			"class_req": "roran",
			"level_req": 41,
			"base_defense": 183,
			"magic_resist": 82,
			"set_name": "inquebravel_farthen",
			"set_display_name": "do Inquebrável de Farthen Dûr",
			"value_gold": 16875
		},
		"chest_inquebravel_farthen": {
			"name": "🥋 Peitoral do Inquebrável de Farthen Dûr",
			"type": ItemType.ARMOR_CHEST,
			"rarity": Rarity.EPIC,
			"class_req": "roran",
			"level_req": 41,
			"base_defense": 355,
			"magic_resist": 159,
			"set_name": "inquebravel_farthen",
			"set_display_name": "do Inquebrável de Farthen Dûr",
			"value_gold": 32625
		},
		"gloves_inquebravel_farthen": {
			"name": "🧤 Luvas do Inquebrável de Farthen Dûr",
			"type": ItemType.ARMOR_GLOVES,
			"rarity": Rarity.EPIC,
			"class_req": "roran",
			"level_req": 41,
			"base_defense": 171,
			"magic_resist": 76,
			"set_name": "inquebravel_farthen",
			"set_display_name": "do Inquebrável de Farthen Dûr",
			"value_gold": 15749
		},
		"pants_inquebravel_farthen": {
			"name": "👖 Calças do Inquebrável de Farthen Dûr",
			"type": ItemType.ARMOR_PANTS,
			"rarity": Rarity.EPIC,
			"class_req": "roran",
			"level_req": 41,
			"base_defense": 281,
			"magic_resist": 126,
			"set_name": "inquebravel_farthen",
			"set_display_name": "do Inquebrável de Farthen Dûr",
			"value_gold": 25874
		},
		"boots_inquebravel_farthen": {
			"name": "🥾 Botas do Inquebrável de Farthen Dûr",
			"type": ItemType.ARMOR_BOOTS,
			"rarity": Rarity.EPIC,
			"class_req": "roran",
			"level_req": 41,
			"base_defense": 196,
			"magic_resist": 88,
			"set_name": "inquebravel_farthen",
			"set_display_name": "do Inquebrável de Farthen Dûr",
			"value_gold": 18000
		},
		"helm_rei_hrothgar": {
			"name": "🪖 Elmo do Rei Hrothgar",
			"type": ItemType.ARMOR_HEAD,
			"rarity": Rarity.LEGENDARY,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 300,
			"magic_resist": 135,
			"set_name": "rei_hrothgar",
			"set_display_name": "do Rei Hrothgar",
			"value_gold": 22500
		},
		"shoulders_rei_hrothgar": {
			"name": "🛡️ Ombreiras do Rei Hrothgar",
			"type": ItemType.ARMOR_SHOULDER,
			"rarity": Rarity.LEGENDARY,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 225,
			"magic_resist": 101,
			"set_name": "rei_hrothgar",
			"set_display_name": "do Rei Hrothgar",
			"value_gold": 16875
		},
		"chest_rei_hrothgar": {
			"name": "🥋 Peitoral do Rei Hrothgar",
			"type": ItemType.ARMOR_CHEST,
			"rarity": Rarity.LEGENDARY,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 435,
			"magic_resist": 195,
			"set_name": "rei_hrothgar",
			"set_display_name": "do Rei Hrothgar",
			"value_gold": 32625
		},
		"gloves_rei_hrothgar": {
			"name": "🧤 Luvas do Rei Hrothgar",
			"type": ItemType.ARMOR_GLOVES,
			"rarity": Rarity.LEGENDARY,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 210,
			"magic_resist": 94,
			"set_name": "rei_hrothgar",
			"set_display_name": "do Rei Hrothgar",
			"value_gold": 15749
		},
		"pants_rei_hrothgar": {
			"name": "👖 Calças do Rei Hrothgar",
			"type": ItemType.ARMOR_PANTS,
			"rarity": Rarity.LEGENDARY,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 345,
			"magic_resist": 155,
			"set_name": "rei_hrothgar",
			"set_display_name": "do Rei Hrothgar",
			"value_gold": 25874
		},
		"boots_rei_hrothgar": {
			"name": "🥾 Botas do Rei Hrothgar",
			"type": ItemType.ARMOR_BOOTS,
			"rarity": Rarity.LEGENDARY,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 240,
			"magic_resist": 108,
			"set_name": "rei_hrothgar",
			"set_display_name": "do Rei Hrothgar",
			"value_gold": 18000
		},
		"helm_titanico_helzvog": {
			"name": "🪖 Elmo Titânico de Helzvog",
			"type": ItemType.ARMOR_HEAD,
			"rarity": Rarity.DIVINE,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 390,
			"magic_resist": 175,
			"set_name": "titanico_helzvog",
			"set_display_name": "Titânico de Helzvog",
			"value_gold": 22500
		},
		"shoulders_titanico_helzvog": {
			"name": "🛡️ Ombreiras Titânico de Helzvog",
			"type": ItemType.ARMOR_SHOULDER,
			"rarity": Rarity.DIVINE,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 292,
			"magic_resist": 131,
			"set_name": "titanico_helzvog",
			"set_display_name": "Titânico de Helzvog",
			"value_gold": 16875
		},
		"chest_titanico_helzvog": {
			"name": "🥋 Peitoral Titânico de Helzvog",
			"type": ItemType.ARMOR_CHEST,
			"rarity": Rarity.DIVINE,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 565,
			"magic_resist": 254,
			"set_name": "titanico_helzvog",
			"set_display_name": "Titânico de Helzvog",
			"value_gold": 32625
		},
		"gloves_titanico_helzvog": {
			"name": "🧤 Luvas Titânico de Helzvog",
			"type": ItemType.ARMOR_GLOVES,
			"rarity": Rarity.DIVINE,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 273,
			"magic_resist": 122,
			"set_name": "titanico_helzvog",
			"set_display_name": "Titânico de Helzvog",
			"value_gold": 15749
		},
		"pants_titanico_helzvog": {
			"name": "👖 Calças Titânico de Helzvog",
			"type": ItemType.ARMOR_PANTS,
			"rarity": Rarity.DIVINE,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 448,
			"magic_resist": 201,
			"set_name": "titanico_helzvog",
			"set_display_name": "Titânico de Helzvog",
			"value_gold": 25874
		},
		"boots_titanico_helzvog": {
			"name": "🥾 Botas Titânico de Helzvog",
			"type": ItemType.ARMOR_BOOTS,
			"rarity": Rarity.DIVINE,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 312,
			"magic_resist": 140,
			"set_name": "titanico_helzvog",
			"set_display_name": "Titânico de Helzvog",
			"value_gold": 18000
		},

		# --- ARMAS ESPECIALIZADAS POR CLASSE (21 ARMAS) ---
		"sword_recruta": {
			"name": "🗡️ Espada de Treino de Carvahall",
			"type": ItemType.WEAPON,
			"rarity": Rarity.COMMON,
			"class_req": "zero",
			"level_req": 1,
			"base_attack": 45,
			"value_gold": 1200
		},
		"sword_escudeiro": {
			"name": "🗡️ Espada Larga de Aço de Sylveria",
			"type": ItemType.WEAPON,
			"rarity": Rarity.MAGIC,
			"class_req": "zero",
			"level_req": 11,
			"base_attack": 110,
			"value_gold": 4800
		},
		"sword_fogo": {
			"name": "🔥 Espada Flamejante dos Cavaleiros",
			"type": ItemType.WEAPON,
			"rarity": Rarity.RARE,
			"class_req": "zero",
			"level_req": 21,
			"base_attack": 215,
			"value_gold": 14000
		},
		"sword_brisingr": {
			"name": "⚔️ Brisingr (A Lâmina de Fogo)",
			"type": ItemType.WEAPON,
			"rarity": Rarity.EPIC,
			"class_req": "zero",
			"level_req": 31,
			"base_attack": 380,
			"value_gold": 42000
		},
		"sword_soberana": {
			"name": "⚔️ Espada Bastarda do Soberano",
			"type": ItemType.WEAPON,
			"rarity": Rarity.EPIC,
			"class_req": "zero",
			"level_req": 41,
			"base_attack": 560,
			"value_gold": 95000
		},
		"sword_zarroc": {
			"name": "🩸 Zar'roc (A Lâmina Carmesim da Miséria)",
			"type": ItemType.WEAPON,
			"rarity": Rarity.LEGENDARY,
			"class_req": "zero",
			"level_req": 1,
			"base_attack": 740,
			"value_gold": 220000
		},
		"sword_vermund_divine": {
			"name": "🌟 Lâmina Solar Primordial de Vermund",
			"type": ItemType.WEAPON,
			"rarity": Rarity.DIVINE,
			"class_req": "zero",
			"level_req": 1,
			"base_attack": 980,
			"value_gold": 600000
		},
		"blade_rastreador": {
			"name": "🗡️ Adaga Curta dos Bosques",
			"type": ItemType.WEAPON,
			"rarity": Rarity.COMMON,
			"class_req": "arya",
			"level_req": 1,
			"base_attack": 42,
			"value_gold": 1100
		},
		"bow_patrulha": {
			"name": "🏹 Arco Recurvo da Patrulha",
			"type": ItemType.WEAPON,
			"rarity": Rarity.MAGIC,
			"class_req": "arya",
			"level_req": 11,
			"base_attack": 105,
			"value_gold": 4600
		},
		"blade_sombras": {
			"name": "🗡️ Florete das Sombras de Du Weldenvarden",
			"type": ItemType.WEAPON,
			"rarity": Rarity.RARE,
			"class_req": "arya",
			"level_req": 21,
			"base_attack": 205,
			"value_gold": 13500
		},
		"bow_ellesmera": {
			"name": "🏹 Arco Longo Sagrado de Ellesméra",
			"type": ItemType.WEAPON,
			"rarity": Rarity.EPIC,
			"class_req": "arya",
			"level_req": 31,
			"base_attack": 365,
			"value_gold": 41000
		},
		"blade_nobreza": {
			"name": "🗡️ Lâmina Fina da Nobreza Élfica",
			"type": ItemType.WEAPON,
			"rarity": Rarity.EPIC,
			"class_req": "arya",
			"level_req": 41,
			"base_attack": 540,
			"value_gold": 92000
		},
		"blade_tamerlein": {
			"name": "⚔️ Tamerlein (A Espada Verde Esmeralda)",
			"type": ItemType.WEAPON,
			"rarity": Rarity.LEGENDARY,
			"class_req": "arya",
			"level_req": 1,
			"base_attack": 720,
			"value_gold": 215000
		},
		"bow_menoa_divine": {
			"name": "🌟 Arco Astral da Grande Árvore Menoa",
			"type": ItemType.WEAPON,
			"rarity": Rarity.DIVINE,
			"class_req": "arya",
			"level_req": 1,
			"base_attack": 960,
			"value_gold": 590000
		},
		"hammer_aprendiz": {
			"name": "🔨 Martelo Forjado Rústico",
			"type": ItemType.WEAPON,
			"rarity": Rarity.COMMON,
			"class_req": "roran",
			"level_req": 1,
			"base_attack": 52,
			"value_gold": 1300
		},
		"hammer_milicia": {
			"name": "🔨 Martelo de Guerra Pesado",
			"type": ItemType.WEAPON,
			"rarity": Rarity.MAGIC,
			"class_req": "roran",
			"level_req": 11,
			"base_attack": 125,
			"value_gold": 5200
		},
		"hammer_rompedor": {
			"name": "🔨 Quebra-Crânios dos Vales",
			"type": ItemType.WEAPON,
			"rarity": Rarity.RARE,
			"class_req": "roran",
			"level_req": 21,
			"base_attack": 240,
			"value_gold": 15500
		},
		"hammer_kulls": {
			"name": "🔨 Demolidor de Urgals e Kulls",
			"type": ItemType.WEAPON,
			"rarity": Rarity.EPIC,
			"class_req": "roran",
			"level_req": 31,
			"base_attack": 410,
			"value_gold": 45000
		},
		"hammer_roran": {
			"name": "🔨 O Martelo-Forte de Carvahall",
			"type": ItemType.WEAPON,
			"rarity": Rarity.EPIC,
			"class_req": "roran",
			"level_req": 41,
			"base_attack": 610,
			"value_gold": 105000
		},
		"hammer_volund": {
			"name": "⚡ Volund (O Machado do Rei Anão)",
			"type": ItemType.WEAPON,
			"rarity": Rarity.LEGENDARY,
			"class_req": "roran",
			"level_req": 1,
			"base_attack": 790,
			"value_gold": 240000
		},
		"hammer_helzvog_divine": {
			"name": "🌟 Martelo Titânico Criador de Helzvog",
			"type": ItemType.WEAPON,
			"rarity": Rarity.DIVINE,
			"class_req": "roran",
			"level_req": 1,
			"base_attack": 1050,
			"value_gold": 650000
		},

		# --- ESCUDOS E ACESSÓRIOS OFF-HAND ---
		"shield_madeira": {
			"name": "🛡️ Escudo de Madeira com Rebites de Ferro",
			"type": ItemType.WEAPON_OFFHAND,
			"rarity": Rarity.COMMON,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 25,
			"value_gold": 800
		},
		"shield_aco": {
			"name": "🛡️ Escudo de Aço Maciço da Espinha",
			"type": ItemType.WEAPON_OFFHAND,
			"rarity": Rarity.MAGIC,
			"class_req": "roran",
			"level_req": 11,
			"base_defense": 60,
			"value_gold": 3200
		},
		"shield_dragon_scale": {
			"name": "🛡️ Escudo de Escamas de Dragão",
			"type": ItemType.WEAPON_OFFHAND,
			"rarity": Rarity.EPIC,
			"class_req": "zero",
			"level_req": 31,
			"base_defense": 160,
			"value_gold": 38000
		},
		"shield_farthen_dur": {
			"name": "🛡️ Broquel Rúnico dos Anões",
			"type": ItemType.WEAPON_OFFHAND,
			"rarity": Rarity.EPIC,
			"class_req": "roran",
			"level_req": 41,
			"base_defense": 220,
			"value_gold": 85000
		},
		"shield_hrothgar": {
			"name": "🛡️ Baluarte da Barreira de Farthen Dûr",
			"type": ItemType.WEAPON_OFFHAND,
			"rarity": Rarity.LEGENDARY,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 310,
			"value_gold": 210000
		},
		"shield_helzvog": {
			"name": "🌟 Muralha Indestrutível de Helzvog",
			"type": ItemType.WEAPON_OFFHAND,
			"rarity": Rarity.MYTHIC,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 420,
			"value_gold": 520000
		},
		"orb_angela": {
			"name": "🔮 Orbe da Vidente Angela",
			"type": ItemType.WEAPON_OFFHAND,
			"rarity": Rarity.RARE,
			"class_req": "zero",
			"level_req": 25,
			"base_defense": 95,
			"value_gold": 22000
		},
		"orb_astral": {
			"name": "🌟 Orbe Astral dos Espíritos Ancestrais",
			"type": ItemType.WEAPON_OFFHAND,
			"rarity": Rarity.EPIC,
			"class_req": "arya",
			"level_req": 41,
			"base_defense": 185,
			"value_gold": 88000
		},

		# --- ASAS (REQUISITOS DE NÍVEL RÍGIDOS: 30, 40, 50) ---
		"wings_tier1": {
			"name": "🪽 Asas Espirituais de Fada (Nvl 1)",
			"type": ItemType.WINGS,
			"tier": 1,
			"level_req": 30,
			"rarity": Rarity.RARE,
			"move_speed_multiplier": 1.2,
			"damage_bonus_pct": 15.0,
			"absorb_bonus_pct": 15.0,
			"value_gold": 60000,
			"description": "Asas etéreas leves com energia feérica. Concedem velocidade e absorção básica."
		},
		"wings_crystal_tier2": {
			"name": "🪽 Asas de Cristal Puro (Nvl 2)",
			"type": ItemType.WINGS,
			"tier": 2,
			"level_req": 40,
			"rarity": Rarity.EPIC,
			"move_speed_multiplier": 1.35,
			"damage_bonus_pct": 30.0,
			"absorb_bonus_pct": 30.0,
			"value_gold": 180000,
			"description": "Forjadas na Máquina do Caos com Joias Creation. Emanam brilho translúcido estonteante."
		},
		"wings_tier3_supreme": {
			"name": "🪽 Asas Cósmicas de Saphira (Nvl 3 / Supremas)",
			"type": ItemType.WINGS,
			"tier": 3,
			"level_req": 50,
			"rarity": Rarity.LEGENDARY,
			"move_speed_multiplier": 1.5,
			"damage_bonus_pct": 50.0,
			"absorb_bonus_pct": 50.0,
			"value_gold": 500000,
			"description": "A glória suprema dos Cavaleiros. Deixam rastro de partículas celestes e concedem poder supremo."
		},

		# --- CAPAS (1 POR FAIXA DE 10 NÍVEIS POR CLASSE = 15 CAPAS) ---
		"cape_recruta_1": {
			"name": "🧣 Capa de Linho do Recruta",
			"type": ItemType.CAPE,
			"rarity": Rarity.COMMON,
			"class_req": "zero",
			"level_req": 1,
			"base_defense": 15,
			"value_gold": 1000
		},
		"cape_escudeiro_2": {
			"name": "🧣 Manto de Aço do Escudeiro",
			"type": ItemType.CAPE,
			"rarity": Rarity.MAGIC,
			"class_req": "zero",
			"level_req": 11,
			"base_defense": 35,
			"value_gold": 3500
		},
		"cape_rider": {
			"name": "🧣 Manto dos Cavaleiros de Dragão",
			"type": ItemType.CAPE,
			"rarity": Rarity.RARE,
			"class_req": "zero",
			"level_req": 21,
			"base_defense": 75,
			"value_gold": 12000
		},
		"cape_dragao_4": {
			"name": "🧣 Capa de Escamas Carmesim",
			"type": ItemType.CAPE,
			"rarity": Rarity.EPIC,
			"class_req": "zero",
			"level_req": 31,
			"base_defense": 130,
			"value_gold": 35000
		},
		"cape_soberano_5": {
			"name": "🧣 Manto Estelar do Soberano",
			"type": ItemType.CAPE,
			"rarity": Rarity.LEGENDARY,
			"class_req": "zero",
			"level_req": 41,
			"base_defense": 210,
			"value_gold": 95000
		},
		"cape_linho_1": {
			"name": "🧣 Manto de Camuflagem dos Bosques",
			"type": ItemType.CAPE,
			"rarity": Rarity.COMMON,
			"class_req": "arya",
			"level_req": 1,
			"base_defense": 12,
			"value_gold": 1000
		},
		"cape_patrulha_2": {
			"name": "🧣 Capa da Patrulha de Ellesméra",
			"type": ItemType.CAPE,
			"rarity": Rarity.MAGIC,
			"class_req": "arya",
			"level_req": 11,
			"base_defense": 30,
			"value_gold": 3500
		},
		"cape_elven_cloak": {
			"name": "🧣 Manto dos Bosques de Du Weldenvarden",
			"type": ItemType.CAPE,
			"rarity": Rarity.RARE,
			"class_req": "arya",
			"level_req": 21,
			"base_defense": 68,
			"value_gold": 12000
		},
		"cape_mestre_4": {
			"name": "🧣 Capa da Ordem dos Magos Élficos",
			"type": ItemType.CAPE,
			"rarity": Rarity.EPIC,
			"class_req": "arya",
			"level_req": 31,
			"base_defense": 120,
			"value_gold": 35000
		},
		"cape_rainha_5": {
			"name": "🧣 Manto da Rainha das Estrelas",
			"type": ItemType.CAPE,
			"rarity": Rarity.LEGENDARY,
			"class_req": "arya",
			"level_req": 41,
			"base_defense": 195,
			"value_gold": 95000
		},
		"cape_pele_1": {
			"name": "🧣 Manto de Peles de Urso",
			"type": ItemType.CAPE,
			"rarity": Rarity.COMMON,
			"class_req": "roran",
			"level_req": 1,
			"base_defense": 20,
			"value_gold": 1000
		},
		"cape_couro_2": {
			"name": "🧣 Capa de Couro Reforçado da Espinha",
			"type": ItemType.CAPE,
			"rarity": Rarity.MAGIC,
			"class_req": "roran",
			"level_req": 11,
			"base_defense": 45,
			"value_gold": 3500
		},
		"cape_carvahall_3": {
			"name": "🧣 Manto da Resistência de Carvahall",
			"type": ItemType.CAPE,
			"rarity": Rarity.RARE,
			"class_req": "roran",
			"level_req": 21,
			"base_defense": 90,
			"value_gold": 12000
		},
		"cape_kulls_4": {
			"name": "🧣 Capa Pesada do Conquistador",
			"type": ItemType.CAPE,
			"rarity": Rarity.EPIC,
			"class_req": "roran",
			"level_req": 31,
			"base_defense": 155,
			"value_gold": 35000
		},
		"cape_titan_5": {
			"name": "🧣 Manto Indomável dos Anões de Beor",
			"type": ItemType.CAPE,
			"rarity": Rarity.LEGENDARY,
			"class_req": "roran",
			"level_req": 41,
			"base_defense": 240,
			"value_gold": 95000
		},

		# --- PETS E MONTARIAS ---
		"pet_cao_guarda": {
			"name": "🐾 Cão de Caça Leal (Tier 1)",
			"type": ItemType.PET,
			"rarity": Rarity.COMMON,
			"level_req": 1,
			"description": "Coleta moedas de ouro próximas.",
			"max_hp_bonus": 100.0,
			"value_gold": 5000
		},
		"pet_falcao_ventos": {
			"name": "🐾 Falcão dos Ventos (Tier 2)",
			"type": ItemType.PET,
			"rarity": Rarity.MAGIC,
			"level_req": 11,
			"description": "Coleta poções e materiais comuns. +8% Vel. Ataque.",
			"max_hp_bonus": 150.0,
			"value_gold": 15000
		},
		"pet_mystic_owl": {
			"name": "🐾 Coruja dos Presságios (Tier 3)",
			"type": ItemType.PET,
			"rarity": Rarity.RARE,
			"level_req": 21,
			"description": "Alerta contra emboscadas e coleta orbes. +12% Dano Crítico.",
			"max_hp_bonus": 200.0,
			"value_gold": 45000
		},
		"pet_raposa_astral": {
			"name": "🐾 Raposa Astral de Menoa (Tier 4)",
			"type": ItemType.PET,
			"rarity": Rarity.EPIC,
			"level_req": 31,
			"description": "Coleta joias Bless e Soul automaticamente. +15% Regen de Mana.",
			"max_hp_bonus": 300.0,
			"value_gold": 120000
		},
		"pet_baby_dragon": {
			"name": "🐾 Dragãozinho Filhote Nieda (Tier 5)",
			"type": ItemType.PET,
			"rarity": Rarity.LEGENDARY,
			"level_req": 41,
			"description": "Sucção magnética de tela inteira. +15% Dano Geral e +25% Magic Find.",
			"max_hp_bonus": 500.0,
			"value_gold": 350000
		},
		"mount_saphira": {
			"name": "🐉 Saphira (A Dama Safira)",
			"type": ItemType.MOUNT,
			"rarity": Rarity.MYTHIC,
			"level_req": 30,
			"move_speed_bonus": 2.2,
			"value_gold": 500000
		},

		# --- ANÉIS E COLARES ---
		"ring_mithril": {
			"name": "💍 Anel de Mithril Élfico",
			"type": ItemType.RING,
			"rarity": Rarity.RARE,
			"level_req": 15,
			"magic_resist": 45,
			"willpower": 12,
			"value_gold": 18000
		},
		"ring_aren": {
			"name": "💍 Aren (O Anel da Princesa Brom)",
			"type": ItemType.RING,
			"rarity": Rarity.EPIC,
			"level_req": 25,
			"max_mp": 280,
			"spell_power": 45,
			"value_gold": 48000
		},
		"ring_starfire": {
			"name": "💍 Anel de Fogo Estelar",
			"type": ItemType.RING,
			"rarity": Rarity.LEGENDARY,
			"level_req": 35,
			"fire_dmg_pct": 22.0,
			"strength": 25,
			"value_gold": 120000
		},
		"ring_vermund_divine": {
			"name": "💍 Selo Cósmico de Vermund",
			"type": ItemType.RING,
			"rarity": Rarity.MYTHIC,
			"level_req": 1,
			"all_stats": 30,
			"all_damage_pct": 20.0,
			"value_gold": 450000
		},
		"amulet_menoa_tear": {
			"name": "📿 Lágrima de Menoa",
			"type": ItemType.AMULET,
			"rarity": Rarity.RARE,
			"level_req": 20,
			"max_hp": 350,
			"hp_regen": 5.0,
			"value_gold": 22000
		},
		"amulet_ancient_language": {
			"name": "📿 Colar da Língua Antiga",
			"type": ItemType.AMULET,
			"rarity": Rarity.EPIC,
			"level_req": 30,
			"all_stats": 18,
			"cooldown_reduction": 10.0,
			"value_gold": 65000
		},
		"amulet_helzvog_eye": {
			"name": "📿 Olho Titânico de Helzvog",
			"type": ItemType.AMULET,
			"rarity": Rarity.MYTHIC,
			"level_req": 1,
			"armor_pct": 35.0,
			"max_hp": 800,
			"value_gold": 480000
		},

		# --- CONSUMÍVEIS E MATERIAIS ---
		"potion_health": {
			"name": "🧪 Poção de Vida Grande",
			"type": ItemType.CONSUMABLE,
			"rarity": Rarity.MAGIC,
			"value_gold": 150,
			"description": "Restaura instantaneamente 1.200 pontos de vida."
		},
		"potion_mana": {
			"name": "🧪 Poção de Mana Grande",
			"type": ItemType.CONSUMABLE,
			"rarity": Rarity.MAGIC,
			"value_gold": 150,
			"description": "Restaura instantaneamente 800 pontos de mana."
		},
		"fairth_stone": {
			"name": "💎 Pedra de Fairth (Memória)",
			"type": ItemType.CONSUMABLE,
			"rarity": Rarity.RARE,
			"value_gold": 2500,
			"description": "Cristal de luz que grava imagens da mente."
		},
		"brightsteel_fragment": {
			"name": "🔩 Fragmento de Brightsteel",
			"type": ItemType.CONSUMABLE,
			"rarity": Rarity.EPIC,
			"value_gold": 5000,
			"description": "Metal estelar raríssimo usado na forja das lâminas dos Cavaleiros."
		},
		"menoa_bark": {
			"name": "🪵 Casca da Grande Árvore Menoa",
			"type": ItemType.CONSUMABLE,
			"rarity": Rarity.RARE,
			"value_gold": 1800,
			"description": "Madeira élfica sagrada usada em cajados, arcos e escudos."
		},
		"tome_ancient_language": {
			"name": "📖 Tomo da Língua Antiga",
			"type": ItemType.TOME,
			"rarity": Rarity.EPIC,
			"value_gold": 35000,
			"description": "Ensina o vocábulo de poder primordial."
		},
	}

## Retorna o dicionário de todos os 21 sets com seus metadados
## Cache dos 21 conjuntos (mesma justificativa de get_all_items).
static var _sets_cache: Dictionary = {}

static func get_all_sets() -> Dictionary:
	if _sets_cache.is_empty():
		_sets_cache = _build_sets()
	return _sets_cache

static func _build_sets() -> Dictionary:
	var dict = {}
	dict["recruta_carvahall"] = {
		"name": "do Recruta de Carvahall",
		"class": "zero",
		"tier": 1,
		"bonus_2": {'strength': 10},
		"bonus_4": {'armor_pct': 12.0},
		"bonus_6": {'all_damage_pct': 10.0}
	}
	dict["escudeiro_aco"] = {
		"name": "do Escudeiro de Aço",
		"class": "zero",
		"tier": 2,
		"bonus_2": {'strength': 22},
		"bonus_4": {'move_speed_pct': 15.0},
		"bonus_6": {'fire_damage_pct': 18.0}
	}
	dict["cavaleiro_fogo"] = {
		"name": "do Cavaleiro de Fogo",
		"class": "zero",
		"tier": 3,
		"bonus_2": {'strength': 38, 'willpower': 25},
		"bonus_4": {'cooldown_reduction': 15.0},
		"bonus_6": {'burn_dot_pct': 25.0}
	}
	dict["dragon_knight"] = {
		"name": "do Dragão Carmesim",
		"class": "zero",
		"tier": 4,
		"bonus_2": {'strength': 55, 'willpower': 40},
		"bonus_4": {'barrier_absorb_pct': 20.0},
		"bonus_6": {'fire_damage_pct': 35.0}
	}
	dict["soberano_sylveria"] = {
		"name": "do Soberano de Sylveria",
		"class": "zero",
		"tier": 5,
		"bonus_2": {'strength': 80, 'willpower': 65},
		"bonus_4": {'all_damage_pct': 30.0},
		"bonus_6": {'meteor_proc_chance': 25.0}
	}
	dict["primeiros_cavaleiros"] = {
		"name": "dos Primeiros Cavaleiros",
		"class": "zero",
		"tier": 5,
		"bonus_2": {'strength': 95, 'willpower': 85},
		"bonus_4": {'cooldown_reduction': 25.0},
		"bonus_6": {'astral_shockwave_proc': 35.0}
	}
	dict["cosmico_vermund"] = {
		"name": "Cósmico de Vermund",
		"class": "zero",
		"tier": 5,
		"bonus_2": {'strength': 140, 'willpower': 120},
		"bonus_4": {'all_damage_pct': 45.0},
		"bonus_6": {'death_immunity_90s': 1.0, 'divine_fire_pct': 50.0}
	}
	dict["rastreador_bosques"] = {
		"name": "do Rastreador dos Bosques",
		"class": "arya",
		"tier": 1,
		"bonus_2": {'dexterity': 10},
		"bonus_4": {'move_speed_pct': 10.0},
		"bonus_6": {'crit_chance': 6.0}
	}
	dict["patrulha_elfica"] = {
		"name": "da Patrulha Élfica",
		"class": "arya",
		"tier": 2,
		"bonus_2": {'dexterity': 22},
		"bonus_4": {'dodge_pct': 12.0},
		"bonus_6": {'crit_damage_pct': 20.0}
	}
	dict["sombras_weldenvarden"] = {
		"name": "das Sombras de Du Weldenvarden",
		"class": "arya",
		"tier": 3,
		"bonus_2": {'dexterity': 40, 'willpower': 25},
		"bonus_4": {'attack_speed_pct': 20.0},
		"bonus_6": {'bleed_on_crit_pct': 30.0}
	}
	dict["prata_menoa"] = {
		"name": "da Lâmina de Prata de Menoa",
		"class": "arya",
		"tier": 4,
		"bonus_2": {'dexterity': 60, 'willpower': 42},
		"bonus_4": {'crit_damage_pct': 35.0},
		"bonus_6": {'illusion_clone_dodge': 25.0}
	}
	dict["nobreza_ellesmera"] = {
		"name": "da Nobreza de Ellesméra",
		"class": "arya",
		"tier": 5,
		"bonus_2": {'dexterity': 85, 'willpower': 65},
		"bonus_4": {'penetration_pct': 35.0},
		"bonus_6": {'floral_step_reset_on_kill': 1.0}
	}
	dict["rainha_islanzadi"] = {
		"name": "da Rainha Islanzadí",
		"class": "arya",
		"tier": 5,
		"bonus_2": {'dexterity': 105, 'willpower': 85},
		"bonus_4": {'crit_chance': 25.0},
		"bonus_6": {'menoa_bloom_annihilation': 40.0}
	}
	dict["astral_menoa"] = {
		"name": "Astral da Deusa Menoa",
		"class": "arya",
		"tier": 5,
		"bonus_2": {'dexterity': 150, 'willpower': 125},
		"bonus_4": {'crit_damage_pct': 60.0},
		"bonus_6": {'death_immunity_90s': 1.0, 'true_pierce_100': 1.0}
	}
	dict["aprendiz_forja"] = {
		"name": "do Aprendiz de Forja",
		"class": "roran",
		"tier": 1,
		"bonus_2": {'vitality': 12},
		"bonus_4": {'armor_pct': 15.0},
		"bonus_6": {'max_hp_bonus': 250.0}
	}
	dict["milicia_espinha"] = {
		"name": "da Milícia da Espinha",
		"class": "roran",
		"tier": 2,
		"bonus_2": {'vitality': 26, 'strength': 20},
		"bonus_4": {'block_chance': 12.0},
		"bonus_6": {'damage_reduction_pct': 12.0}
	}
	dict["rompedor_batalha"] = {
		"name": "do Rompedor de Batalha",
		"class": "roran",
		"tier": 3,
		"bonus_2": {'vitality': 48, 'strength': 38},
		"bonus_4": {'armor_pct': 25.0},
		"bonus_6": {'seismic_stun_duration': 1.5}
	}
	dict["flagelo_kulls"] = {
		"name": "do Flagelo dos Kulls",
		"class": "roran",
		"tier": 4,
		"bonus_2": {'vitality': 70, 'strength': 55},
		"bonus_4": {'block_chance': 22.0},
		"bonus_6": {'reflect_damage_pct': 35.0}
	}
	dict["inquebravel_farthen"] = {
		"name": "do Inquebrável de Farthen Dûr",
		"class": "roran",
		"tier": 5,
		"bonus_2": {'vitality': 100, 'strength': 80},
		"bonus_4": {'armor_pct': 40.0},
		"bonus_6": {'berserk_dmg_scale_pct': 50.0}
	}
	dict["rei_hrothgar"] = {
		"name": "do Rei Hrothgar",
		"class": "roran",
		"tier": 5,
		"bonus_2": {'vitality': 125, 'strength': 100},
		"bonus_4": {'damage_reduction_pct': 25.0},
		"bonus_6": {'titan_quake_aoe_triple': 1.0}
	}
	dict["titanico_helzvog"] = {
		"name": "Titânico de Helzvog",
		"class": "roran",
		"tier": 5,
		"bonus_2": {'vitality': 180, 'strength': 140},
		"bonus_4": {'max_hp_bonus': 1500.0},
		"bonus_6": {'death_immunity_90s': 1.0, 'titan_invulnerable_barrier': 1.0}
	}
	return dict

## Retorna os bônus de conjunto ativos conforme a quantidade de peças equipadas
static func get_set_bonus(set_name: String, piece_count: int) -> Dictionary:
	var sets = get_all_sets()
	if not sets.has(set_name):
		return {}
	var s = sets[set_name]
	var active_bonuses = {}
	if piece_count >= 2:
		for k in s["bonus_2"].keys(): active_bonuses[k] = active_bonuses.get(k, 0.0) + s["bonus_2"][k]
	if piece_count >= 4:
		for k in s["bonus_4"].keys(): active_bonuses[k] = active_bonuses.get(k, 0.0) + s["bonus_4"][k]
	if piece_count >= 6:
		for k in s["bonus_6"].keys(): active_bonuses[k] = active_bonuses.get(k, 0.0) + s["bonus_6"][k]
	return active_bonuses

static func get_set_definition(set_name: String) -> Dictionary:
	var sets = get_all_sets()
	return sets.get(set_name, {})

static func get_slot_key_for_type(type: int) -> String:
	match type:
		ItemType.ARMOR_HEAD: return "head"
		ItemType.ARMOR_SHOULDER: return "shoulders"
		ItemType.ARMOR_CHEST: return "chest"
		ItemType.ARMOR_GLOVES: return "gloves"
		ItemType.ARMOR_PANTS: return "pants"
		ItemType.ARMOR_BOOTS: return "boots"
		ItemType.CAPE: return "cape"
		ItemType.WINGS: return "wings"
		ItemType.WEAPON: return "weapon_main"
		ItemType.WEAPON_OFFHAND: return "weapon_off"
		ItemType.RING: return "ring_1"
		ItemType.AMULET: return "amulet"
		ItemType.MOUNT: return "mount"
		ItemType.PET: return "pet"
	return ""

static func get_slot_name_for_type(type: int) -> String:
	return get_slot_key_for_type(type)