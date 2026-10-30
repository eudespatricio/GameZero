extends Node
class_name CharacterStats

signal stats_changed
signal level_up(new_level: int)
signal enhancement_result(success: bool, new_level: int, message: String)
signal gear_equipped(slot_key: String, item_id: String)
signal gear_unequipped(slot_key: String)
signal bag_changed
signal stat_points_changed
signal quest_updated(quest_id: String)
signal xp_gained(amount: int, source_name: String)
## Emitido a cada dano recebido, já com esquiva/bloqueio/mitigação resolvidos.
signal damage_resolved(final_damage: float, dodged: bool, blocked: bool)

var current_class_id: String = "zero"
var character_name: String = "Zero"

# --- PROGRESSÃO & ECONOMIA ---
var level: int = 1
var current_xp: int = 0
var max_xp: int = 400

var gold: int = 500
var stat_points: int = 0
var total_kills: int = 0

# --- MOCHILA REAL (33 SLOTS) ---
# Cada slot é {} (vazio) ou {"id": String, "count": int}. As joias vivem na mochila e podem ser movidas.
const BAG_SIZE: int = 33
var bag: Array = []

# Contadores de joias são projeções da mochila (compatibilidade com refino/HUD/testes)
var jewels_bless: int:
	get: return count_item("jewel_bless")
	set(v): set_item_count("jewel_bless", v)
var jewels_soul: int:
	get: return count_item("jewel_soul")
	set(v): set_item_count("jewel_soul", v)
var jewels_chaos: int:
	get: return count_item("jewel_chaos")
	set(v): set_item_count("jewel_chaos", v)

# --- MISSÕES ---
var quests: Dictionary = {}

# --- VITAIS & ATRIBUTOS BASE ---
var current_hp: float = 2450.0
var max_hp: float = 2450.0
var current_mp: float = 1180.0
var max_mp: float = 1180.0

var strength: int = 28
var dexterity: int = 22
var vitality: int = 25
var willpower: int = 24

# --- EQUIPAMENTOS (PAPERDOLL DE 15 SLOTS) ---
var equipped_gear: Dictionary = {
	"head": "helm_dragon_knight",
	"shoulders": "shoulders_dragon_knight",
	"chest": "chest_dragon_knight",
	"gloves": "gloves_dragon_knight",
	"pants": "pants_dragon_knight",
	"boots": "boots_dragon_knight",
	"cape": "cape_rider",
	"wings": "wings_crystal_tier2",
	"weapon_main": "sword_brisingr",
	"weapon_off": "shield_dragon_scale",
	"ring_1": "ring_aren",
	"ring_2": "ring_starfire",
	"amulet": "amulet_ancient_language",
	"mount": "mount_saphira",
	"pet": "pet_baby_dragon"
}

# Níveis de Refino individuais
var weapon_refine: int = 11   # Brisingr (+11) com Glow Safira
var armor_refine: int = 9     # Peitoral (+9) com Glow Dourado
var wings_tier: int = 2       # Asas de Cristal Puro Nvl 2
var ritual_awakened: int = 0  # 1 = Despertar de Umaroth completado (Nv 50)

# --- CACHE DE BÔNUS (affixes + conjuntos) ---
# Antes, cada getter varria o paperdoll e reconstruía o catálogo de itens.
# Agora tudo é agregado numa passada só e reutilizado até o próximo recálculo.
var _affix_totals: Dictionary = {}
var _set_counts: Dictionary = {}
var _bonus_ready: bool = false

func _init() -> void:
	bag.resize(BAG_SIZE)
	for i in BAG_SIZE:
		bag[i] = {}
	for entry in [["jewel_bless", 12], ["jewel_soul", 6], ["jewel_chaos", 4], ["potion_health", 5], ["potion_mana", 3],
			["sword_zarroc", 1], ["hammer_roran", 1], ["bow_ellesmera", 1], ["helm_ellesmera_guard", 1],
			["shoulders_silver_leaf", 1], ["pants_elven_mesh", 1], ["boots_sylveria", 1], ["cape_elven_cloak", 1],
			["orb_angela", 1], ["ring_mithril", 1], ["amulet_menoa_tear", 1], ["pet_mystic_owl", 1],
			["tome_ancient_language", 1], ["fairth_stone", 3]]:
		add_item(entry[0], entry[1])

