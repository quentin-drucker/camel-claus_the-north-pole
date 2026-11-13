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
## Unfinished achievements shown as "next goals" cards on the left.
const GOALS_SHOWN: int = 3

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
@onready var best_list: GridContainer = %BestList
@onready var keys: HBoxContainer = %Keys
@onready var coins_label: Label = %Coins
@onready var goals: VBoxContainer = %Goals
@onready var meta_pages: Dictionary = {%WorkshopButton: %WorkshopPanel, %AchievementsButton: %AchievementsPanel,
	%StatsButton: %StatsPanel, %CreditsButton: %CreditsPanel, %CustomizeButton: %CustomizePanel}
## Control hints under the menu: keycap -> what it does.
const KEY_HINTS: Array[Array] = [["WASD", "Move"], ["Space", "Call Santa"], ["Esc", "Pause"]]

## Camera poses: [position, look-at target]. Wide = the menu diorama; close = Customize's live preview.
const CAMERA_WIDE: Array[Vector3] = [Vector3(-2.6, 2.4, 6.5), Vector3(-2.3, 1.55, 0.0)]
const CAMERA_CLOSE: Array[Vector3] = [Vector3(-0.5, 1.5, 4.6), Vector3(-0.25, 1.0, 0.0)]

var _badge: PanelContainer
var _camera_tween: Tween


func _frame_camera(pose: Array[Vector3]) -> void:
	var camera: Camera3D = $Pivot/Camera3D
	var goal := Transform3D(Basis.looking_at(pose[1] - pose[0]), pose[0])
	if _camera_tween:
		_camera_tween.kill()
	_camera_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_camera_tween.tween_property(camera, "transform", goal, 0.0 if Audio.options["reduce_motion"] else 0.5)


func _ready() -> void:
	# Frame Claus on the right third, leaving the left for the menu panel.
	# Low and level enough to show the sky, mountains and aurora above the forest, Claus on the right.
	$Pivot/Camera3D.look_at_from_position(CAMERA_WIDE[0], CAMERA_WIDE[1])
	for critter: Node3D in critters + [yeti, lobber]:
		critter.look_at(Vector3(0.0, critter.position.y, 0.0))  # models face -Z: turn to Claus
	_yeti_scale = yeti.scale
	_lobber_scale = lobber.scale
	get_tree().paused = false
	Audio.set_paused_duck(false)
	Audio.play_music()
	quit_button.visible = not OS.has_feature("web")  # browsers can't quit a page
	var version: String = str(ProjectSettings.get_setting("application/config/version", ""))
	%Version.text = "v" + (version if version != "" else "1.2")
	for hint: Array in KEY_HINTS:
		keys.add_child(Tin.key_hint(hint[0], hint[1]))
	_badge = _make_badge(%WorkshopButton)
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
	# Customize: the camera moves in so Claus stands big between the picker and the detail panel.
	%CustomizePanel.visibility_changed.connect(func() -> void:
		_frame_camera(CAMERA_CLOSE if %CustomizePanel.visible else CAMERA_WIDE))
	_refresh_meta()
	for button: Button in [play_button, settings_button, quit_button] + meta_pages.keys():
		button.mouse_entered.connect(button.grab_focus)  # hover = focus, so the brackets agree
	play_button.grab_focus()


## Best runs, coins, Workshop badge and the next three goals (Profile may have changed after a run or
## a purchase).
func _refresh_meta() -> void:
	for child in best_list.get_children():
		child.queue_free()
	var runs: Array = Profile.data["top_runs"]
	best_list.columns = 1 if runs.is_empty() else 4
	if runs.is_empty():
		best_list.add_child(Tin.label("None yet - good luck!", &"MutedLabel"))
	for i in runs.size():
		var run: Dictionary = runs[i]
		var t: int = int(run["time"])
		var cells: Array[String] = [str(i + 1), "%d:%02d" % [floori(t / 60.0), t % 60], "Lv %d" % int(run["level"]),
			"%s bonks" % Tin.num(int(run["kills"]))]
		for c in cells.size():
			best_list.add_child(Tin.label(cells[c], &"MutedLabel" if c == 0 else (&"GoldLabel" if i == 0 else &"")))
	coins_label.text = Tin.num(Profile.coins())
	var affordable: int = 0
	for item: WorkshopData in Profile.WORKSHOP:
		var cost: int = Profile.workshop_cost(item)
		affordable += int(cost >= 0 and cost <= Profile.coins())
	_badge.visible = affordable > 0
	(_badge.get_child(0) as Label).text = str(affordable)
	_fill_goals()


## Red count bubble on a button's top-right corner (Workshop: upgrades you can afford right now).
func _make_badge(button: Button) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.theme_type_variation = &"Badge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_meta(&"decor", true)  # overhangs the button's corner on purpose
	var l := Tin.label("0", &"BadgeLabel")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_child(l)
	button.add_child(badge)
	var place := func() -> void: badge.position = Vector2(button.size.x - 20.0, -10.0)
	button.resized.connect(place)
	place.call()
	return badge


## Megabonk-style quest cards: knit card, trophy stamp, gold title, description, progress bar + count.
func _fill_goals() -> void:
	for child in goals.get_children():
		child.queue_free()
	var p: Dictionary = Profile.progress()
	var shown: int = 0
	for goal: AchievementData in Profile.ACHIEVEMENTS:
		if shown >= GOALS_SHOWN or Profile.has_achievement(goal.id):
			continue
		shown += 1
		var value: float = minf(float(p.get(goal.stat, 0.0)), goal.target)
		var card := PanelContainer.new()
		card.theme_type_variation = &"KnitCard"
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 12)
		card.add_child(row)
		row.add_child(Tin.stamp(Describe.goal_icon(goal), "common", 34))
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_constant_override(&"separation", 2)
		row.add_child(text)
		text.add_child(Tin.label(goal.title, &"GoalTitle"))
		text.add_child(Tin.label(goal.description, &"SmallLabel", true))
		var meter := HBoxContainer.new()
		meter.add_theme_constant_override(&"separation", 8)
		text.add_child(meter)
		var bar := Tin.bar(&"GoodBar", value, goal.target, 8)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		meter.add_child(bar)
		meter.add_child(Tin.label("%s / %s" % [_goal_num(goal, value), _goal_num(goal, goal.target)], &"SmallLabel"))
		goals.add_child(card)


func _goal_num(goal: AchievementData, v: float) -> String:
	if goal.stat.ends_with("seconds"):
		return "%d:%02d" % [floori(v / 60.0), int(v) % 60]
	return str(int(v))


func _process(delta: float) -> void:
	_time += delta
	if Audio.options["reduce_motion"]:
		return
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

