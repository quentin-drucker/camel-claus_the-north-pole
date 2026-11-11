extends PanelContainer
## Shared settings panel (main menu + pause menu): music and sound volume, fullscreen.
## Volumes go through Audio (bus-based, saved to user://settings.cfg).

signal closed

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
	back_button.pressed.connect(close)
	visibility_changed.connect(func() -> void:
		if visible:
			music_slider.grab_focus())


func close() -> void:
	Audio.play(&"click")
	hide()
	closed.emit()
