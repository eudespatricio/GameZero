extends Node
## Gerenciador de áudio do GameZero.
## - SFX com variações e pitch aleatório (arquivos .ogg gerados por tools/audio/generate_sfx.py)
## - SFX 3D posicionais (monstros, portais)
## - Barramentos SFX / Ambient / Music com compressor, limitador e reverb
## - Diretor de ambiência e música: troca por bioma e luta de chefe com crossfade
## Se algum arquivo estiver ausente, usa os sons sintetizados em memória (fallback) para os efeitos originais.

const SFX_DIR := "res://assets/audio/sfx/"
const AMB_DIR := "res://assets/audio/ambient/"
const MUS_DIR := "res://assets/audio/music/"
const LAYERS := {
	"amb_forest_night": [AMB_DIR, "Ambient"],
	"amb_wasteland": [AMB_DIR, "Ambient"],
	"amb_sanctuary": [AMB_DIR, "Ambient"],
	"music_sanctuary": [MUS_DIR, "Music"],
	"music_wilds": [MUS_DIR, "Music"],
	"music_boss": [MUS_DIR, "Music"],
}

var sfx_players: Array[AudioStreamPlayer] = []
var max_players: int = 14
var _cache: Dictionary = {}          # nome -> Array[AudioStream]
var _layers: Dictionary = {}         # chave -> AudioStreamPlayer
var _targets: Dictionary = {}        # chave -> volume alvo (dB)
var _active_3d: int = 0
var _director_timer: float = 0.0
var _player: Node3D
var _map_builder: Node
var _last_zone: String = ""

# Sons pré-calculados (fallback)
var sound_jewel_drop: AudioStreamWAV
var sound_sword_slash: AudioStreamWAV
var sound_hit: AudioStreamWAV
var sound_level_up: AudioStreamWAV
var sound_refine_success: AudioStreamWAV
var sound_refine_fail: AudioStreamWAV
var sound_gather: AudioStreamWAV

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()

	# Criar pool de tocadores de áudio
	for i in range(max_players):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = "SFX"
		add_child(p)
		sfx_players.append(p)

	# Não sintetizamos na CPU em _ready para economizar ciclos e inicializar instantâneo;
	# os sons sintetizados só são criados sob demanda (lazy) se o arquivo .ogg não existir.
	_start_layers()

