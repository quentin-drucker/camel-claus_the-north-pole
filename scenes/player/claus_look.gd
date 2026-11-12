class_name ClausLook
extends Node3D
## Claus's model, dressed from the Profile: the body (recolored by the skin) + a hat + an outfit, each a
## separate piece modelled around the same head/neck/torso so nothing needs offsets. Used by the player
## (in game) and the main menu (where it is the live Customize preview). Hops, squash and hit-blinks
## act on this node, so every piece follows. Redresses whenever the saved look changes.

const BODY: PackedScene = preload("res://scenes/player/cosmetics/claus_body_model.tscn")
const SWAP: Shader = preload("res://assets/materials/palette_swap.gdshader")

var _pieces: Array[Node3D] = []
var _worn: String = ""


func _ready() -> void:
	dress()
	Profile.changed.connect(dress)


## Rebuild the pieces if the look changed (Profile saves for many reasons; most don't touch the look).
func dress() -> void:
	var look: String = str(Profile.data["look"])
	if look == _worn:
		return
	_worn = look
	for piece in _pieces:
		piece.queue_free()
	_pieces.clear()
	_add(BODY, Profile.equipped(CosmeticData.Slot.SKIN), "")
	for slot: CosmeticData.Slot in [CosmeticData.Slot.HAT, CosmeticData.Slot.OUTFIT]:
		var item: CosmeticData = Profile.equipped(slot)
		if item and item.model:
			_add(item.model, item, Profile.equipped_color(slot))


func _add(scene: PackedScene, item: CosmeticData, color: String) -> void:
	var piece: Node3D = scene.instantiate()
	add_child(piece)
	_pieces.append(piece)
	var targets: PackedColorArray = item.swap_targets(color) if item else PackedColorArray()
	if targets.is_empty():
		return  # its baked colors as they are
	var from: PackedColorArray = item.swap_from.slice(0, targets.size())
	while from.size() < 4:
		from.append(Color.BLACK)
		targets.append(Color.BLACK)
	for mesh: MeshInstance3D in piece.find_children("*", "MeshInstance3D", true, false):
		var material := ShaderMaterial.new()
		material.shader = SWAP
		material.set_shader_parameter(&"albedo_tex", mesh.mesh.surface_get_material(0).albedo_texture)
		material.set_shader_parameter(&"from_colors", from)
		material.set_shader_parameter(&"to_colors", targets)
		material.set_shader_parameter(&"swap_count", mini(item.swap_from.size(), 4))
		mesh.material_override = material
