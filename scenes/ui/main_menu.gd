extends Node3D
## Main menu: a small snowy diorama behind the menu panel — Claus hopping among grumpy critters, the
## Grumpy Yeti looming behind them (breathing, and stomping now and then), a Snowball Lobber winding up,
## an ice bat circling overhead, Santa's Sleigh sweeping across the sky every so often, snowfall and a
## slowly swaying camera. Play opens the loadout panel; Start run fades into the run via Transition.

const MAIN_SCENE: String = "res://scenes/main/main.tscn"
const SLEIGH: PackedScene = preload("res://scenes/santa/sleigh_model.tscn")
## Seconds between the Yeti's stomps, the Lobber's wind-ups and the sleigh's fly-bys.
const STOMP_EVERY: float = 6.5
const WINDUP_EVERY: float = 4.2
const SLEIGH_EVERY: float = 12.0

var _time: float = 0.0
var _yeti_scale: Vector3
var _lobber_scale: Vector3
var _sleigh_left: float = 3.0

@onready var pivot: Node3D = $Pivot
@onready var claus: Node3D = $Claus
@onready var critters: Array[Node3D] = [$Imp1, $Imp2, $Chonk]
@onready var zoomer: Node3D = $Zoomer
@onready var yeti: Node3D = $Yeti
@onready var lobber: Node3D = $Lobber
@onready var menu_box: Control = %MenuBox
@onready var title: Label = %Title
@onready var play_button: Button = %PlayButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var settings: Control = %SettingsPanel
@onready var loadout: Control = %LoadoutPanel
@onready var best_label: Label = %BestLabel
@onready var workshop_button: Button = %WorkshopButton
@onready var meta_pages: Dictionary = {%WorkshopButton: %WorkshopPanel, %AchievementsButton: %AchievementsPanel,
	%StatsButton: %StatsPanel, %CustomizeButton: %CustomizePanel}


func _ready() -> void:
	# Frame Claus on the right third, leaving the left for the menu panel.
	# Low and level enough to show the sky, mountains and aurora above the forest, Claus on the right.
	$Pivot/Camera3D.look_at_from_position(Vector3(-2.6, 2.4, 6.5), Vector3(-2.3, 1.55, 0.0))
	for critter: Node3D in critters + [yeti, lobber]:
		critter.look_at(Vector3(0.0, critter.position.y, 0.0))  # models face -Z: turn to Claus
	_yeti_scale = yeti.scale
	_lobber_scale = lobber.scale
	get_tree().paused = false
	Audio.set_paused_duck(false)
	Audio.play_music()
	quit_button.visible = not OS.has_feature("web")  # browsers can't quit a page
	play_button.pressed.connect(func() -> void:
		Audio.play(&"click")
		menu_box.hide()
		loadout.show())
	loadout.hide()
	loadout.closed.connect(func() -> void:
		menu_box.show()
		play_button.grab_focus())
	loadout.started.connect(func() -> void: Transition.change_scene(MAIN_SCENE))
	settings_button.pressed.connect(func() -> void:
		Audio.play(&"click")
		menu_box.hide()
		settings.show())
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	settings.hide()
	settings.progress_reset.connect(_refresh_meta)
	Profile.changed.connect(_refresh_meta)  # e.g. the demo code unlocking everything
	settings.closed.connect(func() -> void:
		menu_box.show()
		settings_button.grab_focus())
	for button: Button in meta_pages:
		var panel: Control = meta_pages[button]
		panel.hide()
		button.pressed.connect(func() -> void:
			Audio.play(&"click")
			menu_box.hide()
			panel.show())
		panel.closed.connect(func() -> void:
			_refresh_meta()
			menu_box.show()
			button.grab_focus())
	_refresh_meta()
	for button: Button in [play_button, settings_button, quit_button] + meta_pages.keys():
		button.mouse_entered.connect(button.grab_focus)
		button.focus_entered.connect(_pop.bind(button, 1.06))
		button.focus_exited.connect(_pop.bind(button, 1.0))
	play_button.grab_focus()


## Best-run line and coin count on the Workshop button (Profile may have changed after a run or purchase).
func _refresh_meta() -> void:
	var bests: Dictionary = Profile.data["bests"]
	if bests.is_empty():
		best_label.text = "Best run: none yet - good luck!"
	else:
		var t: int = int(bests.get("time", 0))
		best_label.text = "Best run: %d:%02d  -  %d kills  -  %d evolved" % [
			floori(t / 60.0), t % 60, int(bests.get("kills", 0)), int(bests.get("evolutions", 0))]
	workshop_button.text = "Workshop  %d" % Profile.coins()


func _process(delta: float) -> void:
	_time += delta
	pivot.rotation.y = sin(_time * 0.12) * 0.22
	claus.position.y = absf(sin(_time * 3.2)) * 0.1
	claus.rotation.y = PI + sin(_time * 0.6) * 0.35
	for i in critters.size():
		var phase: float = _time * 5.0 + i * 1.7
		critters[i].position.y = absf(sin(phase)) * 0.08
		critters[i].rotation.z = sin(phase) * 0.12
	_animate_cast(delta)
	title.pivot_offset = title.size / 2.0
	title.scale = Vector2.ONE * (1.0 + sin(_time * 2.0) * 0.015)


## The Yeti breathes and stomps, the Lobber winds up, the ice bat circles, the sleigh flies over.
func _animate_cast(delta: float) -> void:
	var breath: float = sin(_time * 1.4)
	var stomp: float = fmod(_time, STOMP_EVERY)
	var hop: float = maxf(sin(stomp / 0.5 * PI), 0.0) if stomp < 0.5 else 0.0  # a heavy little jump
	yeti.scale = _yeti_scale * Vector3(1.0 - breath * 0.015, 1.0 + breath * 0.03, 1.0 - breath * 0.015)
	yeti.position.y = hop * 0.35
	if stomp < 0.5 and stomp + delta >= 0.5:  # landing
		Poof.spawn(yeti.global_position, Color("F4F8FF"), 14, 3.5)
	var windup: float = fmod(_time + 1.3, WINDUP_EVERY)
	lobber.scale = _lobber_scale * (1.0 + 0.07 * sin(_time * 40.0) if windup < 0.6 else 1.0)
	var orbit: float = _time * 0.9
	zoomer.position = Vector3(3.0 + cos(orbit) * 1.4, 2.3 + sin(_time * 4.0) * 0.12, -2.8 + sin(orbit) * 1.1)
	zoomer.rotation.y = atan2(sin(orbit) * 1.4, -cos(orbit) * 1.1)  # face along its path (models face -Z)
	_sleigh_left -= delta
	if _sleigh_left <= 0.0:
		_sleigh_left = SLEIGH_EVERY
		_fly_sleigh()


func _fly_sleigh() -> void:
	var sleigh: Node3D = SLEIGH.instantiate()
	add_child(sleigh)
	# Low across the back of the scene, rising a little: in frame above the mountains, behind the cast.
	var from := Vector3(-24.0, 3.0, -13.0)
	var to := Vector3(26.0, 4.0, -13.0)
	sleigh.position = from
	sleigh.rotation.y = atan2(-(to - from).x, -(to - from).z)  # models face -Z
	sleigh.add_child(Poof.trail(Color("F2B53B"), 12))
	var tween: Tween = create_tween()
	tween.tween_property(sleigh, "position", to, 6.0)
	tween.tween_callback(sleigh.queue_free)


func _pop(button: Button, to_scale: float) -> void:
	button.pivot_offset = button.size / 2.0
	create_tween().tween_property(button, "scale", Vector2.ONE * to_scale, 0.08)
