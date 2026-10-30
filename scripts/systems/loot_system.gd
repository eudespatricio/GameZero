extends Node
class_name LootSystem
## Sistema de Loot e Geração de Equipamentos Instanciados com Affixes Aleatórios.
## Suporta os 21 Sets de Armadura, Armas, Escudos, Joias e Drops Globais Raros (Lendários e Divinos).

const AFFIX_DEFINITIONS = {
	"strength": {"name": "da Força Titânica", "min": 5, "max": 25, "is_pct": false, "format": "+%d Força"},
	"dexterity": {"name": "da Agilidade Élfica", "min": 5, "max": 25, "is_pct": false, "format": "+%d Destreza"},
	"vitality": {"name": "da Vitalidade dos Montes", "min": 5, "max": 25, "is_pct": false, "format": "+%d Vitalidade"},
	"willpower": {"name": "da Vontade Arcana", "min": 5, "max": 25, "is_pct": false, "format": "+%d Vontade"},
	"max_hp": {"name": "da Robustez", "min": 80, "max": 450, "is_pct": false, "format": "+%d Vida Máxima"},
	"max_mp": {"name": "da Mente Clara", "min": 40, "max": 280, "is_pct": false, "format": "+%d Mana Máxima"},
	"fire_dmg_pct": {"name": "do Fogo Dracônico", "min": 6.0, "max": 22.0, "is_pct": true, "format": "+%.1f%% Dano de Fogo"},
	"crit_chance": {"name": "da Precisão Letal", "min": 3.0, "max": 12.0, "is_pct": true, "format": "+%.1f%% Taxa Crítica"},
	"crit_damage_pct": {"name": "do Impacto Devastador", "min": 10.0, "max": 35.0, "is_pct": true, "format": "+%.1f%% Dano Crítico"},
	"armor_pct": {"name": "do Aço Temperado", "min": 8.0, "max": 25.0, "is_pct": true, "format": "+%.1f%% Armadura"},
	"cooldown_reduction": {"name": "dos Reflexos Rápidos", "min": 4.0, "max": 14.0, "is_pct": true, "format": "+%.1f%% Redução de Recarga"},
	"block_chance": {"name": "da Guarda Inabalável", "min": 5.0, "max": 18.0, "is_pct": true, "format": "+%.1f%% Chance de Bloqueio"},
	"dodge_pct": {"name": "do Vento Veloz", "min": 4.0, "max": 15.0, "is_pct": true, "format": "+%.1f%% Esquiva"},
	"all_damage_pct": {"name": "do Conquistador", "min": 5.0, "max": 18.0, "is_pct": true, "format": "+%.1f%% Dano Geral"}
}

