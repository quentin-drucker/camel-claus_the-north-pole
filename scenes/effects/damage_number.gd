class_name DamageNumber
extends Label3D
## Floating damage number: rises and fades, then frees itself. Capped so big fights stay readable.

const FONT: FontFile = preload("res://assets/fonts/Tiny5.ttf")  # style guide 4.14: Tiny5, dark outline
const MAX_ALIVE: int = 40

static var _alive: int = 0


static func spawn(pos: Vector3, amount: float, color: Color = Color("F4F8FF")) -> void:
	if _alive >= MAX_ALIVE or amount < 1.0:
		return
	var label := DamageNumber.new()
	label.text = str(roundi(amount))
	label.modulate = color
	(Engine.get_main_loop() as SceneTree).current_scene.add_child(label)
	label.global_position = pos + Vector3(randf_range(-0.35, 0.35), 1.3, 0.0)


func _init() -> void:
	font = FONT
	font_size = 30
	outline_size = 10
	outline_modulate = Color("0D1322")
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	fixed_size = true
	pixel_size = 0.0011
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST


func _ready() -> void:
	_alive += 1
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y + 0.9, 0.6) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.3)
	tween.chain().tween_callback(queue_free)


func _exit_tree() -> void:
	_alive -= 1