func _ready() -> void:
	max_xp = get_max_xp_for_level(level)
	apply_class_data(current_class_id)
	recalculate_stats()

func get_max_xp_for_level(lvl: int) -> int:
	var base = 400
	for i in range(1, lvl):
		base = int(base * 1.25)
	return max(base, 100)

## Aplica o arquétipo da classe preservando a proporção de HP/MP atual.
## (Antes, trocar de classe com Tab curava o herói por completo: exploit em boss.)
func apply_class_data(class_id: String) -> void:
	var classes = ClassesData.get_all_classes()
	if not classes.has(class_id):
		return

	var hp_ratio := 1.0
	var mp_ratio := 1.0
	if max_hp > 0.0:
		hp_ratio = clampf(current_hp / max_hp, 0.0, 1.0)
	if max_mp > 0.0:
		mp_ratio = clampf(current_mp / max_mp, 0.0, 1.0)

	current_class_id = class_id
	var d = classes[class_id]
	character_name = d["name"]
	max_hp = float(d["base_hp"])
	max_mp = float(d["base_mp"])
	strength = d["strength"]
	dexterity = d["dexterity"]
	vitality = d["vitality"]
	willpower = d["willpower"]
	recalculate_stats()

	current_hp = clampf(max_hp * hp_ratio, 0.0, max_hp)
	current_mp = clampf(max_mp * mp_ratio, 0.0, max_mp)

func _get_slot_item_id(slot: String) -> String:
	var val = equipped_gear.get(slot, "")
	if val is Dictionary: return val.get("id", "")
	elif val is String: return val
	return ""

func _get_slot_item_affixes(slot: String) -> Array:
	var val = equipped_gear.get(slot, "")
	if val is Dictionary: return val.get("affixes", [])
	return []

# ------------------------------------------------------------------
# AGREGAÇÃO DE BÔNUS
# ------------------------------------------------------------------
## Uma única passada por paperdoll + conjuntos: alimenta todos os cálculos.
func _rebuild_bonus_cache() -> void:
	_affix_totals.clear()
	_set_counts.clear()
	var all_items = ItemsDatabase.get_all_items()

	for slot in equipped_gear.keys():
		var item_id := _get_slot_item_id(slot)
		for af in _get_slot_item_affixes(slot):
			if af is Dictionary:
				var stat_name := str(af.get("stat", ""))
				if stat_name != "":
					_affix_totals[stat_name] = float(_affix_totals.get(stat_name, 0.0)) + float(af.get("val", 0))
		if all_items.has(item_id):
			var item: Dictionary = all_items[item_id]
			var set_name := str(item.get("set_name", ""))
			if set_name != "":
				_set_counts[set_name] = int(_set_counts.get(set_name, 0)) + 1

	# Bônus de conjunto (2/4/6 peças) somados ao mesmo balde de atributos
	for set_name in _set_counts.keys():
		var bonuses: Dictionary = ItemsDatabase.get_set_bonus(set_name, int(_set_counts[set_name]))
		for key in bonuses.keys():
			_affix_totals[key] = float(_affix_totals.get(key, 0.0)) + float(bonuses[key])

	_bonus_ready = true

func _ensure_bonus_cache() -> void:
	if not _bonus_ready:
		_rebuild_bonus_cache()

## Soma de um atributo vindo de affixes + conjuntos (percentuais vêm em 0-100).
func bonus(stat_name: String) -> float:
	_ensure_bonus_cache()
	return float(_affix_totals.get(stat_name, 0.0))

func get_set_piece_count(set_name: String) -> int:
	_ensure_bonus_cache()
	return int(_set_counts.get(set_name, 0))

