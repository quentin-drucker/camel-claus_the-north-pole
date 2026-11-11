extends CanvasLayer
## Win/lose screen: freezes the run, fades in over it with the result, run stats and the build,
## then "Play again" or "Main menu" (both through the Transition fade).

const MAIN_SCENE: String = "res://scenes/main/main.tscn"
const MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"

@onready var result_label: Label = %ResultLabel
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton
@onready var build_row: HBoxContainer = %BuildRow


func _ready() -> void:
	hide()
	GameState.run_ended.connect(_on_run_ended)
	restart_button.pressed.connect(_leave.bind(MAIN_SCENE))
	menu_button.pressed.connect(_leave.bind(MENU_SCENE))


func _on_run_ended(won: bool) -> void:
	var survived: int = int(GameState.run_time)
	result_label.text = "%s\nSurvived %d:%02d  -  level %d  -  %d critters bonked" % [
		"You survived the North Pole!" if won else "Claus fainted in the snow...",
		floori(survived / 60.0), survived % 60, GameState.level, GameState.kills,
	]
	var player: Player = GameState.player
	for weapon in player.weapons():
		_add_icon(Describe.weapon_icon(weapon))
	for item: ItemData in player.items:
		_add_icon(Describe.icon_for(item))
	Audio.stop_music()
	Audio.play(&"win" if won else &"lose")
	get_tree().paused = true
	# Short beat so the final moment registers, then the panel fades in.
	await get_tree().create_timer(0.5, true).timeout
	for node: CanvasItem in get_children():
		node.modulate.a = 0.0
		create_tween().tween_property(node, "modulate:a", 1.0, 0.4)
	show()
	restart_button.grab_focus()


func _add_icon(texture: Texture2D) -> void:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(56, 56)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	build_row.add_child(icon)


func _leave(scene: String) -> void:
	Audio.play(&"click")
	Transition.change_scene(scene)
