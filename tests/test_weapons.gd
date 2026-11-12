extends SceneTree
## Run: godot --headless --fixed-fps 60 --path . -s res://tests/test_weapons.gd  (exit code 1 = failure)
## Every weapon really fires: alone with a ring of tough, still enemies (the spawner is off), each
## weapon at Lv 1 and then evolved must deal damage, and the evolved form must deal more in the same
## time. Also checks the ground pickups and that the Snowball Lobber's throw hits a still Claus and
## misses a moving one. Loads scripts at runtime: -s scripts compile before autoloads exist.

const WEAPONS: Array[String] = [
	"res://scenes/weapons/gift_toss.tscn",
	"res://scenes/weapons/candy_cane_orbit.tscn",
	"res://scenes/weapons/jingle_pulse.tscn",
	"res://scenes/weapons/snowball_barrage.tscn",
	"res://scenes/weapons/ornament_mines.tscn",
	"res://scenes/weapons/gingerbread_boomerang.tscn",
]

var _failures: int = 0
var _started: bool = false
var _gs: Node
var _player: Node
var _main: Node


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
	_main = current_scene
	_gs = root.get_node("GameState")
	_player = _gs.player
	_main.get_node("EnemySpawner").set_process(false)  # no spawns, no movement, no contact damage
	_main.get_node("LevelUpMenu").free()  # level-ups would pause the tree mid-test
	for w in _player.weapons():
		w.free()

	for path in WEAPONS:
		var normal: float = await _damage_in(path, false, 4.0)
		var evolved: float = await _damage_in(path, true, 4.0)
		var name: String = path.get_file().get_basename()
		_check(normal > 0.0, "%s Lv 1 deals damage (%.0f)" % [name, normal])
		_check(evolved > normal, "%s evolved deals more than Lv 1 (%.0f > %.0f)" % [name, evolved, normal])
		print("%-18s Lv1 %6.0f   evolved %6.0f  (4 s, 14 still targets)" % [name, normal, evolved])

	await _test_pickups()
	await _test_lobber()
	print("weapon tests: %d failed" % _failures)
	quit(1 if _failures > 0 else 0)


## Damage one weapon deals in `seconds` to a fresh ring of tough enemies around Claus.
func _damage_in(path: String, evolved: bool, seconds: float) -> float:
	_clear_world()
	var targets: Array = []
	for i in 14:
		var ring: float = [0.6, 2.0, 3.0, 5.0, 8.0][i % 5]
		targets.append(_enemy(Vector3(cos(i * 0.9), 0.0, sin(i * 0.9)) * ring, 1000.0))
	var weapon: Node = load(path).instantiate()
	_player.add_child(weapon)
	if evolved:
		weapon.level = 5
		weapon.evolve()
	await _frames(int(seconds * 60.0))
	var dealt: float = 0.0
	for e in targets:
		if is_instance_valid(e):
			dealt += e.max_hp - e.hp
	weapon.free()
	return dealt


