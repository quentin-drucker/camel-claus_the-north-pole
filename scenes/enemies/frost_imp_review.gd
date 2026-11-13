extends Node3D
## Standalone asset review. Does not spawn gameplay enemies or change the player's save.
## F6 this scene. Space toggles the 100-instance view; S saves a screenshot.

const MODEL_PATH: String = "res://assets/models/chaser.glb"
const OUTPUT: String = "res://art_src/frost_imp_v2/"
@export var capture_sequence: bool = false
var _canvas: Control
var _crowd: bool = false
var _frames: int = 0
var _views: Array[SubViewport] = []
var _snapshot_mode: bool = false
var _waddle_material: ShaderMaterial


func _ready() -> void:
	capture_sequence = capture_sequence or OS.get_environment("FROST_IMP_CAPTURE") == "1"
	_snapshot_mode = capture_sequence or "--asset-capture" in OS.get_cmdline_user_args()
	build_review()


func label_at(text: String, pos: Vector2, font_size: int, color: Color = Color("C9DAF0")) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	_canvas.add_child(label)


func build_review() -> void:
	if is_instance_valid(_canvas):
		_canvas.queue_free()
	_views.clear()
	_canvas = Control.new()
	add_child(_canvas)
	var bg := ColorRect.new()
	bg.color = Color("172239")
	bg.size = Vector2(1280, 720)
	_canvas.add_child(bg)
	label_at("FROST IMP / BAKED ASSET", Vector2(24, 15), 27)
	label_at("3,450 triangles  /  1 mesh + 1 material  /  512 x 512 albedo  /  no rig", Vector2(24, 53), 17)
	if _crowd:
		make_view(Vector2(24, 112), Vector2i(1232, 530), 2)
		label_at("100 instances / 345,000 model triangles / existing waddle shader", Vector2(24, 82), 18)
	else:
		label_at("FRONT", Vector2(24, 92), 18)
		label_at("55 DEGREE GAME VIEW", Vector2(430, 92), 18)
		label_at("SMALL-SCALE READ", Vector2(836, 92), 18)
		make_view(Vector2(24, 123), Vector2i(390, 480), 0)
		make_view(Vector2(430, 123), Vector2i(390, 480), 1)
		make_view(Vector2(836, 123), Vector2i(420, 480), 3)
		label_at("Imported GLB / matte baked color", Vector2(24, 616), 16)
		label_at("Game lighting + waddle shader", Vector2(430, 616), 16)
		label_at("40 / 50 / 60 px target heights", Vector2(836, 616), 16)
	label_at("SPACE: 100-instance view    S: save image    ESC: close", Vector2(24, 672), 17)
	_frames = 0


func make_view(pos: Vector2, dimensions: Vector2i, kind: int) -> void:
	var container := SubViewportContainer.new()
	container.position = pos
	container.size = Vector2(dimensions)
	_canvas.add_child(container)
	var view := SubViewport.new()
	view.size = dimensions
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.msaa_3d = Viewport.MSAA_4X
	container.add_child(view)
	_views.append(view)
	var world := Node3D.new()
	view.add_child(world)
	var env_node := WorldEnvironment.new()
	var env: Environment = load("res://assets/materials/world_environment.tres").duplicate()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("CCD9EA")
	env.fog_enabled = false
	env_node.environment = env
	world.add_child(env_node)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -30, 0)
	light.light_energy = 0.9
	light.shadow_enabled = false
	world.add_child(light)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(100, 100)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color("C9DAF0")
	floor_mat.roughness = 1.0
	floor_mat.metallic_specular = 0.0
	floor_mesh.material_override = floor_mat
	world.add_child(floor_mesh)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 0.92
	if kind == 0:
		camera.position = Vector3(0, .36, -3)
		camera.look_at(Vector3(0, .36, 0))
	else:
		camera.position = Vector3(0, .32 + 3.0 * tan(deg_to_rad(55.0)), -3)
		camera.look_at(Vector3(0, .32, 0))
	var packed: PackedScene = load(MODEL_PATH)
	if kind == 2:
		camera.size = 9.6
		camera.position = Vector3(0, 14.28, -10)
		camera.look_at(Vector3.ZERO)
		for i in 100:
			var x: float = (float(i % 10) - 4.5) * .83
			var z: float = (float(i / 10) - 4.5) * .85
			add_imp(world, packed, Vector3(x, 0, z), 1.0, float(i % 5 - 2) * .17, true)
	elif kind == 3:
		camera.size = 5.6
		for i in 3:
			add_imp(world, packed, Vector3(float(1-i)*1.55, 0, 0), .82 + float(i)*.205, 0, true)
	else:
		add_imp(world, packed, Vector3.ZERO, 1, 0 if kind == 0 else -.32, kind != 0)


func add_imp(world: Node3D, packed: PackedScene, pos: Vector3, amount: float, angle: float, waddle: bool) -> void:
	var imp: Node3D = packed.instantiate()
	world.add_child(imp)
	imp.position = pos
	imp.scale = Vector3.ONE * amount
	imp.rotation.y = angle
	var mesh: MeshInstance3D = imp.find_children("*", "MeshInstance3D", true, false)[0]
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if waddle:
		if _waddle_material == null:
			_waddle_material = ShaderMaterial.new()
			_waddle_material.shader = load("res://assets/materials/enemy_waddle.gdshader")
			_waddle_material.set_shader_parameter("albedo_tex", mesh.mesh.surface_get_material(0).albedo_texture)
			_waddle_material.set_shader_parameter("waddle", 0.0 if _snapshot_mode else 1.0)
		mesh.material_override = _waddle_material
	var shadow := MeshInstance3D.new()
	shadow.mesh = load("res://assets/materials/blob_shadow_mesh.tres")
	shadow.scale = Vector3.ONE * .52 * amount
	shadow.position = pos + Vector3(0, .008, 0)
	world.add_child(shadow)


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 40:
		capture()
	if capture_sequence and _frames == 80:
		if _crowd:
			get_tree().quit()
		else:
			_crowd = true
			build_review()


func capture() -> void:
	await RenderingServer.frame_post_draw
	var suffix: String = "crowd" if _crowd else "review"
	var result: Error = get_viewport().get_texture().get_image().save_png(OUTPUT + "godot_" + suffix + ".png")
	print("FROST_IMP_CAPTURE ", suffix, " result=", result, " renderer=", RenderingServer.get_current_rendering_method())
	if not _crowd and _views.size() >= 2:
		_views[0].get_texture().get_image().save_png(OUTPUT + "godot_front.png")
		_views[1].get_texture().get_image().save_png(OUTPUT + "godot_topdown.png")
	print("FROST_IMP_METRICS primitives=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		" draws=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_crowd = not _crowd
		build_review()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_S:
		capture()
	elif event.is_action_pressed("ui_cancel"):
		get_tree().quit()
