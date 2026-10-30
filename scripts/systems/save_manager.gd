extends Node
## Gerenciador de Serialização e Persistência do GameZero.
##
## Converte o estado em tempo de execução de CharacterStats em payloads
## estruturados e restaura com suporte a affixes aleatórios e multi-slots.
##
## Gravação atômica: escreve em `.tmp`, promove o arquivo atual para `.bak`
## e só então renomeia — um crash no meio da escrita não corrompe o save.

const CharacterStatsClass = preload("res://scripts/systems/character_stats.gd")

signal save_started
signal save_finished(success: bool)
signal save_failed(reason: String)

const LOCAL_SAVES_DIR := "user://saves/"
const SAVE_VERSION := 2
## Salvamento periódico de segurança (o debounce cobre as mudanças do dia a dia).
const AUTO_SAVE_INTERVAL: float = 30.0
## Atraso do salvamento por evento: agrupa uma rajada de mudanças num único write.
const DIRTY_DEBOUNCE: float = 1.5

var pending_character_sheet: Dictionary = {}
var active_character_id: String = ""

var _auto_save_timer: float = 0.0
var _dirty: bool = false
var _dirty_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_saves_dir()

func _process(delta: float) -> void:
	_auto_save_timer += delta
	_dirty_timer += delta

	var should_save := false
	if _dirty and _dirty_timer >= DIRTY_DEBOUNCE:
		should_save = true
	elif _auto_save_timer >= AUTO_SAVE_INTERVAL:
		_auto_save_timer = 0.0
		should_save = _dirty

	if not should_save:
		return

	var tree = get_tree()
	if not tree:
		return
	var player = tree.get_first_node_in_group("player")
	if player and "stats" in player and player.stats:
		save_current_character(player.stats)

## Marca o personagem atual como alterado; a gravação acontece em breve.
## Substitui o save síncrono a cada equip/ponto/quest (que travava o frame).
func mark_dirty() -> void:
	_dirty = true
	_dirty_timer = 0.0

func set_active_character(char_id: String, sheet: Dictionary = {}) -> void:
	active_character_id = char_id
	pending_character_sheet = sheet

func _ensure_saves_dir() -> void:
	if not DirAccess.dir_exists_absolute(LOCAL_SAVES_DIR):
		DirAccess.make_dir_recursive_absolute(LOCAL_SAVES_DIR)

## Aceita apenas ids seguros: o id vira nome de arquivo em user://saves/.
static func sanitize_id(raw_id: String) -> String:
	var out := ""
	for i in raw_id.length():
		var c := raw_id[i]
		if c.is_valid_identifier() or c.is_valid_int() or c == "-" or c == "_":
			out += c
		if out.length() >= 64:
			break
	return out

## Serializa o CharacterStats completo em um Dicionário exportável
func serialize_stats(stats: CharacterStatsClass) -> Dictionary:
	if not stats:
		return {}
	return {
		"save_version": SAVE_VERSION,
		"name": stats.character_name,
		"class_id": stats.current_class_id,
		"level": stats.level,
		"current_xp": stats.current_xp,
		"gold": stats.gold,
		"stat_points": stats.stat_points,
		"strength": stats.strength,
		"dexterity": stats.dexterity,
		"vitality": stats.vitality,
		"willpower": stats.willpower,
		"total_kills": stats.total_kills,
		"wings_tier": stats.wings_tier,
		"weapon_refine": stats.weapon_refine,
		"armor_refine": stats.armor_refine,
		"ritual_awakened": stats.ritual_awakened,
		"equipped_gear": stats.equipped_gear.duplicate(true),
		"bag": stats.bag.duplicate(true),
		"quests": stats.quests.duplicate(true),
		"timestamp": Time.get_datetime_string_from_system()
	}

## Aplica os dados serializados de volta ao CharacterStats
func deserialize_stats(stats: CharacterStatsClass, data: Dictionary) -> void:
	if not stats or data.is_empty():
		return

	data = _migrate(data)

	if data.has("class_id") and data["class_id"] != stats.current_class_id:
		stats.apply_class_data(data["class_id"])

	stats.character_name = data.get("name", stats.character_name)
	stats.level = data.get("level", stats.level)
	stats.current_xp = data.get("current_xp", stats.current_xp)
	if stats.has_method("get_max_xp_for_level"):
		stats.max_xp = stats.get_max_xp_for_level(stats.level)
	stats.gold = data.get("gold", stats.gold)
	stats.stat_points = data.get("stat_points", stats.stat_points)
	stats.strength = data.get("strength", stats.strength)
	stats.dexterity = data.get("dexterity", stats.dexterity)
	stats.vitality = data.get("vitality", stats.vitality)
	stats.willpower = data.get("willpower", stats.willpower)
	stats.total_kills = data.get("total_kills", stats.total_kills)
	stats.wings_tier = data.get("wings_tier", stats.wings_tier)
	stats.weapon_refine = data.get("weapon_refine", stats.weapon_refine)
	stats.armor_refine = data.get("armor_refine", stats.armor_refine)
	stats.ritual_awakened = int(data.get("ritual_awakened", 0))

	if data.has("equipped_gear") and data["equipped_gear"] is Dictionary:
		stats.equipped_gear = data["equipped_gear"].duplicate(true)

	if data.has("bag") and data["bag"] is Array:
		stats.bag = data["bag"].duplicate(true)
		# Garante tamanho de 33 slots e nenhum slot nulo
		if stats.bag.size() < CharacterStatsClass.BAG_SIZE:
			stats.bag.resize(CharacterStatsClass.BAG_SIZE)
		for i in stats.bag.size():
			if not stats.bag[i] is Dictionary:
				stats.bag[i] = {}

	if data.has("quests") and data["quests"] is Dictionary:
		stats.quests = data["quests"].duplicate(true)
		# Normaliza todas as missões para garantir chaves 'done', 'claimed', 'goal', 'progress', 'title'
		for qid in stats.quests.keys():
			var q = stats.quests[qid]
			if q is Dictionary:
				var goal = int(q.get("goal", q.get("target", 5)))
				var prog = int(q.get("progress", 0))
				var is_done = q.get("done", false) or q.get("status") == "completed" or (prog >= goal and goal > 0)
				q["done"] = is_done
				q["claimed"] = q.get("claimed", false) or q.get("status") == "claimed"
				q["goal"] = goal
				q["progress"] = prog
				if not q.has("title"):
					q["title"] = qid

	stats.recalculate_stats()
	stats.bag_changed.emit()
	stats.stats_changed.emit()

