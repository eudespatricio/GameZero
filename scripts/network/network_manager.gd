extends Node
## Gerenciador de Rede e Cliente API do GameZero.
##
## Comunica com o Backend REST (FastAPI/Python) para Autenticação,
## Personagens e Sincronização. Suporta modo híbrido (Offline Local de contingência).
##
## Todas as requisições passam por uma fila serial: um único `HTTPRequest`
## compartilhado quebrava quando o autosave coincidia com outra chamada
## ("HTTPRequest is already in use").

signal auth_state_changed(is_logged_in: bool, username: String)
signal characters_updated(character_list: Array)
signal sync_completed(success: bool, message: String)
signal server_status_changed(is_online: bool)

const DEFAULT_SERVER_URL := "http://127.0.0.1:8088"
const REQUEST_TIMEOUT := 6.0
const MAX_ATTEMPTS := 2

var server_url: String = DEFAULT_SERVER_URL
var auth_token: String = ""
var current_username: String = ""
var current_account_id: String = ""
var active_character: Dictionary = {}
var is_server_reachable: bool = false

var _queue: Array[Dictionary] = []
var _processing: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _set_reachable(value: bool) -> void:
	if is_server_reachable != value:
		is_server_reachable = value
		server_status_changed.emit(value)

# ------------------------------------------------------------------
# FILA DE REQUISIÇÕES
# ------------------------------------------------------------------
## Enfileira uma requisição e aguarda a resposta (serial, thread-safe na prática
## porque só existe uma corrotina consumindo a fila por vez).
func _request(endpoint: String, method: int = HTTPClient.METHOD_GET, body_dict: Dictionary = {}) -> Dictionary:
	# Sincronizações do mesmo personagem são coalescidas: mantém só o payload mais novo.
	if method == HTTPClient.METHOD_POST and endpoint.ends_with("/save"):
		for entry in _queue:
			if entry["endpoint"] == endpoint:
				entry["body"] = body_dict
				return {"success": true, "queued": true}
			
	
	_queue.append({"endpoint": endpoint, "method": method, "body": body_dict, "result": {}})
	var entry: Dictionary = _queue.back()

	if not _processing:
		_process_queue()

	# Aguarda o processamento da fila marcar este item.
	while not entry.has("done"):
		if not is_inside_tree():
			return {"success": false, "error": "Árvore de cena indisponível."}
		await get_tree().process_frame

	return entry.get("result", {"success": false, "error": "Resposta vazia."})

func _process_queue() -> void:
	_processing = true
	while not _queue.is_empty():
		var entry: Dictionary = _queue.pop_front()
		entry["result"] = await _execute(entry["endpoint"], entry["method"], entry["body"])
		entry["done"] = true
	_processing = false

func _execute(endpoint: String, method: int, body_dict: Dictionary) -> Dictionary:
	var last_error := {"success": false, "error": "Servidor offline ou inalcançável."}
	for attempt in MAX_ATTEMPTS:
		var res := await _do_http(endpoint, method, body_dict, attempt > 0)
		if res.get("_transport_ok", false):
			res.erase("_transport_ok")
			return res
		last_error = res
		if res.get("error_code", 0) != 0:
			# Erro de transporte (rede): vale tentar de novo; erro HTTP não.
			await get_tree().create_timer(0.35).timeout
	return last_error

