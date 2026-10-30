extends SceneTree
## Sonda de balanceamento: imprime o poder efetivo do herói e a curva de mobs.
## Uso: godot --headless --path . --script tools/dev/balance_probe.gd

func _initialize() -> void:
	var script = load("res://scripts/systems/character_stats.gd")
	var s = script.new()
	root.add_child(s)

	print("=== HERÓI PADRÃO (gear inicial do CharacterStats) ===")
	print("  ataque  = %.1f" % s.get_total_attack())
	print("  defesa  = %.1f" % s.get_total_defense())
	print("  absorve = %.3f" % s.get_total_absorb())
	print("  hp      = %.0f / mp = %.0f" % [s.max_hp, s.max_mp])
	print("  cp      = %d" % s.get_combat_power())

	var gear_backup = s.equipped_gear.duplicate(true)
	s.equipped_gear = {}
	s.recalculate_stats()
	print("=== SEM EQUIPAMENTO ===")
	print("  ataque  = %.1f / defesa = %.1f" % [s.get_total_attack(), s.get_total_defense()])
	s.equipped_gear = gear_backup
	s.recalculate_stats()

	var all = ItemsDatabase.get_all_items()
	print("=== ARMAS DE REFERÊNCIA ===")
	for id in ["sword_recruta", "sword_brisingr", "blade_rastreador", "bow_ellesmera", "hammer_roran"]:
		var it: Dictionary = all.get(id, {})
		print("  %-18s base_attack=%s lvl=%s" % [id, it.get("base_attack", "-"), it.get("level_req", "-")])

	print("=== CURVA DE MOBS (MobsDatabase.build_stats) ===")
	for lvl in [1, 3, 8, 21, 35, 50]:
		var st: Dictionary = MobsDatabase.build_stats({"kind": "mob"}, lvl)
		print("  lvl %2d -> hp %6.0f | dmg %5.0f | xp %4d" % [lvl, st["hp"], st["dmg"], st["xp"]])
	quit()
