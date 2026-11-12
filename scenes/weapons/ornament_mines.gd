class_name OrnamentMines
extends Weapon
## Every cooldown(), drops a festive ornament where Claus stands (so they trail behind him as he
## walks), up to count() on the ground at once. A mine arms after a moment and blows up when an
## enemy comes close, hitting everything within radius().
## Evolved (Chain Reaction): a blast sets off every mine within `chain_range` x radius, and each
## blast throws a second, wider ring a beat later.

const MINE: PackedScene = preload("res://scenes/weapons/ornament_mine.tscn")

@export var chain_range: float = 2.2

var _cooldown_left: float = 0.3
var _mines: Array[OrnamentMine] = []


func _init() -> void:
	data = preload("res://resources/weapons/ornament_mines.tres")


func _process(delta: float) -> void:
	# A plain loop: freed mines can't be passed to a typed lambda.
	var live: Array[OrnamentMine] = []
	for mine in _mines:
		if is_instance_valid(mine) and not mine.exploded:
			live.append(mine)
	_mines = live
	_cooldown_left -= delta
	if _cooldown_left > 0.0 or _mines.size() >= count():
		return
	_cooldown_left = cooldown()
	var mine: OrnamentMine = MINE.instantiate()
	mine.weapon = self
	get_tree().current_scene.add_child(mine)
	# A step behind Claus (or to a random side when he stands still) so it isn't hidden under him.
	var velocity: Vector3 = GameState.player.velocity
	var back: Vector3 = -velocity.normalized() * 0.8 if velocity.length_squared() > 0.01 \
		else Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU) * 1.0
	mine.global_position = Vector3(global_position.x, 0.0, global_position.z) + back
	_mines.append(mine)
	Audio.play(&"mine")


## Mines read damage and radius live, so upgrades apply to mines already on the ground.
func chain_from(source: OrnamentMine) -> void:
	if not evolved:
		return
	var reach: float = radius() * chain_range
	for mine in _mines:
		if is_instance_valid(mine) and mine != source and not mine.exploded \
				and mine.global_position.distance_to(source.global_position) < reach:
			mine.explode(0.12)
