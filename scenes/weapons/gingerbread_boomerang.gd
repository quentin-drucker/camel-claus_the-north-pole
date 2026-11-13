class_name GingerbreadBoomerang
extends Weapon
## Every cooldown(), throws count() gingerbread men in a fan toward the nearest enemy; each flies
## radius() metres out and comes back to Claus (Gingerbread), hitting everything both ways. Rewards
## moving: step sideways while they return and they sweep a fresh line of critters.
## Evolved (Gingerbread Rampage): +2 cookies, bigger (x`evolved_size` hitbox), further, crumb trails.

const COOKIE: PackedScene = preload("res://scenes/weapons/gingerbread.tscn")

## Only throws when an enemy is this close (x the throw distance).
@export var notice_range: float = 1.6
@export var fan: float = 0.45
@export var evolved_size: float = 1.6

var _cooldown_left: float = 0.5


func _init() -> void:
	data = preload("res://resources/weapons/gingerbread_boomerang.tres")


func _process(delta: float) -> void:
	_cooldown_left -= delta
	if _cooldown_left > 0.0:
		return
	var origin: Vector3 = global_position
	var reach: float = radius()
	var nearest: Enemy = null
	var best: float = (reach * notice_range) ** 2
	for enemy in GameState.enemies:
		var d: float = origin.distance_squared_to(enemy.global_position)
		if d < best:
			best = d
			nearest = enemy
	if nearest == null:
		return
	_cooldown_left = cooldown()
	var aim: Vector3 = nearest.global_position - origin
	aim.y = 0.0
	aim = aim.normalized()
	var n: int = count()
	Audio.play(&"throw", 0.7)
	for i in n:
		var cookie: Gingerbread = COOKIE.instantiate()
		cookie.direction = aim.rotated(Vector3.UP, (i - (n - 1) * 0.5) * fan)
		cookie.out_distance = reach
		cookie.damage = damage()
		cookie.source = data.display_name
		cookie.size = evolved_size if evolved else 1.0
		cookie.crumbs = evolved
		cookie.position = origin + Vector3.UP * 0.6  # before add_child: _ready() remembers the start
		get_tree().current_scene.add_child(cookie)
