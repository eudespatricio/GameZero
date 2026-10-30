extends Control
class_name WorldMapModal

@onready var close_btn: Button = $Window/Header/CloseButton
@onready var btn_view_region: Button = $Window/Header/TabContainer/BtnViewRegion
@onready var btn_view_continent: Button = $Window/Header/TabContainer/BtnViewContinent
@onready var player_coord_label: Label = $Window/Header/PlayerCoordLabel

# Painel de Detalhes da Localidade
@onready var location_title: Label = $Window/MainHBox/RightDrawer/Margin/VBox/LocationTitle
@onready var location_tier: Label = $Window/MainHBox/RightDrawer/Margin/VBox/LocationTier
@onready var waypoint_status: Label = $Window/MainHBox/RightDrawer/Margin/VBox/WaypointStatus
@onready var location_desc: Label = $Window/MainHBox/RightDrawer/Margin/VBox/LocationDesc
@onready var threats_info: Label = $Window/MainHBox/RightDrawer/Margin/VBox/ThreatsInfo
@onready var drops_info: Label = $Window/MainHBox/RightDrawer/Margin/VBox/DropsInfo
@onready var btn_march: Button = $Window/MainHBox/RightDrawer/Margin/VBox/BtnMarch
@onready var btn_teleport: Button = $Window/MainHBox/RightDrawer/Margin/VBox/BtnTeleport

# Painel Central do Mapa, Textura de Pergaminho & Overlays
@onready var map_viewport: Control = $Window/MainHBox/CenterMapPanel/MapViewport
@onready var parchment_texture: TextureRect = $Window/MainHBox/CenterMapPanel/MapViewport/ParchmentTexture
@onready var continent_overlay: Control = $Window/MainHBox/CenterMapPanel/MapViewport/ContinentOverlay
@onready var region_canvas = $Window/MainHBox/CenterMapPanel/MapViewport/RegionMapCanvas

# Timers de Eventos (Diablo IV)
@onready var event1_label: Label = $Window/MainHBox/LeftDrawer/Margin/VBox/EventBox/EventVBox/Event1
@onready var event2_label: Label = $Window/MainHBox/LeftDrawer/Margin/VBox/EventBox/EventVBox/Event2
@onready var event3_label: Label = $Window/MainHBox/LeftDrawer/Margin/VBox/EventBox/EventVBox/Event3

# Filtros
@onready var search_input: LineEdit = $Window/MainHBox/LeftDrawer/Margin/VBox/SearchInput
@onready var check_waypoints: CheckBox = $Window/MainHBox/LeftDrawer/Margin/VBox/CheckWaypoints
@onready var check_dungeons: CheckBox = $Window/MainHBox/LeftDrawer/Margin/VBox/CheckDungeons
@onready var check_towns: CheckBox = $Window/MainHBox/LeftDrawer/Margin/VBox/CheckTowns
@onready var check_bosses: CheckBox = $Window/MainHBox/LeftDrawer/Margin/VBox/CheckBosses

# Pins Cartográficos no Mapa
@onready var pin_sylveria: Button = $Window/MainHBox/CenterMapPanel/MapViewport/PinSylveria
@onready var pin_ellesmera: Button = $Window/MainHBox/CenterMapPanel/MapViewport/PinEllesmera
@onready var pin_carvahall: Button = $Window/MainHBox/CenterMapPanel/MapViewport/PinCarvahall
@onready var pin_the_spine: Button = $Window/MainHBox/CenterMapPanel/MapViewport/PinTheSpine
@onready var pin_teirm: Button = $Window/MainHBox/CenterMapPanel/MapViewport/PinTeirm
@onready var pin_yazuac: Button = $Window/MainHBox/CenterMapPanel/MapViewport/PinYazuac
@onready var pin_helgrind: Button = $Window/MainHBox/CenterMapPanel/MapViewport/PinHelgrind
@onready var pin_beor: Button = $Window/MainHBox/CenterMapPanel/MapViewport/PinBeor
@onready var pin_urubaen: Button = $Window/MainHBox/CenterMapPanel/MapViewport/PinUrubaen

enum MapMode { REGION, CONTINENT }
var current_mode: MapMode = MapMode.CONTINENT
var player = null
var selected_location_id: String = "sylveria"
var event_timer_razac: float = 855.0  # ~14min
var event_timer_kull: float = 1720.0  # ~28min
var event_timer_durza: float = 4200.0 # ~70min