func _do_http(endpoint: String, method: int, body_dict: Dictionary, is_retry: bool) -> Dictionary:
	if not is_inside_tree():
		return {"success": false, "error": "Árvore de cena indisponível."}

	var http := HTTPRequest.new()
	http.timeout = REQUEST_TIMEOUT
	add_child(http)

	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json"
	])
	if not auth_token.is_empty():
		headers.append("Authorization: Bearer " + auth_token)

	var payload_str := JSON.stringify(body_dict) if not body_dict.is_empty() else ""
	var err := http.request(server_url + endpoint, headers, method, payload_str)
	if err != OK:
		http.queue_free()
		_set_reachable(false)
		return {"success": false, "error": "Falha ao iniciar requisição (código %d)." % err, "error_code": err}

	var response: Array = await http.request_completed
	http.queue_free()

	var result: int = response[0]
	var code: int = response[1]
	var raw: PackedByteArray = response[3]

	if result != HTTPRequest.RESULT_SUCCESS:
		_set_reachable(false)
		return {"success": false, "error": "Servidor offline ou inalcançável.", "error_code": result}

	_set_reachable(true)
	var parsed = JSON.parse_string(raw.get_string_from_utf8())
	if parsed is Dictionary:
		if not parsed.has("success"):
			parsed["success"] = code >= 200 and code < 300
		parsed["_transport_ok"] = true
		return parsed

	return {"success": code >= 200 and code < 300, "_transport_ok": true}

# ------------------------------------------------------------------
# SERVIÇOS DA API
# ------------------------------------------------------------------

## Verifica se o servidor está online e retorna a versão e patch notes
func check_server_version() -> Dictionary:
	var res = await _request("/api/v1/version", HTTPClient.METHOD_GET)
	if res.get("success", false) and res.has("data"):
		var ver_mgr = get_node_or_null("/root/VersionManager")
		if ver_mgr:
			ver_mgr.validate_server_version(res["data"])
		return res["data"]
	return {}

## Cria uma nova conta
func register_account(username: String, password: String) -> Dictionary:
	var res = await _request("/api/v1/auth/register", HTTPClient.METHOD_POST, {
		"username": username,
		"password": password
	})
	if res.get("success", false) and res.has("session"):
		_apply_session(res["session"])
	return res

## Realiza login e armazena o token de sessão
func login_account(username: String, password: String) -> Dictionary:
	var res = await _request("/api/v1/auth/login", HTTPClient.METHOD_POST, {
		"username": username,
		"password": password
	})
	if res.get("success", false) and res.has("session"):
		_apply_session(res["session"])
	return res

func logout() -> void:
	auth_token = ""
	current_username = ""
	current_account_id = ""
	active_character = {}
	auth_state_changed.emit(false, "")

func _apply_session(session: Dictionary) -> void:
	auth_token = session.get("token", "")
	current_account_id = session.get("account_id", "")
	current_username = session.get("username", "")
	auth_state_changed.emit(true, current_username)

## Busca a lista de personagens da conta (até 4 slots)
func fetch_characters() -> Array:
	if auth_token.is_empty():
		return []
	var res = await _request("/api/v1/characters", HTTPClient.METHOD_GET)
	if res.get("success", false) and res.has("characters"):
		var list: Array = res["characters"]
		characters_updated.emit(list)
		return list
	return []

## Cria um novo personagem num slot livre
func create_character(name: String, class_id: String) -> Dictionary:
	return await _request("/api/v1/characters", HTTPClient.METHOD_POST, {
		"name": name,
		"class_id": class_id
	})

## Deleta um personagem
func delete_character(char_id: String) -> Dictionary:
	return await _request("/api/v1/characters/" + char_id, HTTPClient.METHOD_DELETE)

## Carrega a folha completa do personagem selecionado (stats, gear, bag, missões)
func load_character_full(char_id: String) -> Dictionary:
	var res = await _request("/api/v1/characters/" + char_id, HTTPClient.METHOD_GET)
	if res.get("success", false) and res.has("character"):
		active_character = res["character"]
		return active_character
	return {}

## Sincroniza o progresso atual com o servidor
func sync_character_full(char_id: String, payload: Dictionary) -> Dictionary:
	var res = await _request("/api/v1/characters/" + char_id + "/save", HTTPClient.METHOD_POST, payload)
	if res.get("queued", false):
		return res
	var ok: bool = res.get("success", false)
	sync_completed.emit(ok, res.get("message", res.get("error", "")))
	return res
