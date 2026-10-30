extends RefCounted
class_name DragonsDatabase
## Catálogo de Dragões e Montarias de Alagaësia.
## Inclui os 5 Tiers progressivos de montarias e os Dragões Míticos dos Cavaleiros,
## além de Umaroth, o Dragão Branco Ancião do Ritual do Nível 50.

static func get_all_dragons() -> Dictionary:
	return {
		# --- TIERS PROGRESSIVOS (1 A 5) ---
		"draco_tropeiro": {
			"name": "Draco Veloz de Carvahall",
			"tier": 1,
			"level_req": 1,
			"rarity": 0, # COMMON
			"scale_color": Color(0.65, 0.55, 0.4),
			"wingspan_meters": 5.0,
			"move_speed_bonus": 1.4,
			"bonus_hp": 150.0,
			"lore": "Jovem réptil domesticado nas planícies do vale de Palancar. Ágil no trote e incansável em trilhas rochosas."
		},
		"wyvern_bosques": {
			"name": "Wyvern Alado dos Bosques",
			"tier": 2,
			"level_req": 11,
			"rarity": 1, # MAGIC
			"scale_color": Color(0.2, 0.7, 0.35),
			"wingspan_meters": 9.0,
			"move_speed_bonus": 1.75,
			"bonus_defense": 60.0,
			"lore": "Wyvern nativo das bordas da grande floresta. Realiza saltos prodigiosos e planeia com facilidade sobre rios e desfiladeiros."
		},
		"dragao_sylveria": {
			"name": "Dragão Alado de Sylveria",
			"tier": 3,
			"level_req": 21,
			"rarity": 2, # RARE
			"scale_color": Color(0.2, 0.85, 0.8),
			"wingspan_meters": 14.0,
			"move_speed_bonus": 2.1,
			"damage_bonus_pct": 15.0,
			"lore": "Criado sob o resplendor dos santuários élficos. Capaz de voo sustentado contínuo e sincronia espiritual com seu cavaleiro."
		},
		"dragao_guerra": {
			"name": "Dragão de Guerra Blindado",
			"tier": 4,
			"level_req": 31,
			"rarity": 3, # EPIC
			"scale_color": Color(0.75, 0.25, 0.2),
			"wingspan_meters": 20.0,
			"move_speed_bonus": 2.45,
			"absorb_bonus_pct": 25.0,
			"active_breath": "Sopro de Fogo Pesado que atordoa alvos atingidos.",
			"lore": "Vestido com placas articuladas forjadas em Brightsteel. Um terror voador que rompe linhas de cerco e esmaga pelotões de kulls."
		},
		"dragao_soberano": {
			"name": "Dragão Soberano de Urû'baen",
			"tier": 5,
			"level_req": 41,
			"rarity": 4, # LEGENDARY
			"scale_color": Color(0.9, 0.75, 0.2),
			"wingspan_meters": 28.0,
			"move_speed_bonus": 2.8,
			"all_stats_bonus": 25,
			"active_breath": "Inferno Dracônico Cósmico em leque de 180°.",
			"lore": "Monarca dos céus de Alagaësia. A magnitude de sua envergadura cobre os montes e sua presença impõe reverência a feras e homens."
		},

		# --- DRAGÕES MÍTICOS DOS CAVALEIROS ---
		"saphira": {
			"name": "Saphira (A Dama Safira)",
			"tier": 5,
			"level_req": 30,
			"rarity": 5, # MYTHIC
			"element": "Vento & Frio Astral",
			"scale_color": Color(0.1, 0.4, 0.95),
			"wingspan_meters": 22.0,
			"move_speed_bonus": 3.2,
			"lore": "A lendária dragão azul de escamas reluzentes como gemas preciosas. Dotada de telepatia refinada e conexão inabalável com o Cavaleiro Zero.",
			"active_breath": "Sopro de Frio Astral: Congela o chão e reduz velocidade em 45%.",
			"passive_buff": "+30% Regeneração de Mana e +20% Velocidade de Voo."
		},
		"thorn": {
			"name": "Thorn (O Espinho Carmesim)",
			"tier": 5,
			"level_req": 30,
			"rarity": 5,
			"element": "Fogo Puro & Fúria",
			"scale_color": Color(0.9, 0.15, 0.15),
			"wingspan_meters": 20.5,
			"move_speed_bonus": 3.0,
			"lore": "Chocado em meio ao caos da guerra. Compacto, agressivo e de reflexos fulminantes.",
			"active_breath": "Inferno Carmesim: Cortina de chamas devastadoras.",
			"passive_buff": "+25% Dano Crítico e +20% Resistência Elemental."
		},
		"glaedr": {
			"name": "Glaedr (A Montanha de Ouro)",
			"tier": 5,
			"level_req": 40,
			"rarity": 4, # LEGENDARY
			"element": "Energia Solar & Terra",
			"scale_color": Color(0.95, 0.78, 0.15),
			"wingspan_meters": 32.0,
			"move_speed_bonus": 2.9,
			"lore": "O grande mestre dourado. Sua sabedoria milenar orienta os heróis através do Eldunarí.",
			"active_breath": "Rugido Solar Sísmico: Onda de choque que desestabiliza o terreno.",
			"passive_buff": "+35% Armadura Física e Redução de Dano."
		},
		"shruikan": {
			"name": "Shruikan (O Titã Negro)",
			"tier": 5,
			"level_req": 50,
			"rarity": 5, # MYTHIC
			"element": "Fogo Negro & Caos",
			"scale_color": Color(0.08, 0.08, 0.12),
			"wingspan_meters": 45.0,
			"move_speed_bonus": 3.4,
			"lore": "O colossal dragão do império. Seu poder bruto desafia as leis da natureza.",
			"active_breath": "Chamas Negras do Desespero: Drena 30% da vida dos inimigos.",
			"passive_buff": "+40% Dano Bruto e Presença Aterrorizante."
		},

		# --- ENDGAME CAPSTONE: O DRAGÃO MAIS SÁBIO DA HISTÓRIA ---
		"umaroth": {
			"name": "Umaroth (O Branco / Mestre dos Eldunarí)",
			"tier": 6,
			"level_req": 50,
			"rarity": 5, # MYTHIC / DIVINE
			"element": "Luz Cósmica Primordial",
			"scale_color": Color(0.98, 0.98, 1.0),
			"eye_color": Color(0.3, 0.7, 1.0),
			"wingspan_meters": 40.0,
			"lore": "O dragão do líder lendário Vrael e o maior e mais sábio Eldunarí de toda a história de Alagaësia. Ao atingir o Level Cap 50, ele conduz o Ritual da Ascensão Dracônica, imbuindo o herói com a sabedoria transcendental de sua raça.",
			"ritual_role": "Condutor do Ritual de Ascensão Dracônica no Nível 50."
		}
	}
