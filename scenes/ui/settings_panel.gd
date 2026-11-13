extends PanelContainer
## Shared settings panel (main menu + pause menu), laid out like the approved hybrid (style guide 5.5):
## header band with a close X; Sound (music, sounds), Display (fullscreen, interface size) and Gameplay
## (screen shake, damage numbers, reduce motion); Reset progress (main menu only) and Back.
## Volumes go through Audio's buses; the other options are Audio.options (all in user://settings.cfg).

signal closed
## Profile was wiped (the main menu refreshes its best runs and coins).
signal progress_reset

const SIZES: Array[String] = ["Small", "Medium", "Large"]
const LABEL_WIDTH: int = 210
const VALUE_WIDTH: int = 56

var _reset_armed: bool = false
var music_slider: HSlider
var sfx_slider: HSlider
var fullscreen: CheckButton
var reset_button: Button
var back_button: Button
var _size_value: Label


func _ready() -> void:
	theme_type_variation = &"PlateTightKnit"  # the hybrid's settings plate has the knit behind it
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 0)
	add_child(column)
	column.add_child(Tin.header("Settings", null, close))
	var body := VBoxContainer.new()
	body.add_theme_constant_override(&"separation", 10)
	column.add_child(Tin.body(body, 18))

	body.add_child(Tin.label("Sound", &"SubLabel"))
	music_slider = _slider_row(body, "Music", Audio.get_volume(&"Music"), func(v: float) -> void:
		Audio.set_volume(&"Music", v))
	sfx_slider = _slider_row(body, "Sounds", Audio.get_volume(&"SFX"), func(v: float) -> void:
		Audio.set_volume(&"SFX", v)
		Audio.play(&"click"))

	body.add_child(Tin.label("Display", &"SubLabel"))
	fullscreen = _toggle_row(body, "Fullscreen", _is_fullscreen(), func(on: bool) -> void:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED))
	var size_row := _row(body, "Interface size")
	size_row.add_child(_arrow(preload("res://assets/ui/tin/icon_chevron_left.png"), -1))
	_size_value = Tin.label("", &"GoldLabel")
	_size_value.custom_minimum_size = Vector2(120, 0)
	_size_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	size_row.add_child(_size_value)
	size_row.add_child(_arrow(preload("res://assets/ui/tin/icon_chevron_right.png"), 1))
	_show_size()

	body.add_child(Tin.label("Gameplay", &"SubLabel"))
	_toggle_row(body, "Screen shake", Audio.options["shake"], func(on: bool) -> void:
		Audio.set_option("shake", on))
	_toggle_row(body, "Damage numbers", Audio.options["damage_numbers"], func(on: bool) -> void:
		Audio.set_option("damage_numbers", on))
	_toggle_row(body, "Reduce motion", Audio.options["reduce_motion"], func(on: bool) -> void:
		Audio.set_option("reduce_motion", on))

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override(&"separation", 16)
	column.add_child(Tin.body(footer, 18))
	reset_button = Button.new()
	reset_button.theme_type_variation = &"DangerButton"
	reset_button.pressed.connect(_on_reset)
	footer.add_child(reset_button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	back_button = Button.new()
	back_button.text = "Back"
	back_button.theme_type_variation = &"PrimaryButton"
	back_button.custom_minimum_size = Vector2(150, 0)
	back_button.pressed.connect(close)
	footer.add_child(back_button)
	for b: Button in [reset_button, back_button]:
		b.mouse_entered.connect(b.grab_focus)

	_sync_fullscreen()
	visibility_changed.connect(func() -> void:
		if visible:
			_reset_armed = false
			reset_button.text = "Reset progress"
			reset_button.visible = not GameState.is_running  # main menu only, never mid-run
			music_slider.grab_focus())


func _row(parent: Control, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 16)
	row.custom_minimum_size = Vector2(0, 36)
	parent.add_child(row)
	var l := Tin.label(text)
	l.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(l)
	return row


func _slider_row(parent: Control, text: String, value: float, on_change: Callable) -> HSlider:
	var row := _row(parent, text)
	var slider := HSlider.new()
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size = Vector2(0, 34)
	slider.mouse_entered.connect(slider.grab_focus)
	row.add_child(slider)
	var pct := Tin.label("", &"MutedLabel")
	pct.custom_minimum_size = Vector2(VALUE_WIDTH, 0)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(pct)
	var show := func(v: float) -> void: pct.text = "%d%%" % roundi(v * 100.0)
	show.call(value)
	slider.value_changed.connect(show)
	slider.value_changed.connect(on_change)
	return slider


func _toggle_row(parent: Control, text: String, on: bool, on_toggle: Callable) -> CheckButton:
	var row := _row(parent, text)
	var toggle := CheckButton.new()
	toggle.button_pressed = on
	toggle.text = "On" if on else "Off"
	toggle.layout_direction = Control.LAYOUT_DIRECTION_RTL  # switch first, then "On"/"Off" (prototype order)
	toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	toggle.toggled.connect(func(pressed: bool) -> void:
		toggle.text = "On" if pressed else "Off"
		Audio.play(&"click"))
	toggle.toggled.connect(on_toggle)
	toggle.mouse_entered.connect(toggle.grab_focus)
	row.add_child(toggle)
	return toggle


func _arrow(chevron: Texture2D, step: int) -> Button:
	var b := Button.new()
	b.icon = chevron
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.tooltip_text = "Smaller" if step < 0 else "Larger"
	b.theme_type_variation = &"SmallButton"
	b.custom_minimum_size = Vector2(44, 42)
	b.mouse_entered.connect(b.grab_focus)
	b.pressed.connect(func() -> void:
		Audio.play(&"click")
		Audio.set_option("ui_size", clampi(int(Audio.options["ui_size"]) + step, 0, SIZES.size() - 1))
		_show_size())
	return b


func _show_size() -> void:
	_size_value.text = SIZES[int(Audio.options["ui_size"])]


func _process(_delta: float) -> void:
	if visible:
		_sync_fullscreen()


## Esc closes the panel (main menu and pause menu alike; children get unhandled input first, so the
## pause menu doesn't also resume on the same press).
func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		close()
		get_viewport().set_input_as_handled()


func _is_fullscreen() -> bool:
	var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


## The toggle mirrors the real state: a browser leaves fullscreen on Esc (or its own UI) without the
## game asking, so it is read from the window every frame the panel is open, never remembered.
func _sync_fullscreen() -> void:
	var is_full: bool = _is_fullscreen()
	if fullscreen.button_pressed != is_full:
		fullscreen.set_pressed_no_signal(is_full)
		fullscreen.text = "On" if is_full else "Off"


## Two presses: the first asks, the second wipes coins, Workshop, unlocks, achievements and stats.
func _on_reset() -> void:
	if not _reset_armed:
		_reset_armed = true
		Audio.play(&"hurt", 1.4)
		reset_button.text = "Press again to erase"
		return
	_reset_armed = false
	Profile.reset()
	Audio.play(&"click")
	reset_button.text = "Progress erased"
	progress_reset.emit()


func close() -> void:
	Audio.play(&"click")
	hide()
	closed.emit()
