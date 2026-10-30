extends RefCounted
class_name RPGIconGenerator

static var _cache: Dictionary = {}

static func get_item_icon(item_id: String, item_data: Dictionary, sz: int = 32) -> ImageTexture:
	var key = "%s_%d" % [item_id, sz]
	if _cache.has(key):
		return _cache[key]

	var img = Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var rarity: int = item_data.get("rarity", 0)
	var itype: int = item_data.get("type", 0)
	var glow_col = _rarity_color(rarity)
	var bg_top = Color(0.06, 0.07, 0.10, 1.0)
	var bg_bot = Color(glow_col.r * 0.22, glow_col.g * 0.22, glow_col.b * 0.22, 1.0)

	# 1. Fundo Gradiente Gótico + Moldura Interna Chanfrada
	var c = Vector2(sz * 0.5, sz * 0.5)
	for y in range(sz):
		var ty = float(y) / float(sz - 1)
		for x in range(sz):
			var col = bg_top.lerp(bg_bot, ty)
			var d = Vector2(x, y).distance_to(c) / (sz * 0.65)
			if d < 1.0:
				col = col.lerp(glow_col * Color(0.45, 0.45, 0.45, 1.0), pow(1.0 - d, 2.2) * 0.55)
			if x == 0 or y == 0 or x == sz - 1 or y == sz - 1:
				col = glow_col.darkened(0.25)
			elif x == 1 or y == 1 or x == sz - 2 or y == sz - 2:
				col = Color(0.03, 0.03, 0.05, 1.0)
			img.set_pixel(x, y, col)

	# 2. Silhueta Ilustrada por Tipo de Item (Estilo Diablo IV)
	var gold = Color(0.92, 0.76, 0.28, 1.0)
	var steel = Color(0.75, 0.80, 0.88, 1.0)
	var dark_stone = Color(0.26, 0.24, 0.22, 1.0)

	if "jewel" in item_id or "stone" in item_id or itype == ItemsDatabase.ItemType.JEWEL:
		# Pedra de Runa / Joia entalhada estilo Socketable de Diablo IV
		var rune_col = Color(1.0, 0.68, 0.15) if "bless" in item_id else (Color(0.78, 0.35, 1.0) if "soul" in item_id else Color(0.25, 0.92, 1.0))
		_draw_tablet(img, c, sz * 0.34, dark_stone, gold)
		_draw_rune_glyph(img, c, sz * 0.20, rune_col, item_id.hash())
	elif "sword" in item_id or itype == ItemsDatabase.ItemType.WEAPON:
		var blade_col = Color(0.25, 0.82, 1.0) if "brisingr" in item_id else (Color(1.0, 0.22, 0.25) if "zarroc" in item_id else steel)
		_draw_line_thick(img, Vector2(sz * 0.22, sz * 0.78), Vector2(sz * 0.82, sz * 0.18), 2.4, blade_col)
		_draw_line_thick(img, Vector2(sz * 0.22, sz * 0.56), Vector2(sz * 0.44, sz * 0.78), 2.0, gold)
		_draw_line_thick(img, Vector2(sz * 0.16, sz * 0.84), Vector2(sz * 0.32, sz * 0.68), 2.2, gold)
	elif "shield" in item_id or itype == ItemsDatabase.ItemType.WEAPON_OFFHAND:
		_draw_shield(img, c, sz * 0.32, Color(0.12, 0.38, 0.75), gold)
	elif "helm" in item_id or itype == ItemsDatabase.ItemType.ARMOR_HEAD:
		_draw_circle_ring(img, c + Vector2(0, 2), sz * 0.14, sz * 0.24, steel)
		_draw_line_thick(img, c + Vector2(-sz * 0.26, 2), c + Vector2(-sz * 0.14, -sz * 0.24), 2.2, gold)
		_draw_line_thick(img, c + Vector2(sz * 0.26, 2), c + Vector2(sz * 0.14, -sz * 0.24), 2.2, gold)
	elif "wings" in item_id or itype == ItemsDatabase.ItemType.WINGS:
		for s in [-1.0, 1.0]:
			_draw_line_thick(img, c, c + Vector2(s * sz * 0.34, -sz * 0.26), 2.2, Color(0.25, 0.85, 1.0))
			_draw_line_thick(img, c + Vector2(s * sz * 0.15, -sz * 0.10), c + Vector2(s * sz * 0.32, sz * 0.18), 2.0, Color(0.45, 0.92, 1.0))
	elif "ring" in item_id or itype == ItemsDatabase.ItemType.RING:
		_draw_circle_ring(img, c + Vector2(0, 2), sz * 0.15, sz * 0.23, gold)
		_draw_disc(img, c + Vector2(0, -sz * 0.18), sz * 0.08, glow_col)
	elif "amulet" in item_id or itype == ItemsDatabase.ItemType.AMULET:
		_draw_circle_ring(img, c - Vector2(0, sz * 0.08), sz * 0.18, sz * 0.22, gold)
		_draw_disc(img, c + Vector2(0, sz * 0.10), sz * 0.13, Color(0.2, 0.92, 0.85))
	elif "mount" in item_id or "pet" in item_id or itype == ItemsDatabase.ItemType.MOUNT or itype == ItemsDatabase.ItemType.PET:
		_draw_disc(img, c, sz * 0.20, Color(0.12, 0.52, 0.95))
		_draw_line_thick(img, c + Vector2(-sz * 0.12, -sz * 0.08), c + Vector2(-sz * 0.28, -sz * 0.28), 2.0, gold)
		_draw_line_thick(img, c + Vector2(sz * 0.12, -sz * 0.08), c + Vector2(sz * 0.28, -sz * 0.28), 2.0, gold)
	else:
		# Peitoral / Manoplas / Grevas / Capa
		_draw_shield(img, c, sz * 0.28, steel.darkened(0.25), gold)

	# 3. Estrelas Douradas na Base (Estilo Diablo IV Masterwork Stars)
	var num_stars = clamp(rarity, 1, 4)
	var start_x = c.x - (num_stars - 1) * 3.0
	for s_i in range(num_stars):
		_draw_disc(img, Vector2(start_x + s_i * 6.0, sz - 4.0), 1.6, Color(1.0, 0.88, 0.25))

	var tex = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

