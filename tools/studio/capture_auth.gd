extends SceneTree
## Captura a tela inicial (login/seleção de personagem) para inspeção visual.
## Uso: godot --path . --script tools/studio/capture_auth.gd -- /tmp/gz/auth.png

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "/tmp/auth.png"
	var scn := load("res://scenes/ui/auth_and_character_select.tscn") as PackedScene
	var node := scn.instantiate()
	root.add_child(node)
	current_scene = node
	await process_frame
	await process_frame
	await create_timer(1.2).timeout

	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out)
	print("SALVO ", out, " ", img.get_size())
	quit()
