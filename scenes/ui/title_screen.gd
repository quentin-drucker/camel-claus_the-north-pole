extends CanvasLayer
## Title overlay on top of the paused game world. Clicking Play also unlocks audio in the browser
## (browsers block sound until the first user gesture).

signal play_pressed

@onready var play_button: Button = %PlayButton
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider


func _ready() -> void:
	get_tree().paused = true
	music_slider.value = Audio.get_volume(&"Music")
	sfx_slider.value = Audio.get_volume(&"SFX")
	music_slider.value_changed.connect(func(v: float) -> void: Audio.set_volume(&"Music", v))
	sfx_slider.value_changed.connect(func(v: float) -> void:
		Audio.set_volume(&"SFX", v)
		Audio.play(&"click"))
	play_button.pressed.connect(_on_play)
	play_button.grab_focus()


func _on_play() -> void:
	Audio.play(&"click")
	get_tree().paused = false
	play_pressed.emit()
	queue_free()
