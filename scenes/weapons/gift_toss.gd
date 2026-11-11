class_name GiftToss
extends Node3D
## Auto-fires gifts at the nearest enemies in range.

const PROJECTILE: PackedScene = preload("res://scenes/weapons/gift_projectile.tscn")

@export var data: WeaponData = preload("res://resources/weapons/gift_toss.tres")

var _cooldown_left: float = 0.0


func _ready() -> void:
	data = data.duplicate()  # upgrades change this run's copy, never the .tres


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
	_cooldown_left = data.cooldown
	for i in mini(data.projectile_count, targets.size()):
		_fire_at(targets[i])


func _fire_at(target: Enemy) -> void:
	var projectile: GiftProjectile = PROJECTILE.instantiate()
	var aim: Vector3 = target.global_position - global_position
	aim.y = 0.0
	projectile.direction = aim.normalized()
	projectile.speed = data.projectile_speed
	projectile.damage = data.damage
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + Vector3.UP * 0.6


func apply_upgrade(upgrade: UpgradeData) -> void:
	match upgrade.stat:
		UpgradeData.Stat.WEAPON_DAMAGE:
			data.damage += upgrade.amount
		UpgradeData.Stat.WEAPON_COOLDOWN:
			data.cooldown = maxf(data.cooldown - upgrade.amount, 0.15)
		UpgradeData.Stat.WEAPON_PROJECTILES:
			data.projectile_count += int(upgrade.amount)
