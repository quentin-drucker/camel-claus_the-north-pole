extends Node3D
## Scatters decorative props over the arena: one MultiMeshInstance3D (one draw call) per prop type.
## Decoration only: no collision. A fixed seed keeps the map the same every run.
## The first prop (pines) also rings the arena edge so the invisible walls read as a tree line.

@export var props: Array[PackedScene] = [
	preload("res://scenes/props/pine_model.tscn"),
	preload("res://scenes/props/drift_model.tscn"),
	preload("res://scenes/props/gift_pile_model.tscn"),
	preload("res://scenes/props/cane_post_model.tscn"),
	preload("res://scenes/props/pennant_model.tscn"),
]
@export var counts: Array[int] = [80, 90, 20, 22, 14]
@export var arena_half_size: float = 57.0
## No props this close to the start, so the opening seconds read cleanly.
@export var clear_radius: float = 8.0
## Distance from the centre to the edge tree line, and spacing between those trees.
@export var border_distance: float = 61.5
@export var border_spacing: float = 3.0
@export var seed_value: int = 2026


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in props.size():
		var transforms: Array[Transform3D] = []
		for j in counts[i]:
			var pos := Vector3.ZERO
			while pos.length() < clear_radius:
				pos = Vector3(rng.randf_range(-arena_half_size, arena_half_size), 0.0,
					rng.randf_range(-arena_half_size, arena_half_size))
			transforms.append(_random_transform(rng, pos))
		if i == 0:
			transforms.append_array(_border(rng))
		_add_multimesh(props[i], transforms)


func _random_transform(rng: RandomNumberGenerator, pos: Vector3) -> Transform3D:
	var turn := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.8, 1.3))
	return Transform3D(turn, pos)


func _border(rng: RandomNumberGenerator) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	var steps: int = int(border_distance * 2.0 / border_spacing)
	for side in 4:
		for k in steps:
			var along: float = -border_distance + k * border_spacing + rng.randf_range(-0.6, 0.6)
			var off: float = border_distance + rng.randf_range(-0.8, 0.8)
			var pos: Vector3 = [Vector3(along, 0, -off), Vector3(off, 0, along),
				Vector3(-along, 0, off), Vector3(-off, 0, -along)][side]
			out.append(_random_transform(rng, pos))
	return out


func _add_multimesh(scene: PackedScene, transforms: Array[Transform3D]) -> void:
	var source: Node = scene.instantiate()
	var mesh_node: MeshInstance3D = source.find_children("*", "MeshInstance3D", true, false)[0]
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh_node.mesh
	multimesh.instance_count = transforms.size()
	for k in transforms.size():
		multimesh.set_instance_transform(k, transforms[k])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	source.free()
