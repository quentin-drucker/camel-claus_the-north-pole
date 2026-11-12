extends SceneTree
## Balance bot: plays one full run of main.tscn and prints progression every 30 s.
## Run: godot --headless --fixed-fps 60 --path . -s res://tests/balance_sim.gd -- seed=1 mode=collect
##   mode=collect  walks to the nearest XP while dodging nearby enemies, picks random cards and calls
##                 Santa as soon as the meter is full (an average player);
##   mode=focus    moves like collect but builds on purpose: weapon upgrades first, then damage /
##                 attack speed, evolutions over blessings, and saves a full Santa meter while a weapon
##                 is Lv 4+ so the present can evolve it (a player who knows the game);
##   mode=kite  circles the arena ignoring XP;  mode=idle  stands still (worst case).
##   endless=1  keeps going after a win (Endless mode) until Claus faints.
##   loadout=gift_toss,snowball_barrage,ornament_mines starter=gift_toss  (default: the saved profile;
##   set in memory only, the save file is never written).
## Exit code 0 always: it's a report.

var _gs: Node
var _mode: String = "collect"
var _angle: float = 0.0
var _next_log: float = 30.0
var _level_times: Array[float] = []
var _min_hp_pct: float = 100.0
var _boss_seen: float = -1.0
var _boss_killed: float = -1.0
var _first_evolution: float = -1.0
var _args: Dictionary = {}
var _loaded: bool = false


func _initialize() -> void:
	# Never touch the player's real save: the results screen records every run.
	root.get_node("Profile").save_path = "user://test_scratch_profile.json"
	if FileAccess.file_exists("user://test_scratch_profile.json"):
		DirAccess.remove_absolute("user://test_scratch_profile.json")
	var args: Dictionary = {}
	for arg in OS.get_cmdline_user_args():
		var kv: PackedStringArray = arg.split("=")
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	seed(int(args.get("seed", "1")))
	_mode = args.get("mode", "collect")
	_args = args
	_gs = root.get_node("GameState")
	_gs.weapon_evolved.connect(func(_w: Node) -> void:
		if _first_evolution < 0.0:
			_first_evolution = _gs.run_time)
	_gs.leveled_up.connect(func(_l: int) -> void: _level_times.append(_gs.run_time))


func _process(delta: float) -> bool:
	if not _loaded:  # first frame: Profile._ready() has loaded the save by now, so override it here
		_loaded = true
		if _args.has("loadout"):
			var profile: Node = root.get_node("Profile")
			var ids: Array = Array(_args["loadout"].split(","))
			profile.data["unlocked"] = profile.weapon_ids()
			profile.data["loadout"] = ids
			profile.data["starter"] = _args.get("starter", ids[0])
		change_scene_to_file("res://scenes/main/main.tscn")
		return false
	if current_scene == null or _gs.player == null:
		return false
	if not _gs.is_running:
		if _args.get("endless", "0") == "1" and _gs.won and not _gs.endless:
			_log_line()
			print("ENDLESS continuing after the win")
			current_scene.get_node("EndScreen").continue_endless()
			return false
		_report_end()
		return true
	var menu: Node = current_scene.get_node("LevelUpMenu")
	if menu.visible:
		var visible_buttons: Array = menu.buttons.filter(func(b: Button) -> bool: return b.visible)
		if _mode == "focus":
			var pick: int = _best_choice(menu)
			if menu._kind == 1 and _gs.rerolls > 0 and menu._choices[pick]["card"]["tag"] not in ["WEAPON UPGRADE", "NEW WEAPON"]:
				menu._reroll()  # no weapon card: a player who knows the game rerolls
				return false
			visible_buttons[pick].pressed.emit()
		else:
			visible_buttons.pick_random().pressed.emit()
		return false
	if _gs.santa_ready and (_mode != "focus" or not _saving_for_evolution()):
		_gs.call_santa()
	_angle += delta * 0.35
	if _mode == "kite":
		_steer(Vector2(cos(_angle), sin(_angle)))
	elif _mode == "collect" or _mode == "focus":
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


## Focus picks: evolution > weapon upgrade > new weapon > damage > attack speed > projectiles > rest.
func _best_choice(menu: Node) -> int:
	var rank: Dictionary = {"EVOLUTION": 0, "WEAPON UPGRADE": 1, "NEW WEAPON": 2}
	var stat_rank: Dictionary = {"Heavier Gifts": 3, "Faster Wrapping": 4, "Double Gift": 5}
	var best: int = 0
	var best_score: int = 99
	for i in menu._choices.size():
		var card: Dictionary = menu._choices[i]["card"]
		var score: int = rank.get(card["tag"], stat_rank.get(card["name"], 9))
		if score < best_score:
			best_score = score
			best = i
	return best


func _saving_for_evolution() -> bool:
	for w in _gs.player.weapons():
		if w.level >= 4 and not w.evolved:
			return w.level < 5  # hold at Lv 4; at Lv 5 call (the present evolves it)
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
	for ring: Node3D in get_nodes_in_group(&"enemy_snowballs"):  # a player steps out of purple rings
		var away := Vector2(pos.x - ring.global_position.x, pos.z - ring.global_position.z)
		var d: float = away.length()
		if d < 2.2:
			dir += (away / maxf(d, 0.01) if d > 0.05 else Vector2(cos(_angle), sin(_angle))) * 3.0
	dir -= Vector2(pos.x, pos.z) / 45.0 * maxf(Vector2(pos.x, pos.z).length() - 40.0, 0.0) / 5.0  # stay off walls
	return dir.normalized()


func _steer(dir: Vector2) -> void:
	Input.action_press("move_right", maxf(dir.x, 0.0))
	Input.action_press("move_left", maxf(-dir.x, 0.0))
	Input.action_press("move_down", maxf(dir.y, 0.0))
	Input.action_press("move_up", maxf(-dir.y, 0.0))


func _log_line() -> void:
	var p: Node = _gs.player  # untyped: -s scripts compile before autoloads exist
	print("%5.0fs  lobs %3d  Lv %2d  HP %3.0f/%3.0f  enemies %3d  kills %4d  dmg x%.1f  atk +%3.0f%%  proj +%d  pos (%.0f, %.0f)" % [
		_gs.run_time, load("res://scenes/enemies/enemy_snowball.gd").launched, _gs.level, p.hp, p.max_hp, _gs.enemies.size(), _gs.kills,
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
	var lobber_kills: int = 0
	print("LOBBERS %d snowballs thrown" % load("res://scenes/enemies/enemy_snowball.gd").launched)
	print("SANTA %d calls · evolutions %d (first at %s) · rerolls left %d" % [_gs.santa_calls, _gs.evolutions,
		"%.0fs" % _first_evolution if _first_evolution >= 0.0 else "never", _gs.rerolls])
	print("BOSS %s" % ("not reached" if _boss_seen < 0.0 else
		("killed in %.0fs" % (_boss_killed - _boss_seen) if _boss_killed >= 0.0 else "survived the run")))
	var per_minute: Array[int] = [0, 0, 0, 0, 0]
	for t in _level_times:
		per_minute[mini(int(t / 60.0), 4)] += 1
	print("RESULT %s at %.0fs · level %d · %d level-ups (per minute: %s) · %d kills · lowest HP %.0f%%" % [
		"WIN" if _gs.run_time >= _gs.RUN_LENGTH else "DIED", _gs.run_time, _gs.level,
		_level_times.size(), per_minute, _gs.kills, _min_hp_pct,
	])
