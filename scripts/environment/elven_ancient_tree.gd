extends StaticBody3D
class_name ElvenAncientTree

static var _shared_foliage_mat: ShaderMaterial
static var _shared_bark_mat: ShaderMaterial

func _enter_tree() -> void:
	_apply_tree_shaders()

func _ready() -> void:
	_apply_tree_shaders()

static func get_foliage_material() -> ShaderMaterial:
	if not _shared_foliage_mat:
		var sh = load("res://assets/shaders/tree_foliage.gdshader") as Shader
		if sh:
			_shared_foliage_mat = ShaderMaterial.new()
			_shared_foliage_mat.shader = sh
	return _shared_foliage_mat

static func get_bark_material() -> ShaderMaterial:
	if not _shared_bark_mat:
		var sh = load("res://assets/shaders/tree_bark.gdshader") as Shader
		if sh:
			_shared_bark_mat = ShaderMaterial.new()
			_shared_bark_mat.shader = sh
	return _shared_bark_mat

func _apply_tree_shaders() -> void:
	var f_mat = get_foliage_material()
	var b_mat = get_bark_material()
	
	var model = get_node_or_null("TreeModel")
	if not model:
		return
		
	for child in model.get_children():
		if child is MeshInstance3D:
			var cname = child.name.to_lower()
			if cname.contains("canopy") or cname.contains("foliage") or cname.contains("leaf"):
				if f_mat:
					child.material_override = f_mat
			elif cname.contains("trunk") or cname.contains("bark"):
				if b_mat:
					child.material_override = b_mat