static func get_skill_icon(skill_id: String, sz: int = 48) -> ImageTexture:
	var key = "skill_%s_%d" % [skill_id, sz]
	if _cache.has(key):
		return _cache[key]

	var img = Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var c = Vector2(sz * 0.5, sz * 0.5)

	# Fundo metálico escuro com borda ornamental chanfrada
	var border_gold = Color(0.72, 0.58, 0.28, 1.0)
	var bg_inner = Color(0.06, 0.08, 0.12, 1.0)
	var bg_outer = Color(0.14, 0.16, 0.22, 1.0)

	for y in range(sz):
		var ty = float(y) / float(sz - 1)
		for x in range(sz):
			var tx = float(x) / float(sz - 1)
			var dist = Vector2(tx - 0.5, ty - 0.5).length() * 2.0
			var col = bg_inner.lerp(bg_outer, dist * 0.6)
			if x <= 1 or y <= 1 or x >= sz - 2 or y >= sz - 2:
				col = border_gold
			elif x == 2 or y == 2 or x == sz - 3 or y == sz - 3:
				col = Color(0.03, 0.03, 0.04, 1.0)
			img.set_pixel(x, y, col)

	# Silhuetas artísticas de Habilidades
	var cyan = Color(0.28, 0.88, 1.0, 1.0)
	var white = Color(0.95, 0.98, 1.0, 1.0)
	var gold = Color(0.95, 0.78, 0.25, 1.0)
	var fire_blue = Color(0.2, 0.65, 1.0, 1.0)
	var green_earth = Color(0.3, 0.95, 0.55, 1.0)
	var purple_vortex = Color(0.75, 0.35, 1.0, 1.0)

	match skill_id:
		"attack", "combo":
			# Espada curva cortante diagonal
			_draw_line_thick(img, Vector2(sz * 0.2, sz * 0.8), Vector2(sz * 0.8, sz * 0.2), 3.2, white)
			_draw_line_thick(img, Vector2(sz * 0.25, sz * 0.75), Vector2(sz * 0.75, sz * 0.25), 2.0, cyan)
			_draw_line_thick(img, Vector2(sz * 0.15, sz * 0.65), Vector2(sz * 0.35, sz * 0.85), 2.8, gold) # Guarda
			_draw_disc(img, Vector2(sz * 0.15, sz * 0.85), 2.2, gold) # Pomo
		"brisingr", "fire":
			# Labareda flamejante azul de Gedwëy Ignasia
			_draw_disc(img, c + Vector2(0, sz * 0.1), sz * 0.26, fire_blue)
			_draw_disc(img, c + Vector2(0, sz * 0.02), sz * 0.18, cyan)
			_draw_disc(img, c - Vector2(0, sz * 0.08), sz * 0.10, white)
			# Faíscas ascendentes
			_draw_line_thick(img, c + Vector2(0, sz * 0.1), c - Vector2(0, sz * 0.3), 2.2, cyan)
			_draw_disc(img, c - Vector2(sz * 0.14, sz * 0.18), 1.8, fire_blue)
			_draw_disc(img, c + Vector2(sz * 0.14, sz * 0.20), 1.8, fire_blue)
		"jierda", "earth":
			# Martelo de impacto sísmico e rachaduras
			_draw_line_thick(img, c + Vector2(-sz * 0.22, sz * 0.22), c + Vector2(sz * 0.18, -sz * 0.18), 2.6, gold) # Cabo
			_draw_line_thick(img, c + Vector2(sz * 0.08, -sz * 0.28), c + Vector2(sz * 0.28, -sz * 0.08), 5.0, Color(0.7, 0.75, 0.82)) # Cabeça
			# Ondas de choque no solo
			_draw_circle_ring(img, c + Vector2(-sz * 0.18, sz * 0.18), sz * 0.08, sz * 0.16, green_earth)
			_draw_circle_ring(img, c + Vector2(-sz * 0.18, sz * 0.18), sz * 0.18, sz * 0.24, green_earth.darkened(0.3))
		"vortex":
			# Vórtice espiral arcano
			_draw_circle_ring(img, c, sz * 0.12, sz * 0.18, purple_vortex)
			_draw_circle_ring(img, c, sz * 0.24, sz * 0.30, purple_vortex.lightened(0.2))
			_draw_disc(img, c, sz * 0.08, white)
			_draw_line_thick(img, c - Vector2(sz * 0.28, 0), c + Vector2(sz * 0.28, 0), 1.6, cyan)
			_draw_line_thick(img, c - Vector2(0, sz * 0.28), c + Vector2(0, sz * 0.28), 1.6, cyan)
		"mount", "dragon":
			# Perfil majestoso da cabeça e asas da Saphira
			_draw_line_thick(img, c + Vector2(-sz * 0.28, sz * 0.15), c + Vector2(sz * 0.15, -sz * 0.22), 2.8, cyan) # Focinho/pescoço
			_draw_line_thick(img, c + Vector2(sz * 0.15, -sz * 0.22), c + Vector2(sz * 0.32, -sz * 0.05), 2.2, cyan) # Cabeça
			# Chifre dourado
			_draw_line_thick(img, c + Vector2(sz * 0.08, -sz * 0.20), c + Vector2(sz * 0.26, -sz * 0.35), 2.0, gold)
			# Asa aberta
			_draw_line_thick(img, c + Vector2(-sz * 0.10, sz * 0.05), c + Vector2(-sz * 0.35, -sz * 0.25), 2.4, Color(0.2, 0.5, 0.9))
			_draw_disc(img, c + Vector2(sz * 0.18, -sz * 0.12), 1.8, gold) # Olho dourado
		"dash":
			# Asas aerodinâmicas / rastro de velocidade
			for off_y in [-sz * 0.12, 0.0, sz * 0.12]:
				_draw_line_thick(img, c + Vector2(-sz * 0.30, off_y), c + Vector2(sz * 0.25, off_y), 2.0, cyan)
			_draw_line_thick(img, c + Vector2(sz * 0.10, -sz * 0.25), c + Vector2(sz * 0.32, 0), 2.4, white)
			_draw_line_thick(img, c + Vector2(sz * 0.10, sz * 0.25), c + Vector2(sz * 0.32, 0), 2.4, white)
		_:
			_draw_disc(img, c, sz * 0.22, cyan)

	var tex = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

