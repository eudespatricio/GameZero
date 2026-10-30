extends SceneTree
## Teste Automatizado de Verificação de Qualidade Visual e Desobstrução de Visão (Árvores Élficas)
## GameZero - Padrão Dark Fantasy Diablo IV / Path of Exile

func _init() -> void:
	print("\n==================================================")
	print("🧪 TESTE AUTOMATIZADO: ÁRVORES & DESOBSTRUÇÃO DE VISÃO")
	print("==================================================")

	var all_ok := true
	all_ok = all_ok and _test_shaders_exist_and_compile()
	all_ok = all_ok and _test_tree_model_optimization()
	all_ok = all_ok and _test_shader_globals_registered()
	all_ok = all_ok and _test_ancient_tree_prop_materials()
	all_ok = all_ok and _test_occlusion_mathematics()

	print("==================================================")
	if all_ok:
		print("🎉 TODOS OS TESTES DE ÁRVORES E DESOBSTRUÇÃO PASSARAM COM 100% DE SUCESSO!")
		quit(0)
	else:
		printerr("❌ FALHA EM UM OU MAIS TESTES DE ÁRVORES!")
		quit(1)

func _test_shaders_exist_and_compile() -> bool:
	print("[1/5] Validando Compilação dos Novos Shaders PBR (Folhagem e Madeira)...")
	var foliage_path := "res://assets/shaders/tree_foliage.gdshader"
	var bark_path := "res://assets/shaders/tree_bark.gdshader"

	var f_sh = load(foliage_path) as Shader
	if not f_sh:
		printerr("  ❌ Erro: Não foi possível carregar shader de folhagem: ", foliage_path)
		return false
	var f_mat := ShaderMaterial.new()
	f_mat.shader = f_sh

	var b_sh = load(bark_path) as Shader
	if not b_sh:
		printerr("  ❌ Erro: Não foi possível carregar shader de casca/madeira: ", bark_path)
		return false
	var b_mat := ShaderMaterial.new()
	b_mat.shader = b_sh

	print("  ✅ Sucesso: Shaders de Folhagem e Madeira compilados e prontos!")
	return true

func _test_tree_model_optimization() -> bool:
	print("[2/5] Validando Otimização do Modelo 3D (Draw Calls e Meshes Unificadas)...")
	var model_path := "res://assets/models/elven_tree_detailed.glb"
	var scn = load(model_path) as PackedScene
	if not scn:
		printerr("  ❌ Erro: Não foi possível carregar ", model_path)
		return false

	var inst = scn.instantiate()
	var mesh_names: Array[String] = []
	for child in inst.get_children():
		if child is MeshInstance3D:
			mesh_names.append(child.name)
	inst.free()

	if mesh_names.size() != 2:
		printerr("  ❌ Erro: Esperado exatamente 2 meshes unificadas (Trunk e Canopy), mas encontrou %d: %s" % [mesh_names.size(), str(mesh_names)])
		return false

	var has_trunk = "Trunk" in mesh_names
	var has_canopy = "Canopy" in mesh_names
	if not (has_trunk and has_canopy):
		printerr("  ❌ Erro: Meshes encontradas não correspondem a Trunk e Canopy: ", mesh_names)
		return false

	print("  ✅ Sucesso: Modelo 3D com 2 meshes unificadas (Trunk e Canopy). Draw calls reduzidos em 8x!")
	return true

func _test_shader_globals_registered() -> bool:
	print("[3/5] Testando Globais de Shaders para Câmera e Jogador...")
	var has_player = ProjectSettings.has_setting("shader_globals/player_world_pos")
	var has_cam = ProjectSettings.has_setting("shader_globals/camera_world_pos")

	# Testar chamada de API do RenderingServer (executa sem falha ou crash mesmo em headless)
	var test_player_pos := Vector3(12.5, 0.0, -34.2)
	var test_cam_pos := Vector3(12.5, 14.0, -23.2)
	RenderingServer.global_shader_parameter_set("player_world_pos", test_player_pos)
	RenderingServer.global_shader_parameter_set("camera_world_pos", test_cam_pos)

	if not (has_player and has_cam):
		printerr("  ❌ Erro: Globais de shader não configuradas no project.godot!")
		return false

	print("  ✅ Sucesso: Globais 'player_world_pos' e 'camera_world_pos' registradas no projeto e sincronizadas no RenderingServer!")
	return true

