extends Node3D
## Scenery beyond the arena, shared by the game and the main menu: a distant forest (one MultiMesh),
## two rings of snowy mountains (the far ring bigger), a pixel moon, a few stars and a slow aurora.
## The world environment's depth fog (from 60 m) fades each layer toward the horizon colour, so they
## recede naturally. The game camera mostly looks down and only sees the near forest at the edges; the
## menu camera sees all of it. Decoration only: no collision, fixed seed.

const PINE: PackedScene = preload("res://scenes/props/pine_model.tscn")
const MOUNTAIN: PackedScene = preload("res://scenes/world/mountain_model.tscn")
const AURORA: Shader = preload("res://assets/materials/aurora.gdshader")

@export var forest_inner: float = 74.0
@export var forest_outer: float = 135.0
@export var forest_count: int = 450
## Per mountain ring: (radius min, radius max, count, scale min); scale max is scale min x 1.6.
@export var mountain_rings: Array[Vector4] = [Vector4(190, 230, 30, 2.0), Vector4(290, 340, 24, 3.4)]
@export var moon_position: Vector3 = Vector3(140.0, 110.0, -400.0)
@export var aurora_position: Vector3 = Vector3(-40.0, 120.0, -470.0)
@export var seed_value: int = 1225


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var trees: Array[Transform3D] = []
	while trees.size() < forest_count:
		var pos := Vector3(rng.randf_range(-forest_outer, forest_outer), 0.0, rng.randf_range(-forest_outer, forest_outer))
		if maxf(absf(pos.x), absf(pos.z)) < forest_inner:
			continue
		trees.append(_transform(rng, pos, 1.3, 2.4))
	_multimesh(PINE, trees)
	var peaks: Array[Transform3D] = []
	for ring in mountain_rings:
		for i in int(ring.z):
			var angle: float = TAU * i / ring.z + rng.randf_range(-0.08, 0.08)
			var r: float = rng.randf_range(ring.x, ring.y)
			var pos := Vector3(cos(angle) * r, -2.0, sin(angle) * r)
			peaks.append(_transform(rng, pos, ring.w, ring.w * 1.6))
	_multimesh(MOUNTAIN, peaks)
	_add_moon()
	_add_stars(rng)
	_add_aurora()


func _transform(rng: RandomNumberGenerator, pos: Vector3, min_scale: float, max_scale: float) -> Transform3D:
	var s: float = rng.randf_range(min_scale, max_scale)
	return Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.85, 1.2), s)), pos)


func _multimesh(scene: PackedScene, transforms: Array[Transform3D]) -> void:
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


## A flat, unshaded billboard disc with a hard pixel edge (no smooth gradients, per ART_DIRECTION).
func _disc(size: float, colors: PackedColorArray, offsets: PackedFloat32Array) -> MeshInstance3D:
	var gradient := Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	gradient.offsets = offsets
	gradient.colors = colors
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 32
	texture.height = 32
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.disable_fog = true
	material.albedo_texture = texture
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var node := MeshInstance3D.new()
	node.mesh = quad
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


func _add_moon() -> void:
	var moon: MeshInstance3D = _disc(46.0,
		PackedColorArray([Color("F4F8FF"), Color("C9DAF0"), Color(0.788, 0.855, 0.941, 0.25), Color(0, 0, 0, 0)]),
		PackedFloat32Array([0.0, 0.55, 0.7, 0.85]))
	moon.position = moon_position
	add_child(moon)


func _add_stars(rng: RandomNumberGenerator) -> void:
	var star: MeshInstance3D = _disc(1.6, PackedColorArray([Color("F4F8FF"), Color(0, 0, 0, 0)]), PackedFloat32Array([0.0, 0.5]))
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = star.mesh
	multimesh.instance_count = 70
	for k in 70:
		var angle: float = rng.randf() * TAU
		var pos := Vector3(cos(angle) * 420.0, rng.randf_range(90.0, 260.0), sin(angle) * 420.0)
		multimesh.set_instance_transform(k, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * rng.randf_range(0.7, 1.6)), pos))
	var stars := MultiMeshInstance3D.new()
	stars.multimesh = multimesh
	stars.material_override = star.material_override
	stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(stars)
	star.free()


func _add_aurora() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(760.0, 120.0)
	var material := ShaderMaterial.new()
	material.shader = AURORA
	var aurora := MeshInstance3D.new()
	aurora.mesh = quad
	aurora.material_override = material
	aurora.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	aurora.position = aurora_position
	add_child(aurora)