## Ponto único de migração de saves antigos.
func _migrate(data: Dictionary) -> Dictionary:
	var version: int = int(data.get("save_version", 1))
	if version >= SAVE_VERSION:
		return data

	# v1 -> v2: "target" virou "goal" nas missões e joias passaram a viver na mochila.
	var quests = data.get("quests", {})
	if quests is Dictionary:
		for qid in quests.keys():
			var q = quests[qid]
			if q is Dictionary and q.has("target") and not q.has("goal"):
				q["goal"] = q["target"]

	data["save_version"] = SAVE_VERSION
	return data

## Salva localmente em disco no user://saves/ de forma atômica.
func save_local(char_id: String, data: Dictionary) -> bool:
	_ensure_saves_dir()
	var safe_id := sanitize_id(char_id)
	if safe_id == "":
		save_failed.emit("ID de personagem inválido para gravação.")
		return false

	var final_path := LOCAL_SAVES_DIR + safe_id + ".json"
	var tmp_path := final_path + ".tmp"

	var payload := data.duplicate(true)
	payload["save_version"] = SAVE_VERSION

	var f = FileAccess.open(tmp_path, FileAccess.WRITE)
	if not f:
		save_failed.emit("Não foi possível abrir %s para escrita." % tmp_path)
		return false
	f.store_string(JSON.stringify(payload, "\t"))
	f.flush()
	f.close()

	# Mantém o último save íntegro como backup antes de sobrescrever
	if FileAccess.file_exists(final_path):
		if FileAccess.file_exists(final_path + ".bak"):
			DirAccess.remove_absolute(final_path + ".bak")
		DirAccess.copy_absolute(final_path, final_path + ".bak")

	var err := DirAccess.rename_absolute(tmp_path, final_path)
	if err != OK:
		# Alguns sistemas de arquivos não permitem rename: cai para cópia direta.
		var copy_err := DirAccess.copy_absolute(tmp_path, final_path)
		DirAccess.remove_absolute(tmp_path)
		if copy_err != OK:
			save_failed.emit("Falha ao gravar o save (código %d)." % copy_err)
			return false
	_dirty = false
	_auto_save_timer = 0.0
	return true

## Carrega do disco local. Se o JSON principal estiver corrompido, tenta o backup.
func load_local(char_id: String) -> Dictionary:
	var safe_id := sanitize_id(char_id)
	if safe_id == "":
		return {}
	var file_path := LOCAL_SAVES_DIR + safe_id + ".json"

	for candidate in [file_path, file_path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var f = FileAccess.open(candidate, FileAccess.READ)
		if not f:
			continue
		var text := f.get_as_text()
		f.close()
		var parsed = JSON.parse_string(text)
		if parsed is Dictionary:
			if candidate.ends_with(".bak"):
				push_warning("[SaveManager] Save principal ilegível: recuperado do backup (%s)." % safe_id)
			return parsed
		push_warning("[SaveManager] JSON inválido em %s (tentando backup)." % candidate)
	return {}

## Lista todos os perfis salvos localmente
func list_local_characters() -> Array:
	_ensure_saves_dir()
	var result: Array = []
	var dir = DirAccess.open(LOCAL_SAVES_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var full_path = LOCAL_SAVES_DIR + file_name
				var f = FileAccess.open(full_path, FileAccess.READ)
				if f:
					var p = JSON.parse_string(f.get_as_text())
					f.close()
					if p is Dictionary:
						p["id"] = file_name.replace(".json", "")
						result.append(p)
			file_name = dir.get_next()
	return result

## Salva o personagem atual de forma unificada (Nuvem se online, Local sempre como backup)
func save_current_character(stats: CharacterStatsClass) -> void:
	if not stats:
		return
	save_started.emit()
	var payload = serialize_stats(stats)
	var net = get_node_or_null("/root/NetworkManager")
	var char_id := active_character_id
	if char_id == "" and net and not net.active_character.is_empty():
		char_id = net.active_character.get("id", "")
	if char_id == "":
		char_id = "char_local_1"

	# 1. Salva backup local sempre (atômico)
	var ok = save_local(char_id, payload)

	# 2. Se online, enfileira o envio para a nuvem
	if net and not net.auth_token.is_empty() and not char_id.begins_with("char_local_"):
		net.sync_character_full(char_id, payload)

	save_finished.emit(ok)