## Estrada/portal do mapa local que leva a cada região do continente
const LOC_TO_ROAD := {
	"sylveria": "",
	"ellesmera": "norte",
	"carvahall": "oeste",
	"the_spine": "oeste",
	"teirm": "oeste",
	"yazuac": "oeste",
	"helgrind": "oeste",
	"beor": "sul_beor",
	"urubaen": "sul_urubaen",
}

## Posição 3D (diante do portal) para onde o herói marcha / é teleportado para cada região.
func _gate_world_pos(loc_id: String) -> Vector3:
	if loc_id == "sylveria":
		return Vector3(0.0, 0.05, 5.0)
	var road_id: String = LOC_TO_ROAD.get(loc_id, "")
	var mb := get_tree().get_first_node_in_group("map_builder") if is_inside_tree() else null
	if mb and road_id != "":
		for g in mb.gates:
			if g["id"] == road_id:
				var st: Vector2 = g.get("stand", g["pos"])
				return Vector3(st.x, 0.05, st.y)
	return Vector3(0.0, 0.05, 5.0)

var locations_db = {
	"sylveria": {
		"title": "🌲 Santuário de Sylveria [Du Weldenvarden]",
		"tier": "Área Segura • Níveis 36 – 50 [Ponto Atual]",
		"waypoint": "✅ Portal Ativo & Sintonizado [Retorno]",
		"desc": "A sagrada floresta dos elfos sob o dossel vivo de Du Weldenvarden. Árvores cantadas em magia e refúgio protegido contra as forças de Galbatorix.",
		"threats": "💀 Chefe Regional: Durza, O Espectro (Nvl 50)\n• Inimigos: Golem de Raiz, Fanghur das Sombras",
		"drops": "💎 Lâmina Brisingr (+11 Glow)\n💎 Asas Élficas Nvl 2\n💎 Transfiguração em Elfo",
		"type": "waypoint",
		"can_teleport": true
	},
	"ellesmera": {
		"title": "🏰 Ellesméra [Capital dos Elfos]",
		"tier": "Cidadela Nobre • Níveis 40 – 50",
		"waypoint": "🔒 Requer Desbloqueio da Barreira Élfica",
		"desc": "A lendária capital de Islanzadí e Arya. Morada da ferreira Rhunön e da Árvore Menoa. Ponto ápice do treinamento dos Cavaleiros.",
		"threats": "✨ Área Protegida por Feitiços de Barreira\n• Treinadores de Magia Ancestral",
		"drops": "💎 Brightsteel Puro\n💎 Lâmina de Taelbor\n💎 Armadura Élfica de Escamas",
		"type": "town",
		"can_teleport": false
	},
	"carvahall": {
		"title": "🌾 Vale do Palancar & Carvahall",
		"tier": "Vila Inicial • Níveis 1 – 10 [Origem Humana]",
		"waypoint": "✅ Portal Ativo & Sintonizado",
		"desc": "Pequena aldeia camponesa cercada por trigais e montanhas escarpadas. Berço onde a jornada do Cavaleiro e o ovo de dragão foram descobertos.",
		"threats": "💀 Chefe: O Saqueador Urgal (Nvl 10)\n• Inimigos: Javalis Silvestres, Lobos da Espinha",
		"drops": "💎 Joia da Bênção (+1)\n💎 Espada Rústica de Carvahall\n💎 Couro Batido",
		"type": "waypoint",
		"can_teleport": true
	},
	"the_spine": {
		"title": "⛰️ Cordilheira da Espinha (The Spine)",
		"tier": "Picos Hostis • Níveis 11 – 20 [O Ninho]",
		"waypoint": "⚠️ Ponto de Acampamento Perigoso",
		"desc": "Cordilheira inóspita temida pelos homens. Picos afiados de granito onde os Ra'zac caçam nas sombras.",
		"threats": "💀 Chefe: O Caçador Ra'zac (Nvl 20)\n• Inimigos: Wyverns Alados, Vítimas Corrompidas",
		"drops": "💎 Joia da Alma (+7)\n💎 Sela de Voo do Dragão\n💎 Couro de Wyvern",
		"type": "dungeon",
		"can_teleport": false
	},
	"teirm": {
		"title": "⚓ Porto Fortificado de Teirm",
		"tier": "Cidade Mercantil • Níveis 15 – 25",
		"waypoint": "✅ Portal Ativo & Sintonizado",
		"desc": "Imponente cidade murada com torres de vigia sobre o oceano. Centro de comércio marítimo e lar da botica profética de Angela.",
		"threats": "🛡️ Patrulhas do Império & Contrabandistas\n• Casa de Poções e Alquimia",
		"drops": "💎 Elixires Maiores de Mana\n💎 Tomos da Língua Antiga\n💎 Ouro Mercantil",
		"type": "town",
		"can_teleport": true
	},
	"yazuac": {
		"title": "🔥 Ruínas de Yazuac & Hadarac",
		"tier": "Terras Devastadas • Níveis 21 – 35",
		"waypoint": "⚠️ Posto de Vigia Fronteiriço",
		"desc": "Vilarejo incendiado sob os ventos cáusticos do deserto. Território de gigantes Kulls com mais de 2,5 metros de altura.",
		"threats": "💀 Chefe: General Kull Nar Garzhvog (Nvl 35)\n• Inimigos: Xamãs de Sangue, Kulls Gigantes",
		"drops": "💎 Armadura de Placas de Aço Negro\n💎 Joia da Criação (Chaos)\n💎 Machado de Batalha Kull",
		"type": "dungeon",
		"can_teleport": false
	},
	"helgrind": {
		"title": "⛰️ Picos Negros de Helgrind",
		"tier": "Santuário Macabro • Níveis 30 – 40",
		"waypoint": "🔒 Zona Proibida aos Não-Iniciados",
		"desc": "Colunas de pedra vulcânica que perfuram as nuvens perto do Lago Leona. Templo sinistro dos sacerdotes de carne e sangue.",
		"threats": "💀 Fanáticos de Helgrind & Ra'zac Alados\n• Rituais de Sacrifício",
		"drops": "💎 Adaga Cerimonial de Sangue\n💎 Poções de Absorção Extrema",
		"type": "boss",
		"can_teleport": false
	},
	"beor": {
		"title": "🔷 Farthen Dûr & Tronjheim (Beor)",
		"tier": "Fortaleza Anã • Níveis 45 – 50 [Subterrâneo]",
		"waypoint": "✅ Portal Ativo & Sintonizado",
		"desc": "A monumental montanha oca de 15 quilômetros de largura que abriga a cidade cônica de mármore de Tronjheim e a tumba da Estrela de Safira.",
		"threats": "💀 Invasão das Sombras de Durza\n• Defensores Anões e Ursgalianos",
		"drops": "💎 Joia da Alma (+9)\n💎 Martelo dos Clãs Anões\n💎 Escudo de Isidar Mithrim",
		"type": "waypoint",
		"can_teleport": true
	},
	"urubaen": {
		"title": "👑 Cidadela Negra de Urû'baen",
		"tier": "Fortaleza do Imperador • Nível 50+ [Fim do Arco 1]",
		"waypoint": "🔒 Protegido pelos Eldunarí de Galbatorix",
		"desc": "Antiga Ilírea élfica transformada na impenetrável sede do Rei Galbatorix e do dragão negro Shruikan. A muralha mais imponente de Alagaësia.",
		"threats": "👑 Rei Galbatorix & Guardas Juramentados\n• Dragão Negro Shruikan",
		"drops": "💎 Eldunarí Lendário\n💎 Coroa Imperial de Alagaësia",
		"type": "boss",
		"can_teleport": false
	}
}

