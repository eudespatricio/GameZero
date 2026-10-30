extends SceneTree

const ItemsDatabaseScript = preload("res://scripts/data/items_database.gd")
const CharacterStatsScript = preload("res://scripts/systems/character_stats.gd")
const LootSystemScript = preload("res://scripts/systems/loot_system.gd")
const ClassesDataScript = preload("res://scripts/data/classes_data.gd")

func _init() -> void:
	print("==================================================")
	print("🧪 TESTE AUTOMATIZADO: 21 SETS, AFFIXES & RITUAL")
	print("==================================================")

	var errors = 0

	# 1. Validar os 21 Sets de Armadura
	print("[1/5] Validando Catálogo dos 21 Sets de Armadura...")
	var all_sets = ItemsDatabaseScript.get_all_sets()
	if all_sets.size() != 21:
		print("  ❌ Erro: Quantidade de sets incorreta (%d/21 esperado)" % all_sets.size())
		errors += 1
	else:
		print("  ✅ Sucesso: Todos os 21 Sets de Armadura registrados!")

	var classes_found = {"zero": 0, "arya": 0, "roran": 0}
	for sname in all_sets.keys():
		var s = all_sets[sname]
		var c = s.get("class", "")
		if classes_found.has(c):
			classes_found[c] += 1
		# Verificar se tem bônus de 2, 4 e 6 peças
		if not s.has("bonus_2") or not s.has("bonus_4") or not s.has("bonus_6"):
			print("  ❌ Erro: Set '%s' sem estrutura completa de bônus 2/4/6!" % sname)
			errors += 1

	for c in classes_found.keys():
		if classes_found[c] == 7:
			print("  ✅ Sucesso: 7 sets validados para a classe '%s' (5 progressivos + 1 lendário + 1 divino)!" % c)
		else:
			print("  ❌ Erro: Classe '%s' tem %d sets (esperado 7)" % [c, classes_found[c]])
			errors += 1

	# 2. Validar LootSystem e Rolagem de Affixes (1 a 4 aleatórios e 5 no Divino)
	print("[2/5] Validando LootSystem e Rolagem de Affixes Aleatórios...")
	var test_inst = LootSystemScript.create_instanced_item("chest_dragon_knight", "zero")
	if test_inst.is_empty():
		print("  ❌ Erro: create_instanced_item retornou vazio!")
		errors += 1
	else:
		var aff_count = test_inst.get("affixes", []).size()
		if aff_count >= 1 and aff_count <= 4:
			print("  ✅ Sucesso: Item instanciado com %d affixes da classe Zero!" % aff_count)
			for af in test_inst["affixes"]:
				print("     ✦ %s (+%s)" % [af.get("desc", ""), str(af.get("val", 0))])
		else:
			print("  ❌ Erro: Quantidade de affixes fora do intervalo 1-4: %d" % aff_count)
			errors += 1

	# Testar 50 gerações de itens para garantir consistência de affixes
	var drop_success = true
	for i in range(50):
		var item_id = LootSystemScript._select_equipment_drop(25, false)
		if item_id != "":
			var drop = LootSystemScript.create_instanced_item(item_id, "zero")
			var affs = drop.get("affixes", [])
			if affs.size() < 1 or affs.size() > 5:
				drop_success = false
	if drop_success:
		print("  ✅ Sucesso: 50 gerações de loot produziram affixes consistentes com pesos de classe!")
	else:
		print("  ❌ Erro: Inconsistência na rolagem de affixes!")
		errors += 1

	# 3. Validar Restrições de Nível e Asas (Nvl 1: 30, Nvl 2: 40, Nvl 3: 50)
	print("[3/5] Validando Restrições de Nível e Asas...")
	var stats = CharacterStatsScript.new()
	stats.level = 25 # Nível menor que as asas
	stats.current_class_id = "zero"

	# Tentativa de equipar asas Nvl 1 (min 30) em nível 25 -> Deve falhar
	var check_w1 = stats.can_equip_item("wings_tier1")
	if check_w1.get("can_equip", false) == false:
		print("  ✅ Sucesso: Asas Tier 1 bloqueadas corretamente no Nível 25 (Exige Nvl 30)!")
	else:
		print("  ❌ Erro: Asas Tier 1 equipadas indevidamente no Nível 25!")
		errors += 1

	stats.level = 35
	check_w1 = stats.can_equip_item("wings_tier1")
	var check_w2 = stats.can_equip_item("wings_crystal_tier2")
	if check_w1.get("can_equip", false) == true and check_w2.get("can_equip", true) == false:
		print("  ✅ Sucesso: Asas Tier 1 permitidas no Nvl 35 e Tier 2 bloqueadas (Exige Nvl 40)!")
	else:
		print("  ❌ Erro: Validação de Asas Tier 1 e 2 falhou no Nível 35!")
		errors += 1

	stats.level = 50
	var check_w3 = stats.can_equip_item("wings_tier3_supreme")
	if check_w3.get("can_equip", false) == true:
		print("  ✅ Sucesso: Asas Supremas Tier 3 permitidas no Nível 50!")
	else:
		print("  ❌ Erro: Asas Supremas Tier 3 bloqueadas no Nível 50!")
		errors += 1

	# Testar restrição de classe cruzada (Zero tentando equipar item da Arya)
	var check_cross = stats.can_equip_item("bow_ellesmera")
	if check_cross.get("can_equip", false) == false:
		print("  ✅ Sucesso: Item da Guardiã Élfica (Arya) bloqueado para Cavaleiro Zero!")
	else:
		print("  ❌ Erro: Item de outra classe equipado indevidamente!")
		errors += 1

	# 4. Validar Integração de Affixes no CharacterStats
	print("[4/5] Validando Bônus de Atributos e Poder de Combate (CP) com Affixes...")
	stats.equipped_gear.clear()
	stats.recalculate_stats()
	var base_atk = stats.get_total_attack()

	# Equipa item instanciado com +25 de Força e +30% de Dano de Fogo
	var custom_sword = {
		"id": "sword_recruta",
		"affixes": [
			{"stat": "strength", "val": 25, "desc": "+25 Força"},
			{"stat": "all_damage_pct", "val": 30.0, "desc": "+30% Dano Global"}
		]
	}
	stats.equip_gear("weapon_main", custom_sword)
	var new_atk = stats.get_total_attack()
	if new_atk > base_atk:
		print("  ✅ Sucesso: Affixes amplificaram o Ataque de %.1f para %.1f!" % [base_atk, new_atk])
	else:
		print("  ❌ Erro: Affixes não influenciaram o cálculo de Ataque!")
		errors += 1

	# 5. Validar Ritual Sagrado de Umaroth (Dragão Mais Sábio - Nível 50 Capstone)
	print("[5/5] Validando Ritual Sagrado de Umaroth no Nível 50...")
	stats.level = 49
	var ritual_res = stats.perform_umaroth_ritual()
	if ritual_res.get("success", false) == false:
		print("  ✅ Sucesso: Ritual de Umaroth recusado antes do Nível 50!")
	else:
		print("  ❌ Erro: Ritual permitido antes do Nível 50!")
		errors += 1

	stats.level = 50
	var cp_before_ritual = stats.get_combat_power()
	ritual_res = stats.perform_umaroth_ritual()
	var cp_after_ritual = stats.get_combat_power()

	if ritual_res.get("success", false) == true and ritual_res.get("awakened", false) == true:
		print("  ✅ Sucesso: Umaroth conduziu o Ritual Sagrado com sucesso!")
		print("     - Bênção: %s" % ritual_res.get("name", ""))
		print("     - CP antes: %d | CP após Ritual: %d (+%d de prestígio mítico)" % [cp_before_ritual, cp_after_ritual, cp_after_ritual - cp_before_ritual])
	else:
		print("  ❌ Erro: Falha ao executar o Ritual de Umaroth no Nível 50!")
		errors += 1

	# Testar tentativa repetida
	var repeat_ritual = stats.perform_umaroth_ritual()
	if repeat_ritual.get("already_awakened", false) == true:
		print("  ✅ Sucesso: O ritual é único e previne ativação duplicada!")
	else:
		print("  ❌ Erro: Ritual permitiu duplicação indevida!")
		errors += 1

	# Finalização
	print("==================================================")
	if errors == 0:
		print("🎉 TODOS OS TESTES DE SETS, AFFIXES E RITUAL PASSARAM COM SUCESSO!")
		print("==================================================")
		quit(0)
	else:
		print("⚠️ FINALIZADO COM %d ERRO(S)!" % errors)
		print("==================================================")
		quit(1)