# ------------------------------------------------------------------
# VITAIS
# ------------------------------------------------------------------
func recalculate_stats() -> void:
	_rebuild_bonus_cache()

	var extra_vit := int(bonus("vitality"))
	var extra_wil := int(bonus("willpower"))
	var extra_hp := bonus("max_hp")
	var extra_mp := bonus("max_mp")

	# Compatibilidade clássica Dragon Knight Set
	if get_set_piece_count("dragon_knight") >= 3:
		extra_hp += 500.0

	# Ritual do Despertar de Umaroth (Nível 50 Capstone)
	if ritual_awakened == 1:
		var awak: Dictionary = ClassesData.get_all_classes().get(current_class_id, {}).get("umaroth_awakening", {})
		extra_hp += float(awak.get("bonus_hp", 0.0))
		extra_mp += float(awak.get("bonus_mp", 0.0))

	var lvl_bonus = float(level - 15)
	max_hp = 2450.0 + ((vitality + extra_vit) * 40.0) + extra_hp + lvl_bonus * 120.0
	max_mp = 1180.0 + ((willpower + extra_wil) * 25.0) + extra_mp + lvl_bonus * 60.0
	max_hp = maxf(max_hp, 1.0)
	max_mp = maxf(max_mp, 1.0)
	current_hp = min(current_hp, max_hp)
	current_mp = min(current_mp, max_mp)
	stats_changed.emit()

# ------------------------------------------------------------------
# PODER DE COMBATE
# ------------------------------------------------------------------
func get_total_attack() -> float:
	_ensure_bonus_cache()
	var all_items = ItemsDatabase.get_all_items()

	var base_atk = float((strength + int(bonus("strength"))) * 4 + (dexterity + int(bonus("dexterity"))) * 2)

	# Arma Principal
	var main_id = _get_slot_item_id("weapon_main")
	if all_items.has(main_id):
		var w: Dictionary = all_items[main_id]
		var w_dmg := float(w.get("base_attack", w.get("base_damage", 50)))
		base_atk += w_dmg * (1.0 + (weapon_refine * 0.12))

	# Multiplicador das Asas
	var wings_id = _get_slot_item_id("wings")
	if all_items.has(wings_id):
		base_atk *= float(all_items[wings_id].get("damage_multiplier", 1.0))

	# Bônus do Pet
	if _get_slot_item_id("pet") == "pet_baby_dragon":
		base_atk *= 1.12

	if get_set_piece_count("dragon_knight") >= 5:
		base_atk *= 1.25

	var dmg_mult := 1.0
	dmg_mult += bonus("all_damage_pct") * 0.01
	if current_class_id == "zero":
		dmg_mult += bonus("fire_dmg_pct") * 0.01

	# Ritual de Umaroth (Zero / Arya)
	if ritual_awakened == 1:
		if current_class_id == "zero":
			dmg_mult += 0.40
		elif current_class_id == "arya":
			dmg_mult += 0.35

	return base_atk * dmg_mult

func get_total_defense() -> float:
	_ensure_bonus_cache()
	var all_items = ItemsDatabase.get_all_items()

	var flat_def := 0.0
	for slot in ["head", "shoulders", "chest", "gloves", "pants", "boots", "cape", "weapon_off", "ring_1", "ring_2"]:
		var id := _get_slot_item_id(slot)
		if all_items.has(id):
			flat_def += float(all_items[id].get("base_defense", 0))

	var total_def = float((vitality + int(bonus("vitality"))) * 3) + flat_def
	total_def *= (1.0 + (armor_refine * 0.08))

	if get_set_piece_count("dragon_knight") >= 3:
		total_def *= 1.15

	var def_mult := 1.0 + bonus("armor_pct") * 0.01
	if ritual_awakened == 1 and current_class_id == "roran":
		def_mult += 0.50

	return total_def * def_mult

func get_total_absorb() -> float:
	_ensure_bonus_cache()
	var all_items = ItemsDatabase.get_all_items()

	var absorb := 0.0
	for slot in equipped_gear.keys():
		var id := _get_slot_item_id(slot)
		if all_items.has(id):
			var it: Dictionary = all_items[id]
			absorb += float(it.get("damage_absorb", it.get("absorb_bonus_pct", 0.0) * 0.01))

	absorb += bonus("barrier_absorb_pct") * 0.01

	if ritual_awakened == 1 and current_class_id == "roran":
		absorb += 0.15 # Absorção Mítica do Martelo-Forte

	return clampf(absorb, 0.0, 0.75) # Teto de 75% de absorção

