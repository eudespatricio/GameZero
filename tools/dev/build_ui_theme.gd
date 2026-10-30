extends SceneTree
## Gera `assets/ui/ui_theme.tres` a partir do UIStyle.
## Uso: godot --headless --path . --script tools/dev/build_ui_theme.gd

func _initialize() -> void:
	await process_frame
	var ui = root.get_node_or_null("UIStyle")
	if not ui:
		push_error("Autoload UIStyle não encontrado.")
		quit(1)
		return

	ui._load_fonts()
	ui.theme = ui.build_theme()
	var err: int = ui.save_theme()
	if err != OK:
		push_error("Falha ao salvar o tema (código %d)." % err)
		quit(1)
		return

	print("Tema salvo em ", ui.THEME_PATH)
	quit(0)
