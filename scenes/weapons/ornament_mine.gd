class_name OrnamentMine
extends Node3D
## One ornament mine (see OrnamentMines). Pops up out of the snow, arms after `arm_time`, blinks
## while armed, and explodes when an enemy comes within `trigger_radius` (or when its fuse runs out).

@export var arm_time: float = 0.35
@export var trigger_radius: float = 1.3
## Seconds before an untouched mine goes off by itself (keeps the cap cycling).
@export var fuse: float = 14.0

## The weapon that dropped it (damage, radius and evolution are read live).
var weapon: OrnamentMines
var exploded: bool = false

var _age: float = 0.0

@onready var body: Node3D = $Body


func _process(delta: float) -> void:
	if exploded:
		return
	_age += delta
	# Pop out of the snow, then a slow bob + a quick blink once armed.
	body.scale = Vector3.ONE * minf(_age / arm_time, 1.0)
	body.rotate_y(1.5 * delta)
	if _age < arm_time:
		return
	body.position.y = 0.05 + absf(sin(_age * 3.0)) * 0.06
	var blink: bool = fmod(_age, 0.8) < 0.1
	body.scale = Vector3.ONE * (1.15 if blink else 1.0)
	if _age > fuse or not is_instance_valid(weapon):
		explode()
		return
	var pos: Vector3 = global_position
	for enemy in GameState.enemies:
		var e_pos: Vector3 = enemy.global_position
		var reach: float = trigger_radius + enemy.radius
		if Vector2(pos.x - e_pos.x, pos.z - e_pos.z).length_squared() < reach * reach:
			explode()
			return


## Blow up now, or after `delay` seconds (chain reactions ripple outward).
func explode(delay: float = 0.0) -> void:
	if exploded:
		return
	exploded = true
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout
	if not is_instance_valid(weapon):
		queue_free()
		return
	var pos: Vector3 = global_position
	var reach: float = weapon.radius()
	var dmg: float = weapon.damage()
	_blast(pos, reach, dmg)
	Burst.spawn(Burst.RED, pos, reach)
	Poof.spawn(pos, Color("3E9A5B"), 10, 4.0)
	Audio.play(&"explode", randf_range(1.1, 1.3))
	get_tree().call_group(&"camera", &"shake", 0.08)
	if weapon.evolved:
		weapon.chain_from(self)
		hide()
		await get_tree().create_timer(0.18, false).timeout
		if is_instance_valid(weapon):
			_blast(pos, reach * 1.6, dmg * 0.5)
			Burst.spawn(Burst.GOLD, pos, reach * 1.6)
	queue_free()


func _blast(pos: Vector3, reach: float, dmg: float) -> void:
	for enemy: Enemy in GameState.enemies.duplicate():
		var e_pos: Vector3 = enemy.global_position
		var r: float = reach + enemy.radius
		if Vector2(pos.x - e_pos.x, pos.z - e_pos.z).length_squared() < r * r:
			GameState.player.deal_damage(enemy, dmg, true, weapon.data.display_name)