func _test_pickups() -> void:
	_clear_world()
	var pickup_script: GDScript = load("res://scenes/pickups/pickup.gd")
	var drops: Array = pickup_script.DROPS
	# Magnet: every XP ornament on the map ends up collected.
	var orb_scene: PackedScene = load("res://scenes/pickups/xp_ornament.tscn")
	for i in 20:
		var orb: Node3D = orb_scene.instantiate()
		_main.add_child(orb)
		orb.global_position = Vector3(cos(i) * 25.0, 0.0, sin(i) * 25.0)
	var xp_before: int = _gs.xp + _gs.level * 1000
	_drop(drops[0], Vector3(0.3, 0, 0))
	await _frames(120)
	_check(get_nodes_in_group(&"xp_ornaments").is_empty(), "magnet pulls in every XP ornament")
	_check(_gs.xp + _gs.level * 1000 > xp_before, "magnet XP is collected")
	# Cookies wait while HP is full, then heal.
	_player.hp = _player.max_hp
	_drop(drops[1], Vector3(0.3, 0, 0))
	await _frames(10)
	_check(get_nodes_in_group(&"pickups").size() == 1, "cookies stay on the ground at full HP")
	_player.hp = _player.max_hp * 0.5
	await _frames(10)
	_check(_player.hp > _player.max_hp * 0.5, "cookies heal when hurt")
	# Snow bomb pops normal enemies nearby, chips an elite, leaves far ones.
	_clear_world()
	var near: Node = _enemy(Vector3(3, 0, 0), 1.0)
	var far: Node = _enemy(Vector3(15, 0, 0), 1.0)
	var elite: Node = _enemy(Vector3(0, 0, 3), 15.0, true)
	_drop(drops[2], Vector3(0.3, 0, 0))
	await _frames(5)
	_check(not is_instance_valid(near) or near.hp <= 0.0, "snow bomb pops a nearby enemy")
	_check(is_instance_valid(far) and far.hp == far.max_hp, "snow bomb leaves far enemies alone")
	_check(is_instance_valid(elite) and elite.hp < elite.max_hp and elite.hp > 0.0, "snow bomb chips an elite")


func _test_lobber() -> void:
	var lobber_data: Resource = load("res://resources/enemies/lobber.tres")
	# Standing still: the snowball lands on Claus.
	_clear_world()
	_player.invincible = false
	_player.global_position = Vector3.ZERO
	_player.hp = _player.max_hp
	_enemy(Vector3(7, 0, 0), 100.0, false, lobber_data)
	await _frames(int(6.0 * 60.0))
	_check(_player.hp < _player.max_hp, "a lobbed snowball hits a Claus who stands still")
	# Walking away once the ring shows: it misses.
	_clear_world()
	_player.invincible = false
	await _frames(60)  # let the hurt invulnerability run out
	_player.hp = _player.max_hp
	_enemy(Vector3(7, 0, 0), 100.0, false, lobber_data)
	# A freed node compares equal to null in Godot 4, so track "seen" with a flag, not `ball == null`.
	var seen: bool = false
	var ball: Node = null
	for f in int(6.0 * 60.0):
		await process_frame
		if not seen and not get_nodes_in_group(&"enemy_snowballs").is_empty():
			seen = true
			ball = get_nodes_in_group(&"enemy_snowballs")[0]
			_player.global_position = Vector3(0, 0, -3)
		if seen and not is_instance_valid(ball):
			break  # judge only the dodged ball: a later throw aims at the new spot
	_check(seen, "the lobber threw within 6 s")
	_check(_player.hp == _player.max_hp, "stepping out of the purple ring dodges the snowball")


func _enemy(pos: Vector3, hp_mult: float, elite: bool = false, type: Resource = null) -> Node:
	var enemy: Node = load("res://scenes/enemies/enemy.tscn").instantiate()
	enemy.setup(type if type else load("res://resources/enemies/chaser.tres"), hp_mult, 1.6 if elite else 1.0, elite)
	_main.get_node("EnemySpawner").add_child(enemy)
	enemy.global_position = pos
	return enemy


func _drop(data: Resource, pos: Vector3) -> void:
	var pickup: Node3D = load("res://scenes/pickups/pickup.tscn").instantiate()
	pickup.data = data
	_main.add_child(pickup)
	pickup.global_position = pos


## Free enemies, projectiles, mines, drops and pickups from the last check.
func _clear_world() -> void:
	for e in _gs.enemies.duplicate():
		e.free()
	for node in _main.get_children():
		if node.get_script() and node.get_script().get_global_name() in [
				&"GiftProjectile", &"SnowballShell", &"OrnamentMine", &"XpOrnament", &"Pickup", &"Chest"]:
			node.free()
	for node in _main.get_node("EnemySpawner").get_children():
		node.free()
	_player.global_position = Vector3.ZERO
	_player.invincible = true


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		push_error("FAIL: " + what)