# ------------------------------------------------------------------
# ATRIBUTOS SECUNDÁRIOS (agora realmente usados no combate)
# ------------------------------------------------------------------
func get_crit_chance() -> float:
	return clampf(5.0 + bonus("crit_chance"), 0.0, 75.0)

func get_crit_multiplier() -> float:
	return 1.5 + bonus("crit_damage_pct") * 0.01

func get_dodge_chance() -> float:
	return clampf(bonus("dodge_pct"), 0.0, 45.0)

func get_block_chance() -> float:
	# Bloqueio só existe com escudo equipado.
	if _get_slot_item_id("weapon_off") == "":
		return 0.0
	return clampf(bonus("block_chance"), 0.0, 60.0)

func get_cooldown_reduction() -> float:
	return clampf(bonus("cooldown_reduction"), 0.0, 50.0)

func get_move_speed_pct() -> float:
	return clampf(bonus("move_speed_pct"), 0.0, 35.0)

## Poder de ataque "esperado" para o nível: âncora da curva de dano.
func get_expected_attack() -> float:
	return 150.0 + 45.0 * float(level)

## Dano de um golpe básico. Cresce com o nível e com o poder real de ataque,
## mas normalizado pela curva de HP dos mobs para não desbalancear o combate.
func get_attack_damage() -> float:
	var factor := clampf(get_total_attack() / maxf(get_expected_attack(), 1.0), 0.5, 2.5)
	return (45.0 + 10.0 * float(level)) * factor

func get_combat_power() -> int:
	var atk = get_total_attack()
	var def = get_total_defense()
	var cp = int((atk * 0.9) + (def * 1.8) + (max_hp * 0.3) + (max_mp * 0.2))
	cp += (weapon_refine * 450) + (armor_refine * 320) + (wings_tier * 1200)
	if ritual_awakened == 1:
		cp += 5000 # Bônus de Prestígio Mítico do Despertar de Umaroth
	return cp

func _get_set_count(set_name: String) -> int:
	return get_set_piece_count(set_name)

func can_equip_item(item_data) -> Dictionary:
	var item_id := ""
	var item_dict := {}
	if item_data is Dictionary:
		item_id = item_data.get("id", "")
		item_dict = item_data
	elif item_data is String:
		item_id = item_data

	var all_items = ItemsDatabase.get_all_items()
	if not all_items.has(item_id):
		return {"can_equip": false, "reason": "Item inexistente ou não registrado."}

	var base_info: Dictionary = all_items[item_id]
	var req_lvl: int = item_dict.get("level_req", base_info.get("level_req", 1))
	if level < req_lvl:
		return {"can_equip": false, "reason": "Nível insuficiente! Requer Nível %d (Você está no Nível %d)." % [req_lvl, level]}

	var req_class: String = item_dict.get("class_req", base_info.get("class_req", ""))
	if req_class != "" and req_class != current_class_id:
		var c_name = ClassesData.get_all_classes().get(req_class, {}).get("name", req_class)
		return {"can_equip": false, "reason": "Classe incompatível! Este item requer a classe %s." % c_name}

	# Validação rígida de Asas (Nvl 1 -> 30, Nvl 2 -> 40, Nvl 3 -> 50)
	if base_info.get("type") == ItemsDatabase.ItemType.WINGS:
		var w_tier: int = base_info.get("tier", 1)
		var min_w_lvl := 30
		if w_tier == 2: min_w_lvl = 40
		elif w_tier >= 3: min_w_lvl = 50
		if level < min_w_lvl:
			return {"can_equip": false, "reason": "Asas Nvl %d exigem Nível %d para alçar voo!" % [w_tier, min_w_lvl]}

	return {"can_equip": true, "reason": "OK"}