## Gera um item instanciado com 1 a 4 atributos aleatórios baseado na raridade
static func create_instanced_item(item_id: String, target_class: String = "") -> Dictionary:
	var all_items = ItemsDatabase.get_all_items()
	if not all_items.has(item_id):
		return {"id": item_id, "refine": 0, "affixes": []}

	var base_data: Dictionary = all_items[item_id]
	var rarity = base_data.get("rarity", ItemsDatabase.Rarity.COMMON)
	var c_req = base_data.get("class_req", target_class)
	if c_req == "" and target_class != "":
		c_req = target_class

	# Quantidade de affixes por raridade
	var num_affixes := 0
	match rarity:
		ItemsDatabase.Rarity.COMMON:
			num_affixes = 1 if randf() < 0.4 else 0
		ItemsDatabase.Rarity.MAGIC:
			num_affixes = randi_range(1, 2)
		ItemsDatabase.Rarity.RARE:
			num_affixes = randi_range(2, 3)
		ItemsDatabase.Rarity.EPIC:
			num_affixes = randi_range(3, 4)
		ItemsDatabase.Rarity.LEGENDARY:
			num_affixes = 4
		ItemsDatabase.Rarity.MYTHIC, ItemsDatabase.Rarity.DIVINE:
			num_affixes = 4

	var affixes: Array = []
	var pool: Array = AFFIX_DEFINITIONS.keys()

	# Prioriza affixes da classe alvo se definida
	var class_weights: Dictionary = {}
	var classes = ClassesData.get_all_classes()
	if classes.has(c_req):
		class_weights = classes[c_req].get("affix_weights", {})

	var chosen_stats := []
	for i in range(num_affixes):
		var available = []
		for st in pool:
			if st not in chosen_stats:
				available.append(st)
		if available.is_empty():
			break

		# Ponderação
		var selected_stat = available[randi() % available.size()]
		var best_weight := 0.0
		for cand in available:
			var w = class_weights.get(cand, 1.0) * randf()
			if w > best_weight:
				best_weight = w
				selected_stat = cand

		chosen_stats.append(selected_stat)
		var def = AFFIX_DEFINITIONS[selected_stat]

		# Rolagem do valor
		var mult = 1.0
		if rarity == ItemsDatabase.Rarity.LEGENDARY:
			mult = randf_range(0.85, 1.0)
		elif rarity == ItemsDatabase.Rarity.MYTHIC or rarity == ItemsDatabase.Rarity.DIVINE:
			mult = 1.0
		else:
			mult = randf_range(0.35, 0.95)

		var val
		if def["is_pct"]:
			val = round((def["min"] + (def["max"] - def["min"]) * mult) * 10.0) / 10.0
		else:
			val = int(round(def["min"] + (def["max"] - def["min"]) * mult))

		var desc_text = def["format"] % val
		affixes.append({
			"stat": selected_stat,
			"name": def["name"],
			"val": val,
			"desc": desc_text,
			"display": desc_text
		})

	# 5º Affix Divino especial para itens Míticos / Divinos
	if rarity == ItemsDatabase.Rarity.MYTHIC or rarity == ItemsDatabase.Rarity.DIVINE:
		var divine_bonus = {
			"stat": "divine_power",
			"name": "Bênção Cósmica Ancestral",
			"val": 35.0,
			"desc": "🌟 +35% de Poder Mítico e Transcendência",
			"display": "🌟 +35% de Poder Mítico e Transcendência"
		}
		affixes.append(divine_bonus)

	return {
		"id": item_id,
		"uid": "inst_%d_%d" % [Time.get_ticks_msec(), randi() % 99999],
		"refine": 0,
		"affixes": affixes,
		"rarity": rarity,
		"class_req": c_req,
		"level_req": base_data.get("level_req", 1)
	}

static func roll_mob_loot(tree: SceneTree, mob_name: String, mob_level: int, is_boss: bool, death_pos: Vector3) -> Dictionary:
	var result = {"gold": 0, "dropped_jewel": "", "dropped_material": "", "drops": []}
	var drops: Array = []  # [{kind, id, amount, instance}]

	# 1. Ouro (escalonado)
	var base_gold = mob_level * randi_range(35, 75)
	if is_boss:
		base_gold *= 8
	result["gold"] = base_gold
	var piles = 3 if is_boss else (2 if base_gold > 800 else 1)
	for i in piles:
		drops.append({"kind": "gold", "amount": int(float(base_gold) / float(piles))})

	# 2. Joias MU Online
	var bless_chance = 0.55 if is_boss else 0.08
	var soul_chance = 0.35 if is_boss else 0.04
	var chaos_chance = 0.22 if is_boss else 0.02
	var roll = randf()
	var jewel = ""
	if roll < chaos_chance:
		jewel = "jewel_chaos"
	elif roll < chaos_chance + soul_chance:
		jewel = "jewel_soul"
	elif roll < chaos_chance + soul_chance + bless_chance:
		jewel = "jewel_bless"
	if jewel != "":
		result["dropped_jewel"] = jewel
		drops.append({"kind": "item", "id": jewel, "amount": 1})

	# 3. Materiais e Poções
	if randf() < 0.28 or is_boss:
		drops.append({"kind": "item", "id": "brightsteel_fragment", "amount": 1})
	elif randf() < 0.45:
		drops.append({"kind": "item", "id": "menoa_bark", "amount": 1})

	if randf() < 0.25:
		drops.append({"kind": "item", "id": "potion_health", "amount": 1})
	if randf() < 0.15:
		drops.append({"kind": "item", "id": "potion_mana", "amount": 1})

	# 4. Equipamentos (Tiers decimais + Drops Globais Raros e Divinos)
	var gear_chance = 0.15 + min(mob_level, 50) * 0.003
	if is_boss:
		gear_chance = 1.0

	if randf() < gear_chance:
		var rolled_item_id = _select_equipment_drop(mob_level, is_boss)
		if rolled_item_id != "":
			var inst = create_instanced_item(rolled_item_id)
			drops.append({
				"kind": "item",
				"id": rolled_item_id,
				"amount": 1,
				"instance": inst
			})

		# Bosses dropam uma 2ª peça de equipamento
		if is_boss:
			var second_id = _select_equipment_drop(mob_level, true)
			if second_id != "":
				var inst2 = create_instanced_item(second_id)
				drops.append({
					"kind": "item",
					"id": second_id,
					"amount": 1,
					"instance": inst2
				})

	result["drops"] = drops
	var parent = tree.current_scene
	if parent == null:
		return result

	var idx = 0
	for d in drops:
		var node = LootDrop.new()
		node.kind = d["kind"]
		node.item_id = d.get("id", "")
		node.amount = d.get("amount", 1)
		if d.has("instance"):
			node.set("item_instance", d["instance"])
		var ang = TAU * float(idx) / max(drops.size(), 1) + randf() * 0.6
		var off = Vector3(cos(ang), 0, sin(ang)) * (0.9 + randf() * 0.9)
		parent.add_child(node)
		node.global_position = death_pos + Vector3(0, 0.3, 0)
		node.launch(death_pos + off)
		idx += 1

	if jewel != "":
		GameAudio.play_jewel(tree)
	return result

