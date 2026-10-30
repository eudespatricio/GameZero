extends Control
## Modal de Notas da Versão e Atualizações do GameZero.
## Apresenta os destaques e novidades do SemVer atual com botão de fechar/confirmar.

signal closed

@onready var title_label: Label = $CenterContainer/Panel/VBox/Header/VBoxText/Title
@onready var subtitle_label: Label = $CenterContainer/Panel/VBox/Header/VBoxText/Subtitle
@onready var version_badge: Label = $CenterContainer/Panel/VBox/Header/VersionBadge
@onready var notes_content: RichTextLabel = $CenterContainer/Panel/VBox/Scroll/Margin/Content
@onready var close_button: Button = $CenterContainer/Panel/VBox/Footer/CloseButton

func _ready() -> void:
	visible = false
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func show_patch_notes(manifest: Dictionary = {}) -> void:
	if manifest.is_empty():
		var ver_mgr = get_node_or_null("/root/VersionManager")
		if ver_mgr:
			manifest = ver_mgr.patch_notes_data

	var v_str = manifest.get("version", "0.5.0")
	var t_str = manifest.get("title", "Notas de Atualização")
	var sub_str = manifest.get("subtitle", "")
	var highlights = manifest.get("highlights", [])
	var changes = manifest.get("changes", [])

	if version_badge:
		version_badge.text = " v%s " % v_str
	if title_label:
		title_label.text = t_str
	if subtitle_label:
		subtitle_label.text = sub_str

	var bbcode := ""
	if not highlights.is_empty():
		bbcode += "[color=#e5c158][b]🌟 PRINCIPAIS NOVIDADES[/b][/color]\n"
		for h in highlights:
			bbcode += "  • %s\n" % str(h)
		bbcode += "\n"

	if not changes.is_empty():
		for sec in changes:
			var cat = sec.get("category", "Geral")
			var items = sec.get("items", [])
			bbcode += "[color=#6bb5ff][b]🔹 %s[/b][/color]\n" % cat
			for item in items:
				bbcode += "  - %s\n" % str(item)
			bbcode += "\n"

	if notes_content:
		notes_content.text = bbcode

	visible = true

func _on_close_pressed() -> void:
	visible = false
	var ver_mgr = get_node_or_null("/root/VersionManager")
	if ver_mgr:
		ver_mgr.mark_patch_notes_seen()
	closed.emit()
