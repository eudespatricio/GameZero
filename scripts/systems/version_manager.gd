extends Node
## Gerenciador de Versão e Handshake do GameZero.
## Lê res://version.json e valida compatibilidade com o servidor/CDN.
## Dispara o modal de Notas da Versão quando detecta atualização recente.

signal version_checked(success: bool, is_compatible: bool, message: String)
signal patch_notes_available(notes: Dictionary)

const VERSION_FILE_PATH := "res://version.json"
const STATE_FILE_PATH := "user://version_state.json"

var local_version: String = "0.5.0"
var build_number: int = 142
var min_required_version: String = "0.5.0"
var download_url: String = ""
var patch_notes_data: Dictionary = {}
var is_outdated: bool = false
var has_new_update_notes: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_local_manifest()
	check_state()

func load_local_manifest() -> void:
	if FileAccess.file_exists(VERSION_FILE_PATH):
		var file = FileAccess.open(VERSION_FILE_PATH, FileAccess.READ)
		if not file:
			return
		var text = file.get_as_text()
		file.close()
		var json = JSON.parse_string(text)
		if json is Dictionary:
			local_version = json.get("client_version", "0.5.0")
			build_number = json.get("build_number", 1)
			min_required_version = json.get("min_required_version", local_version)
			download_url = json.get("download_url", "")
			patch_notes_data = json.get("patch_notes", {})

func check_state() -> void:
	var last_seen := ""
	if FileAccess.file_exists(STATE_FILE_PATH):
		var f = FileAccess.open(STATE_FILE_PATH, FileAccess.READ)
		var parsed = {}
		if f:
			parsed = JSON.parse_string(f.get_as_text())
			f.close()
		if parsed is Dictionary:
			last_seen = parsed.get("last_seen_version", "")
	
	if last_seen != local_version:
		has_new_update_notes = true

func mark_patch_notes_seen() -> void:
	has_new_update_notes = false
	var dir = DirAccess.open("user://")
	if dir:
		var f = FileAccess.open(STATE_FILE_PATH, FileAccess.WRITE)
		if f:
			var data = {"last_seen_version": local_version, "timestamp": Time.get_datetime_string_from_system()}
			f.store_string(JSON.stringify(data, "\t"))
			f.close()

## Compara duas versões SemVer (ex.: "0.5.0" vs "0.4.9")
## Retorna 1 se v1 > v2, -1 se v1 < v2, 0 se iguais
func compare_semver(v1: String, v2: String) -> int:
	var p1 = v1.replace("v", "").split(".")
	var p2 = v2.replace("v", "").split(".")
	for i in range(maxi(p1.size(), p2.size())):
		var n1 = int(p1[i]) if i < p1.size() else 0
		var n2 = int(p2[i]) if i < p2.size() else 0
		if n1 > n2: return 1
		elif n1 < n2: return -1
	return 0

## Valida se a versão do cliente é compatível com o requisito mínimo do servidor
func validate_server_version(server_version_data: Dictionary) -> bool:
	var req_min: String = server_version_data.get("min_required_version", local_version)
	# Se a nossa versão for menor que a versão mínima exigida, bloqueia o cliente
	if compare_semver(local_version, req_min) < 0:
		is_outdated = true
		version_checked.emit(true, false, "Cliente desatualizado! Versão mínima exigida: v%s (Atual: v%s)" % [req_min, local_version])
		return false
	
	is_outdated = false
	var remote_notes: Dictionary = server_version_data.get("patch_notes", patch_notes_data)
	if not remote_notes.is_empty():
		patch_notes_data = remote_notes
		
	version_checked.emit(true, true, "Versão compatível (v%s)" % local_version)
	return true
