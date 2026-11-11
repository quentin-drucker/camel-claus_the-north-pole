extends CanvasLayer
## Win/lose screen with a restart button.

@onready var result_label: Label = %ResultLabel
@onready var restart_button: Button = %RestartButton


func _ready() -> void:
	hide()
	GameState.run_ended.connect(_on_run_ended)
	restart_button.pressed.connect(_on_restart_pressed)


func _on_run_ended(won: bool) -> void:
	var survived: int = int(GameState.run_time)
	result_label.text = "%s\nSurvived %d:%02d  -  level %d  -  %d critters bonked" % [
		"You survived the North Pole!" if won else "Claus fainted in the snow...",
		floori(survived / 60.0), survived % 60, GameState.level, GameState.kills,
	]
	Audio.stop_music()
	Audio.play(&"win" if won else &"lose")
	show()
	get_tree().paused = true
	restart_button.grab_focus()


func _on_restart_pressed() -> void:
	Audio.play(&"click")
	GameState.skip_title = true
	get_tree().paused = false
	get_tree().reload_current_scene()
