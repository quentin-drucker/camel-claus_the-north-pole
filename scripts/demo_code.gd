extends CanvasLayer
## Autoload "DemoCode": a secret for live demos. Typing the letters of CODE anywhere (menus or mid-run,
## release builds too) unlocks everything in the Profile (Profile.unlock_everything()); during a run it
## also levels every loadout weapon to Lv 5 and fills Santa's meter, so an evolution is one Space away.
## Uses only letters with no binding (H, O), so typing it in a fight doesn't move, pause or call Santa.
## Not shown anywhere in the game; documented in docs/PUBLISHING.md. Reset progress undoes it.

const CODE: String = "hohoho"

var _typed: String = ""
var _toast: Label


func _ready() -> void:
	layer = 99  # over menus, under the Transition fade
	process_mode = Node.PROCESS_MODE_ALWAYS  # works while paused and on menus
	_toast = Label.new()
	# Right half, below the timer: clear of the main menu panel and of the run's HUD.
	_toast.position = Vector2(660.0, 112.0)
	_toast.size = Vector2(600.0, 60.0)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.theme_type_variation = &"HeaderLabel"
	_toast.add_theme_color_override(&"font_color", Color("F2B53B"))
	_toast.add_theme_constant_override(&"outline_size", 12)
	_toast.add_theme_color_override(&"font_outline_color", Color("22304F"))
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.hide()
	add_child(_toast)


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.unicode == 0:
		return
	_typed = (_typed + char(key.unicode).to_lower()).right(CODE.length())
	if _typed == CODE:
		_typed = ""
		_activate()


func _activate() -> void:
	Profile.unlock_everything()
	var text: String = "Ho ho ho!  Everything unlocked"
	if GameState.is_running and is_instance_valid(GameState.player):
		for id in GameState.loadout:
			var card: UpgradeData = Profile.weapon_card(id)
			while GameState.player.upgrade_level(card) < card.max_level:
				GameState.player.apply_upgrade(card)
		GameState.santa_progress = GameState.santa_needed()
		GameState.santa_ready = true
		GameState.santa_changed.emit(GameState.santa_progress, GameState.santa_needed(), true)
		text = "Ho ho ho!  Max weapons + Santa ready"
	Audio.play(&"evolve")
	_toast.text = text
	_toast.show()
	_toast.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(_toast, "modulate:a", 0.0, 0.6)
	tween.tween_callback(_toast.hide)