## Seleciona o item baseado no nível do mob, com suporte a drops globais Lendários e Divinos
static func _select_equipment_drop(mob_level: int, is_boss: bool) -> String:
	# 1. Checagem de Drop Divino (Ultra Raro Global: 0.05% normal, 1.5% boss)
	var divine_chance = 0.015 if is_boss else 0.0005
	if randf() < divine_chance:
		var divines = [
			"sword_vermund_divine", "bow_menoa_divine", "hammer_helzvog_divine",
			"ring_vermund_divine", "amulet_helzvog_eye", "shield_helzvog",
			"helm_cosmico_vermund", "chest_cosmico_vermund", "boots_cosmico_vermund",
			"helm_astral_menoa", "chest_astral_menoa", "boots_astral_menoa",
			"helm_titanico_helzvog", "chest_titanico_helzvog", "boots_titanico_helzvog"
		]
		return divines[randi() % divines.size()]

	# 2. Checagem de Drop Lendário (Raro Global: 0.8% normal, 10% boss)
	var legendary_chance = 0.10 if is_boss else 0.008
	if randf() < legendary_chance:
		var legendaries = [
			"sword_zarroc", "blade_tamerlein", "hammer_volund",
			"shield_hrothgar", "ring_starfire", "wings_tier3_supreme",
			"helm_primeiros_cavaleiros", "chest_primeiros_cavaleiros", "boots_primeiros_cavaleiros",
			"helm_rainha_islanzadi", "chest_rainha_islanzadi", "boots_rainha_islanzadi",
			"helm_rei_hrothgar", "chest_rei_hrothgar", "boots_rei_hrothgar"
		]
		return legendaries[randi() % legendaries.size()]

	# 3. Equipamentos Progressivos da Faixa de Nível do Mob (Tiers 1 a 5)
	var tier := 1
	if mob_level >= 41: tier = 5
	elif mob_level >= 31: tier = 4
	elif mob_level >= 21: tier = 3
	elif mob_level >= 11: tier = 2

	var set_prefix := "recruta_carvahall"
	var class_choice = ["zero", "arya", "roran"][randi() % 3]

	match tier:
		1:
			match class_choice:
				"zero": set_prefix = "recruta_carvahall"
				"arya": set_prefix = "rastreador_bosques"
				"roran": set_prefix = "aprendiz_forja"
		2:
			match class_choice:
				"zero": set_prefix = "escudeiro_aco"
				"arya": set_prefix = "patrulha_elfica"
				"roran": set_prefix = "milicia_espinha"
		3:
			match class_choice:
				"zero": set_prefix = "cavaleiro_fogo"
				"arya": set_prefix = "sombras_weldenvarden"
				"roran": set_prefix = "rompedor_batalha"
		4:
			match class_choice:
				"zero": set_prefix = "dragon_knight"
				"arya": set_prefix = "prata_menoa"
				"roran": set_prefix = "flagelo_kulls"
		5:
			match class_choice:
				"zero": set_prefix = "soberano_sylveria"
				"arya": set_prefix = "nobreza_ellesmera"
				"roran": set_prefix = "inquebravel_farthen"

	var pieces = ["helm", "shoulders", "chest", "gloves", "pants", "boots"]
	var chosen_piece = pieces[randi() % pieces.size()]
	return "%s_%s" % [chosen_piece, set_prefix]