func _ensure_nodes() -> void:
	if not close_btn: close_btn = get_node_or_null("Window/Header/CloseButton")
	if not btn_view_region: btn_view_region = get_node_or_null("Window/Header/TabContainer/BtnViewRegion")
	if not btn_view_continent: btn_view_continent = get_node_or_null("Window/Header/TabContainer/BtnViewContinent")
	if not player_coord_label: player_coord_label = get_node_or_null("Window/Header/PlayerCoordLabel")
	if not parchment_texture: parchment_texture = get_node_or_null("Window/MainHBox/CenterMapPanel/MapViewport/ParchmentTexture")
	if not continent_overlay: continent_overlay = get_node_or_null("Window/MainHBox/CenterMapPanel/MapViewport/ContinentOverlay")
	if not region_canvas: region_canvas = get_node_or_null("Window/MainHBox/CenterMapPanel/MapViewport/RegionMapCanvas")
	if not btn_march: btn_march = get_node_or_null("Window/MainHBox/RightDrawer/Margin/VBox/BtnMarch")
	if not btn_teleport: btn_teleport = get_node_or_null("Window/MainHBox/RightDrawer/Margin/VBox/BtnTeleport")

func _ready() -> void:
	visible = false
	_ensure_nodes()
	if close_btn and not close_btn.pressed.is_connected(toggle_map):
		close_btn.pressed.connect(toggle_map)

	if btn_view_region:
		btn_view_region.pressed.connect(func(): set_map_mode(MapMode.REGION))
	if btn_view_continent:
		btn_view_continent.pressed.connect(func(): set_map_mode(MapMode.CONTINENT))

	_connect_pins()
	_connect_filters()

	if btn_march and not btn_march.pressed.is_connected(_on_march_pressed):
		btn_march.pressed.connect(_on_march_pressed)
	if btn_teleport and not btn_teleport.pressed.is_connected(_on_teleport_pressed):
		btn_teleport.pressed.connect(_on_teleport_pressed)

	if continent_overlay:
		if not continent_overlay.draw.is_connected(_on_continent_overlay_draw):
			continent_overlay.draw.connect(_on_continent_overlay_draw)
		if not continent_overlay.gui_input.is_connected(_on_continent_overlay_gui_input):
			continent_overlay.gui_input.connect(_on_continent_overlay_gui_input)

	select_location("sylveria")
	set_map_mode(MapMode.CONTINENT)