# --- RITUAL DO DRAGÃO MAIS SÁBIO (UMAROTH - LEVEL 50) ---
func perform_umaroth_ritual() -> Dictionary:
	if level < 50:
		return {"success": false, "message": "Você precisa atingir o Nível 50 para despertar a sabedoria dos Cavaleiros Antigos."}
	if ritual_awakened == 1:
		return {"success": true, "already_awakened": true, "message": "O Ritual de Umaroth já foi completado por este herói!"}

	ritual_awakened = 1
	recalculate_stats()
	var classes = ClassesData.get_all_classes()
	var awak = classes.get(current_class_id, {}).get("umaroth_awakening", {})
	_safe_play_audio("play_level_up")
	return {
		"success": true,
		"awakened": true,
		"name": awak.get("name", "Despertar Dracônico"),
		"desc": awak.get("desc", ""),
		"message": "🌟 Umaroth conduziu o Ritual Sagrado! Bênção concedida: %s" % awak.get("name", "")
	}

# --- EQUIPAR / DESEQUIPAR ---
func equip_gear(slot_key: String, item_data) -> bool:
	var item_id := ""
	if item_data is Dictionary: item_id = item_data.get("id", "")
	elif item_data is String: item_id = item_data

	var all_items = ItemsDatabase.get_all_items()
	if not all_items.has(item_id):
		return false

	var check = can_equip_item(item_data)
	if not check.get("can_equip", true):
		return false

	equipped_gear[slot_key] = item_data
	recalculate_stats()
	gear_equipped.emit(slot_key, item_id)
	_safe_play_audio("play_slash")
	return true

func unequip_gear(slot_key: String) -> void:
	if equipped_gear.has(slot_key):
		equipped_gear.erase(slot_key)
		recalculate_stats()
		gear_unequipped.emit(slot_key)

func add_xp(amount: int, source_name: String = "") -> void:
	current_xp += amount
	xp_gained.emit(amount, source_name)
	var leveled = false
	while current_xp >= max_xp and level < 50:
		current_xp -= max_xp
		level += 1
		max_xp = get_max_xp_for_level(level)
		stat_points += 5
		leveled = true
		_safe_play_audio("play_level_up")
		level_up.emit(level)
	if leveled:
		recalculate_stats()
		current_hp = max_hp
		current_mp = max_mp
		stat_points_changed.emit()
	stats_changed.emit()

## Distribui 1 ponto de atributo (evolução do personagem)
func spend_stat_point(attr: String) -> bool:
	if stat_points <= 0:
		return false
	match attr:
		"strength": strength += 1
		"dexterity": dexterity += 1
		"vitality": vitality += 1
		"willpower": willpower += 1
		_: return false
	stat_points -= 1
	recalculate_stats()
	stat_points_changed.emit()
	return true

# --- MOCHILA: API ---
func is_stackable(item_id: String) -> bool:
	var all_items = ItemsDatabase.get_all_items()
	if not all_items.has(item_id):
		return false
	return all_items[item_id]["type"] in [ItemsDatabase.ItemType.JEWEL, ItemsDatabase.ItemType.CONSUMABLE]

func count_item(item_id: String) -> int:
	var total = 0
	for slot in bag:
		if not slot.is_empty() and slot.get("id", "") == item_id:
			total += int(slot.get("count", 1))
	return total

func free_slots() -> int:
	var n = 0
	for slot in bag:
		if slot.is_empty():
			n += 1
	return n

func first_free_slot() -> int:
	for i in bag.size():
		if bag[i].is_empty():
			return i
	return -1

## Adiciona item (empilha joias/consumíveis). Retorna false se a mochila estiver cheia.
## Suporta dicionário instanciado (com affixes gerados por LootSystem).
func add_item(item_id: String, count: int = 1, item_instance: Dictionary = {}) -> bool:
	if is_stackable(item_id) and item_instance.is_empty():
		for slot in bag:
			if not slot.is_empty() and slot.get("id", "") == item_id and not slot.has("affixes"):
				slot["count"] = int(slot.get("count", 1)) + count
				bag_changed.emit()
				return true
	var idx = first_free_slot()
	if idx < 0:
		return false
	if not item_instance.is_empty():
		var inst = item_instance.duplicate(true)
		if not inst.has("count"):
			inst["count"] = count
		bag[idx] = inst
	else:
		bag[idx] = {"id": item_id, "count": count}
	bag_changed.emit()
	return true

