extends RefCounted
class_name ZonesData

static func get_all_zones() -> Array[Dictionary]:
	return [
		{
			"id": "carvahall_valley",
			"name": "🌾 Vale do Palancar & Carvahall",
			"level_range": "Níveis 1 – 10 [Origem Humana]",
			"description": "Colinas verdes e fazendas pacatas às margens da montanha proibida. Local onde o protagonista viveu como caçador antes do chamado do destino.",
			"safe_zone": "Aldeia de Carvahall (Ferreiro Horst)",
			"mobs": [
				{"name": "Javali da Floresta", "level": "1-3", "type": "Comum", "drop": "Carne Seca, Couro Rústico"},
				{"name": "Lobo da Espinha", "level": "4-6", "type": "Matilha", "drop": "Presa Afiada, Poção Menor"},
				{"name": "Bandido Desertor", "level": "7-9", "type": "Humanoide", "drop": "Moedas, Peitoral de Couro"}
			],
			"mini_boss": {"name": "Alfa Voraz da Espinha (Nvl 6)", "desc": "Lobo titânico com uivo atordoante."},
			"world_boss": {
				"name": "O Saqueador Urgal (Nvl 10)",
				"desc": "Bárbaro guerreiro armado com machado rústico pesado.",
				"reward": "Primeira Joia da Bênção (+1) e Espada de Carvahall"
			}
		},
		{
			"id": "the_spine",
			"name": "⛰️ Cordilheira da Espinha (The Spine)",
			"level_range": "Níveis 11 – 20 [O Ninho do Dragão]",
			"description": "Picos escarpados e ventos uivantes onde aldeões temem pisar. Berço onde o ovo de dragão é encontrado e a marca Gedwëy Ignasia desperta.",
			"safe_zone": "Caverna dos Ninhos / Acampamento Eremita",
			"mobs": [
				{"name": "Víbora das Rochas", "level": "11-13", "type": "Veneno", "drop": "Veneno Cristalizado"},
				{"name": "Drake Jovem da Espinha", "level": "14-17", "type": "Alado", "drop": "Escama de Dragão Menor"},
				{"name": "Batedor Urgal de Chifre", "level": "18-19", "type": "Soldado", "drop": "Escudo de Ferro Rústico"}
			],
			"mini_boss": {"name": "Matriarca Wyvern (Nvl 16)", "desc": "Criatura alada com rasantes e pedras pontiagudas."},
			"world_boss": {
				"name": "O Caçador Ra'zac (Nvl 20)",
				"desc": "O sinistro assassino sem sangue, mestre das sombras e bile corrosiva.",
				"reward": "Joia da Alma (+7), Sela de Voo do Dragão e Armadura Reforçada"
			}
		},
		{
			"id": "yazuac_wasteland",
			"name": "🔥 Ruínas de Yazuac & Terras dos Kulls",
			"level_range": "Níveis 21 – 35 [A Marcha dos Gigantes]",
			"description": "Vilarejo destruído pela horda bárbara com céu tingido de cinzas. Território de gigantes Kulls de 2,5 metros e feitiços primitivos.",
			"safe_zone": "Posto Avançado da Fronteira",
			"mobs": [
				{"name": "Guerreiro Urgal Enfurecido", "level": "21-24", "type": "Bruto", "drop": "Machado de Batalha"},
				{"name": "Xamã de Sangue Urgal", "level": "25-28", "type": "Mago", "drop": "Orbe Flamejante, Poção Média"},
				{"name": "Kull Jovem", "level": "29-34", "type": "Gigante", "drop": "Fragmento de Aço Negro"}
			],
			"mini_boss": {"name": "Chefe do Clã Gromk (Nvl 28)", "desc": "Gira com machado pesado em turbilhão contínuo."},
			"world_boss": {
				"name": "General Kull: Nar Garzhvog (Nvl 35)",
				"desc": "Titã de honra e pura força física. Pisotões sísmicos e investidas brutais.",
				"reward": "Armadura de Placas de Aço Negro (+9 Glow) e Joia da Criação"
			}
		},
		{
			"id": "du_weldenvarden_gates",
			"name": "🌲 Portões de Du Weldenvarden & Prova Élfica",
			"level_range": "Níveis 36 – 50 [A Transfiguração Élfica]",
			"description": "A sagrada e colossal floresta dos elfos, onde cada árvore é viva e cantada em magia. O local do despertar final do Cavaleiro de Dragão.",
			"safe_zone": "Santuário de Sylveria [Pátio de Mármore]",
			"mobs": [
				{"name": "Golen de Raiz Antiga", "level": "36-39", "type": "Construto", "drop": "Seiva de Menoa, Madeira Viva"},
				{"name": "Fanghur das Sombras", "level": "40-43", "type": "Espírito", "drop": "Essência Élfica, Dreno de Mana"},
				{"name": "Guardião Silvestre Corrompido", "level": "44-48", "type": "Arqueiro", "drop": "Arco Curvo de Prata"}
			],
			"mini_boss": {"name": "Guardião de Pedra Élfico (Nvl 42)", "desc": "Estátua animada com reflexão de magia."},
			"world_boss": {
				"name": "Durza, O Espectro (The Shade) (Nvl 50)",
				"desc": "Chefe Máximo do Arco 1. Feiticeiro imortal com clones de sombra e forma de fumaça.",
				"reward": "Lâmina Brisingr/Zar'roc (+11 Glow), Asas Élficas Nvl 2 e Transfiguração em Elfo"
			}
		}
	]
