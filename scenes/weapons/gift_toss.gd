class_name GiftToss
extends Node3D
## Auto-fires gifts at the nearest enemies in range. Scales with the player's global stats.

const PROJECTILE: PackedScene = preload("res://scenes/weapons/gift_projectile.tscn")

@export var data: WeaponData = preload("res://resources/weapons/gift_toss.tres")

var _cooldown_left: float = 0.0


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
	var player: Player = GameState.player
	# Attack speed is a percentage: +100% = twice as often. Linear, so no runaway like flat -0.12 s.
	_cooldown_left = data.cooldown / (1.0 + player.attack_speed_bonus)
	for i in mini(data.projectile_count + player.extra_projectiles, targets.size()):
		_fire_at(targets[i], data.damage * player.damage_mult)


func _fire_at(target: Enemy, damage: float) -> void:
	var projectile: GiftProjectile = PROJECTILE.instantiate()
	var aim: Vector3 = target.global_position - global_position
	aim.y = 0.0
	projectile.direction = aim.normalized()
	projectile.speed = data.projectile_speed
	projectile.damage = damage
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + Vector3.UP * 0.6