func set_item_count(item_id: String, new_count: int) -> bool:
	new_count = max(0, new_count)
	for i in bag.size():
		if not bag[i].is_empty() and bag[i]["id"] == item_id:
			if new_count == 0:
				bag[i] = {}
			else:
				bag[i]["count"] = new_count
			bag_changed.emit()
			return true
	if new_count > 0:
		return add_item(item_id, new_count)
	return true

func remove_item_at(idx: int, count: int = 1) -> void:
	if idx < 0 or idx >= bag.size() or bag[idx].is_empty():
		return
	bag[idx]["count"] = int(bag[idx]["count"]) - count
	if bag[idx]["count"] <= 0:
		bag[idx] = {}
	bag_changed.emit()

## Arrastar & soltar na mochila: move, troca ou empilha.
func move_bag_item(from_idx: int, to_idx: int) -> void:
	if from_idx == to_idx or from_idx < 0 or to_idx < 0 or from_idx >= bag.size() or to_idx >= bag.size():
		return
	var a = bag[from_idx]
	var b = bag[to_idx]
	if a.is_empty():
		return
	if not b.is_empty() and a["id"] == b["id"] and is_stackable(a["id"]):
		b["count"] = int(b["count"]) + int(a["count"])
		bag[from_idx] = {}
	else:
		bag[from_idx] = b
		bag[to_idx] = a
	bag_changed.emit()

## Equipa item da mochila no slot (troca com o item atualmente equipado, que volta à mochila).
## Preserva dicionários instanciados com affixes e refino.
func equip_from_bag(idx: int, target_slot: String = "") -> bool:
	if idx < 0 or idx >= bag.size() or bag[idx].is_empty():
		return false
	var bag_item = bag[idx]
	var item_id: String = bag_item.get("id", "")
	var all_items = ItemsDatabase.get_all_items()
	if not all_items.has(item_id):
		return false
	var slot_key = ItemsDatabase.get_slot_key_for_type(all_items[item_id]["type"])
	if slot_key == "":
		return false
	if target_slot != "":
		if slot_key == "ring_1" and target_slot == "ring_2":
			slot_key = "ring_2"
		elif target_slot != slot_key:
			return false
	elif slot_key == "ring_1" and _get_slot_item_id("ring_1") != "" and _get_slot_item_id("ring_2") == "":
		slot_key = "ring_2"

	var check = can_equip_item(bag_item)
	if not check.get("can_equip", true):
		return false

	var previous = equipped_gear.get(slot_key, "")
	var to_equip = bag_item.duplicate(true) if bag_item.has("affixes") else item_id

	var prev_id: String = ""
	if previous is Dictionary:
		prev_id = previous.get("id", "")
	elif previous is String:
		prev_id = previous.strip_edges()

	if prev_id != "":
		if previous is Dictionary:
			var prev_dict = previous.duplicate(true)
			if not prev_dict.has("count"): prev_dict["count"] = 1
			bag[idx] = prev_dict
		else:
			bag[idx] = {"id": prev_id, "count": 1}
	else:
		bag[idx] = {}

	equip_gear(slot_key, to_equip)
	bag_changed.emit()
	return true

