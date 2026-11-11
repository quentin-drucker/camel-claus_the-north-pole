extends Node3D
## Main menu: a small snowy diorama (Claus hopping among a few critters, snowfall, a slowly swaying
## camera) behind the menu panel. Play fades into the run via Transition.

const MAIN_SCENE: String = "res://scenes/main/main.tscn"

var _time: float = 0.0

@onready var pivot: Node3D = $Pivot
@onready var claus: Node3D = $Claus
@onready var critters: Array[Node3D] = [$Imp1, $Imp2, $Chonk, $Zoomer]
@onready var menu_box: Control = %MenuBox
@onready var title: Label = %Title
@onready var play_button: Button = %PlayButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var settings: Control = %SettingsPanel


func _ready() -> void:
	# Frame Claus on the right third, leaving the left for the menu panel.
	$Pivot/Camera3D.look_at_from_position(Vector3(-2.6, 3.0, 6.5), Vector3(-2.3, 0.8, 0.0))
	for critter in critters:
		critter.look_at(Vector3(0.0, critter.position.y, 0.0))  # models face -Z: turn to Claus
	get_tree().paused = false
	Audio.set_paused_duck(false)
	Audio.play_music()
	quit_button.visible = not OS.has_feature("web")  # browsers can't quit a page
	play_button.pressed.connect(func() -> void:
		Audio.play(&"click")
		Transition.change_scene(MAIN_SCENE))
	settings_button.pressed.connect(func() -> void:
		Audio.play(&"click")
		menu_box.hide()
		settings.show())
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	settings.hide()
	settings.closed.connect(func() -> void:
		menu_box.show()
		settings_button.grab_focus())
	for button: Button in [play_button, settings_button, quit_button]:
		button.mouse_entered.connect(button.grab_focus)
		button.focus_entered.connect(_pop.bind(button, 1.06))
		button.focus_exited.connect(_pop.bind(button, 1.0))
	play_button.grab_focus()


func _process(delta: float) -> void:
	_time += delta
	pivot.rotation.y = sin(_time * 0.12) * 0.22
	claus.position.y = absf(sin(_time * 3.2)) * 0.1
	claus.rotation.y = PI + sin(_time * 0.6) * 0.35
	for i in critters.size():
		var phase: float = _time * 5.0 + i * 1.7
		critters[i].position.y = absf(sin(phase)) * 0.08
		critters[i].rotation.z = sin(phase) * 0.12
	title.pivot_offset = title.size / 2.0
	title.scale = Vector2.ONE * (1.0 + sin(_time * 2.0) * 0.015)


func _pop(button: Button, to_scale: float) -> void:
	button.pivot_offset = button.size / 2.0
	create_tween().tween_property(button, "scale", Vector2.ONE * to_scale, 0.08)
