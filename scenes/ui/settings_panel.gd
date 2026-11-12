extends PanelContainer
## Shared settings panel (main menu + pause menu): music and sound volume, fullscreen, reset progress.
## Volumes go through Audio (bus-based, saved to user://settings.cfg).

signal closed
## Profile was wiped (the main menu refreshes its best-run line and coins).
signal progress_reset

var _reset_armed: bool = false

@onready var reset_button: Button = %ResetButton
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var fullscreen: CheckButton = %Fullscreen
@onready var back_button: Button = %BackButton


func _ready() -> void:
	music_slider.value = Audio.get_volume(&"Music")
	sfx_slider.value = Audio.get_volume(&"SFX")
	fullscreen.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	music_slider.value_changed.connect(func(v: float) -> void: Audio.set_volume(&"Music", v))
	sfx_slider.value_changed.connect(func(v: float) -> void:
		Audio.set_volume(&"SFX", v)
		Audio.play(&"click"))
	fullscreen.toggled.connect(func(on: bool) -> void:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED))
	_sync_fullscreen()
	back_button.pressed.connect(close)
	reset_button.pressed.connect(_on_reset)
	visibility_changed.connect(func() -> void:
		if visible:
			_reset_armed = false
			reset_button.text = "Reset progress"
			reset_button.visible = not GameState.is_running  # main menu only, never mid-run
			music_slider.grab_focus())


func _process(_delta: float) -> void:
	if visible:
		_sync_fullscreen()


## Esc closes the panel (main menu and pause menu alike; children get unhandled input first, so the
## pause menu doesn't also resume on the same press).
func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		close()
		get_viewport().set_input_as_handled()


## The checkbox mirrors the real state: a browser leaves fullscreen on Esc (or its own UI) without the
## game asking, so the box is read from the window every frame the panel is open, never remembered.
func _sync_fullscreen() -> void:
	var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	var is_full: bool = mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	if fullscreen.button_pressed != is_full:
		fullscreen.set_pressed_no_signal(is_full)


## Two presses: the first asks, the second wipes coins, Workshop, unlocks, achievements and stats.
func _on_reset() -> void:
	if not _reset_armed:
		_reset_armed = true
		Audio.play(&"hurt", 1.4)
		reset_button.text = "Really erase all progress? Press again"
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
