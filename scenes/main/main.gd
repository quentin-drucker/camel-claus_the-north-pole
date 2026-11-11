extends Node3D
## Starts a run after the title screen (or straight away after "Play again"), and fades in the
## music's drive layer for the final stretch.

## Run time when the music's intensity layer fades in (docs/PLAN.md five-minute arc).
const INTENSITY_TIME: float = 210.0

var _intense: bool = false


func _ready() -> void:
	if GameState.skip_title:
		$TitleScreen.queue_free()
		get_tree().paused = false
		_begin()
	else:
		$TitleScreen.play_pressed.connect(_begin)


func _begin() -> void:
	GameState.start_run()
	Audio.start_music()


func _process(_delta: float) -> void:
	if not _intense and GameState.is_running and GameState.run_time >= INTENSITY_TIME:
		_intense = true
		Audio.set_intensity(true)


func _unhandled_input(event: InputEvent) -> void:
	# ponytail: debug loadout (F4) to see all Phase 3 content fast; remove before ship with F2/F3.
	if not event.is_action_pressed("debug_loadout"):
		return
	var player: Player = GameState.player
	for upgrade: UpgradeData in $LevelUpMenu.upgrades:
		if upgrade.stat == UpgradeData.Stat.WEAPON:
			while player.upgrade_level(upgrade) < upgrade.max_level:
				player.apply_upgrade(upgrade)
	player.add_item(preload("res://resources/items/santas_sack.tres"))
	player.add_item(preload("res://resources/items/sleigh_bells.tres"))
	GameState.add_chest()
