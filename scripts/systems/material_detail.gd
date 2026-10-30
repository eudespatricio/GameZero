extends RefCounted
class_name MaterialDetail
## Aplica detalhe de superfície procedural aos materiais das criaturas.
##
## Os modelos não têm UV (foram gerados por primitivas/remesh), então usamos
## mapeamento triplanar: a mesma textura tileável de ruído serve de grão para
## pelo, casca, pedra e tecido. O albedo é neutro (0.72–1.0) para multiplicar a
## cor base sem escurecer, e o normal map dá relevo sem custo de geometria.

const ALBEDO_PATH := "res://assets/textures/detail_albedo.png"
const NORMAL_PATH := "res://assets/textures/detail_normal.png"

static var _albedo: Texture2D
static var _normal: Texture2D
static var _loaded := false

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if ResourceLoader.exists(ALBEDO_PATH):
		_albedo = load(ALBEDO_PATH)
	if ResourceLoader.exists(NORMAL_PATH):
		_normal = load(NORMAL_PATH)

## Aplica o grão num material já duplicado (não mexe no recurso compartilhado).
## `scale` controla o tamanho da textura no mundo (maior = grão menor).
static func apply(mat: StandardMaterial3D, scale: float = 3.0, normal_scale: float = 0.9) -> void:
	if mat == null:
		return
	_ensure_loaded()
	if _albedo == null:
		return

	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(scale, scale, scale)
	mat.albedo_texture = _albedo

	if _normal:
		mat.normal_enabled = true
		mat.normal_texture = _normal
		mat.normal_scale = normal_scale

	# Superfícies orgânicas: um pouco mais fosco e sem brilho de plástico
	if mat.roughness < 0.55:
		mat.roughness = 0.65
	mat.metallic_specular = 0.35
