extends SceneTree
## Run: godot --headless --fixed-fps 60 --path . -s res://tests/test_santa.gd  (exit code 1 = failure)
## Santa's Sleigh meter (thresholds, holding when full), the whole call -> fly-over -> present -> menu
## flow, loadout-only weapon cards, banish/reroll, Santa offering evolutions vs blessings, and timed
## blessings undoing themselves. Loads scripts at runtime: -s scripts compile before autoloads exist.

var _failures: int = 0
var _started: bool = false


func _initialize() -> void:
	# Never touch the player's real save: the results screen records every run.
	root.get_node("Profile").save_path = "user://test_scratch_profile.json"
	if FileAccess.file_exists("user://test_scratch_profile.json"):
		DirAccess.remove_absolute("user://test_scratch_profile.json")
	change_scene_to_file("res://scenes/main/main.tscn")


func _process(_delta: float) -> bool:
	if not _started and current_scene != null:
		_started = true
		_run()
	if Time.get_ticks_msec() > 180000:  # a script error stops _run() before quit(): fail instead of hanging
		push_error("FAIL: timed out (a script error above stopped the test)")
		quit(1)
	return false


func _run() -> void:
	await _frames(3)
	var gs: Node = root.get_node("GameState")
	var main: Node = current_scene
	var player: Node = gs.player
	var menu: Node = main.get_node("LevelUpMenu")
	main.get_node("EnemySpawner").set_process(false)
	player.invincible = true
	var dummy: Node = load("res://scenes/enemies/enemy.gd").new()
	var speed_before: float = player.move_speed_bonus

	# --- Meter: 8 kills for the first charge, then it holds; calling resets to the next threshold.
	_check(gs.santa_needed() == 8, "first charge needs 8 kills")
	for i in 7:
		gs.register_kill(dummy)
	_check(not gs.santa_ready, "7 kills: not ready")
	gs.register_kill(dummy)
	_check(gs.santa_ready, "8 kills: ready")
	for i in 50:
		gs.register_kill(dummy)
	_check(gs.santa_progress == 8, "a full meter holds instead of banking extra kills")
	_check(gs.call_santa(), "calling a full meter works")
	_check(not gs.call_santa(), "can't call again right away")
	_check(gs.santa_needed() == 180, "second charge needs 180")
	gs.santa_calls = 4
	_check(gs.santa_needed() == 520, "after the list, +100 per charge (5th = 520)")
	gs.santa_calls = 1

	# --- Whole flow: call -> sleigh -> present lands near Claus -> homes in -> Santa menu (blessings).
	# The call above already sent a sleigh, so two presents come down together: one menu each.
	for i in 180:
		gs.register_kill(dummy)
	_check(gs.call_santa(), "second charge called")
	await _frames(int(1.4 * 60))  # dropped at 1.1 s, still falling (it lands inside pickup reach)
	var presents: Array = get_nodes_in_group(&"santa_presents")
	_check(presents.size() == 2, "each sleigh dropped one present (%d)" % presents.size())
	for present: Node3D in presents:
		var d: float = present.global_position.distance_to(player.global_position)
		_check(d < 4.0, "present lands next to Claus (%.1f m)" % d)
	await _frames(int(5.0 * 60))
	_check(menu.visible and paused, "picking up the present opens the menu")
	_check(menu.title.text.begins_with("Santa's present!"), "Santa's title: " + menu.title.text)
	_check(menu._choices.size() == 3 and menu._choices.all(func(c: Dictionary) -> bool: return c["card"]["tag"] == "BLESSING"),
		"no Lv 5 weapon: 3 blessings")
	_check(not menu.tools.visible, "no reroll/banish on Santa's screen")
	var opened: int = 0
	for f in 6 * 60:  # the 2nd present waits (frozen) while the 1st menu pauses, then arrives
		if menu.visible:
			menu.buttons[0].pressed.emit()
			opened += 1
		await process_frame
	_check(opened == 2, "one Santa menu per present (%d)" % opened)
	_check(not player.blessings.is_empty() and not paused, "picking a blessing applies it and resumes")

	# --- Blessings undo themselves (wait out the longest, Christmas Spirit 30 s).
	var cocoa: Resource = load("res://resources/blessings/hot_cocoa.tres")
	var rush: Resource = load("res://resources/blessings/reindeer_rush.tres")
	player.bless(cocoa)
	player.bless(rush)
	_check(player.blessing_damage >= 2.0, "Hot Cocoa doubles damage")
	var with_cocoa: float = player.blessing_damage
	player.bless(cocoa)  # refresh, not stack
	_check(is_equal_approx(player.blessing_damage, with_cocoa), "a second Hot Cocoa refreshes instead of stacking")
	await _frames(int(31.0 * 60))
	_check(player.blessings.is_empty() and is_equal_approx(player.blessing_damage, 1.0)
		and is_equal_approx(player.move_speed_bonus, speed_before) and is_equal_approx(gs.xp_mult, 1.0),
		"blessings wear off exactly")

	# --- Santa with a Lv 5 weapon: evolutions only.
	var gift: Node = player.weapons()[0]
	gift.level = 5
	gs.pending_santa += 1
	gs.santa_present_found.emit()
	_check(menu._choices.size() == 1 and menu._choices[0]["card"]["tag"] == "EVOLUTION", "Lv 5 weapon: Santa offers its evolution")
	menu.buttons[0].pressed.emit()
	_check(gift.evolved and gs.evolutions == 1, "evolution applied and counted")

	# --- Chests never offer evolutions.
	var cane_card: Resource = load("res://resources/upgrades/weapon_candy_cane_orbit.tres")
	gs.loadout.assign(["gift_toss", "candy_cane_orbit", "jingle_pulse"])
	player.apply_upgrade(cane_card)
	var cane: Node = player.find_weapon(cane_card.weapon_scene)
	cane.level = 5
	gs.add_chest()
	_check(menu._choices.all(func(c: Dictionary) -> bool: return c["card"]["tag"].begins_with("ITEM")), "chests offer items only")
	menu.buttons[0].pressed.emit()

	# --- Level-up pool: only loadout weapons, banish removes a card, rerolls run out.
	gs.loadout.assign(["gift_toss", "candy_cane_orbit", "snowball_barrage"])
	var pool: Array = menu.level_up_pool()
	var names: Array = pool.map(func(u: Resource) -> String: return u.title)
	_check("Snowball Barrage" in names, "loadout weapon offered")
	_check("Jingle Pulse" not in names and "Ornament Mines" not in names, "weapons outside the loadout never offered: %s" % [names])
	_check("Gift Toss" not in names and "Candy Cane Orbit" not in names, "Lv 5 weapons stop appearing")
	gs.pending_level_ups += 1
	gs.leveled_up.emit(gs.level)
	_check(menu.visible and menu.tools.visible, "level-up shows reroll/banish")
	var rerolls: int = gs.rerolls
	menu._reroll()
	menu._reroll()
	menu._reroll()
	_check(gs.rerolls == 0 and rerolls == 2, "two rerolls, then none")
	menu.banish_button.button_pressed = true
	var banished: Resource = menu._choices[0]["upgrade"]
	menu.buttons[0].pressed.emit()
	_check(banished in gs.banished and gs.banishes == 0, "banish spends the charge")
	_check(banished not in menu.level_up_pool(), "a banished card leaves the pool")
	_check(menu.visible, "the level-up stays open after banishing")
	menu.buttons[0].pressed.emit()
	_check(not menu.visible, "then a pick closes it")

	# --- Blizzard event: slows critters and shrinks reach while it blows, then restores both exactly.
	var reach_before: float = player.pickup_bonus
	gs.run_time = 165.5
	await _frames(int(3.0 * 60))
	_check(is_equal_approx(gs.enemy_speed_mult, 0.65), "blizzard slows critters 35%% (%.2f)" % gs.enemy_speed_mult)
	_check(is_equal_approx(player.pickup_bonus, reach_before - 0.3), "blizzard shrinks pickup reach")
	gs.run_time = 186.0
	await _frames(int(3.0 * 60))
	_check(is_equal_approx(gs.enemy_speed_mult, 1.0) and is_equal_approx(player.pickup_bonus, reach_before),
		"after the blizzard everything is back")

	# --- Demo code: typing "hohoho" mid-run unlocks everything, maxes the loadout and readies Santa.
	var demo: Node = root.get_node("DemoCode")
	var profile: Node = root.get_node("Profile")
	gs.santa_ready = false
	for letter in "xhohoho":  # a stray key first: the code still matches on its last letters
		var key := InputEventKey.new()
		key.pressed = true
		key.unicode = letter.unicode_at(0)
		demo._input(key)
	_check(gs.loadout.all(func(id: String) -> bool: return player.upgrade_level(profile.weapon_card(id)) == 5),
		"demo code: every loadout weapon at Lv 5")
	_check(gs.santa_ready, "demo code: Santa ready")
	_check(profile.coins() >= 99999 and profile.is_unlocked("gingerbread_boomerang")
		and profile.owns_cosmetic(profile.cosmetic("skin_golden")) and profile.has_achievement("not_a_scratch"),
		"demo code: coins, weapons, cosmetics and achievements unlocked")

	dummy.free()
	print("santa tests: %d failed" % _failures)
	quit(1 if _failures > 0 else 0)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		push_error("FAIL: " + what)