func set_map_mode(mode: MapMode) -> void:
	_ensure_nodes()
	current_mode = mode

	# Atualização visual dos botões de abas
	if btn_view_continent:
		if mode == MapMode.CONTINENT:
			btn_view_continent.modulate = Color(1.3, 1.3, 1.3)
			btn_view_continent.text = "● Continente (Ativo)"
		else:
			btn_view_continent.modulate = Color(0.7, 0.7, 0.7)
			btn_view_continent.text = "🗺️ Continente Alagaësia"

	if btn_view_region:
		if mode == MapMode.REGION:
			btn_view_region.modulate = Color(1.3, 1.3, 1.3)
			btn_view_region.text = "● Região Sylveria (Ativo)"
		else:
			btn_view_region.modulate = Color(0.7, 0.7, 0.7)
			btn_view_region.text = "🌲 Região Sylveria"

	if mode == MapMode.CONTINENT:
		if parchment_texture:
			parchment_texture.visible = true
		if continent_overlay:
			continent_overlay.visible = true
			continent_overlay.queue_redraw()
		if region_canvas:
			region_canvas.visible = false
		_apply_filters()
	else:
		if parchment_texture:
			parchment_texture.visible = false
		if continent_overlay:
			continent_overlay.visible = false
		if region_canvas:
			region_canvas.visible = true
			region_canvas.queue_redraw()
		for btn in [pin_sylveria, pin_ellesmera, pin_carvahall, pin_the_spine, pin_teirm, pin_yazuac, pin_helgrind, pin_beor, pin_urubaen]:
			if btn:
				btn.visible = false

func _process(delta: float) -> void:
	if not visible:
		return

	# Timers de Eventos estilo Diablo IV Helltide
	event_timer_razac = max(0.0, event_timer_razac - delta)
	event_timer_kull = max(0.0, event_timer_kull - delta)
	event_timer_durza = max(0.0, event_timer_durza - delta)

	if event1_label:
		event1_label.text = "🔥 Caçada Ra'zac:  %s" % _format_timer(event_timer_razac)
	if event2_label:
		event2_label.text = "⚔️ Invasão Kull:      %s" % _format_timer(event_timer_kull)
	if event3_label:
		event3_label.text = "💀 Espectro Durza: %s" % _format_timer(event_timer_durza)

	# Atualização da Localização e Status de Marcha do Herói no Header
	if not player:
		player = get_tree().get_first_node_in_group("player") as Player

	if player_coord_label and player:
		var px = int(player.global_position.x)
		var pz = int(player.global_position.z)
		var is_mount = player.is_mounted if ("is_mounted" in player) else false
		var is_moving = player.is_moving_to_target if ("is_moving_to_target" in player) else false
		var riding_str = " (🐉 Montado)" if is_mount else ""
		var march_str = "🧭 Em Marcha para Destino" if ((region_canvas and region_canvas.has_destination) or is_moving) else "🛡️ Parado"
		player_coord_label.text = "📍 Herói: [X: %d, Z: %d]%s • %s" % [px, pz, riding_str, march_str]

	if current_mode == MapMode.CONTINENT and continent_overlay and continent_overlay.visible:
		continent_overlay.queue_redraw()

