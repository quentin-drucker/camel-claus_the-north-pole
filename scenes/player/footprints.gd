class_name Footprints
extends MultiMeshInstance3D
## Claus's hoofprints in the snow. One pooled MultiMesh (`max_prints` flat quads = one draw call, no
## new nodes): every `stride` metres walked a print is placed, alternating left/right of his path and
## turned to his heading; each fades out over `fade_time`, then its slot is reused. Pale snow-shadow
## blue, lighter than anything you play with, so it never competes with enemies, XP or attacks.
## Every `puff_every` prints a tiny snow puff kicks up at his hooves.

@export var max_prints: int = 64
@export var stride: float = 0.42
@export var fade_time: float = 4.0
@export var side_offset: float = 0.13
@export var puff_every: int = 5
@export var print_color: Color = Color(0.561, 0.663, 0.82, 0.55)

var _ages: PackedFloat32Array = PackedFloat32Array()
var _next: int = 0
var _walked: float = 0.0
var _last: Vector3
var _left: bool = true
var _count: int = 0


func _ready() -> void:
	top_level = true  # prints stay where they were made, not glued to Claus
	global_transform = Transform3D.IDENTITY
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var quad := PlaneMesh.new()
	quad.size = Vector2(0.15, 0.2)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	quad.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = quad
	multimesh.instance_count = max_prints
	_ages.resize(max_prints)
	for i in max_prints:
		_ages[i] = fade_time
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO), Vector3.ZERO))
		multimesh.set_instance_color(i, Color(print_color, 0.0))
	_last = get_parent().global_position


func _process(delta: float) -> void:
	var pos: Vector3 = get_parent().global_position
	var step: Vector3 = pos - _last
	step.y = 0.0
	_last = pos
	var moved: float = step.length()
	_walked += moved
	if _walked >= stride and moved > 0.0001:
		_walked = 0.0
		_place(pos, step / moved)
	for i in max_prints:  # fade (64 slots: trivial)
		if _ages[i] < fade_time:
			_ages[i] += delta
			multimesh.set_instance_color(i, Color(print_color, print_color.a * (1.0 - minf(_ages[i] / fade_time, 1.0))))


func _place(pos: Vector3, heading: Vector3) -> void:
	var right := Vector3(-heading.z, 0.0, heading.x)
	var spot: Vector3 = pos + right * (side_offset if _left else -side_offset)
	_left = not _left
	spot.y = 0.025  # just above the snow, under the blob shadow
	multimesh.set_instance_transform(_next, Transform3D(Basis(Vector3.UP, atan2(-heading.x, -heading.z)), spot))
	_ages[_next] = 0.0
	multimesh.set_instance_color(_next, print_color)
	_next = (_next + 1) % max_prints
	_count += 1
	if _count % puff_every == 0:
		Poof.spawn(spot + Vector3.DOWN * 0.35, Color("F4F8FF"), 3, 1.0)
