extends Node
## Estilo global da interface (autoload `UIStyle`).
##
## Constrói o `Theme` do jogo (tipografia, paleta e styleboxes) e o aplica na
## janela raiz. O mesmo tema é exportado para `assets/ui/ui_theme.tres` e
## registrado em `gui/theme/custom`, porque a HUD vive num `CanvasLayer` — fora
## da cadeia de herança de tema dos Controls — e só o padrão do projeto a alcança.
##
## Para regenerar o .tres após mudar a paleta:
##   godot --headless --path . --script tools/dev/build_ui_theme.gd

const FONT_UI := "res://assets/fonts/Montserrat.ttf"
const FONT_EMOJI := "res://assets/fonts/NotoEmoji.ttf"
const THEME_PATH := "res://assets/ui/ui_theme.tres"

# --- Paleta (Dark Fantasy / Alagaësia) ---
const BG_DEEP := Color("#0b0d12")
const BG_PANEL := Color("#11141b")
const BG_RAISED := Color("#1a1f2a")
const LINE_GOLD := Color("#c9a95c")
const LINE_SOFT := Color("#2b3542")
const TEXT_MAIN := Color("#e6ebf2")
const TEXT_MUTED := Color("#94a1b3")
const GOLD := Color("#e8c46a")
const TEAL := Color("#4fd8c4")
const HP_RED := Color("#c9333f")
const MP_BLUE := Color("#3e7be0")
const XP_BLUE := Color("#2fa8e0")

# --- Escala tipográfica ---
const FS_TITLE := 22
const FS_HEADING := 17
const FS_BODY := 15
const FS_SMALL := 13

var theme: Theme
var font_ui: Font
var font_emoji: Font
var font_display: Font

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_fonts()
	theme = build_theme()
	_apply.call_deferred()

func _apply() -> void:
	var win := get_tree().root
	if win and theme:
		win.theme = theme

## Montserrat como fonte principal, com Noto Emoji como fallback de pictogramas.
## A composição vai num `FontVariation` para que a cadeia seja serializável no .tres.
func _load_fonts() -> void:
	font_ui = load(FONT_UI)
	font_emoji = load(FONT_EMOJI)
	if font_ui and font_emoji:
		var variation := FontVariation.new()
		variation.base_font = font_ui
		variation.fallbacks = [font_emoji]
		font_display = variation
	else:
		font_display = font_ui if font_ui else ThemeDB.fallback_font

func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font_display
	t.default_font_size = FS_BODY

	_setup_labels(t)
	_setup_buttons(t)
	_setup_panels(t)
	_setup_bars(t)
	_setup_inputs(t)
	_setup_popups(t)
	return t

## Grava o tema em disco para ser usado como tema padrão do projeto.
func save_theme() -> Error:
	var dir := DirAccess.open("res://assets/ui")
	if not dir:
		DirAccess.make_dir_recursive_absolute("res://assets/ui")
	return ResourceSaver.save(theme, THEME_PATH)

# ------------------------------------------------------------------
# HELPERS
# ------------------------------------------------------------------
static func panel_box(bg: Color = BG_PANEL, border: Color = LINE_SOFT, radius: int = 8,
		border_w: int = 1, shadow: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(border_w)
	sb.border_color = border
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	if shadow > 0:
		sb.shadow_color = Color(0, 0, 0, 0.55)
		sb.shadow_size = shadow
		sb.shadow_offset = Vector2(0, 2)
	return sb

static func bar_fill(color: Color, radius: int = 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	return sb

# ------------------------------------------------------------------
# TIPOS
# ------------------------------------------------------------------
func _setup_labels(t: Theme) -> void:
	for type_name in ["Label", "RichTextLabel"]:
		t.set_font("font", type_name, font_display)
	t.set_color("font_color", "Label", TEXT_MAIN)
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 1)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.75))
	t.set_color("default_color", "RichTextLabel", TEXT_MAIN)
	t.set_font_size("normal_font_size", "RichTextLabel", FS_BODY)

