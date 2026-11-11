extends SceneTree
## Balance bot: plays one full run of main.tscn and prints progression every 30 s.
## Run: godot --headless --fixed-fps 60 --path . -s res://tests/balance_sim.gd -- seed=1 mode=collect
##   mode=collect  walks to the nearest XP while dodging nearby enemies (an average player);
##   mode=kite  circles the arena ignoring XP;  mode=idle  stands still (worst case).
## Picks a random card at each level-up, like an average player. Exit code 0 always: it's a report.

var _gs: Node
var _mode: String = "collect"
var _angle: float = 0.0
var _next_log: float = 30.0
var _level_times: Array[float] = []
var _min_hp_pct: float = 100.0
var _boss_seen: float = -1.0
var _boss_killed: float = -1.0


func _initialize() -> void:
	var args: Dictionary = {}
	for arg in OS.get_cmdline_user_args():
		var kv: PackedStringArray = arg.split("=")
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	seed(int(args.get("seed", "1")))
	_mode = args.get("mode", "collect")
	_gs = root.get_node("GameState")
	_gs.leveled_up.connect(func(_l: int) -> void: _level_times.append(_gs.run_time))
	change_scene_to_file("res://scenes/main/main.tscn")


func _process(delta: float) -> bool:
	if current_scene == null or _gs.player == null:
		return false
	if not _gs.is_running:
		_report_end()
		return true
	var menu: Node = current_scene.get_node("LevelUpMenu")
	if menu.visible:
		var visible_buttons: Array = menu.buttons.filter(func(b: Button) -> bool: return b.visible)
		visible_buttons.pick_random().pressed.emit()
		return false
	_angle += delta * 0.35
	if _mode == "kite":
		_steer(Vector2(cos(_angle), sin(_angle)))
	elif _mode == "collect":
		_steer(_collect_direction())
	if _gs.boss != null and _boss_seen < 0.0:
		_boss_seen = _gs.run_time
	if _boss_seen >= 0.0 and _gs.boss == null and _boss_killed < 0.0:
		_boss_killed = _gs.run_time
	_min_hp_pct = minf(_min_hp_pct, _gs.player.hp / _gs.player.max_hp * 100.0)
	if _gs.run_time >= _next_log:
		_next_log += 30.0
		_log_line()
	return false


func _collect_direction() -> Vector2:
	var pos: Vector3 = _gs.player.global_position
	var dir := Vector2(cos(_angle), sin(_angle)) * 0.3  # wander when there's nothing to grab
	var nearest_sq: float = 15.0 * 15.0
	for chest: Node3D in get_nodes_in_group(&"chests"):  # chests beat XP
		if pos.distance_squared_to(chest.global_position) < 25.0 * 25.0:
			nearest_sq = -1.0
			dir = Vector2(chest.global_position.x - pos.x, chest.global_position.z - pos.z).normalized()
	for orb: Node3D in get_nodes_in_group(&"xp_ornaments"):
		var d_sq: float = pos.distance_squared_to(orb.global_position)
		if nearest_sq >= 0.0 and d_sq < nearest_sq:
			nearest_sq = d_sq
			dir = Vector2(orb.global_position.x - pos.x, orb.global_position.z - pos.z).normalized()
	for enemy: Node3D in _gs.enemies:
		var away := Vector2(pos.x - enemy.global_position.x, pos.z - enemy.global_position.z)
		var d: float = away.length()
		if d < 4.0 and d > 0.01:
			dir += away / d * (4.0 - d) * 0.8
	dir -= Vector2(pos.x, pos.z) / 45.0 * maxf(Vector2(pos.x, pos.z).length() - 40.0, 0.0) / 5.0  # stay off walls
	return dir.normalized()


func _steer(dir: Vector2) -> void:
	Input.action_press("move_right", maxf(dir.x, 0.0))
	Input.action_press("move_left", maxf(-dir.x, 0.0))
	Input.action_press("move_down", maxf(dir.y, 0.0))
	Input.action_press("move_up", maxf(-dir.y, 0.0))


func _log_line() -> void:
	var p: Node = _gs.player  # untyped: -s scripts compile before autoloads exist
	print("%5.0fs  Lv %2d  HP %3.0f/%3.0f  enemies %3d  kills %4d  dmg x%.1f  atk +%3.0f%%  proj +%d  pos (%.0f, %.0f)" % [
		_gs.run_time, _gs.level, p.hp, p.max_hp, _gs.enemies.size(), _gs.kills,
		p.damage_mult, p.attack_speed_bonus * 100.0, p.extra_projectiles, p.position.x, p.position.z,
	])


func _report_end() -> void:
	_log_line()
	var p: Node = _gs.player
	var gear: PackedStringArray = []
	for w in p.weapons():
		gear.append("%s Lv%d" % [w.title(), w.level])
	for item in p.items:
		gear.append("%s x%d" % [item.title, p.items[item]])
	print("GEAR " + ", ".join(gear))
	print("BOSS %s" % ("not reached" if _boss_seen < 0.0 else
		("killed in %.0fs" % (_boss_killed - _boss_seen) if _boss_killed >= 0.0 else "survived the run")))
	var per_minute: Array[int] = [0, 0, 0, 0, 0]
	for t in _level_times:
		per_minute[mini(int(t / 60.0), 4)] += 1
	print("RESULT %s at %.0fs · level %d · %d level-ups (per minute: %s) · %d kills · lowest HP %.0f%%" % [
		"WIN" if _gs.run_time >= _gs.RUN_LENGTH else "DIED", _gs.run_time, _gs.level,
		_level_times.size(), per_minute, _gs.kills, _min_hp_pct,
	])
