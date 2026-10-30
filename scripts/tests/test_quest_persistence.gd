extends SceneTree
## Regressão: missões com `target_pos` (Vector2) precisam sobreviver ao JSON.
##
## Bug original: `JSON.stringify` gravava "(0, 34)" e, ao carregar, o valor
## voltava como String — o minimapa então fazia `String != Vector2` e o jogo
## quebrava com "Invalid operands 'String' and 'Vector2' in operator '!='".

const SaveManagerClass = preload("res://scripts/systems/save_manager.gd")
const CharacterStatsClass = preload("res://scripts/systems/character_stats.gd")

const TEST_ID := "char_test_quest_vector"

var errors := 0

func _init() -> void:
	call_deferred("_run")

func _check(cond: bool, ok_msg: String, err_msg: String) -> void:
	if cond:
		print("  ✅ " + ok_msg)
	else:
		print("  ❌ " + err_msg)
		errors += 1

func _run() -> void:
	print("\n==================================================")
	print("🧪 TESTE: PERSISTÊNCIA DE MISSÃO (target_pos Vector2)")
	print("==================================================")

	var sm = root.get_node_or_null("SaveManager")
	if not sm:
		sm = SaveManagerClass.new()
		sm.name = "SaveManager"
		root.add_child(sm)

	var target := Vector2(12.5, -7.25)
	var stats = CharacterStatsClass.new()
	root.add_child(stats)
	stats.start_quest("q_vector", 5, "Caçada ao Acampamento", "Siga para o oeste", target, "west")

	print("[1/4] Serialização gera payload JSON-compatível...")
	var payload: Dictionary = sm.serialize_stats(stats)
	var raw_json := JSON.stringify(payload)
	var reparsed = JSON.parse_string(raw_json)
	_check(reparsed is Dictionary, "payload serializa e reparseia como Dictionary", "payload não é JSON válido")
	var stored = payload.get("quests", {}).get("q_vector", {}).get("target_pos", null)
	_check(stored is Array, "target_pos é gravado como [x, y]", "gravado como %s: %s" % [type_string(typeof(stored)), str(stored)])

	print("[2/4] Ida e volta por arquivo recupera Vector2...")
	sm.save_local(TEST_ID, payload)
	var loaded: Dictionary = sm.load_local(TEST_ID)
	_check(not loaded.is_empty(), "arquivo lido de user://saves/", "load_local devolveu vazio")

	var stats2 = CharacterStatsClass.new()
	root.add_child(stats2)
	sm.deserialize_stats(stats2, loaded)
	var q: Dictionary = stats2.quests.get("q_vector", {})
	var pos = q.get("target_pos", null)
	_check(pos is Vector2, "target_pos voltou como Vector2", "voltou como %s: %s" % [type_string(typeof(pos)), str(pos)])
	_check(pos is Vector2 and pos.is_equal_approx(target), "posição preservada (%.2f, %.2f)" % [target.x, target.y], "posição divergiu: %s" % str(pos))

	print("[3/4] get_active_quest() expõe Vector2 (minimapa/mapa regional)...")
	var act: Dictionary = stats2.get_active_quest()
	var act_pos = act.get("target_pos", null)
	_check(act_pos is Vector2, "missão ativa entrega Vector2", "entrega %s" % type_string(typeof(act_pos)))
	# A comparação que quebrava no minimapa:
	_check(not (act_pos is Vector2) or act_pos != Vector2.ZERO, "comparação com Vector2.ZERO é válida", "comparação inválida")

	print("[4/4] Compatibilidade com saves antigos e outros formatos...")
	_check(SaveService.to_vector2("(3, -4)") == Vector2(3, -4), "string legada \"(3, -4)\" é convertida", "string legada falhou")
	_check(SaveService.to_vector2([1, 2]) == Vector2(1, 2), "array [1, 2] é convertido", "array falhou")
	_check(SaveService.to_vector2({"x": 5, "y": 6}) == Vector2(5, 6), "dicionário {x, y} é convertido", "dicionário falhou")
	_check(SaveService.to_vector2(Vector2(7, 8)) == Vector2(7, 8), "Vector2 passa direto", "Vector2 falhou")
	_check(SaveService.to_vector2(null) == Vector2.ZERO, "valor inválido vira Vector2.ZERO", "fallback falhou")

	# limpeza
	stats.queue_free()
	stats2.queue_free()
	for suffix in [".json", ".json.bak"]:
		var path: String = "user://saves/" + TEST_ID + String(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

	print("==================================================")
	if errors == 0:
		print("🎉 PERSISTÊNCIA DE MISSÃO OK")
	else:
		print("❌ %d ERRO(S)" % errors)
	print("==================================================")
	quit(errors)
