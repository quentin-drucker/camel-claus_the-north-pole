extends Control
## "Knit + Tin" intro (art_reference/GUI_Style_Guide §7): needles knit the logo row by row, a yarn ball
## rolls across, the subtitle springs up on a riveted pine plate, Claus pops up, the Santa hat drops onto
## the C. Any key, click or tap skips; then the knitted curtain (Transition) lifts on the main menu.
## Plays in full the first time, then at double speed as a short sting (Profile "seen_intro").
## Editor runs (F5) go straight to the menu unless camel_claus/always_show_intro is on; exports always play.

const MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const LOGO_HEIGHT: float = 160.0
const KNIT_ROWS: int = 12
const KNIT_START: float = 0.3
const KNIT_TIME: float = 1.5
const END_AT: float = 4.3
const STING_SPEED: float = 2.0

var _leaving: bool = false
var _timeline: Tween

@onready var logo_clip: Control = %LogoClip
@onready var needles: Control = %Needles
@onready var needle_a: Control = %NeedleA
@onready var needle_b: Control = %NeedleB
@onready var plate: Control = %Plate
@onready var yarn_line: Control = %YarnLine
@onready var yarn_ball: Control = %YarnBall
@onready var claus: Control = %Claus
@onready var hat: Control = %Hat
@onready var press: Control = %Press


func _ready() -> void:
	if not OS.has_feature("template") and not ProjectSettings.get_setting("camel_claus/always_show_intro", false):
		get_tree().change_scene_to_file.call_deferred(MENU_SCENE)  # no intro while developing
		return
	_play(STING_SPEED if Profile.data.get("seen_intro", false) else 1.0)


func _play(speed: float) -> void:
	var view_w: float = get_viewport_rect().size.x
	var claus_y: float = claus.position.y
	var hat_y: float = hat.position.y
	var needles_y: float = needles.position.y
	logo_clip.size.y = 0.0
	plate.pivot_offset = plate.size / 2.0
	plate.scale = Vector2.ONE * 0.6
	plate.modulate.a = 0.0
	claus.position.y = claus_y + 420.0
	hat.position.y = hat_y - 320.0
	hat.rotation = 0.7
	press.modulate.a = 0.0
	yarn_line.pivot_offset = Vector2.ZERO
	yarn_line.scale.x = 0.0
	yarn_ball.position.x = -120.0

	_timeline = create_tween().set_parallel()
	_timeline.set_speed_scale(speed)
	# Knitting: the logo appears in 12 rows under the needles, which click on every row.
	for row in KNIT_ROWS + 1:
		var at: float = KNIT_START + KNIT_TIME * row / KNIT_ROWS
		var height: float = LOGO_HEIGHT * row / KNIT_ROWS
		_timeline.tween_callback(func() -> void:
			logo_clip.size.y = height
			needles.position.y = needles_y + height
			needle_a.rotation = 0.1 if row % 2 == 0 else 0.02
			needle_b.rotation = -0.1 if row % 2 == 0 else -0.02).set_delay(at)
	_timeline.tween_property(needles, "modulate:a", 0.0, 0.3).set_delay(KNIT_START + KNIT_TIME + 0.05)
	# Yarn ball rolls across the bottom, unspooling its line.
	_timeline.tween_property(yarn_ball, "position:x", view_w * 0.83, 2.6).set_delay(KNIT_START) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_timeline.tween_property(yarn_ball, "rotation", TAU * 3.0, 2.6).set_delay(KNIT_START) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_timeline.tween_property(yarn_line, "scale:x", 0.86, 2.6).set_delay(KNIT_START) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Subtitle plate springs up, Claus pops in, the hat drops onto the C.
	_timeline.tween_property(plate, "modulate:a", 1.0, 0.15).set_delay(1.9)
	_timeline.tween_property(plate, "scale", Vector2.ONE, 0.4).set_delay(1.9) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_timeline.tween_property(claus, "position:y", claus_y, 0.65).set_delay(2.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_timeline.tween_property(hat, "position:y", hat_y, 0.55).set_delay(2.45) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_timeline.tween_property(hat, "rotation", -0.35, 0.55).set_delay(2.45) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_timeline.tween_property(press, "modulate:a", 1.0, 0.3).set_delay(3.0)
	_timeline.tween_callback(_leave).set_delay(END_AT)
	# Claus sways gently once he has landed.
	var sway: Tween = create_tween().set_loops()
	sway.tween_interval(2.8 / speed)
	sway.tween_property(claus, "rotation", -0.035, 1.5).set_trans(Tween.TRANS_SINE)
	sway.tween_property(claus, "rotation", 0.0, 1.5).set_trans(Tween.TRANS_SINE)


func _input(event: InputEvent) -> void:
	var skip: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed)
	if skip and not _leaving:
		get_viewport().set_input_as_handled()
		_leave()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	Profile.data["seen_intro"] = true
	Profile.save()
	Transition.change_scene(MENU_SCENE)