## Desequipa para a mochila (slot específico opcional). Troca se o destino for compatível.
## Preserva dicionários instanciados com affixes.
func unequip_to_bag(slot_key: String, target_idx: int = -1) -> bool:
	if not equipped_gear.has(slot_key):
		return false
	var current_item = equipped_gear[slot_key]
	var item_id: String = current_item.get("id", "") if current_item is Dictionary else (current_item if current_item is String else "")
	if item_id.strip_edges() == "":
		return false
	if target_idx >= 0 and target_idx < bag.size() and not bag[target_idx].is_empty():
		var other_entry = bag[target_idx]
		var other_id: String = other_entry.get("id", "")
		var all_items = ItemsDatabase.get_all_items()
		if all_items.has(other_id):
			var other_slot = ItemsDatabase.get_slot_key_for_type(all_items[other_id]["type"])
			if other_slot == slot_key or (other_slot == "ring_1" and slot_key == "ring_2"):
				return equip_from_bag(target_idx, slot_key)
		return false
	var dest = target_idx if (target_idx >= 0 and target_idx < bag.size()) else first_free_slot()
	if dest < 0:
		return false
	if current_item is Dictionary:
		var dict_item = current_item.duplicate(true)
		if not dict_item.has("count"): dict_item["count"] = 1
		bag[dest] = dict_item
	else:
		bag[dest] = {"id": item_id, "count": 1}
	unequip_gear(slot_key)
	bag_changed.emit()
	return true

## Consome poções/pedras da mochila.
func use_bag_item(idx: int) -> String:
	if idx < 0 or idx >= bag.size() or bag[idx].is_empty():
		return ""
	var item_id: String = bag[idx]["id"]
	match item_id:
		"potion_health":
			if current_hp >= max_hp: return "Vida já está cheia."
			heal(max_hp * 0.4)
			remove_item_at(idx)
			return "🧪 +%d HP" % int(max_hp * 0.4)
		"potion_mana":
			if current_mp >= max_mp: return "Mana já está cheia."
			current_mp = min(max_mp, current_mp + max_mp * 0.5)
			remove_item_at(idx)
			stats_changed.emit()
			return "🔮 +%d MP" % int(max_mp * 0.5)
		"elixir_dragon":
			if current_hp >= max_hp and current_mp >= max_mp: return "Vida e Mana já estão completas."
			current_hp = max_hp
			current_mp = max_mp
			remove_item_at(idx)
			stats_changed.emit()
			return "✨ 100% HP & MP RESTAURADOS!"
	return ""

# --- MISSÕES SIMPLES ---
func start_quest(quest_id: String, goal: int, title: String, hint: String = "", target_pos: Vector2 = Vector2.ZERO, target_zone: String = "") -> void:
	if quests.has(quest_id):
		return
	quests[quest_id] = {
		"title": title,
		"progress": 0,
		"goal": goal,
		"done": false,
		"claimed": false,
		"status": "in_progress",
		"hint": hint,
		"target_pos": target_pos,
		"target_zone": target_zone
	}
	quest_updated.emit(quest_id)

func get_active_quest() -> Dictionary:
	for qid in quests.keys():
		var q = quests[qid]
		if q is Dictionary and not q.get("claimed", false):
			var res = q.duplicate()
			res["id"] = qid
			return res
	return {}

func register_kill(mob_name: String) -> void:
	total_kills += 1
	for qid in quests.keys():
		var q = quests[qid]
		if not q is Dictionary:
			continue
		var is_done: bool = q.get("done", false) or q.get("status") == "completed"
		if not is_done:
			var goal: int = int(q.get("goal", q.get("target", 5)))
			var current_prog: int = int(q.get("progress", 0)) + 1
			q["progress"] = min(goal, current_prog)
			q["done"] = (q["progress"] >= goal)
			if q["done"]:
				q["status"] = "completed"
			else:
				q["status"] = "in_progress"
			quest_updated.emit(qid)

# ------------------------------------------------------------------
# DANO RECEBIDO
# ------------------------------------------------------------------
## Resolve esquiva → bloqueio → defesa → absorção e devolve o resultado.
## Retorna {"damage": float, "dodged": bool, "blocked": bool}.
func take_damage(amount: float) -> Dictionary:
	_ensure_bonus_cache()

	var dodged := randf() * 100.0 < get_dodge_chance()
	if dodged:
		damage_resolved.emit(0.0, true, false)
		stats_changed.emit()
		return {"damage": 0.0, "dodged": true, "blocked": false}

	var blocked := randf() * 100.0 < get_block_chance()

	var absorb := get_total_absorb()
	var defense := get_total_defense()
	var mitigation := defense / (defense + 400.0)
	var reduction := clampf(bonus("damage_reduction_pct") * 0.01, 0.0, 0.6)

	var final_damage := amount * (1.0 - mitigation) * (1.0 - absorb) * (1.0 - reduction)
	if blocked:
		final_damage *= 0.4

	final_damage = maxf(final_damage, 1.0)
	current_hp = max(0.0, current_hp - final_damage)
	damage_resolved.emit(final_damage, false, blocked)
	stats_changed.emit()
	return {"damage": final_damage, "dodged": false, "blocked": blocked}