func _format_timer(seconds: float) -> String:
	var total = int(seconds)
	var h = int(float(total) / 3600.0)
	var m = int(float(total % 3600) / 60.0)
	var s = total % 60
	if h > 0:
		return "%02d:%02d:%02d" % [h, m, s]
	return "%02d:%02d" % [m, s]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_map") or (visible and event.is_action_pressed("ui_cancel")):
		toggle_map()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.is_echo():
		if visible and event.keycode == KEY_TAB:
			var next_mode = MapMode.CONTINENT if current_mode == MapMode.REGION else MapMode.REGION
			set_map_mode(next_mode)
			get_viewport().set_input_as_handled()

func toggle_map() -> void:
	visible = !visible
	if is_inside_tree():
		GameAudio.play_ui(get_tree(), "open" if visible else "close")
	if visible:
		if not player:
			player = get_tree().get_first_node_in_group("player") as Player
		set_map_mode(current_mode)
		if current_mode == MapMode.CONTINENT and continent_overlay:
			continent_overlay.queue_redraw()
		elif region_canvas:
			region_canvas.queue_redraw()

func _connect_pins() -> void:
	var pins = {
		pin_sylveria: "sylveria",
		pin_ellesmera: "ellesmera",
		pin_carvahall: "carvahall",
		pin_the_spine: "the_spine",
		pin_teirm: "teirm",
		pin_yazuac: "yazuac",
		pin_helgrind: "helgrind",
		pin_beor: "beor",
		pin_urubaen: "urubaen"
	}
	for btn in pins.keys():
		if btn:
			var loc_id = pins[btn]
			btn.pressed.connect(select_location.bind(loc_id, true))

func _connect_filters() -> void:
	if check_waypoints: check_waypoints.toggled.connect(func(_b): _apply_filters())
	if check_dungeons: check_dungeons.toggled.connect(func(_b): _apply_filters())
	if check_towns: check_towns.toggled.connect(func(_b): _apply_filters())
	if check_bosses: check_bosses.toggled.connect(func(_b): _apply_filters())
	if search_input: search_input.text_changed.connect(func(_t): _apply_filters())

func _apply_filters() -> void:
	if current_mode == MapMode.REGION:
		for btn in [pin_sylveria, pin_ellesmera, pin_carvahall, pin_the_spine, pin_teirm, pin_yazuac, pin_helgrind, pin_beor, pin_urubaen]:
			if btn: btn.visible = false
		return

	var show_wp = check_waypoints.button_pressed if check_waypoints else true
	var show_dung = check_dungeons.button_pressed if check_dungeons else true
	var show_town = check_towns.button_pressed if check_towns else true
	var show_boss = check_bosses.button_pressed if check_bosses else true
	var query = search_input.text.to_lower() if search_input else ""

	var pin_map = {
		pin_sylveria: "sylveria",
		pin_ellesmera: "ellesmera",
		pin_carvahall: "carvahall",
		pin_the_spine: "the_spine",
		pin_teirm: "teirm",
		pin_yazuac: "yazuac",
		pin_helgrind: "helgrind",
		pin_beor: "beor",
		pin_urubaen: "urubaen"
	}

	for btn in pin_map.keys():
		if not btn: continue
		var loc_id = pin_map[btn]
		var data = locations_db.get(loc_id, {})
		var ltype = data.get("type", "")
		var title = data.get("title", "").to_lower()

		var type_match = true
		if ltype == "waypoint" and not show_wp: type_match = false
		elif ltype == "dungeon" and not show_dung: type_match = false
		elif ltype == "town" and not show_town: type_match = false
		elif ltype == "boss" and not show_boss: type_match = false

		var search_match = true
		if query != "" and not title.contains(query):
			search_match = false

		btn.visible = type_match and search_match

