extends RefCounted
class_name ForgeRecipes

static func get_all_recipes() -> Array[Dictionary]:
	var list: Array[Dictionary] = [
		{
			"id": "recipe_wings_tier2",
			"name": "🪽 Forjar Asas de Cristal Puro [Nvl 2]",
			"category": "Asas",
			"desc": "Fusão mística das Asas Élficas com Joias do Caos e da Alma. Concede +35% de dano e +28% de absorção.",
			"result_id": "wings_crystal_tier2",
			"result_count": 1,
			"gold_cost": 25000,
			"success_rate": 0.85, # 85%
			"ingredients": [
				{"id": "wings_crystal_tier1", "count": 1},
				{"id": "jewel_chaos", "count": 1},
				{"id": "jewel_soul", "count": 1},
				{"id": "brightsteel_fragment", "count": 2}
			]
		},
		{
			"id": "recipe_wings_tier3",
			"name": "🪽 Criar Asas Míticas do Rei Dragão [Nvl 3]",
			"category": "Asas",
			"desc": "A transmutação máxima da Máquina do Caos. Concede +68% de dano, +45% de absorção e aura de fogo azul.",
			"result_id": "wings_dragon_tier3",
			"result_count": 1,
			"gold_cost": 75000,
			"success_rate": 0.70, # 70%
			"ingredients": [
				{"id": "wings_crystal_tier2", "count": 1},
				{"id": "jewel_chaos", "count": 2},
				{"id": "jewel_creation", "count": 1},
				{"id": "jewel_soul", "count": 2}
			]
		},
		{
			"id": "recipe_sword_zarroc",
			"name": "⚔️ Forjar Lâmina Zar'roc Carmesim",
			"category": "Armas",
			"desc": "Transmuta aço refinado e fogo caótico na temida espada rubi dos Cavaleiros Renegados.",
			"result_id": "sword_zarroc",
			"result_count": 1,
			"gold_cost": 40000,
			"success_rate": 0.80, # 80%
			"ingredients": [
				{"id": "sword_steel", "count": 1},
				{"id": "jewel_chaos", "count": 1},
				{"id": "jewel_bless", "count": 2},
				{"id": "brightsteel_fragment", "count": 3}
			]
		},
		{
			"id": "recipe_jewel_creation",
			"name": "💎 Transmutar Joia da Criação",
			"category": "Joias",
			"desc": "Combinação sagrada de bênçãos e almas catalisada pelo fogo do Caos primordial.",
			"result_id": "jewel_creation",
			"result_count": 1,
			"gold_cost": 15000,
			"success_rate": 0.90, # 90%
			"ingredients": [
				{"id": "jewel_bless", "count": 2},
				{"id": "jewel_soul", "count": 2},
				{"id": "jewel_chaos", "count": 1}
			]
		},
		{
			"id": "recipe_elixir_dragon",
			"name": "🧪 Destilar Elixir Dracônico Supremo",
			"category": "Alquimia",
			"desc": "Condensa poções élficas sob alta pressão mágica, gerando um néctar que cura 100% de Vida e Mana.",
			"result_id": "elixir_dragon",
			"result_count": 2,
			"gold_cost": 8000,
			"success_rate": 1.00, # 100% garantido
			"ingredients": [
				{"id": "potion_health", "count": 3},
				{"id": "potion_mana", "count": 3},
				{"id": "jewel_chaos", "count": 1}
			]
		}
	]
	return list

static func can_craft(recipe: Dictionary, stats) -> bool:
	if not stats:
		return false
	if stats.gold < recipe.get("gold_cost", 0):
		return false
	for ing in recipe.get("ingredients", []):
		var item_id = ing["id"]
		var req_count = ing["count"]
		if stats.count_item(item_id) < req_count:
			return false
	return true
