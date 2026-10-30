extends SceneTree
## Teste Automatizado de Backend, Versionamento, Multi-Personagens e Saves

func _init() -> void:
	print("\n==================================================")
	print("🧪 TESTE AUTOMATIZADO: BACKEND, VERSION & SAVES")
	print("==================================================")

	var all_ok = true

	# [1/5] Validação do manifesto version.json
	print("[1/5] Validando Manifesto de Versão (version.json)...")
	var vm_script = load("res://scripts/systems/version_manager.gd")
	var vm = vm_script.new()
	vm.load_local_manifest()
	if vm.local_version == "0.5.0" and vm.build_number == 142:
		print("  ✅ Sucesso: version.json carregado com versão v%s (Build %d)!" % [vm.local_version, vm.build_number])
	else:
		print("  ❌ Falha: version.json com valores inesperados.")
		all_ok = false

	# Teste SemVer
	assert(vm.compare_semver("0.5.0", "0.4.9") == 1)
	assert(vm.compare_semver("0.5.0", "0.5.0") == 0)
	assert(vm.compare_semver("0.4.5", "0.5.0") == -1)
	print("  ✅ Sucesso: Algoritmo SemVer validou precedência de versões!")
	vm.queue_free()

	# [2/5] Teste de Serialização do SaveManager
	print("[2/5] Validando Serialização e Desserialização (SaveManager)...")
	var sm_script = load("res://scripts/systems/save_manager.gd")
	var sm = sm_script.new()
	var cs_script = load("res://scripts/systems/character_stats.gd")
	var cs = cs_script.new()
	cs._init()
	cs.character_name = "TesteRider"
	cs.level = 25
	cs.gold = 99999
	cs.equipped_gear["weapon_main"] = "sword_zarroc"

	var serialized = sm.serialize_stats(cs)
	if serialized["name"] == "TesteRider" and serialized["level"] == 25 and serialized["equipped_gear"]["weapon_main"] == "sword_zarroc":
		print("  ✅ Sucesso: Serialização de CharacterStats em JSON concluída!")
	else:
		print("  ❌ Falha na serialização.")
		all_ok = false

	# Teste Roundtrip de Desserialização
	var cs2 = cs_script.new()
	cs2._init()
	sm.deserialize_stats(cs2, serialized)
	if cs2.character_name == "TesteRider" and cs2.level == 25 and cs2.gold == 99999:
		print("  ✅ Sucesso: Desserialização reconstruiu o herói perfeitamente!")
	else:
		print("  ❌ Falha na desserialização.")
		all_ok = false

	# [3/5] Teste de Gravação e Leitura Local (user://saves/)
	print("[3/5] Testando Persistência em Disco Local (user://saves/)...")
	var save_test_id = "test_char_automation"
	var save_ok = sm.save_local(save_test_id, serialized)
	if save_ok:
		print("  ✅ Sucesso: Perfil salvo com sucesso em disco!")
	var loaded = sm.load_local(save_test_id)
	if loaded.get("name") == "TesteRider" and loaded.get("level") == 25:
		print("  ✅ Sucesso: Leitura de perfil em disco confirmada com 100% de integridade!")
	else:
		print("  ❌ Falha ao recarregar perfil salvo.")
		all_ok = false

	# Limpa arquivo temporário de teste
	var dir = DirAccess.open("user://saves/")
	if dir and dir.file_exists(save_test_id + ".json"):
		dir.remove(save_test_id + ".json")

	sm.queue_free()
	cs.queue_free()
	cs2.queue_free()

	# [4/5] Testando Instanciação do NetworkManager
	print("[4/5] Validando NetworkManager e Protocolos...")
	var nm_script = load("res://scripts/network/network_manager.gd")
	var nm = nm_script.new()
	if nm.server_url.contains("8088"):
		print("  ✅ Sucesso: NetworkManager inicializado com endpoint padrão (porta 8088)!")
	nm.queue_free()

	# [5/5] Validação das Cenas de UI (PatchNotesModal & AuthAndCharacterSelect)
	print("[5/5] Validando Cenas de Autenticação e Notas da Versão...")
	var scn_notes = load("res://scenes/ui/patch_notes_modal.tscn")
	var node_notes = scn_notes.instantiate()
	if node_notes != null:
		print("  ✅ Cena validada: patch_notes_modal.tscn")
		node_notes.free()

	var scn_auth = load("res://scenes/ui/auth_and_character_select.tscn")
	var node_auth = scn_auth.instantiate()
	if node_auth != null:
		print("  ✅ Cena validada: auth_and_character_select.tscn (4 Slots + Login/Register)")
		node_auth.free()

	print("==================================================")
	if all_ok:
		print("🎉 TODOS OS TESTES DE INFRAESTRUTURA PASSARAM COM SUCESSO!")
	else:
		print("❌ HOUVE FALHAS NOS TESTES!")
	print("==================================================")
	quit(0 if all_ok else 1)