static func get_potion_flask_icon(potion_type: String, sz: int = 48) -> ImageTexture:
	var key = "potion_flask_%s_%d" % [potion_type, sz]
	if _cache.has(key):
		return _cache[key]

	var img = Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var c = Vector2(sz * 0.5, sz * 0.55)

	# Fundo escuro com moldura ornamental arredondada
	var gold = Color(0.92, 0.78, 0.32, 1.0)
	var dark_rim = Color(0.12, 0.14, 0.18, 1.0)

	for y in range(sz):
		for x in range(sz):
			var col = Color(0.04, 0.05, 0.07, 0.95)
			if x == 0 or y == 0 or x == sz - 1 or y == sz - 1:
				col = gold.darkened(0.3)
			elif x == 1 or y == 1 or x == sz - 2 or y == sz - 2:
				col = dark_rim
			img.set_pixel(x, y, col)

	var liquid_col = Color(0.92, 0.18, 0.22, 1.0) if potion_type == "health" else Color(0.18, 0.55, 1.0, 1.0)
	var liquid_glow = Color(1.0, 0.45, 0.48, 1.0) if potion_type == "health" else Color(0.45, 0.82, 1.0, 1.0)

	# 1. Corpo arredondado do frasco (alquimia / orbe de vidro)
	var flask_rad = sz * 0.28
	_draw_disc(img, c, flask_rad, Color(0.1, 0.12, 0.16, 1.0))
	# Líquido mágico preenchendo a metade inferior
	for y in range(int(c.y - flask_rad * 0.2), int(c.y + flask_rad)):
		for x in range(int(c.x - flask_rad), int(c.x + flask_rad + 1)):
			if Vector2(x, y).distance_to(c) <= flask_rad - 1.2:
				var ty = float(y - c.y) / flask_rad
				img.set_pixel(x, y, liquid_col.lerp(liquid_glow, 1.0 - ty * 0.5))

	# Bolhas mágicas brilhantes
	_draw_disc(img, c + Vector2(-sz * 0.10, sz * 0.12), 1.6, liquid_glow)
	_draw_disc(img, c + Vector2(sz * 0.08, sz * 0.08), 1.4, liquid_glow)

	# Borda de vidro do frasco
	_draw_circle_ring(img, c, flask_rad - 1.5, flask_rad, Color(0.8, 0.85, 0.92, 0.85))

	# Reflexo de luz especular curva no vidro
	_draw_disc(img, c - Vector2(sz * 0.12, sz * 0.12), 2.2, Color(1.0, 1.0, 1.0, 0.85))

	# Pescoço e rolha do frasco
	var neck_top = c.y - flask_rad - sz * 0.12
	_draw_line_thick(img, Vector2(c.x, c.y - flask_rad + 2), Vector2(c.x, neck_top), 5.0, Color(0.8, 0.85, 0.92, 0.9))
	_draw_line_thick(img, Vector2(c.x - sz * 0.10, neck_top), Vector2(c.x + sz * 0.10, neck_top), 2.2, gold)
	# Rolha de cortiça dourada
	_draw_line_thick(img, Vector2(c.x, neck_top), Vector2(c.x, neck_top - sz * 0.08), 4.2, Color(0.65, 0.45, 0.22, 1.0))

	var tex = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex

static func _rarity_color(rarity: int) -> Color:
	match rarity:
		1: return Color(0.2, 0.9, 0.4)
		2: return Color(0.2, 0.7, 1.0)
		3: return Color(0.75, 0.3, 0.95)
		4: return Color(1.0, 0.78, 0.18)
		5: return Color(1.0, 0.28, 0.32)
	return Color(0.65, 0.68, 0.72)

static func _draw_disc(img: Image, center: Vector2, rad: float, col: Color) -> void:
	var w = img.get_width()
	var h = img.get_height()
	for y in range(max(0, int(center.y - rad - 1)), min(h, int(center.y + rad + 2))):
		for x in range(max(0, int(center.x - rad - 1)), min(w, int(center.x + rad + 2))):
			var d = Vector2(x, y).distance_to(center)
			if d <= rad:
				img.set_pixel(x, y, col)

static func _draw_circle_ring(img: Image, center: Vector2, r_in: float, r_out: float, col: Color) -> void:
	var w = img.get_width()
	var h = img.get_height()
	for y in range(max(0, int(center.y - r_out - 1)), min(h, int(center.y + r_out + 2))):
		for x in range(max(0, int(center.x - r_out - 1)), min(w, int(center.x + r_out + 2))):
			var d = Vector2(x, y).distance_to(center)
			if d >= r_in and d <= r_out:
				img.set_pixel(x, y, col)

static func _draw_line_thick(img: Image, a: Vector2, b: Vector2, thickness: float, col: Color) -> void:
	var steps = int(a.distance_to(b) * 2.0) + 1
	for i in range(steps + 1):
		var p = a.lerp(b, float(i) / float(steps))
		_draw_disc(img, p, thickness * 0.5, col)

static func _draw_tablet(img: Image, c: Vector2, r: float, fill: Color, border: Color) -> void:
	var w = img.get_width()
	var h = img.get_height()
	for y in range(h):
		for x in range(w):
			var dx = abs(x - c.x)
			var dy = abs(y - c.y)
			if dx < r * 0.85 and dy < r and (dx + dy * 0.6) < r * 1.25:
				var is_edge = dx > r * 0.72 or dy > r * 0.86
				img.set_pixel(x, y, border if is_edge else fill)

static func _draw_shield(img: Image, c: Vector2, r: float, fill: Color, border: Color) -> void:
	var w = img.get_width()
	var h = img.get_height()
	for y in range(h):
		for x in range(w):
			var dy = y - c.y
			var max_w = r * (0.9 - max(0.0, dy / r) * 0.55)
			var dx = abs(x - c.x)
			if abs(dy) <= r and dx <= max_w:
				var is_edge = dx > max_w - 1.8 or abs(dy) > r - 1.8
				img.set_pixel(x, y, border if is_edge else fill)

static func _draw_rune_glyph(img: Image, c: Vector2, r: float, col: Color, seed_val: int) -> void:
	_draw_line_thick(img, c + Vector2(0, -r), c + Vector2(0, r), 1.8, col)
	var dir = 1.0 if (seed_val % 2 == 0) else -1.0
	_draw_line_thick(img, c + Vector2(-r * 0.7, -r * 0.4 * dir), c + Vector2(r * 0.7, r * 0.4 * dir), 1.8, col)
	_draw_line_thick(img, c + Vector2(-r * 0.5, r * 0.5), c + Vector2(r * 0.6, -r * 0.2), 1.6, col)