func select_location(loc_id: String, start_march: bool = false) -> void:
	selected_location_id = loc_id
	if not locations_db.has(loc_id):
		return

	var d = locations_db[loc_id]
	if location_title: location_title.text = d["title"]
	if location_tier: location_tier.text = d["tier"]
	if waypoint_status: waypoint_status.text = d["waypoint"]
	if location_desc: location_desc.text = d["desc"]
	if threats_info: threats_info.text = d["threats"]
	if drops_info: drops_info.text = d["drops"]

	var short_name = d["title"].split("[")[0].strip_edges()
	if btn_march:
		btn_march.text = "🧭 Marchar até a Fronteira de %s" % short_name

	if btn_teleport:
		if d["can_teleport"]:
			btn_teleport.text = "⚡ Teleportar para o Destino"
			btn_teleport.disabled = false
		else:
			btn_teleport.text = "🔒 Destino Não Sintonizado"
			btn_teleport.disabled = true

	if start_march:
		march_to_location(loc_id)

	if continent_overlay:
		continent_overlay.queue_redraw()

func _on_march_pressed() -> void:
	march_to_location(selected_location_id)

func march_to_location(loc_id: String) -> void:
	if not LOC_TO_ROAD.has(loc_id):
		return

	var dest_3d: Vector3 = _gate_world_pos(loc_id)
	var d = locations_db.get(loc_id, {})
	var title = d.get("title", loc_id).split("[")[0].strip_edges()

	if not player:
		player = get_tree().get_first_node_in_group("player") as Player

	if player:
		player.target_position = dest_3d
		player.is_moving_to_target = true
		if player.click_marker:
			player.click_marker.global_position = dest_3d + Vector3(0, 0.06, 0)
			player.click_marker.visible = true

		var t = get_tree()
		if t:
			GameAudio.play_pickup(t)
			var hud = t.get_first_node_in_group("hud")
			if hud and hud.has_method("show_notification"):
				var gate_name = "Portão Norte (Ellesméra)" if loc_id == "ellesmera" else ("Portão Oeste (Fronteira)" if loc_id in ["carvahall", "the_spine", "teirm", "yazuac", "helgrind"] else ("Portão Sul (Império/Beor)" if loc_id in ["beor", "urubaen"] else "Praça do Santuário"))
				hud.show_notification("🧭 Cavaleiro em marcha até o %s rumo a: %s" % [gate_name, title], Color(1.0, 0.88, 0.35))

	if continent_overlay:
		continent_overlay.queue_redraw()

func _get_pin_center(btn: Button) -> Vector2:
	if not btn: return Vector2.ZERO
	return btn.position + btn.size * 0.5

