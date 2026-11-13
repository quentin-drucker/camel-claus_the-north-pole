extends SceneTree
## Run: godot --headless --path . -s res://tests/test_profile.gd  (exit code 1 = failure)
## Meta-progression on a scratch save (user://test_profile.json; the real save is never touched):
## defaults, save/load round trip, old saves missing keys, corrupt saves, run payout, stats counted once,
## bests, achievements earned once with rewards, weapon unlock -> buy, Workshop prices and caps.

const TEST_SAVE: String = "user://test_profile.json"

var _failures: int = 0


func _initialize() -> void:
	var profile: Node = root.get_node("Profile")
	var gs: Node = root.get_node("GameState")
	profile.save_path = TEST_SAVE
	for path in [TEST_SAVE, TEST_SAVE + ".corrupt"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

	# Fresh profile.
	profile.load_profile()
	_check(profile.coins() == 0 and profile.loadout().size() == 3, "fresh profile: 0 coins, starter loadout")
	_check(not profile.is_unlocked("snowball_barrage"), "new weapons start locked")

	# A losing run at 2:30: payout, stats, combos.
	gs.start_run()
	gs.run_time = 150.0
	gs.kills = 300
	gs.elites_killed = 2
	gs.damage_dealt = 5000.0
	gs.won = false
	gs.is_running = false
	var summary: Dictionary = profile.record_run()
	var expected: int = 30 + 15 + 30  # kills/10 + seconds/10 + 2 elites
	_check(summary["coins"]["total"] == expected, "loss payout %d == %d" % [summary["coins"]["total"], expected])
	_check(profile.record_run().is_empty(), "a run is recorded only once")
	_check(profile.stat("runs") == 1 and profile.stat("kills") == 300 and profile.stat("deaths") == 1, "stats added once")
	var earned: Array = summary["achievements"].map(func(a: Resource) -> String: return a.id)
	_check("snow_day" in earned and "snowball_fight" in earned and "critter_control" in earned and "crown_collector" in earned,
		"first-run goals earned: %s" % [earned])
	var rewards: int = 20 + 25 + 30 + 30  # (Sweet Tooth needs 3:00; this run lasted 2:30)
	_check(profile.coins() == expected + rewards, "coins = payout + rewards (%d)" % profile.coins())
	_check(profile.check_achievements().is_empty(), "goals are earned only once")

	# Unlock -> buy.
	_check(profile.is_buyable("snowball_barrage") and profile.is_buyable("ornament_mines"), "goals make weapons buyable")
	var coins_before: int = profile.coins()
	_check(profile.buy_weapon("snowball_barrage"), "buy Snowball Barrage")
	_check(profile.is_unlocked("snowball_barrage") and profile.coins() == coins_before - 150, "bought for 150")
	_check(not profile.buy_weapon("snowball_barrage"), "can't buy twice")
	_check(not profile.buy_weapon("ornament_mines"), "not enough coins left")

	# Workshop: prices rise, levels cap, bonuses add up.
	var sweater: Resource = load("res://resources/workshop/cozy_sweater.tres")
	profile.data["coins"] = 10000
	var paid: int = 0
	for i in 7:
		var cost: int = profile.workshop_cost(sweater)
		if profile.buy_workshop(sweater):
			paid += cost
	_check(profile.workshop_level(sweater) == 5 and paid == 800, "Cozy Sweater caps at Lv 5 for 800 coins")
	_check(profile.workshop_bonus(0) == 50.0, "+50 max HP at Lv 5")
	_check(profile.has_achievement("workshop_regular"), "5 Workshop levels earn Workshop Regular")

	# A winning run: records, bests, combos.
	profile.data["loadout"] = ["gift_toss", "snowball_barrage", "jingle_pulse"]
	gs.start_run()
	gs.run_time = 300.0
	gs.kills = 1200
	gs.bosses_killed = 1
	gs.damage_dealt = 90000.0
	gs.evolutions = 2
	gs.won = true
	gs.is_running = false
	summary = profile.record_run()
	_check("kills" in summary["records"] and "time" in summary["records"], "new records: %s" % [summary["records"]])
	_check(profile.data["bests"]["kills"] == 1200, "best kills saved")
	_check(profile.stat("runs") == 2 and profile.stat("wins") == 1, "lifetime runs/wins")
	_check((profile.data["seen_combos"] as Array).size() == 2, "two loadouts seen")

	# Endless: the same run keeps going; its end records only the extra part.
	var stats_kills: float = profile.stat("kills")
	gs.continue_endless()
	_check(gs.endless and gs.is_running and not gs.recorded, "Keep going continues the same run")
	gs.run_time = 500.0
	gs.kills = 1700
	gs.end_run(false)
	summary = profile.record_run()
	_check(summary["coins"]["total"] == 50 + 20, "Endless pays only the extra part, no 2nd win bonus (%d)" % summary["coins"]["total"])
	_check(profile.stat("runs") == 2 and profile.stat("kills") == stats_kills + 500, "the continuation isn't a new run")
	_check("endless" in summary["records"] and profile.data["bests"]["endless"] == 500, "Longest Endless run saved")
	_check(profile.has_achievement("endless_night"), "8:00 earns Endless Night")

	# Cosmetics: free pieces owned, buy -> wear -> color, stale looks fall back, default look.
	var frosty: Resource = profile.cosmetic("skin_frosty")
	var elf: Resource = profile.cosmetic("hat_elf")
	_check(profile.owns_cosmetic(profile.cosmetic("hat_beanie")) and not profile.owns_cosmetic(frosty), "free pieces owned, paid ones not")
	profile.equip(frosty)
	_check(profile.equipped(0).id == "skin_classic", "can't wear what you don't own")
	profile.data["coins"] = 500
	_check(profile.buy_cosmetic(frosty) and profile.coins() == 380, "buy Frosty for 120")
	_check(not profile.buy_cosmetic(frosty), "can't buy twice")
	profile.equip(frosty)
	profile.buy_cosmetic(elf)
	profile.equip(elf)
	_check(profile.equipped(0) == frosty and profile.equipped(1) == elf, "wearing Frosty + elf hat")
	_check(not profile.data["look"].has("hat_color"), "pieces keep their own colors (no recolor saved)")
	profile.data["look"]["hat"] = "hat_unknown"
	profile.save()
	profile.load_profile()
	_check(profile.equipped(1).id == "hat_santa" and profile.equipped(0) == frosty, "a stale look falls back per slot, the rest survives a reload")
	profile.reset_look()
	_check(profile.equipped(0).id == "skin_classic" and profile.owns_cosmetic(frosty), "Default look keeps what you bought")

	# Save -> load round trip.
	# JSON stores every number as a float, so compare both sides after a JSON round trip.
	var snapshot: String = JSON.stringify(JSON.parse_string(JSON.stringify(profile.data)))
	profile.load_profile()
	_check(JSON.stringify(JSON.parse_string(JSON.stringify(profile.data))) == snapshot, "save/load keeps everything")

	# An old save missing keys and holding a removed weapon still loads.
	var old := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	old.store_string('{"version": 1, "coins": 42, "loadout": ["gift_toss", "laser_reindeer"], "starter": "laser_reindeer"}')
	old.close()
	profile.load_profile()
	_check(profile.coins() == 42 and profile.loadout() == ["gift_toss"] and profile.starter() == "gift_toss",
		"old save: missing keys filled, unknown weapon dropped")
	_check(profile.data["achievements"] is Dictionary and profile.data["stats"] is Dictionary, "old save: defaults for new fields")

	# A corrupt save is kept aside and the game starts fresh.
	var bad := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	bad.store_string("{not json")
	bad.close()
	profile.load_profile()
	_check(profile.coins() == 0 and FileAccess.file_exists(TEST_SAVE + ".corrupt"), "corrupt save kept aside, fresh start")

	for path in [TEST_SAVE, TEST_SAVE + ".corrupt"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	print("profile tests: %d failed" % _failures)
	quit(1 if _failures > 0 else 0)


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		push_error("FAIL: " + what)
