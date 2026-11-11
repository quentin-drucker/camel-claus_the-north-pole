class_name Poof
extends CPUParticles3D
## One-shot puff of little snow cubes (enemy deaths, chest opening), then frees itself.

static var _cube: BoxMesh


static func spawn(pos: Vector3, tint: Color = Color("F4F8FF"), count: int = 8, speed: float = 3.0) -> void:
	var poof := Poof.new()
	poof.amount = count
	poof.color = tint
	poof.initial_velocity_min = speed * 0.6
	poof.initial_velocity_max = speed
	(Engine.get_main_loop() as SceneTree).current_scene.add_child(poof)
	poof.global_position = pos + Vector3.UP * 0.4


func _init() -> void:
	if _cube == null:
		_cube = BoxMesh.new()
		_cube.size = Vector3.ONE * 0.13
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.vertex_color_use_as_albedo = true
		_cube.material = material
	mesh = _cube
	one_shot = true
	explosiveness = 1.0
	lifetime = 0.45
	direction = Vector3.UP
	spread = 75.0
	gravity = Vector3(0, -12, 0)
	scale_amount_min = 0.5
	scale_amount_max = 1.0
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	emitting = true
	finished.connect(queue_free)