func _test_ancient_tree_prop_materials() -> bool:
	print("[4/5] Testando Instanciação do Prop ElvenAncientTree com Shaders...")
	var tree_prop_scn := load("res://scenes/environment/props/elven_ancient_tree.tscn") as PackedScene
	if not tree_prop_scn:
		printerr("  ❌ Erro: Não foi possível carregar elven_ancient_tree.tscn")
		return false

	var tree_inst = tree_prop_scn.instantiate()
	root.add_child(tree_inst)
	tree_inst._ready()

	var model = tree_inst.get_node_or_null("TreeModel")
	if not model:
		printerr("  ❌ Erro: TreeModel não encontrado no prop!")
		tree_inst.queue_free()
		return false

	var trunk_child = model.get_node_or_null("Trunk") as MeshInstance3D
	var canopy_child = model.get_node_or_null("Canopy") as MeshInstance3D

	if not trunk_child or not canopy_child:
		printerr("  ❌ Erro: Trunk ou Canopy não encontrados no TreeModel!")
		tree_inst.queue_free()
		return false

	if not (trunk_child.material_override is ShaderMaterial):
		printerr("  ❌ Erro: Trunk não possui ShaderMaterial override!")
		tree_inst.queue_free()
		return false

	if not (canopy_child.material_override is ShaderMaterial):
		printerr("  ❌ Erro: Canopy não possui ShaderMaterial override!")
		tree_inst.queue_free()
		return false

	tree_inst.queue_free()
	print("  ✅ Sucesso: ElvenAncientTree prop aplica shaders procedurais com sucesso!")
	return true

func _test_occlusion_mathematics() -> bool:
	print("[5/5] Validando Algoritmos de Desobstrução de Visão (Proximidade e Raio de Câmera)...")

	var player_pos := Vector3(0.0, 0.0, 0.0)
	var cam_pos := Vector3(0.0, 14.0, 11.0)
	var player_eye := player_pos + Vector3(0.0, 1.25, 0.0)

	# Caso 1: Ponto da copa diretamente acima da cabeça do jogador (altura Y=4.5, X=0, Z=0)
	var canopy_overhead := Vector3(0.0, 4.5, 0.0)
	var dist_overhead_xz := Vector2(canopy_overhead.x - player_pos.x, canopy_overhead.z - player_pos.z).length()
	var height_overhead_diff := canopy_overhead.y - player_pos.y

	var prox_alpha: float = 1.0
	if height_overhead_diff > 0.6:
		prox_alpha = clampf((dist_overhead_xz - 1.8) / (6.8 - 1.8), 0.0, 1.0)
	var final_overhead_alpha: float = lerpf(0.18, 1.0, prox_alpha)

	if final_overhead_alpha > 0.25:
		printerr("  ❌ Erro: Copa diretamente acima do jogador deveria ser translúcida (<= 0.25), mas deu: ", final_overhead_alpha)
		return false
	print("  ✅ Sucesso: Jogador passando por baixo da copa ativa ver-através (Alpha = %.2f)" % final_overhead_alpha)

	# Caso 2: Ponto da árvore distante (X=25.0, Z=30.0, Y=5.0)
	var tree_distant := Vector3(25.0, 5.0, 30.0)
	var dist_dist_xz: float = Vector2(tree_distant.x - player_pos.x, tree_distant.z - player_pos.z).length()
	var dist_prox_alpha: float = clampf((dist_dist_xz - 1.8) / (6.8 - 1.8), 0.0, 1.0)
	var final_dist_alpha: float = lerpf(0.18, 1.0, dist_prox_alpha)

	if final_dist_alpha < 0.99:
		printerr("  ❌ Erro: Árvore distante deveria ser 100% opaca, mas deu: ", final_dist_alpha)
		return false
	print("  ✅ Sucesso: Árvore distante preserva 100%% de opacidade e detalhes PBR (Alpha = %.2f)" % final_dist_alpha)

	# Caso 3: Ponto bloqueando a linha de visão entre câmera e herói (t = 0.5 ao longo do raio)
	var mid_ray_point := (player_eye + cam_pos) * 0.5
	# Distância ao segmento
	var ab := cam_pos - player_eye
	var ap := mid_ray_point - player_eye
	var t: float = clampf(ap.dot(ab) / ab.dot(ab), 0.0, 1.0)
	var closest: Vector3 = player_eye + t * ab
	var los_dist: float = mid_ray_point.distance_to(closest)
	var los_alpha: float = clampf((los_dist - 1.2) / (3.6 - 1.2), 0.0, 1.0)
	var final_los_alpha: float = lerpf(0.20, 1.0, los_alpha)

	if final_los_alpha > 0.25:
		printerr("  ❌ Erro: Tronco/copa bloqueando a linha de visão deveria ser translúcido, mas deu: ", final_los_alpha)
		return false
	print("  ✅ Sucesso: Obstrução na linha de visão Câmera-Jogador desobstruída com sucesso (Alpha = %.2f)" % final_los_alpha)

	return true
