class_name GiftToss
extends Weapon
## Auto-fires gifts at the nearest enemies in range.
## Evolved (Present Barrage): +2 gifts per volley and each gift pierces 2 enemies.

const PROJECTILE: PackedScene = preload("res://scenes/weapons/gift_projectile.tscn")

var _cooldown_left: float = 0.0


func _init() -> void:
	data = preload("res://resources/weapons/gift_toss.tres")


func _process(delta: float) -> void:
	_cooldown_left -= delta
	if _cooldown_left > 0.0:
		return
	var origin: Vector3 = global_position
	var range_sq: float = data.attack_range * data.attack_range
	var targets: Array[Enemy] = GameState.enemies.filter(
		func(e: Enemy) -> bool: return origin.distance_squared_to(e.global_position) < range_sq
	)
	if targets.is_empty():
		return
	targets.sort_custom(
		func(a: Enemy, b: Enemy) -> bool:
			return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position)
	)
	_cooldown_left = cooldown()
	Audio.play(&"throw", 1.25 if evolved else 1.0)
	for i in count():
		_fire_at(targets[i % targets.size()], floori(float(i) / targets.size()))


func _fire_at(target: Enemy, fan_step: int) -> void:
	var projectile: GiftProjectile = PROJECTILE.instantiate()
	var aim: Vector3 = target.global_position - global_position
	aim.y = 0.0
	# More gifts than targets: fan the extras out instead of stacking them on one line.
	projectile.direction = aim.normalized().rotated(Vector3.UP, fan_step * 0.35)
	projectile.speed = data.projectile_speed
	projectile.damage = damage()
	projectile.source = data.display_name
	projectile.pierce = data.evolved_pierce if evolved else 0
	projectile.evolved = evolved
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + Vector3.UP * 0.6
