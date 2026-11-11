extends SceneTree
## Run: godot --headless --path . -s res://tests/test_upgrades.gd  (exit code 1 = failure)
## Loads project scripts at runtime (not as types): -s scripts compile before autoloads exist.

var _failures: int = 0


func _initialize() -> void:
	var atk: Resource = load("res://resources/upgrades/faster_wrapping.tres")
	var proj: Resource = load("res://resources/upgrades/double_gift.tres")
	_check(atk.describe(1.0) == "+15% attack speed (all weapons)", "common card text: " + atk.describe(1.0))
	_check(atk.describe(1.5) == "+22.5% attack speed (all weapons)", "rare card text: " + atk.describe(1.5))

	var player: Node = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(player)
	player.apply_upgrade(atk, 1.5)
	player.apply_upgrade(atk, 1.0)
	_check(is_equal_approx(player.attack_speed_bonus, 0.375), "rarity scales the bonus and picks add up")
	_check(player.upgrade_level(atk) == 2, "levels are counted per upgrade")
	player.apply_upgrade(proj, 2.0)
	_check(player.extra_projectiles == 1, "projectiles ignore rarity")

	player.free()
	print("upgrade tests: %d failed" % _failures)
	quit(1 if _failures > 0 else 0)


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		push_error("FAIL: " + what)