func _setup_buttons(t: Theme) -> void:
	var normal := panel_box(BG_PANEL, LINE_SOFT, 6, 1, 3)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 5
	normal.content_margin_bottom = 5

	var hover := panel_box(BG_RAISED, LINE_GOLD, 6, 1, 4)
	hover.content_margin_left = 10
	hover.content_margin_right = 10
	hover.content_margin_top = 5
	hover.content_margin_bottom = 5

	var pressed := panel_box(Color("#0a0c10"), GOLD, 6, 1, 0)
	pressed.content_margin_left = 10
	pressed.content_margin_right = 10
	pressed.content_margin_top = 5
	pressed.content_margin_bottom = 5

	var disabled := panel_box(Color("#0c0e13"), Color("#20262f"), 6, 1, 0)
	disabled.content_margin_left = 10
	disabled.content_margin_right = 10
	disabled.content_margin_top = 5
	disabled.content_margin_bottom = 5

	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)
	focus.set_border_width_all(1)
	focus.border_color = Color(TEAL, 0.75)
	focus.set_corner_radius_all(6)
	focus.set_expand_margin_all(1.0)

	for type_name in ["Button", "OptionButton", "MenuButton", "CheckBox", "CheckButton"]:
		t.set_stylebox("normal", type_name, normal)
		t.set_stylebox("hover", type_name, hover)
		t.set_stylebox("pressed", type_name, pressed)
		t.set_stylebox("disabled", type_name, disabled)
		t.set_stylebox("focus", type_name, focus)
		t.set_font("font", type_name, font_display)
		t.set_color("font_color", type_name, TEXT_MAIN)
		t.set_color("font_hover_color", type_name, Color("#fff3d4"))
		t.set_color("font_pressed_color", type_name, GOLD)
		t.set_color("font_disabled_color", type_name, Color(TEXT_MUTED, 0.55))
		t.set_font_size("font_size", type_name, FS_BODY - 1)

func _setup_panels(t: Theme) -> void:
	t.set_stylebox("panel", "Panel", panel_box(BG_PANEL, LINE_SOFT, 8, 1, 6))
	t.set_stylebox("panel", "PanelContainer", panel_box(BG_PANEL, LINE_SOFT, 8, 1, 6))
	t.set_stylebox("panel", "ScrollContainer", panel_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 0))
	t.set_stylebox("panel", "PopupPanel", panel_box(BG_DEEP, LINE_GOLD, 8, 1, 10))
	t.set_stylebox("panel", "TooltipPanel", panel_box(Color("#0d1017"), LINE_GOLD, 6, 1, 6))
	t.set_font("font", "TooltipLabel", font_display)
	t.set_color("font_color", "TooltipLabel", TEXT_MAIN)
	t.set_font_size("font_size", "TooltipLabel", FS_SMALL)

func _setup_bars(t: Theme) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("#070a0e")
	bg.set_corner_radius_all(5)
	bg.set_border_width_all(1)
	bg.border_color = Color("#000000", 0.9)

	t.set_stylebox("background", "ProgressBar", bg)
	t.set_stylebox("fill", "ProgressBar", bar_fill(HP_RED, 4))
	t.set_color("font_color", "ProgressBar", TEXT_MAIN)
	t.set_font_size("font_size", "ProgressBar", FS_SMALL)

func _setup_inputs(t: Theme) -> void:
	var normal := panel_box(Color("#0a0d13"), LINE_SOFT, 5, 1, 0)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	var focus := panel_box(Color("#0a0d13"), GOLD, 5, 1, 0)
	focus.content_margin_left = 10
	focus.content_margin_right = 10
	t.set_stylebox("normal", "LineEdit", normal)
	t.set_stylebox("focus", "LineEdit", focus)
	t.set_stylebox("read_only", "LineEdit", normal)
	t.set_font("font", "LineEdit", font_display)
	t.set_color("font_color", "LineEdit", TEXT_MAIN)
	t.set_color("font_placeholder_color", "LineEdit", Color(TEXT_MUTED, 0.7))
	t.set_color("caret_color", "LineEdit", GOLD)
	t.set_font_size("font_size", "LineEdit", FS_BODY)

func _setup_popups(t: Theme) -> void:
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(GOLD, 0.16)
	hover.set_corner_radius_all(4)
	t.set_stylebox("hover", "PopupMenu", hover)
	t.set_stylebox("panel", "PopupMenu", panel_box(BG_DEEP, LINE_GOLD, 8, 1, 10))
	t.set_font("font", "PopupMenu", font_display)
	t.set_color("font_color", "PopupMenu", TEXT_MAIN)
	t.set_font_size("font_size", "PopupMenu", FS_SMALL)
	t.set_stylebox("panel", "ItemList", panel_box(BG_DEEP, LINE_SOFT, 6, 1, 6))
	t.set_stylebox("selected", "ItemList", hover)
