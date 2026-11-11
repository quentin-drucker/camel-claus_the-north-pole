extends SceneTree
## Run: godot --headless --path . -s res://tests/test_game_state.gd  (exit code 1 = failure)


func _initialize() -> void:
	var gs: Node = load("res://scripts/game_state.gd").new()
	gs.start_run()
	var level_ups: Array[int] = []
	gs.leveled_up.connect(func(l: int) -> void: level_ups.append(l))

	gs.add_xp(4)
	_check(gs.level == 1 and gs.xp == 4, "4 xp stays level 1")
	gs.add_xp(1)
	_check(gs.level == 2 and gs.xp == 0 and gs.pending_level_ups == 1, "5 xp reaches level 2")
	gs.add_xp(9 + 13 + 2)  # level 2 needs 9, level 3 needs 13
	_check(gs.level == 4 and gs.xp == 2 and gs.pending_level_ups == 3, "one big grab gives two levels")
	_check(level_ups == [2, 3, 4], "leveled_up emitted once per level")

	gs.end_run(false)
	gs.end_run(true)
	_check(not gs.is_running, "end_run only ends once")
	gs.free()
	print("game_state tests: %d failed" % _failures)
	quit(1 if _failures > 0 else 0)


var _failures: int = 0


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		push_error("FAIL: " + what)
