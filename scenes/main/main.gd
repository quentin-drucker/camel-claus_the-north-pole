extends Node3D


func _ready() -> void:
	GameState.start_run()


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
