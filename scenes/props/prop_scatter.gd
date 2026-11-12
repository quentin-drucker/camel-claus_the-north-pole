extends Node3D
## Builds the arena's decoration (used by the game and the main-menu diorama): one MultiMeshInstance3D
## (one draw call) per prop type, a fixed seed so the map is the same every run, no collision.
## - Field props scattered inside the arena (pines, drifts, gift piles, candy-cane posts, pennants).
## - The **boundary ridge** right on the invisible wall (59 m): a continuous line of overlapping
##   snowbanks (random size/turn so it never looks tiled), rocks, then 3 jittered rows of pines that get
##   taller outward. Claus's clamp and the enemies' spawn ring sit inside it, so what blocks you is what
##   you see.
## - Life: each prop type gets the prop_sway shader (sway grows toward the top, phase from position, so
##   nothing moves in sync; gift-pile gold twinkles), and pines shed a little snow — now and then near
##   Claus, and whenever he brushes past one.

const SWAY: Shader = preload("res://assets/materials/prop_sway.gdshader")
const PINE: int = 0
const DRIFT: int = 1

@export var props: Array[PackedScene] = [
	preload("res://scenes/props/pine_model.tscn"),
	preload("res://scenes/props/drift_model.tscn"),
	preload("res://scenes/props/gift_pile_model.tscn"),
	preload("res://scenes/props/cane_post_model.tscn"),
	preload("res://scenes/props/pennant_model.tscn"),
	preload("res://scenes/props/rock_model.tscn"),
]
@export var counts: Array[int] = [80, 90, 20, 22, 14, 10]
## Per prop type: sway in metres at `heights`, and gold twinkle (0..1).
@export var sways: Array[float] = [0.1, 0.0, 0.0, 0.04, 0.14, 0.0]
@export var heights: Array[float] = [3.2, 1.0, 1.0, 1.6, 2.2, 1.0]
@export var twinkles: Array[float] = [0.0, 0.0, 0.9, 0.0, 0.0, 0.0]
@export var arena_half_size: float = 57.0
## No props this close to the start, so the opening seconds read cleanly.
@export var clear_radius: float = 8.0
@export var seed_value: int = 2026

@export_group("Boundary ridge")
## Where the snowbanks sit (Claus is clamped at 59).
@export var bank_distance: float = 61.0  # the banks' foot meets the wall at 59
@export var bank_spacing: float = 2.2
## Pine rows behind the banks: distance and spacing per row.
@export var tree_rows: Array[float] = [64.0, 67.5, 71.5]
@export var tree_spacing: Array[float] = [2.6, 3.0, 3.4]
@export var rock_spacing: float = 9.0

@export_group("Snow shedding")
## A random pine within this distance of Claus sheds now and then.
@export var shed_range: float = 14.0
@export var shed_interval: Vector2 = Vector2(1.0, 2.6)
## Walking this close to a pine shakes snow off it.
@export var brush_distance: float = 1.6

var _pines: Array[Transform3D] = []
var _shed_left: float = 1.0
var _brushed: Dictionary = {}  # pine index -> time it last shed from a brush
var _time: float = 0.0
var _rng := RandomNumberGenerator.new()


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
			transforms.append(_random_transform(rng, pos, 0.8, 1.3))
		match i:
			PINE:
				for r in tree_rows.size():
					transforms.append_array(_ring(rng, tree_rows[r], tree_spacing[r], 1.0, 1.0 + 0.25 * r, 1.4 + 0.3 * r))
				_pines = transforms
			DRIFT:
				transforms.append_array(_ring(rng, bank_distance, bank_spacing, 0.4, 2.4, 3.4, 0.65))
			5:  # rocks
				transforms.append_array(_ring(rng, bank_distance + 1.6, rock_spacing, 2.0, 1.1, 2.0))
		_add_multimesh(i, transforms)
	_rng.randomize()


func _random_transform(rng: RandomNumberGenerator, pos: Vector3, min_scale: float, max_scale: float,
		flatten: float = 1.0) -> Transform3D:
	var s: float = rng.randf_range(min_scale, max_scale)
	var turn := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * flatten, s))
	return Transform3D(turn, pos)


## Props along the square at `distance` from the centre, every `spacing` m, jittered by `jitter`.
func _ring(rng: RandomNumberGenerator, distance: float, spacing: float, jitter: float, min_scale: float,
		max_scale: float, flatten: float = 1.0) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	var steps: int = int(distance * 2.0 / spacing)
	for side in 4:
		for k in steps:
			var along: float = -distance + k * spacing + rng.randf_range(-jitter, jitter)
			var off: float = distance + rng.randf_range(-jitter, jitter)
			var pos: Vector3 = [Vector3(along, 0, -off), Vector3(off, 0, along),
				Vector3(-along, 0, off), Vector3(-off, 0, -along)][side]
			out.append(_random_transform(rng, pos, min_scale, max_scale, flatten))
	return out


func _add_multimesh(index: int, transforms: Array[Transform3D]) -> void:
	var source: Node = props[index].instantiate()
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
	if sways[index] > 0.0 or twinkles[index] > 0.0:
		var material := ShaderMaterial.new()
		material.shader = SWAY
		material.set_shader_parameter(&"albedo_tex", mesh_node.mesh.surface_get_material(0).albedo_texture)
		material.set_shader_parameter(&"sway", sways[index])
		material.set_shader_parameter(&"height", heights[index])
		material.set_shader_parameter(&"twinkle", twinkles[index])
		instance.material_override = material
	add_child(instance)
	source.free()


func _process(delta: float) -> void:
	_time += delta
	var claus: Vector3 = GameState.player.global_position if is_instance_valid(GameState.player) else Vector3.ZERO
	_shed_left -= delta
	if _shed_left <= 0.0:
		_shed_left = _rng.randf_range(shed_interval.x, shed_interval.y)
		for attempt in 6:  # a random pine near Claus (a few tries; most pines are far away)
			var pine: Transform3D = _pines[_rng.randi() % _pines.size()]
			if pine.origin.distance_to(claus) < shed_range:
				_shed(pine)
				break
	if Engine.get_process_frames() % 6 == 0:  # brushing past a pine shakes snow off it
		for i in _pines.size():
			var pine: Transform3D = _pines[i]
			if absf(pine.origin.x - claus.x) < brush_distance and absf(pine.origin.z - claus.z) < brush_distance \
					and _time - _brushed.get(i, -99.0) > 3.0:
				_brushed[i] = _time
				_shed(pine, 8)


func _shed(pine: Transform3D, amount: int = 5) -> void:
	var top: Vector3 = pine.origin + Vector3.UP * 2.4 * pine.basis.get_scale().y
	Poof.spawn(top, Color("F4F8FF"), amount, 1.6)