var _mp_regen_timer: float = 0.0

func _process(delta: float) -> void:
	if current_mp < max_mp:
		var regen_mp = (18.0 + float(willpower) * 0.8) * delta
		current_mp = min(max_mp, current_mp + regen_mp)
		_mp_regen_timer += delta
		if _mp_regen_timer >= 0.2:
			_mp_regen_timer = 0.0
			stats_changed.emit()

func heal(amount: float) -> void:
	current_hp = min(max_hp, current_hp + amount)
	stats_changed.emit()

func consume_mana(amount: float) -> bool:
	if current_mp >= amount:
		current_mp -= amount
		stats_changed.emit()
		return true
	return false

# --- SISTEMA DE REFINO ESTILO MU ONLINE ---
func enhance_weapon() -> void:
	if weapon_refine >= 15:
		enhancement_result.emit(false, weapon_refine, "A arma já atingiu o refino MÁXIMO (+15)!")
		return

	if weapon_refine < 6:
		if jewels_bless <= 0:
			_safe_play_audio("play_fail")
			enhancement_result.emit(false, weapon_refine, "Você precisa de uma Joia da Bênção (Bless)!")
			return
		jewels_bless -= 1
		weapon_refine += 1
		_safe_play_audio("play_success")
		enhancement_result.emit(true, weapon_refine, "✨ Sucesso! Lâmina aprimorada para +%d!" % weapon_refine)
	elif weapon_refine < 9:
		if jewels_soul <= 0:
			_safe_play_audio("play_fail")
			enhancement_result.emit(false, weapon_refine, "Você precisa de uma Joia da Alma (Soul)!")
			return
		jewels_soul -= 1
		if randf() <= 0.75:
			weapon_refine += 1
			_safe_play_audio("play_success")
			enhancement_result.emit(true, weapon_refine, "✨ Sucesso Divino! Lâmina alcançou o prestígio +%d!" % weapon_refine)
		else:
			weapon_refine = max(0, weapon_refine - 1)
			_safe_play_audio("play_fail")
			enhancement_result.emit(false, weapon_refine, "Falha no refino! A lâmina regrediu para +%d." % weapon_refine)
	else:
		if jewels_chaos <= 0 or jewels_soul <= 0:
			_safe_play_audio("play_fail")
			enhancement_result.emit(false, weapon_refine, "Você precisa de 1 Joia do Caos e 1 Joia da Alma!")
			return
		jewels_chaos -= 1
		jewels_soul -= 1
		if randf() <= 0.50:
			weapon_refine += 1
			_safe_play_audio("play_success")
			enhancement_result.emit(true, weapon_refine, "🔥 PODER SUPREMO! Lâmina incendiada com Glow +%d!" % weapon_refine)
		else:
			weapon_refine = 0
			_safe_play_audio("play_fail")
			enhancement_result.emit(false, weapon_refine, "💀 A forja entrou em colapso! A lâmina foi redefinida para +0.")

	recalculate_stats()

func _safe_play_audio(method: String) -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root and tree.root.has_node("AudioManager"):
		var am = tree.root.get_node("AudioManager")
		if am.has_method(method):
			am.call(method)

func get_weapon_glow_energy() -> float:
	if weapon_refine < 7: return 0.5
	elif weapon_refine < 9: return 1.5
	elif weapon_refine < 11: return 2.5
	elif weapon_refine < 13: return 4.0
	elif weapon_refine < 15: return 6.0
	else: return 8.0
