extends RefCounted
class_name ClassesData
## Banco de Dados Central das Classes de Alagaësia.
## Define os arquétipos, atributos base, proficiências, pesos de affixes
## e o Despertar do Ritual de Umaroth no Nível 50.

static func get_all_classes() -> Dictionary:
	return {
		"zero": {
			"name": "Zero (O Cavaleiro de Dragão)",
			"title": "Portador da Gedwëy Ignasia",
			"archetype": "Híbrido (Melee / Magia Arcana)",
			"weapon_type": "Espada Bastarda / Magia de Chamas",
			"primary_stats": ["strength", "willpower"],
			"base_hp": 2450,
			"base_mp": 1180,
			"strength": 28,
			"dexterity": 22,
			"vitality": 25,
			"willpower": 24,
			"passives": "Transfiguração Élfica: Ganha +2% de agilidade por nível e regenera mana ao desferir golpes críticos.",
			"skills": [
				{"key": "1", "name": "Brisingr", "type": "Ataque Mágico", "desc": "Dispara projétil de fogo que inflama o chão e queima inimigos."},
				{"key": "2", "name": "Jierda", "type": "Quebra de Armadura", "desc": "Golpe cinético que quebra escudos e reduz a defesa do alvo em 35%."},
				{"key": "3", "name": "Vórtice de Aço", "type": "Área (AoE)", "desc": "Gira com a lâmina em 360° repelindo todos os monstros próximos."},
				{"key": "4", "name": "Asas do Dragão", "type": "Mobilidade / Voo", "desc": "Abre asas de energia, ganha 50% de velocidade e atravessa obstáculos."}
			],
			"affix_weights": {
				"fire_dmg_pct": 3.0,
				"strength": 2.5,
				"willpower": 2.5,
				"cooldown_reduction": 2.0,
				"hybrid_power": 2.0,
				"max_mp": 1.5,
				"max_hp": 1.5,
				"crit_chance": 1.5
			},
			"umaroth_awakening": {
				"name": "Transcendência da Gedwëy Ignasia",
				"desc": "35% do dano converte-se em Fogo Dracônico Sagrado. Acertos críticos invocam chuva de meteoros astrais. +500 HP, +250 MP, +20% CDR permanente.",
				"bonus_hp": 500.0,
				"bonus_mp": 250.0,
				"cdr_pct": 20.0,
				"fire_convert_pct": 35.0
			}
		},
		"arya": {
			"name": "Arya (A Guardiã de Ellesméra)",
			"title": "Mestra-Espadachim e Alta Maga Élfica",
			"archetype": "Duelista de Precisão (Agilidade / Alta Magia)",
			"weapon_type": "Lâmina Fina Élfica & Arco de Teixo",
			"primary_stats": ["dexterity", "willpower"],
			"base_hp": 1850,
			"base_mp": 1950,
			"strength": 16,
			"dexterity": 38,
			"vitality": 18,
			"willpower": 36,
			"passives": "Graça de Ellesméra: 25% de chance de esquiva completa de ataques físicos e passos silenciosos.",
			"skills": [
				{"key": "1", "name": "Canto do Vento", "type": "Buff de Grupo", "desc": "Aumenta a velocidade de ataque e esquiva de toda a equipe em 30%."},
				{"key": "2", "name": "Waíse Heill", "type": "Cura e Purificação", "desc": "Restaura instantaneamente a vida de si mesma ou de um aliado próximo."},
				{"key": "3", "name": "Dardo de Prata", "type": "Disparo Preciso", "desc": "Flecha encantada perfurante com 100% de chance de acerto crítico."},
				{"key": "4", "name": "Dança das Folhas", "type": "Teleporte de Esquiva", "desc": "Desaparece em pétalas mágicas e ressurge atrás do inimigo."}
			],
			"affix_weights": {
				"dexterity": 3.0,
				"crit_chance": 2.5,
				"crit_damage": 2.5,
				"dodge_pct": 2.5,
				"attack_speed": 2.0,
				"armor_penetration": 2.0,
				"willpower": 1.5,
				"max_mp": 1.5
			},
			"umaroth_awakening": {
				"name": "Comunhão da Grande Árvore Menoa",
				"desc": "Esquivas geram clones astrais que atacam inimigos. +50% Dano Crítico, +15% Velocidade Geral, penetração absoluta de armadura. +300 HP, +400 MP.",
				"bonus_hp": 300.0,
				"bonus_mp": 400.0,
				"crit_damage_pct": 50.0,
				"move_speed_pct": 15.0
			}
		},
		"roran": {
			"name": "Roran (O Martelo-Forte)",
			"title": "O Guerreiro Indomável de Carvahall",
			"archetype": "Conquistador / Berserker (Tanque Físico Puro)",
			"weapon_type": "Martelo de Guerra de Duas Mãos & Escudo Pesado",
			"primary_stats": ["strength", "vitality"],
			"base_hp": 3400,
			"base_mp": 450,
			"strength": 42,
			"dexterity": 14,
			"vitality": 44,
			"willpower": 12,
			"passives": "Vontade de Ferro: Conforme a vida cai, ganha até 50% de bônus de dano e resistência a atordoamentos.",
			"skills": [
				{"key": "1", "name": "Impacto Sísmico", "type": "Controle de Multidão", "desc": "Esmaga o chão com o martelo, atordoando todos os inimigos por 2s."},
				{"key": "2", "name": "Grito de Guerra de Carvahall", "type": "Buff de Tanque", "desc": "Provoca todos os monstros da área a atacarem Roran e concede +40% de Armadura."},
				{"key": "3", "name": "Golpe Demolidor", "type": "Dano Massivo", "desc": "Golpe carregado de cima para baixo que causa 300% de dano em alvo único."},
				{"key": "4", "name": "Fúria Inquebrável", "type": "Sobrevivência", "desc": "Fica imune à morte e absorve 40% do dano recebido como vida por 5s."}
			],
			"affix_weights": {
				"vitality": 3.0,
				"strength": 2.5,
				"armor_pct": 2.5,
				"block_chance": 2.5,
				"damage_reduction": 2.0,
				"hp_regen": 2.0,
				"max_hp": 2.0,
				"thorns_reflect": 1.5
			},
			"umaroth_awakening": {
				"name": "Alma Inquebrável de Helzvog",
				"desc": "Imunidade permanente a atordoamentos e empurrões. Barreira invulnerável de 4s em golpe letal (CD 120s). Ondas sísmicas de 2.5x dano. +800 HP.",
				"bonus_hp": 800.0,
				"bonus_mp": 100.0,
				"armor_bonus_pct": 50.0,
				"cc_immune": true
			}
		}
	}