func _on_continent_overlay_draw() -> void:
	if not pin_sylveria: return
	var sylv_pos = _get_pin_center(pin_sylveria)

	# 1. RADAR ARCANO DO HERÓI EM SYLVERIA (VOCÊ ESTÁ AQUI)
	var pulse = (sin(Time.get_ticks_msec() / 180.0) + 1.0) * 0.5
	var radar_rad = 18.0 + pulse * 8.0
	continent_overlay.draw_arc(sylv_pos, radar_rad, 0, TAU, 32, Color(0.25, 0.95, 1.0, 0.85 - pulse * 0.45), 2.2)
	continent_overlay.draw_circle(sylv_pos, 5.0, Color(0.2, 0.9, 1.0, 1.0))

	# Seta Direcional de Orientação do Cavaleiro
	var rot_y = player.visual_root.rotation.y if (player and player.visual_root) else 0.0
	var dir_forward = Vector2(sin(rot_y), cos(rot_y))
	var dir_right = Vector2(-dir_forward.y, dir_forward.x)
	var tip = sylv_pos + dir_forward * 13.0
	var base_l = sylv_pos - dir_forward * 4.0 - dir_right * 5.0
	var base_r = sylv_pos - dir_forward * 4.0 + dir_right * 5.0
	continent_overlay.draw_colored_polygon(PackedVector2Array([tip, base_l, base_r]), Color(1.0, 0.88, 0.28, 1.0))

	continent_overlay.draw_string(ThemeDB.fallback_font, sylv_pos + Vector2(-65, -18), "📍 VOCÊ ESTÁ AQUI", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.3, 0.98, 1.0))

	# 2. ROTA DE VIAGEM ATÉ O DESTINO SELECIONADO
	if selected_location_id != "" and selected_location_id != "sylveria":
		var pin_map = {
			"ellesmera": pin_ellesmera,
			"carvahall": pin_carvahall,
			"the_spine": pin_the_spine,
			"teirm": pin_teirm,
			"yazuac": pin_yazuac,
			"helgrind": pin_helgrind,
			"beor": pin_beor,
			"urubaen": pin_urubaen
		}
		var target_btn = pin_map.get(selected_location_id)
		if target_btn and target_btn.visible:
			var dest_pos = _get_pin_center(target_btn)

			# Linha de rota de navegação tracejada em ouro brilhante
			var mid_pt = (sylv_pos + dest_pos) * 0.5 + Vector2(0, -25.0)
			var steps = 18
			var prev_pt = sylv_pos
			for i in range(1, steps + 1):
				var t = float(i) / float(steps)
				var curr_pt = (1.0 - t) * (1.0 - t) * sylv_pos + 2.0 * (1.0 - t) * t * mid_pt + t * t * dest_pos
				if i % 2 == 1:
					continent_overlay.draw_line(prev_pt, curr_pt, Color(1.0, 0.85, 0.35, 0.88), 2.5)
				prev_pt = curr_pt

			# Waypoint pulsante no destino
			var dest_pulse = (sin(Time.get_ticks_msec() / 220.0 + 1.2) + 1.0) * 0.5
			var dest_rad = 16.0 + dest_pulse * 6.0
			continent_overlay.draw_arc(dest_pos, dest_rad, 0, TAU, 28, Color(1.0, 0.85, 0.25, 0.95), 2.2)
			continent_overlay.draw_circle(dest_pos, 4.5, Color(1.0, 0.45, 0.2, 1.0))
			continent_overlay.draw_string(ThemeDB.fallback_font, dest_pos + Vector2(-35, -16), "🏁 DESTINO", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1.0, 0.88, 0.35))

func _on_continent_overlay_gui_input(event: InputEvent) -> void:
	if not visible or current_mode != MapMode.CONTINENT:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pin_map = {
			"sylveria": pin_sylveria,
			"ellesmera": pin_ellesmera,
			"carvahall": pin_carvahall,
			"the_spine": pin_the_spine,
			"teirm": pin_teirm,
			"yazuac": pin_yazuac,
			"helgrind": pin_helgrind,
			"beor": pin_beor,
			"urubaen": pin_urubaen
		}
		var closest_id = "sylveria"
		var min_dist = INF
		for loc_id in pin_map.keys():
			var btn = pin_map[loc_id]
			if btn and btn.visible:
				var d = event.position.distance_to(_get_pin_center(btn))
				if d < min_dist:
					min_dist = d
					closest_id = loc_id

		select_location(closest_id, true)
		accept_event()

func _on_teleport_pressed() -> void:
	if not locations_db.has(selected_location_id):
		return

	var d = locations_db[selected_location_id]
	if not d["can_teleport"]:
		return

	var tree = get_tree()
	if not player:
		player = tree.get_first_node_in_group("player")

	# Viagem instantânea: o herói reaparece diante do portal da estrada correspondente
	if player:
		var from_pos: Vector3 = player.global_position
		var dest: Vector3 = _gate_world_pos(selected_location_id)
		CombatVFX.spawn_shockwave_ring(tree, from_pos, 5.0, Color(0.3, 0.9, 1.0))
		CombatVFX.spawn_cast_charge(tree, from_pos, Color(0.3, 0.9, 1.0), 0.3)
		player.global_position = dest
		player.velocity = Vector3.ZERO
		player.is_moving_to_target = false
		if player.click_marker:
			player.click_marker.visible = false
		CombatVFX.spawn_level_up(tree, dest)
		CombatVFX.trigger_screen_shake(tree, 0.3)

	var hud = tree.get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("Viagem pelo Portal concluída: %s" % d["title"], Color(0.3, 0.9, 1.0))

	# Som de teleporte
	GameAudio.am(tree, "play_teleport")

	toggle_map()
