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
	root.get_node("GameState").player = player  # the tree isn't live in _initialize, so _enter_tree didn't run
	player.apply_upgrade(atk, 1.5)
	player.apply_upgrade(atk, 1.0)
	_check(is_equal_approx(player.attack_speed_bonus, 0.375), "rarity scales the bonus and picks add up")
	_check(player.upgrade_level(atk) == 2, "levels are counted per upgrade")
	player.apply_upgrade(proj, 2.0)
	_check(player.extra_projectiles == 1, "projectiles ignore rarity")

	# Weapon cards add a weapon, then level it.
	var cane_card: Resource = load("res://resources/upgrades/weapon_candy_cane_orbit.tres")
	_check(player.upgrade_level(cane_card) == 0, "weapon not owned yet")
	player.apply_upgrade(cane_card)
	player.apply_upgrade(cane_card)
	_check(player.upgrade_level(cane_card) == 2, "weapon card adds then levels the weapon")

	# Items stack; evolution needs weapon Lv 5 + its item.
	var sack: Resource = load("res://resources/items/santas_sack.tres")
	var gift_card: Resource = load("res://resources/upgrades/weapon_gift_toss.tres")
	for i in 4:
		player.apply_upgrade(gift_card)
	_check(player.evolvable_weapons().is_empty(), "no evolution without the item")
	player.add_item(sack)
	_check(player.evolvable_weapons().size() == 1, "Gift Toss Lv 5 + Santa's Sack can evolve")
	var cracker: Resource = load("res://resources/items/christmas_cracker.tres")
	player.add_item(cracker)
	player.add_item(cracker)
	_check(is_equal_approx(player.explode_chance, 0.5), "item copies stack")

	player.free()
	print("upgrade tests: %d failed" % _failures)
	quit(1 if _failures > 0 else 0)


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		push_error("FAIL: " + what)