# ------------------------------------------------------------------
# BARRAMENTOS
# ------------------------------------------------------------------
func _setup_buses() -> void:
	for bus_name in ["SFX", "Ambient", "Music"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")
	var sfx := AudioServer.get_bus_index("SFX")
	if AudioServer.get_bus_effect_count(sfx) == 0:
		var comp := AudioEffectCompressor.new()
		comp.threshold = -14.0
		comp.ratio = 3.0
		comp.attack_us = 15.0
		comp.release_ms = 140.0
		AudioServer.add_bus_effect(sfx, comp)
	AudioServer.set_bus_volume_db(sfx, 0.0)

	var amb := AudioServer.get_bus_index("Ambient")
	AudioServer.set_bus_volume_db(amb, -5.0)

	var mus := AudioServer.get_bus_index("Music")
	if AudioServer.get_bus_effect_count(mus) == 0:
		var rev := AudioEffectReverb.new()
		rev.room_size = 0.55
		rev.wet = 0.12
		AudioServer.add_bus_effect(mus, rev)
	AudioServer.set_bus_volume_db(mus, -9.0)

	var master := AudioServer.get_bus_index("Master")
	if AudioServer.get_bus_effect_count(master) == 0:
		var lim := AudioEffectLimiter.new()
		lim.ceiling_db = -1.0
		AudioServer.add_bus_effect(master, lim)

# ------------------------------------------------------------------
# CARREGAMENTO COM VARIAÇÕES (nome, nome_1, nome_2 ...)
# ------------------------------------------------------------------
func _variants(sfx_name: String) -> Array:
	if _cache.has(sfx_name):
		return _cache[sfx_name]
	var list: Array = []
	var base := SFX_DIR + sfx_name + ".ogg"
	if ResourceLoader.exists(base):
		list.append(load(base))
	for i in range(1, 9):
		var v := SFX_DIR + "%s_%d.ogg" % [sfx_name, i]
		if ResourceLoader.exists(v):
			list.append(load(v))
	_cache[sfx_name] = list
	return list

func has_sfx(sfx_name: String) -> bool:
	return not _variants(sfx_name).is_empty()

## Toca um efeito (escolhe uma variação aleatória) com leve variação de pitch.
func play_sfx(sfx_name: String, volume_db: float = 0.0, pitch: float = 1.0, pitch_var: float = 0.05) -> bool:
	var list := _variants(sfx_name)
	if list.is_empty():
		return false
	var stream: AudioStream = list[randi() % list.size()]
	var p := _free_player()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch * (1.0 + randf_range(-pitch_var, pitch_var))
	p.play()
	return true

## Toca um efeito 3D no ponto do mundo (monstros, portais). Descarta se houver muitos simultâneos.
func play_sfx_3d(sfx_name: String, pos: Vector3, volume_db: float = 0.0, max_dist: float = 35.0, pitch: float = 1.0, pitch_var: float = 0.12) -> void:
	var list := _variants(sfx_name)
	if list.is_empty() or _active_3d >= 24:
		return
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	var scene := tree.current_scene
	var p := AudioStreamPlayer3D.new()
	p.stream = list[randi() % list.size()]
	p.bus = "SFX"
	p.volume_db = volume_db
	p.unit_size = 9.0
	p.max_distance = max_dist
	p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
	p.pitch_scale = pitch * (1.0 + randf_range(-pitch_var, pitch_var))
	scene.add_child(p)
	p.global_position = pos
	_active_3d += 1
	p.finished.connect(func():
		_active_3d = maxi(0, _active_3d - 1)
		if is_instance_valid(p):
			p.queue_free()
	)
	p.play()

func _free_player() -> AudioStreamPlayer:
	for p in sfx_players:
		if not p.playing:
			return p
	return sfx_players[0]

func play_sound(stream: AudioStreamWAV, volume_db: float = 0.0) -> void:
	if not stream:
		return
	var p := _free_player()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0
	p.play()

# ------------------------------------------------------------------
# API PÚBLICA (compatível com GameAudio)
# ------------------------------------------------------------------
func play_jewel() -> void:
	if not play_sfx("loot_item", -1.0, 1.0, 0.04):
		if sound_jewel_drop == null:
			sound_jewel_drop = _synth_crystal_chime()
		play_sound(sound_jewel_drop, 2.0)

func play_slash() -> void:
	if not play_sfx("slash", 0.0, 1.0, 0.08):
		if sound_sword_slash == null:
			sound_sword_slash = _synth_slash()
		play_sound(sound_sword_slash, -2.0)

func play_hit() -> void:
	if not play_sfx("hit_flesh", 0.0, 1.0, 0.1):
		if sound_hit == null:
			sound_hit = _synth_hit()
		play_sound(sound_hit, 0.0)

func play_level_up() -> void:
	if not play_sfx("level_up", 0.0, 1.0, 0.0):
		if sound_level_up == null:
			sound_level_up = _synth_level_up()
		play_sound(sound_level_up, 1.0)

func play_success() -> void:
	if not play_sfx("craft_success", 0.0, 1.0, 0.0):
		if sound_refine_success == null:
			sound_refine_success = _synth_refine_success()
		play_sound(sound_refine_success, 1.0)

func play_fail() -> void:
	if not play_sfx("craft_fail", 0.0, 1.0, 0.0):
		if sound_refine_fail == null:
			sound_refine_fail = _synth_refine_fail()
		play_sound(sound_refine_fail, 0.0)

func play_refine_success() -> void:
	play_success()

func play_refine_fail() -> void:
	play_fail()

func play_gather() -> void:
	if not play_sfx("gather", 0.0, 1.0, 0.06):
		if sound_gather == null:
			sound_gather = _synth_gather()
		play_sound(sound_gather, 0.0)

func play_crit() -> void:
	play_sfx("hit_crit", 0.0, 1.0, 0.05)

func play_spell(slot: int) -> void:
	match slot:
		1:
			play_sfx("brisingr_cast", 0.0, 1.0, 0.04)
		2:
			play_sfx("jierda_cast", 0.0, 1.0, 0.03)
		3:
			play_sfx("vortex_cast", 0.0, 1.0, 0.02)

func play_no_mana() -> void:
	play_sfx("no_mana", 0.0, 1.0, 0.03)

func play_dash() -> void:
	play_sfx("dash", 0.0, 1.0, 0.06)

func play_jump() -> void:
	play_sfx("jump", 0.0, 1.0, 0.06)

func play_land(strength: float = 1.0) -> void:
	play_sfx("land", linear_to_db(clamp(strength, 0.3, 1.0)), 1.0, 0.08)

func play_step(surface: String = "grass", loudness_db: float = 0.0) -> void:
	play_sfx("step_" + surface, loudness_db, 1.0, 0.12)

func play_player_hurt() -> void:
	play_sfx("player_hurt", 0.0, 1.0, 0.05)

func play_potion() -> void:
	play_sfx("potion", 0.0, 1.0, 0.03)

func play_coin() -> void:
	play_sfx("coin", 0.0, 1.0, 0.06)

func play_loot_rare() -> void:
	play_sfx("loot_rare", 0.0, 1.0, 0.02)

func play_anvil() -> void:
	play_sfx("anvil", 0.0, 1.0, 0.05)

func play_ui(kind: String = "click") -> void:
	play_sfx("ui_" + kind, 0.0, 1.0, 0.03)

func play_portal_open() -> void:
	play_sfx("portal_open", 0.0, 1.0, 0.02)

func play_teleport() -> void:
	play_sfx("teleport", 0.0, 1.0, 0.0)

func play_dragon_roar() -> void:
	play_sfx("dragon_roar", 0.0, 1.0, 0.04)

func play_wing_flap(loudness_db: float = -4.0) -> void:
	play_sfx("wing_flap", loudness_db, 1.0, 0.08)

func play_boss_roar(pos: Vector3 = Vector3.ZERO) -> void:
	if pos != Vector3.ZERO:
		play_sfx_3d("boss_roar_intimidating", pos, 4.0, 85.0, 0.95)
	else:
		play_sfx("boss_roar_intimidating", 3.0, 0.95, 0.05)

func play_boss_slam(pos: Vector3 = Vector3.ZERO) -> void:
	if pos != Vector3.ZERO:
		play_sfx_3d("boss_slam_heavy", pos, 5.0, 85.0, 0.9)
	else:
		play_sfx("boss_slam_heavy", 4.0, 0.9, 0.05)

func play_npc_bark(npc_kind: String) -> void:
	match npc_kind:
		"blacksmith":
			play_sfx("npc_horst", 1.0, 1.0, 0.04)
		"herbalist":
			play_sfx("npc_angela", 1.0, 1.0, 0.04)
		"storyteller":
			play_sfx("npc_brom", 1.0, 1.0, 0.04)
		_:
			play_sfx("ui_click", 0.0, 1.0, 0.05)

func play_player_exert(level: int = 1) -> void:
	var sfx_name = "player_exert_1" if level == 1 else "player_exert_2"
	play_sfx(sfx_name, -2.0, 1.0, 0.06)

func play_player_victory() -> void:
	play_sfx("player_victory", 1.5, 1.0, 0.0)

## Sons de monstros no espaço 3D: "growl_*", "mob_attack", "mob_death", "boss_slam", "boss_roar", "hit_flesh"
func play_mob(sfx_name: String, pos: Vector3, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	play_sfx_3d(sfx_name, pos, volume_db, 35.0, pitch)

func _enter_tree() -> void:
	for p in _layers.values():
		if p is AudioStreamPlayer and p.is_inside_tree() and not p.playing:
			p.play()

# ------------------------------------------------------------------
# DIRETOR DE AMBIÊNCIA E MÚSICA
# ------------------------------------------------------------------
func _start_layers() -> void:
	for key in LAYERS.keys():
		var path: String = (LAYERS[key][0] as String) + key + ".ogg"
		if not ResourceLoader.exists(path):
			continue
		var stream = load(path)
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		var p := AudioStreamPlayer.new()
		p.name = "Layer_" + key
		p.stream = stream
		p.bus = LAYERS[key][1]
		p.volume_db = -80.0
		add_child(p)
		if p.is_inside_tree():
			p.play()
		_layers[key] = p
		_targets[key] = -80.0
	_set_zone_targets("sanctuary", false)

func _set_zone_targets(zone_id: String, boss_fight: bool) -> void:
	for k in _targets.keys():
		_targets[k] = -80.0
	match zone_id:
		"sanctuary":
			_targets["amb_sanctuary"] = 0.0
			_targets["amb_forest_night"] = -14.0
			_targets["music_sanctuary"] = -1.0
		"start":
			_targets["amb_forest_night"] = -2.0
			_targets["amb_sanctuary"] = -16.0
			_targets["music_sanctuary"] = -8.0
		"west":
			_targets["amb_wasteland"] = -1.0
			_targets["music_wilds"] = -3.0
		"south_east":
			_targets["amb_wasteland"] = -7.0
			_targets["amb_forest_night"] = -12.0
			_targets["music_wilds"] = -3.0
		_:
			_targets["amb_forest_night"] = -1.0
			_targets["music_wilds"] = -5.0
	if boss_fight:
		for k in ["music_sanctuary", "music_wilds"]:
			_targets[k] = -80.0
		_targets["music_boss"] = -1.0

func _process(delta: float) -> void:
	# Crossfade suave de todas as camadas
	for key in _layers.keys():
		var p: AudioStreamPlayer = _layers[key]
		var target: float = _targets.get(key, -80.0)
		p.volume_db = move_toward(p.volume_db, target, 22.0 * delta)
	_director_timer -= delta
	if _director_timer > 0.0:
		return
	_director_timer = 0.5
	_update_director()

func _update_director() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	if _player == null or not is_instance_valid(_player):
		_player = tree.get_first_node_in_group("player") as Node3D
		if _player == null:
			return
	if _map_builder == null or not is_instance_valid(_map_builder):
		_map_builder = tree.get_first_node_in_group("map_builder")
	var zone := "sanctuary"
	if _map_builder and _map_builder.has_method("zone_at"):
		zone = _map_builder.zone_at(Vector2(_player.global_position.x, _player.global_position.z))["id"]
	# Luta de chefe: algum chefe perseguindo/atacando a menos de 40 m
	var boss_fight := false
	for e in tree.get_nodes_in_group("enemies"):
		if e.get("behavior") == 2 and e.get("current_state") in [2, 3]:
			if e.global_position.distance_to(_player.global_position) < 40.0:
				boss_fight = true
				break
	var key := zone + ("_boss" if boss_fight else "")
	if key != _last_zone:
		_last_zone = key
		_set_zone_targets(zone, boss_fight)

# --- SÍNTESE PROCEDURAL DE ÁUDIO (PCM SINTETIZADOR) ---

func _synth_crystal_chime() -> AudioStreamWAV:
	# O lendário sino do MU Online (harmônicos puros de 2093Hz e 3136Hz)
	var sample_rate = 44100
	var duration = 1.6
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 3.8) # Decaimento exponencial suave
		var wave1 = sin(2.0 * PI * 2093.0 * t)
		var wave2 = sin(2.0 * PI * 3136.0 * t) * 0.65
		var wave3 = sin(2.0 * PI * 4186.0 * t) * 0.35
		var sample = (wave1 + wave2 + wave3) * env * 0.45

		var sample_int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		bytes[i * 2] = sample_int & 0xFF
		bytes[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	return stream

func _synth_slash() -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 0.22
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = sin(clamp(t / duration, 0.0, 1.0) * PI)
		var noise = randf_range(-1.0, 1.0)
		var tone = sin(2.0 * PI * (600.0 - t * 1800.0) * t) * 0.5
		var sample = (noise * 0.6 + tone) * env * 0.4

		var sample_int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		bytes[i * 2] = sample_int & 0xFF
		bytes[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = bytes
	return stream

func _synth_hit() -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 0.28
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 14.0)
		var bass = sin(2.0 * PI * (130.0 - t * 350.0) * t)
		var click = randf_range(-1.0, 1.0) * exp(-t * 40.0) * 0.7
		var sample = (bass + click) * env * 0.55

		var sample_int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		bytes[i * 2] = sample_int & 0xFF
		bytes[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = bytes
	return stream

func _synth_level_up() -> AudioStreamWAV:
	# Arpeggio celestial: Dó (523Hz) -> Mi (659Hz) -> Sol (784Hz) -> Si (987Hz) -> Dó Agudo (1046Hz)
	var sample_rate = 44100
	var duration = 1.4
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)

	var notes = [523.25, 659.25, 783.99, 987.77, 1046.50]
	var note_duration = 0.16

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var note_idx = int(t / note_duration)
		var sample: float = 0.0

		if note_idx < notes.size():
			var freq = notes[note_idx]
			var note_t = fmod(t, note_duration)
			var env = exp(-note_t * 6.0)
			sample = (sin(2.0 * PI * freq * t) + sin(2.0 * PI * freq * 2.0 * t) * 0.4) * env * 0.4
		else:
			# Sustentação final da última nota
			var sustain_t = t - (notes.size() * note_duration)
			var env = exp(-sustain_t * 2.5)
			sample = sin(2.0 * PI * 1046.50 * t) * env * 0.4

		var sample_int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		bytes[i * 2] = sample_int & 0xFF
		bytes[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = bytes
	return stream

func _synth_refine_success() -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 0.9
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 4.0)
		# Acorde de Dó Maior (Dó 523Hz + Sol 784Hz + Dó Alto 1046Hz)
		var c = sin(2.0 * PI * 523.25 * t)
		var g = sin(2.0 * PI * 783.99 * t) * 0.7
		var c_high = sin(2.0 * PI * 1046.50 * t) * 0.5
		var sample = (c + g + c_high) * env * 0.35

		var sample_int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		bytes[i * 2] = sample_int & 0xFF
		bytes[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = bytes
	return stream

func _synth_refine_fail() -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 0.55
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 7.0)
		# Trítono dissonante / quebra
		var n1 = sin(2.0 * PI * 300.0 * t)
		var n2 = sin(2.0 * PI * 424.0 * t) # Trítono
		var noise = randf_range(-0.5, 0.5) * exp(-t * 15.0)
		var sample = (n1 + n2 + noise) * env * 0.35

		var sample_int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		bytes[i * 2] = sample_int & 0xFF
		bytes[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = bytes
	return stream

func _synth_gather() -> AudioStreamWAV:
	var sample_rate = 44100
	var duration = 0.4
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = exp(-t * 8.0)
		var shimmer = sin(2.0 * PI * (1200.0 + t * 800.0) * t) * 0.5
		var sample = shimmer * env * 0.4

		var sample_int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		bytes[i * 2] = sample_int & 0xFF
		bytes[i * 2 + 1] = (sample_int >> 8) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = bytes
	return stream
